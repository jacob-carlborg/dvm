/**
 * Copyright: Copyright (c) 2009 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 21, 2009
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.util.Registry;

version (Windows) {} else
	static assert(false, "dvm.util.Registry is only for Windows");

/// High-Level Registry Utilities

import mambo.core.string;
import dvm.sys.Registry;
import dvm.util.Windows;
import tango.sys.win32.Types;
import tango.sys.win32.UserGdi;

public import dvm.sys.Registry :
	RegRoot,
	HKEY_CLASSES_ROOT,
	HKEY_CURRENT_USER,
	HKEY_LOCAL_MACHINE,
	HKEY_USERS,
	HKEY_PERFORMANCE_DATA,
	HKEY_CURRENT_CONFIG,
	HKEY_DYN_DATA,
	RegKeyAccess,
	RegValueType,
	RegQueryResult,
	RegistryException,
	toString;

enum RegKeyOpenMode
{
	Open, Create
}

scope final class RegistryKey
{
	/// Properties ////////////////////////
	private RegRoot _root;
	private string _subKey;
	private RegKeyAccess _access;
	private HKEY _hKey;
	private bool _wasCreated=false;

	RegRoot root()
	{
		return _root;
	}
	string subKey()
	{
		return _subKey.dup;
	}
	RegKeyAccess access()
	{
		return _access;
	}
	HKEY hKey()
	{
		return _hKey;
	}
	bool wasCreated()
	{
		return _wasCreated;
	}
	
	/// toString ////////////////////////
	string toString()
	{
		return dvm.sys.Registry.toString(_root) ~ `\` ~ _subKey;
	}
	
	static string toString(RegRoot root, string subKey)
	{
		return dvm.sys.Registry.toString(root) ~ `\` ~ subKey;
	}
	
	/// Private Error Handling Utilities ////////////////////////
	private static string chooseErrorMsg(WinAPIException e, string msg)
	{
		if(msg == "")
		{
			auto re = cast(RegistryException)e;
			if(re)
				return re.registryMsg;
		}
		return msg;
	}
	
	private static void staticErrorKey(WinAPIException e, RegRoot root, string subKey, string msg="")
	{
		msg = chooseErrorMsg(e, msg);
		throw new RegistryException(e.code, toString(root, subKey), true, msg);
	}
	
	private void errorKey(WinAPIException e, string msg="")
	{
		msg = chooseErrorMsg(e, msg);
		throw new RegistryException(e.code, this.toString(), true, msg);
	}
	
	private void errorValue(WinAPIException e, string valueName, string msg="")
	{
		msg = chooseErrorMsg(e, msg);
		
		if(valueName == "")
			valueName = "(Default)";

		throw new RegistryException(e.code, this.toString()~`\`~valueName, false, msg);
	}
	
	/// Constructor/Destructor ////////////////////////
	this(
		RegRoot root, string subKey,
		RegKeyOpenMode create = RegKeyOpenMode.Open,
		RegKeyAccess access = RegKeyAccess.All
	)
	{
		_root   = root;
		_subKey = subKey;
		_access = access;
		
		if(create == RegKeyOpenMode.Create)
		{
			try _hKey = regCreateKey(cast(HKEY)root, subKey, 0, access, _wasCreated);
			catch(WinAPIException e) errorKey(e);
		}
		else
		{
			try _hKey = regOpenKey(cast(HKEY)root, subKey, access);
			catch(WinAPIException e) errorKey(e);
		}
	}
	
	~this()
	{
		try regCloseKey(_hKey);
		catch(WinAPIException e) errorKey(e);
	}
	
	/// Registry Functions ////////////////////////
	static void deleteKey(RegRoot root, string subKey)
	{
		try
		{
			scope key = new RegistryKey(root, "", RegKeyOpenMode.Open, RegKeyAccess.Write);
			regDeleteKey(key._hKey, subKey);
		}
		catch(WinAPIException e)
			staticErrorKey(e, root, subKey);
	}

	void deleteValue(string valueName)
	{
		try regDeleteValue(_hKey, valueName);
		catch(WinAPIException e) errorValue(e, valueName);
	}
	
	bool valueExists(string valueName)
	{
		try return regValueExists(_hKey, valueName);
		catch(WinAPIException e) errorValue(e, valueName);
	}
	
	/// Registry Functions: setValue //////////////////////////////
	void setValue(string valueName, RegValueType type, ubyte[] data)
	{
		try regSetValue(_hKey, valueName, type, data);
		catch(WinAPIException e) errorValue(e, valueName);
	}

	void setValue(string valueName, string data)
	{
		try regSetValue(_hKey, valueName, data);
		catch(WinAPIException e) errorValue(e, valueName);
	}

	void setValueExpand(string valueName, string data)
	{
		try regSetValueExpand(_hKey, valueName, data);
		catch(WinAPIException e) errorValue(e, valueName);
	}

	void setValue(string valueName, string data, bool expand)
	{
		try regSetValue(_hKey, valueName, data, expand);
		catch(WinAPIException e) errorValue(e, valueName);
	}

	void setValue(string valueName, string[] data)
	{
		try regSetValue(_hKey, valueName, data);
		catch(WinAPIException e) errorValue(e, valueName);
	}

	void setValue(string valueName, ubyte[] data)
	{
		try regSetValue(_hKey, valueName, data);
		catch(WinAPIException e) errorValue(e, valueName);
	}

	void setValue(string valueName, uint data)
	{
		try regSetValue(_hKey, valueName, data);
		catch(WinAPIException e) errorValue(e, valueName);
	}

	void setValue(string valueName)
	{
		try regSetValue(_hKey, valueName);
		catch(WinAPIException e) errorValue(e, valueName);
	}

	void setValue(string valueName, RegQueryResult data)
	{
		try regSetValue(_hKey, valueName, data);
		catch(WinAPIException e) errorValue(e, valueName);
	}

	/// Registry Functions: getValue //////////////////////////////
	RegQueryResult getValue(string valueName)
	{
		try return regQueryValue(_hKey, valueName);
		catch(WinAPIException e) errorValue(e, valueName);
	}

	string getValueString(string valueName)
	{
		try return regQueryValue!(RegValueType.SZ)(_hKey, valueName);
		catch(WinAPIException e) errorValue(e, valueName);
	}

	string getValueExpandString(string valueName)
	{
		try return regQueryValue!(RegValueType.EXPAND_SZ)(_hKey, valueName);
		catch(WinAPIException e) errorValue(e, valueName);
	}

	string[] getValueStringArray(string valueName)
	{
		try return regQueryValue!(RegValueType.MULTI_SZ)(_hKey, valueName);
		catch(WinAPIException e) errorValue(e, valueName);
	}

	ubyte[] getValueBinary(string valueName)
	{
		try return regQueryValue!(RegValueType.BINARY)(_hKey, valueName);
		catch(WinAPIException e) errorValue(e, valueName);
	}

	uint getValueUInt(string valueName)
	{
		try return regQueryValue!(RegValueType.DWORD)(_hKey, valueName);
		catch(WinAPIException e) errorValue(e, valueName);
	}
}
