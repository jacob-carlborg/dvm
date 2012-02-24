/**
 * Copyright: Copyright (c) 2011 Nick Sabalausky. All rights reserved.
 * Authors: Nick Sabalausky
 * Version: Initial created: Jun 1, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.sys.Registry;

version (Windows):

import tango.sys.win32.Types;
import tango.sys.win32.UserGdi;
import tango.text.Util;
import tango.util.Convert;

import mambo.core.string;
import dvm.dvm.Exceptions;
import dvm.util.Windows;

/// Low-Level Registry Wrappers
///
/// WARNING: REG_MULTI_SZ, REG_BINARY and REG_NONE are untested.

/// Types and Constants ///////////////////////////

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
	REG_OPTION_CREATE_LINK = 2,
	REG_OPTION_BACKUP_RESTORE = 4,
}

enum RegRoot : DWORD
{
	HKEY_CLASSES_ROOT = (0x80000000),
	HKEY_CURRENT_USER = (0x80000001),
	HKEY_LOCAL_MACHINE = (0x80000002),
	HKEY_USERS = (0x80000003),
	HKEY_PERFORMANCE_DATA = (0x80000004),
	HKEY_CURRENT_CONFIG = (0x80000005),
	HKEY_DYN_DATA = (0x80000006),
}

HKEY HKEY_CLASSES_ROOT ()
{
	return cast(HKEY) RegRoot.HKEY_CLASSES_ROOT;
}

HKEY HKEY_CURRENT_USER ()
{
	return cast(HKEY) RegRoot.HKEY_CURRENT_USER;
}

HKEY HKEY_LOCAL_MACHINE ()
{
	return cast(HKEY) RegRoot.HKEY_LOCAL_MACHINE;
}

HKEY HKEY_USERS ()
{
	return cast(HKEY) RegRoot.HKEY_USERS;
}

HKEY HKEY_PERFORMANCE_DATA ()
{
	return cast(HKEY) RegRoot.HKEY_PERFORMANCE_DATA;
}

HKEY HKEY_CURRENT_CONFIG ()
{
	return cast(HKEY) RegRoot.HKEY_CURRENT_CONFIG;
}

HKEY HKEY_DYN_DATA ()
{
	return cast(HKEY) RegRoot.HKEY_DYN_DATA;
}

enum RegKeyAccess
{
	Read, Write, All
}

enum RegValueType : DWORD
{
	Unknown = DWORD.max,

	BINARY = REG_BINARY,
	DWORD = REG_DWORD,
	EXPAND_SZ = REG_EXPAND_SZ,
	LINK = REG_LINK,
	MULTI_SZ = REG_MULTI_SZ,
	NONE = REG_NONE,
	SZ = REG_SZ,

	// Beware, these are reported to not work on all versions
	// of Windows from Win2K and up:
	//QWORD = REG_QWORD,
	//QWORD_LITTLE_ENDIAN = REG_QWORD_LITTLE_ENDIAN,
	DWORD_LITTLE_ENDIAN = REG_DWORD_LITTLE_ENDIAN,
	DWORD_BIG_ENDIAN = REG_DWORD_BIG_ENDIAN,
}

struct RegQueryResult
{
	RegValueType type;
	string asString;
	string[] asStringArray;
	uint asUInt;
	ubyte[] asBinary;
}

template DataTypeOf (RegValueType type)
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

/// Exception ///////////////////////////

class RegistryException : WinAPIException
{
	string registryMsg;
	string path;
	bool isKey; // Is path a key or a value?
	
	this (LONG code, string path, bool isKey, string registryMsg="")
	{
		this.registryMsg = registryMsg;
		this.path = path;
		this.isKey = isKey;
		
		string keyInfo;
		if(isKey)
			keyInfo = "Registry Key '" ~ path ~ "': ";
		else
			keyInfo = "Registry Value '" ~ path ~ "': ";
		
		string regMsgInfo = registryMsg;
		string windowsMsg = "";

		if(code != ERROR_SUCCESS)
			windowsMsg = WinAPIException.getMessage(code);

		if(regMsgInfo != "" && windowsMsg != "")
			regMsgInfo ~= ": ";
		
		super(code, keyInfo ~ regMsgInfo ~ windowsMsg);
	}

	this (string path, bool isKey, string registryMsg = "")
	{
		this(ERROR_SUCCESS, path, isKey, registryMsg);
	}
}

/// Conversion Functions ///////////////////////////

private alias dvm.util.Windows.toString16z toString16z;
private alias dvm.core.string.toString16z toString16z;

ubyte[] toRegDWord (ref uint val)
{
	return (cast(ubyte*) &val)[0..4];
}

ubyte[] toRegSZ (string str)
{
	auto wstr = to!(wstring)(str);

	if(wstr.length == 0 || wstr[$-1] != '\0')
		wstr ~= '\0';

	return cast(ubyte[])wstr;
}

ubyte[] toRegMultiSZ (string[] arr)
{
	ushort[] result;

	foreach(str; arr)
	{
		if(str.length == 0)
			throw new DvmException("Cannot store empty strings in a REG_MULTI_SZ", __FILE__, __LINE__);
		
		auto wstr = to!(wstring)(str);
		result ~= cast(ushort[]) wstr;
		result ~= 0;
	}

	result ~= 0;
	
	return cast(ubyte[]) result;
}

REGSAM toRegSam (RegKeyAccess access)
{
	switch(access)
	{
		case RegKeyAccess.Read: return KEY_READ;
		case RegKeyAccess.Write: return KEY_WRITE;
		case RegKeyAccess.All: return KEY_READ | KEY_WRITE;

		default:
			throw new Exception("Internal Error: Unhandled RegKeyAccess: '" ~ to!(string)(access) ~ "'", __FILE__, __LINE__);
	}
}

string toString (RegRoot root)
{
	switch(root)
	{
		case RegRoot.HKEY_CLASSES_ROOT: return "HKEY_CLASSES_ROOT";
		case RegRoot.HKEY_CURRENT_USER: return "HKEY_CURRENT_USER";
		case RegRoot.HKEY_LOCAL_MACHINE: return "HKEY_LOCAL_MACHINE";
		case RegRoot.HKEY_USERS: return "HKEY_USERS";
		case RegRoot.HKEY_PERFORMANCE_DATA: return "HKEY_PERFORMANCE_DATA";
		case RegRoot.HKEY_CURRENT_CONFIG: return "HKEY_CURRENT_CONFIG";
		case RegRoot.HKEY_DYN_DATA: return "HKEY_DYN_DATA";

		default:
			throw new Exception("Internal Error: Unhandled RegRoot '" ~ to!(string)(root) ~ "'", __FILE__, __LINE__);
	}
}

string toString (RegValueType type)
{
	switch(type)
	{
		case RegValueType.BINARY: return "REG_BINARY";
		case RegValueType.DWORD: return "REG_DWORD";
		case RegValueType.EXPAND_SZ: return "REG_EXPAND_SZ";
		case RegValueType.LINK: return "REG_LINK";
		case RegValueType.MULTI_SZ: return "REG_MULTI_SZ";
		case RegValueType.NONE: return "REG_NONE";
		case RegValueType.SZ: return "REG_SZ";
		case RegValueType.DWORD_BIG_ENDIAN: return "REG_DWORD_BIG_ENDIAN";
		case RegValueType.Unknown: return "(Unknown KeyValueType)";

		default:
			return "(KeyValueType #" ~ to!(string)(cast(DWORD) type) ~ ")";
	}
}

/// Private Error Handling Utilities ///////////////////////////

private void ensureSuccess (LONG code, string path, bool isKey, string registryMsg="")
{
	if (code != ERROR_SUCCESS)
		error(code, path, isKey, registryMsg);
}

private void ensureSuccessKey (LONG code, string path, string registryMsg="")
{
	ensureSuccess(code, path, true, registryMsg);
}

private void ensureSuccessValue (LONG code, string path, string registryMsg="")
{
	ensureSuccess(code, path, false, registryMsg);
}

private void error (LONG code, string path, bool isKey, string registryMsg="")
{
	throw new RegistryException(code, `{Unknown Path}\` ~ path, isKey, registryMsg);
}

private void errorKey (LONG code, string path, string registryMsg="")
{
	error(code, path, true, registryMsg);
}

private void errorValue (LONG code, string path, string registryMsg="")
{
	error(code, path, false, registryMsg);
}

/// Registry Functions ///////////////////////////

HKEY regOpenKey (HKEY hKey, string subKey, RegKeyAccess access)
{
	HKEY outKey;
	
	auto result = RegOpenKeyExW(hKey, to!(wstring)(subKey).toString16z(),0, toRegSam(access), &outKey);
	ensureSuccessKey(result, subKey, "Couldn't open key");
		
	return outKey;
}

HKEY regCreateKey (HKEY hKey, string subKey, DWORD dwOptions, RegKeyAccess access, out bool wasCreated)
{
	HKEY outKey;
	DWORD disposition;
	auto result = RegCreateKeyExW(hKey, subKey.toString16z(), 0, null, dwOptions, toRegSam(access), null, &outKey, &disposition);	
	wasCreated = (disposition == REG_CREATED_NEW_KEY);	
	ensureSuccessKey(result, subKey, "Couldn't open or create key");
		
	return outKey;
}

HKEY regCreateKey (HKEY hKey, string subKey, DWORD dwOptions, RegKeyAccess access)
{
	bool wasCreated;
	return regCreateKey(hKey, subKey, dwOptions, access, wasCreated);
}

void regCloseKey (HKEY hKey)
{
	auto result = RegCloseKey(hKey);
	ensureSuccessKey(result, "{Unknown Key}", "Couldn't close key");
}

bool regValueExists (HKEY hKey, string valueName)
{
	auto result = RegQueryValueExW(hKey, valueName.toString16z(), null, null, null, null);

	if(result == ERROR_FILE_NOT_FOUND)
		return false;
	
	if(result == ERROR_SUCCESS)
		return true;

	errorValue(result, valueName, "Couldn't check if value exists");
}

void regDeleteKey (HKEY hKey, string subKey)
{
	auto result = RegDeleteKeyW(hKey, subKey.toString16z());
	ensureSuccessKey(result, subKey, "Couldn't delete key");
}

void regDeleteValue (HKEY hKey, string valueName)
{
	auto result = RegDeleteValueW(hKey, valueName.toString16z());
	ensureSuccessValue(result, valueName, "Couldn't delete value");
}

/// Registry Functions: regSetValue ///////////////////////////

/// Be very careful with this particuler version.
/// Make sure to follow all the rules in MS's documentation.
/// The other overloads of regSetValue are recommended over
/// this one, since they already handle all the proper rules.
void regSetValue (HKEY hKey, string valueName, RegValueType type, ubyte[] data)
{
	if(type == RegValueType.Unknown)
		errorValue(ERROR_SUCCESS, valueName, "Can't set a key value of type 'Unknown'");
	
	auto ptr = (data is null)? null : data.ptr;
	auto len = (data is null)? 0 : data.length;
	
	auto result = RegSetValueExW(hKey, valueName.toString16z(), 0, type, ptr, len);
	ensureSuccessValue(result, valueName, "Couldn't set "~toString(type)~" value");
}

void regSetValue (HKEY hKey, string valueName, string data)
{
	regSetValue(hKey, valueName, data, false);
}

void regSetValueExpand (HKEY hKey, string valueName, string data)
{
	regSetValue(hKey, valueName, data, true);
}

void regSetValue (HKEY hKey, string valueName, string data, bool expand)
{
	auto type = expand? RegValueType.EXPAND_SZ : RegValueType.SZ;
	regSetValue(hKey, valueName, type, data.toRegSZ());
}

void regSetValue (HKEY hKey, string valueName, string[] data)
{
	regSetValue(hKey, valueName, RegValueType.MULTI_SZ, data.toRegMultiSZ());
}

void regSetValue (HKEY hKey, string valueName, ubyte[] data)
{
	regSetValue(hKey, valueName, RegValueType.BINARY, data);
}

void regSetValue (HKEY hKey, string valueName, uint data)
{
	regSetValue(hKey, valueName, RegValueType.DWORD, toRegDWord(data));
}

void regSetValue (HKEY hKey, string valueName)
{
	regSetValue(hKey, valueName, RegValueType.NONE, null);
}

void regSetValue (HKEY hKey, string valueName, RegQueryResult data)
{
	switch(data.type)
	{
		case RegValueType.DWORD:
			regSetValue(hKey, valueName, data.type, toRegDWord(data.asUInt));
		break;
		
		case RegValueType.SZ, RegValueType.EXPAND_SZ:
			regSetValue(hKey, valueName, data.type, data.asString.toRegSZ());
		break;

		case RegValueType.MULTI_SZ:
			regSetValue(hKey, valueName, data.type, data.asStringArray.toRegMultiSZ());
		break;
		
		default:
			regSetValue(hKey, valueName, data.type, data.asBinary);
		break;
	}
}

/// Registry Functions: regQueryValue ///////////////////////////

RegQueryResult regQueryValue () (HKEY hKey, string valueName)
{
	RegQueryResult ret;
	DWORD dataSize;
	auto valueNameZ = valueName.toString16z();
	
	auto result = RegQueryValueExW(hKey, valueNameZ, null, null, null, &dataSize);
	ensureSuccessValue(result, valueName, "Couldn't check length of value's data");

	ubyte[] data;
	data.length = dataSize;
	
	result = RegQueryValueExW(hKey, valueNameZ, null, &(cast(DWORD)(ret.type)), data.ptr, &dataSize);
	ensureSuccessValue(result, valueName, "Couldn't get value");

	switch(ret.type)
	{
		case RegValueType.DWORD:
			ret.asUInt = (cast(uint[])data)[0];
		break;
		
		case RegValueType.SZ, RegValueType.EXPAND_SZ:
			ret.asString = to!(string)( (cast(wstring) data)[0 .. $-1] );
		break;

		case RegValueType.MULTI_SZ:
			ret.asStringArray = null;
			auto wstrArr = split(cast(wstring)data, "\0"w)[0 .. $-1];

			foreach(wstr; wstrArr)
				ret.asStringArray ~= to!(string)(wstr);
		break;
		
		default:
			ret.asBinary = data;
		break;
	}

	return ret;
}

DataTypeOf!(type) regQueryValue (RegValueType type) (HKEY hKey, string valueName)
{
	auto result = regQueryValue(hKey, valueName);
	
	if(result.type != type)
		errorValue(ERROR_SUCCESS, valueName, "Expected key type '" ~ toString(type) ~ "', " ~"not '"~toString(result.type)~"'");
	
	alias DataTypeOf!(type) T;

	static if (is(T == uint))
		return result.asUInt;

	else static if (is(T == string))
		return result.asString;

	else static if (is(T == string[]))
		return result.asStringArray;

	else
		return result.asBinary;
}