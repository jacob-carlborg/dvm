/**
 * Copyright: Copyright (c) 2009-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 21, 2009
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.sys.Process;

import tango.sys.Process;
import tango.io.Stdout;
import mambo.core.string;

version (darwin)
{
	import tango.stdc.posix.stdlib;
	import tango.stdc.stringz;
	private extern (C) int _NSGetExecutablePath(char* buf, uint* bufsize);
}

else version (freebsd)
	import tango.stdc.posix.unistd;

else version (linux)
	import tango.stdc.posix.unistd;

else version (Windows)
{
	import tango.sys.win32.UserGdi;
	import tango.text.convert.Utf;
	import tango.text.Util;
}

/**
 * Gets the path of the current process.
 * 
 * To fit the whole path inside the given buffer without
 * using the heap the buffer has to be equal or larger than:
 * 
 * On darwin: 1024
 * On freebsd: 1024
 * On linux: 1024
 * On windows: tango.sys.win32.UserGdi.MAX_PATH + 1
 * 
 * Params:
 *     buf = this buffer will be used unless it's to small
 *     
 * Returns: the path of the current process
 */
char[] getProcessPath (char[] buf = null)
{
	version (darwin)
	{
		uint size;
		
		_NSGetExecutablePath(null, &size); // get the length of the path
		
		if (size > buf.length)
			buf ~= new char[size - buf.length];
		
		_NSGetExecutablePath(buf.ptr, &size);
		
		auto tmp = buf[0 .. size];
		size_t len = 1024 - size;	
		buf = buf[size .. $];
		
		if (len > buf.length)
			buf ~= new char[len - buf.length];

		auto strLen = strlenz(realpath(tmp.ptr, buf.ptr));
		buf = buf[0 .. strLen];;
	}
	
	else version (freebsd)
	{
		const size_t len = 1024;
		
		if (len > buf.length)
			buf ~= new char[len - buf.length];
		
		auto count = readlink("/proc/curproc/file".ptr, buf.ptr, buf.length);
		
		buf = buf[0 .. count];
	}
	
	else version (linux)
	{
		const size_t len = 1024;
		
		if (len > buf.length)
			buf ~= new char[len - buf.length];
		
		auto count = readlink("/proc/self/exe".ptr, buf.ptr, buf.length);
		
		buf = buf[0 .. count];
	}
	
	else version (Windows)
	{
		const size_t len = MAX_PATH + 1; // Don't forget the null char
		
		if (len > buf.length)
			buf ~= new char[len - buf.length];
		
		GetModuleFileNameA(null, buf.ptr, buf.length - 1);
		
		size_t i = buf.locate(char.init);
		
		buf = buf[0 .. i - 1]; // Remove the null char		
	}
	
	else
		assert(false, "getProcessPath is not supported on this platform");

	return buf;
}

/// Copies environment to new process.
/// Waits for process to finish.
/// Params: 'args' is same as in tango.sys.Process.new(true, char[][] args...)
/// Returns: Process.Result (containing status code and reason the process ended)
Process.Result system(char[][] args...)
{
	Process p;
	auto result = system(p, args);
	p.close;
	return result;
}

/// Has extra param to retreive the Process object used so you can obtain extra information.
/// Make sure to call p.close() when you're done with it.
Process.Result system(out Process p, char[][] args...)
{
	p = new Process(true, args);
	p.redirect = Redirect.None;
	p.execute();
	auto result = p.wait();
	return result;
}
