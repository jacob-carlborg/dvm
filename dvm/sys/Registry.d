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
	KEY_WRITE;

enum RegRoot : DWORD
{
	HKEY_CLASSES_ROOT     = (0x80000000),
	HKEY_CURRENT_USER     = (0x80000001),
	HKEY_LOCAL_MACHINE    = (0x80000002),
	HKEY_USERS            = (0x80000003),
	HKEY_PERFORMANCE_DATA = (0x80000004),
	HKEY_CURRENT_CONFIG   = (0x80000005),
	HKEY_DYN_DATA         = (0x80000006),
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

private alias dvm.core.string.toString16z toString16z;
private wchar* toString16z(string str)
{
	return to!(wstring)(str).toString16z();
}

HKEY RegOpenKey(HKEY hKey, string subKey, REGSAM samDesired)
{
	HKEY outKey;
	auto result = RegOpenKeyExW(hKey, to!(wstring)(subKey).toString16z(), 0, samDesired, &outKey);
	if(result != ERROR_SUCCESS)
		throw new WinAPIException(result);
		
	return outKey;
}

HKEY RegCreateKey(
	HKEY hKey,
	string subKey,
	DWORD dwOptions,
	REGSAM samDesired,
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
		samDesired,
		null,
		&outKey,
		&disposition
	);
	
	neededToCreate = (disposition == REG_CREATED_NEW_KEY);
	
	if(result != ERROR_SUCCESS)
		throw new WinAPIException(result);
		
	return outKey;
}

HKEY RegCreateKey(
	HKEY hKey,
	string subKey,
	DWORD dwOptions,
	REGSAM samDesired
)
{
	bool neededToCreate;
	return
		RegCreateKey(
			hKey,
			subKey,
			dwOptions,
			samDesired,
			neededToCreate
		);
}

void RegCloseKey(HKEY hKey)
{
	auto result = tango.sys.win32.UserGdi.RegCloseKey(hKey);
	if(result != ERROR_SUCCESS)
		throw new WinAPIException(result);
}

bool RegValueExists(HKEY hKey, string valueName)
{
	auto result = RegQueryValueExW(hKey, valueName.toString16z(), null, null, null, null);

	if(result == ERROR_FILE_NOT_FOUND)
		return false;
	
	if(result == ERROR_SUCCESS)
		return true;

	throw new WinAPIException(result);
}

/+ RegSetValue +++++++++++++++++++++++++/

/// Be very careful with this particuler version.
/// Make sure to follow all the rules in MS's documentation.
/// The other overloads of RegSetValue are recommended over
/// this one, since they already handle all the proper rules.
void RegSetValue(HKEY hKey, string valueName, RegValueType type, void* dataPtr, size_t dataLength)
{
	if(type == RegValueType.Unknown)
		throw new Exception("Can't set a key value of type 'Unknown'");
		
	auto result = RegSetValueExW(hKey, valueName.toString16z(), 0, type, cast(ubyte*)dataPtr, dataLength);
	if(result != ERROR_SUCCESS)
		throw new WinAPIException(result);
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

	auto wstr = to!(wstring)(data);
	if(wstr.length > 0 && wstr[$-1] != '\0')
		wstr ~= '\0';
	
	RegSetValue(hKey, valueName, type, wstr.ptr, wstr.length * 2);
}

void RegSetValue(HKEY hKey, string valueName, string[] data)
{
	ushort[] finalData;
	foreach(str; data)
	{
		if(str.length == 0)
			throw new Exception("Cannot store empty strings in a REG_MULTI_SZ");
		
		auto wstr = to!(wstring)( str );
		finalData ~= cast(ushort[])wstr;
		finalData ~= 0;
	}
	finalData ~= 0;
	
	RegSetValue(hKey, valueName, RegValueType.MULTI_SZ, finalData.ptr, finalData.length * 2);
}

void RegSetValue(HKEY hKey, string valueName, ubyte[] data)
{
	RegSetValue(hKey, valueName, RegValueType.BINARY, data.ptr, data.length);
}

void RegSetValue(HKEY hKey, string valueName, uint data)
{
	RegSetValue(hKey, valueName, RegValueType.DWORD, &data, data.sizeof);
}

void RegSetValue(HKEY hKey, string valueName)
{
	RegSetValue(hKey, valueName, RegValueType.NONE, null, 0);
}

/+void RegSetValue(HKEY hKey, string valueName, RegQueryResult data)
{
	switch(data.type)
	{
	case RegValueType.DWORD:
		RegSetValue(hKey, valueName, data.type, data.asUInt);
		break;
		
	case RegValueType.SZ, RegValueType.EXPAND_SZ:
		RegSetValue(hKey, valueName, data.type, data.asString);
		break;

	case RegValueType.MULTI_SZ:
		RegSetValue(hKey, valueName, data.type, data.asStringArray);
		break;
		
	default:
		RegSetValue(hKey, valueName, data.type, data.asBinary);
		break;
	}
}+/

/+ RegQueryValue +++++++++++++++++++++++++/

RegQueryResult RegQueryValue()(HKEY hKey, string valueName)
{
	RegQueryResult ret;
	DWORD dataSize;
	auto valueNameZ = valueName.toString16z();
	
	auto result = RegQueryValueExW(hKey, valueNameZ, null, null, null, &dataSize);
	if(result != ERROR_SUCCESS)
		throw new WinAPIException(result);

	ubyte[] data;
	data.length = dataSize;
	
	auto result = RegQueryValueExW(hKey, valueNameZ, null, &ret.type, data.ptr, data.length);
	if(result != ERROR_SUCCESS)
		throw new WinAPIException(result);

	switch(ret.type)
	{
	case RegValueType.DWORD, RegValueType.DWORD_LITTLE_ENDIAN:
		ret.asUInt = (cast(uint[])data)[0];
		break;
		
	case RegValueType.SZ, RegValueType.EXPAND_SZ:
		ret.asString = to!(string)( (cast(wstring)data)[0..$-1] );
		break;

	case RegValueType.MULTI_SZ:
		ret.asStringArray = "";
		auto wstrArr = data.split("\0"w)[0..$-1];
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

