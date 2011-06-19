/**
 * Copyright: Copyright (c) 2011 Nick Sabalausky.
 * Authors: Nick Sabalausky
 * Version: Initial created: Jun 1, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.util.Windows;

version (Windows):

import dvm.core.string;
import dvm.dvm.Exceptions;
import tango.sys.win32.Types;
import tango.sys.win32.UserGdi;
import tango.util.Convert;

// If FORMAT_MESSAGE_ALLOCATE_BUFFER is used, then this is the correct
// signature. Otherwise, the signature in tango.sys.win32.UserGdi is corrent.
extern (Windows) DWORD FormatMessageW (DWORD, LPCVOID, DWORD, DWORD, LPWSTR*, DWORD, VA_LIST*);

class WinAPIException : DvmException
{
	LONG code;
	string windowsMsg;
	
	this (LONG code, string msg="")
	{
		this.code = code;

		if(windowsMsg == "")
			windowsMsg = getMessage(code);

		super(msg==""? windowsMsg : msg);
	}
	
	static string getMessage (DWORD errorCode)
	{
		wchar* pMsg;

		auto result = FormatMessageW(
			FORMAT_MESSAGE_ALLOCATE_BUFFER | 
			FORMAT_MESSAGE_FROM_SYSTEM     |
			FORMAT_MESSAGE_IGNORE_INSERTS,
			null, errorCode, 0, &pMsg, 0, null
		);
		
		if(result == 0)
			return "Unknown WinAPI Error";

		scope (exit)
			LocalFree(pMsg);

		auto msg = fromString16z(pMsg);
		return to!(string)(msg);
	}
}

private alias dvm.core.string.toString16z toString16z;

wchar* toString16z (string str)
{
	return to!(wstring)(str).toString16z();
}

import tango.io.Stdout;
/// For more info, see: http://msdn.microsoft.com/en-us/library/ms725497(VS.85).aspx
void broadcastSettingChange (string settingName, uint timeout=1)
{
	auto result = SendMessageTimeoutW(
		HWND_BROADCAST, WM_SETTINGCHANGE,
		0, cast(LPARAM)(settingName.toString16z()),
		SMTO_ABORTIFHUNG, timeout, null
	);
	
	if(result == 0)
	{
		auto errCode = GetLastError();
		Stdout.formatln("ERROR_SUCCESS==0: {}", ERROR_SUCCESS == 0);

		if (errCode != ERROR_SUCCESS)
			throw new WinAPIException(errCode, "Problem broadcasting WM_SETTINGCHANGE of '"~settingName~"'");
	}
}
