/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 26, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.util.Windows;

version (Windows) {} else
	static assert(false, "dvm.util.Windows is only for Windows");

import dvm.core.string;
import tango.sys.win32.Types;
import tango.sys.win32.UserGdi;
import tango.util.Convert;

// If FORMAT_MESSAGE_ALLOCATE_BUFFER is used, then this is the correct
// signature. Otherwise, the signature in tango.sys.win32.UserGdi is corrent.
extern(Windows) DWORD FormatMessageW(DWORD, LPCVOID, DWORD, DWORD, LPWSTR*, DWORD, VA_LIST*);

class WinAPIException : Exception
{
	LONG code;
	string windowsMsg;
	
	this(LONG code, string msg="")
	{
		this.code = code;

		if(windowsMsg == "")
			windowsMsg = getMessage(code);

		super(msg==""? windowsMsg : msg);
	}
	
	static string getMessage(DWORD errorCode)
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
		
		scope(exit)	LocalFree(pMsg);
			
		auto msg = fromString16z(pMsg);
		return to!(string)(msg);
	}
}
