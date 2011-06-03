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

import dvm.core.string;
import dvm.sys.Registry;
import dvm.util.Windows;
import tango.sys.win32.Types;
import tango.sys.win32.UserGdi;

import tango.io.Stdout;

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
	
	string toString()
	{
		return dvm.sys.Registry.toString(_root) ~ `\` ~ _subKey;
	}
	
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
			_hKey = RegCreateKey(cast(HKEY)root, subKey, 0, access, _wasCreated);
		else
			_hKey = RegOpenKey(cast(HKEY)root, subKey, access);
	}
	
	~this()
	{
		dvm.sys.Registry.RegCloseKey(_hKey);
	}
	
	static void deleteKey(RegRoot root, string subKey)
	{
		scope key = new RegistryKey(root, "", RegKeyOpenMode.Open, RegKeyAccess.Write);
		RegDeleteKey(key._hKey, subKey);
	}

	void deleteValue(string valueName)
	{
		RegDeleteValue(_hKey, valueName);
	}
	
	bool valueExists(string valueName)
	{
		return RegValueExists(_hKey, valueName);
	}
	
	/// setValue //////////////////////////////
	void setValue(string valueName, RegValueType type, ubyte[] data)
	{
		RegSetValue(_hKey, valueName, type, data);
	}

	void setValue(string valueName, string data)
	{
		RegSetValue(_hKey, valueName, data);
	}

	void setValueExpand(string valueName, string data)
	{
		RegSetValueExpand(_hKey, valueName, data);
	}

	void setValue(string valueName, string data, bool expand)
	{
		RegSetValue(_hKey, valueName, data, expand);
	}

	void setValue(string valueName, string[] data)
	{
		RegSetValue(_hKey, valueName, data);
	}

	void setValue(string valueName, ubyte[] data)
	{
		RegSetValue(_hKey, valueName, data);
	}

	void setValue(string valueName, uint data)
	{
		RegSetValue(_hKey, valueName, data);
	}

	void setValue(string valueName)
	{
		RegSetValue(_hKey, valueName);
	}

	void setValue(string valueName, RegQueryResult data)
	{
		RegSetValue(_hKey, valueName, data);
	}

	/// getValue //////////////////////////////
	RegQueryResult getValue(string valueName)
	{
		return RegQueryValue(_hKey, valueName);
	}

	string getValueString(string valueName)
	{
		return RegQueryValue!(RegValueType.SZ)(_hKey, valueName);
	}

	string getValueExpandString(string valueName)
	{
		return RegQueryValue!(RegValueType.EXPAND_SZ)(_hKey, valueName);
	}

	string[] getValueStringArray(string valueName)
	{
		return RegQueryValue!(RegValueType.MULTI_SZ)(_hKey, valueName);
	}

	ubyte[] getValueBinary(string valueName)
	{
		return RegQueryValue!(RegValueType.BINARY)(_hKey, valueName);
	}

	uint getValueUInt(string valueName)
	{
		return RegQueryValue!(RegValueType.DWORD)(_hKey, valueName);
	}
}

/+ RegSetValue +++++++++++++++++++++++++/

