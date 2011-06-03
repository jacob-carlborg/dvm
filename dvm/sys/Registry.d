/**
 * Copyright: Copyright (c) 2009 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 21, 2009
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.sys.Registry;

version (Windows) {} else
	static assert(false, "dvm.sys.Registry is only for Windows");

import dvm.core.string;
import dvm.util.Windows;
import tango.sys.win32.Types;
import tango.sys.win32.UserGdi;
import tango.text.Util;
import tango.util.Convert;

/// WARNING: REG_DWORD, REG_MULTI_SZ, REG_BINARY and REG_NONE are untested.

/+ Types and Constants +++++++++++++++++++++++++/

public import tango.sys.win32.Types :
	HKEY,
	KEY_ALL_ACCESS,
	KEY_CREATE_LINK,
	KEY_CREATE_SUB_KEY,
	KEY_ENUMERATE_SUB_KEYS,
	KEY_EXECUTE,
	KEY_NOTIFY,
	KEY_QUERY_VALUE,
	KEY_READ,
	KEY_SET_VALUE,
	KEY_WRITE,
	REG_OPTION_NON_VOLATILE,
	REG_OPTION_VOLATILE;
	
enum : DWORD
{
	REG_OPTION_CREATE_LINK    = 2,
	REG_OPTION_BACKUP_RESTORE = 4,
}

enum RegRootEnum : DWORD
{
	HKEY_CLASSES_ROOT     = (0x80000000),
	HKEY_CURRENT_USER     = (0x80000001),
	HKEY_LOCAL_MACHINE    = (0x80000002),
	HKEY_USERS            = (0x80000003),
	HKEY_PERFORMANCE_DATA = (0x80000004),
	HKEY_CURRENT_CONFIG   = (0x80000005),
	HKEY_DYN_DATA         = (0x80000006),
}

HKEY HKEY_CLASSES_ROOT()     { return cast(HKEY) RegRootEnum.HKEY_CLASSES_ROOT;     }
HKEY HKEY_CURRENT_USER()     { return cast(HKEY) RegRootEnum.HKEY_CURRENT_USER;     }
HKEY HKEY_LOCAL_MACHINE()    { return cast(HKEY) RegRootEnum.HKEY_LOCAL_MACHINE;    }
HKEY HKEY_USERS()            { return cast(HKEY) RegRootEnum.HKEY_USERS;            }
HKEY HKEY_PERFORMANCE_DATA() { return cast(HKEY) RegRootEnum.HKEY_PERFORMANCE_DATA; }
HKEY HKEY_CURRENT_CONFIG()   { return cast(HKEY) RegRootEnum.HKEY_CURRENT_CONFIG;   }
HKEY HKEY_DYN_DATA()         { return cast(HKEY) RegRootEnum.HKEY_DYN_DATA;         }

enum RegKeyAccess
{
	Read, Write, All
}

enum RegValueType : DWORD
{
	Unknown             = DWORD.max,

	BINARY              = REG_BINARY,
	DWORD               = REG_DWORD,
	EXPAND_SZ           = REG_EXPAND_SZ,
	LINK                = REG_LINK,
	MULTI_SZ            = REG_MULTI_SZ,
	NONE                = REG_NONE,
	SZ                  = REG_SZ,

	// Beware, these are reported to not work on all versions
	// of Windows from Win2K and up:
	//QWORD               = REG_QWORD,
	//QWORD_LITTLE_ENDIAN = REG_QWORD_LITTLE_ENDIAN,
	DWORD_LITTLE_ENDIAN = REG_DWORD_LITTLE_ENDIAN,
	DWORD_BIG_ENDIAN    = REG_DWORD_BIG_ENDIAN,
}

struct RegQueryResult
{
	RegValueType type;
	string   asString;
	string[] asStringArray;
	uint     asUInt;
	ubyte[]  asBinary;
}

template DataTypeOf(RegValueType type)
{
	static if(type == RegValueType.DWORD)
		alias uint DataTypeOf;
		
	else static if(type == RegValueType.DWORD_LITTLE_ENDIAN)
		alias uint DataTypeOf;
		
	else static if(type == RegValueType.SZ)
		alias string DataTypeOf;
		
	else static if(type == RegValueType.EXPAND_SZ)
		alias string DataTypeOf;
		
	else static if(type == RegValueType.MULTI_SZ)
		alias string[] DataTypeOf;
		
	else
		alias ubyte[] DataTypeOf;
}

/+ Exception +++++++++++++++++++++++++/

class RegistryException : WinAPIException
{
	string action;
	
	this(LONG code, string action="")
	{
		this.action = action;
		super(code, action);
	}
}

/+ Conversion Functions +++++++++++++++++++++++++/

private alias dvm.core.string.toString16z toString16z;
private wchar* toString16z(string str)
{
	return to!(wstring)(str).toString16z();
}

ubyte[] toRegDWord(ref uint val)
{
	return (cast(ubyte*)&val)[0..4];
}

ubyte[] toRegSZ(string str)
{
	auto wstr = to!(wstring)(str);
	if(wstr.length == 0 || wstr[$-1] != '\0')
		wstr ~= '\0';
	return cast(ubyte[])wstr;
}

ubyte[] toRegMultiSZ(string[] arr)
{
	ushort[] result;
	foreach(str; arr)
	{
		if(str.length == 0)
			throw new Exception("Cannot store empty strings in a REG_MULTI_SZ");
		
		auto wstr = to!(wstring)(str);
		result ~= cast(ushort[])wstr;
		result ~= 0;
	}
	result ~= 0;
	
	return cast(ubyte[])result;
}

REGSAM toRegSam(RegKeyAccess access)
{
	switch(access)
	{
	case RegKeyAccess.Read:  return KEY_READ;
	case RegKeyAccess.Write: return KEY_WRITE;
	case RegKeyAccess.All:   return KEY_READ | KEY_WRITE;
	default:
		throw new Exception("Internal Error: Unhandled RegKeyAccess: '"~to!(string)(access)~"'");
	}
}

/+ Registry Functions +++++++++++++++++++++++++/

HKEY RegOpenKey(HKEY hKey, string subKey, RegKeyAccess access)
{
	HKEY outKey;
	
	auto result =
		RegOpenKeyExW(
			hKey,
			to!(wstring)(subKey).toString16z(),
			0, toRegSam(access), &outKey
		);

	if(result != ERROR_SUCCESS)
		throw new RegistryException(result, "Open SubKey '"~subKey~"'");
		
	return outKey;
}

HKEY RegCreateKey(
	HKEY hKey,
	string subKey,
	DWORD dwOptions,
	RegKeyAccess access,
	out bool neededToCreate
)
{
	HKEY outKey;
	DWORD disposition;
	auto result = RegCreateKeyExW(
		hKey,
		subKey.toString16z(),
		0,
		null,
		dwOptions,
		toRegSam(access),
		null,
		&outKey,
		&disposition
	);
	
	neededToCreate = (disposition == REG_CREATED_NEW_KEY);
	
	if(result != ERROR_SUCCESS)
		throw new RegistryException(result, "Create/Open SubKey '"~subKey~"'");
		
	return outKey;
}

HKEY RegCreateKey(
	HKEY hKey,
	string subKey,
	DWORD dwOptions,
	RegKeyAccess access
)
{
	bool neededToCreate;
	return
		RegCreateKey(
			hKey,
			subKey,
			dwOptions,
			access,
			neededToCreate
		);
}

void RegCloseKey(HKEY hKey)
{
	auto result = tango.sys.win32.UserGdi.RegCloseKey(hKey);
	if(result != ERROR_SUCCESS)
		throw new RegistryException(result, "Close Key");
}

bool RegValueExists(HKEY hKey, string valueName)
{
	auto result = RegQueryValueExW(hKey, valueName.toString16z(), null, null, null, null);

	if(result == ERROR_FILE_NOT_FOUND)
		return false;
	
	if(result == ERROR_SUCCESS)
		return true;

	throw new RegistryException(result, "Check if value '"~valueName~"' exists");
}

void RegDeleteKey(HKEY hKey, string subKey)
{
	auto result = RegDeleteKeyW(hKey, subKey.toString16z());
	if(result != ERROR_SUCCESS)
		throw new RegistryException(result, "Delete SubKey '"~subKey~"'");
}

void RegDeleteValue(HKEY hKey, string valueName)
{
	auto result = RegDeleteValueW(hKey, valueName.toString16z());
	if(result != ERROR_SUCCESS)
		throw new RegistryException(result, "Delete Value '"~valueName~"'");
}

/+ RegSetValue +++++++++++++++++++++++++/

/// Be very careful with this particuler version.
/// Make sure to follow all the rules in MS's documentation.
/// The other overloads of RegSetValue are recommended over
/// this one, since they already handle all the proper rules.
void RegSetValue(HKEY hKey, string valueName, RegValueType type, ubyte[] data)
{
	if(type == RegValueType.Unknown)
		throw new Exception("Can't set a key value of type 'Unknown'");
	
	auto ptr = (data is null)? null : data.ptr;
	auto len = (data is null)? 0    : data.length;
	
	auto result = RegSetValueExW(hKey, valueName.toString16z(), 0, type, ptr, len);
	if(result != ERROR_SUCCESS)
		throw new RegistryException(result, "Set Value '"~valueName~"'");
}

void RegSetValue(HKEY hKey, string valueName, string data)
{
	RegSetValue(hKey, valueName, data, false);
}

void RegSetValueExpand(HKEY hKey, string valueName, string data)
{
	RegSetValue(hKey, valueName, data, true);
}

void RegSetValue(HKEY hKey, string valueName, string data, bool expand)
{
	auto type = expand? RegValueType.EXPAND_SZ : RegValueType.SZ;
	RegSetValue(hKey, valueName, type, data.toRegSZ());
}

void RegSetValue(HKEY hKey, string valueName, string[] data)
{
	RegSetValue(hKey, valueName, RegValueType.MULTI_SZ, data.toRegMultiSZ());
}

void RegSetValue(HKEY hKey, string valueName, ubyte[] data)
{
	RegSetValue(hKey, valueName, RegValueType.BINARY, data);
}

void RegSetValue(HKEY hKey, string valueName, uint data)
{
	RegSetValue(hKey, valueName, RegValueType.DWORD, toRegDWord(data));
}

void RegSetValue(HKEY hKey, string valueName)
{
	RegSetValue(hKey, valueName, RegValueType.NONE, null);
}

void RegSetValue(HKEY hKey, string valueName, RegQueryResult data)
{
	switch(data.type)
	{
	case RegValueType.DWORD:
		RegSetValue(hKey, valueName, data.type, toRegDWord(data.asUInt));
		break;
		
	case RegValueType.SZ, RegValueType.EXPAND_SZ:
		RegSetValue(hKey, valueName, data.type, data.asString.toRegSZ());
		break;

	case RegValueType.MULTI_SZ:
		RegSetValue(hKey, valueName, data.type, data.asStringArray.toRegMultiSZ());
		break;
		
	default:
		RegSetValue(hKey, valueName, data.type, data.asBinary);
		break;
	}
}

/+ RegQueryValue +++++++++++++++++++++++++/

RegQueryResult RegQueryValue()(HKEY hKey, string valueName)
{
	RegQueryResult ret;
	DWORD dataSize;
	auto valueNameZ = valueName.toString16z();
	
	auto result = RegQueryValueExW(hKey, valueNameZ, null, null, null, &dataSize);
	if(result != ERROR_SUCCESS)
		throw new RegistryException(result, "Check length of data for value '"~valueName~"'");

	ubyte[] data;
	data.length = dataSize;
	
	result = RegQueryValueExW(hKey, valueNameZ, null, &(cast(DWORD)(ret.type)), data.ptr, &dataSize);
	if(result != ERROR_SUCCESS)
		throw new RegistryException(result, "Query Value '"~valueName~"'");

	switch(ret.type)
	{
	case RegValueType.DWORD:
		ret.asUInt = (cast(uint[])data)[0];
		break;
		
	case RegValueType.SZ, RegValueType.EXPAND_SZ:
		ret.asString = to!(string)( (cast(wstring)data)[0..$-1] );
		break;

	case RegValueType.MULTI_SZ:
		ret.asStringArray = null;
		auto wstrArr = split(cast(wstring)data, "\0"w)[0..$-1];
		foreach(wstr; wstrArr)
			ret.asStringArray ~= to!(string)(wstr);
		break;
		
	default:
		ret.asBinary = data;
		break;
	}

	return ret;
}

DataTypeOf!(type) RegQueryValue(RegValueType type)(HKEY hKey, string valueName)
{
	auto result = RegQueryValue(hKey, valueName);
	
	if(result.type != type)
		throw new Exception(
			"Expected key type '"~to!(string)(type)~"', "~
			"not '"~to!(string)(result.type)~"' for key '"~valueName~"'"
		);
	
	alias DataTypeOf!(type) T;
	static if(is(T==uint))
		return result.asUInt;
	else static if(is(T==string))
		return result.asString;
	else static if(is(T==string[]))
		return result.asStringArray;
	else
		return result.asBinary;
}

