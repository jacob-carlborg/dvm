/**
 * Copyright: Copyright (c) 2009 Jacob Carlborg.
 * Authors: Jacob Carlborg
 * Version: Initial created: Mar 28, 2009
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.util.Version;

template Version (char[] V)
{
	mixin(
	"version(" ~ V ~ ")
	{
		const bool Version = true;
	}
	else
	{
		const bool Version = false;
	}");
}

version (GNU)
{	
	static if ((void*).sizeof > int.sizeof)
		version = D_LP64;
}

version (DigitalMars)
	version (OSX)
		version = darwin;

version (osx)
	version = darwin;

//Compiler Vendors
version (DigitalMars) const bool DigitalMars = true;
else const bool DigitalMars = false;

version (GNU) const bool GNU = true;
else const bool GNU = false;

version (LDC) const bool LDC = true;
else const bool LDC = false;

version (LLVM) const bool LLVM = true;
else const bool LLVM = false;

version (D_Version2) const bool D_Version2 = true;
else const bool D_Version2 = false;



//Processors 
version (PPC) const bool PPC = true;
else const bool PPC = false;

version (PPC64) const bool PPC64 = true;
else const bool PPC64 = false;

version (SPARC) const bool SPARC = true;
else const bool SPARC = false;

version (SPARC64) const bool SPARC64 = true;
else const bool SPARC64 = false;

version (X86) const bool X86 = true;
else const bool X86 = false;

version (X86_64) const bool X86_64 = true;
else const bool X86_64 = false;



//Operating Systems
version (aix) const bool aix = true;
else const bool aix = false;

version (cygwin) const bool cygwin = true;
else const bool cygwin = false;

version (darwin) const bool darwin = true;
else const bool darwin = false;

version (freebsd) const bool freebsd = true;
else const bool freebsd = false;

version (linux) const bool linux = true;
else const bool linux = false;

version (solaris) const bool solaris = true;
else const bool solaris = false;

version (Unix) const bool Unix = true;
else const bool Unix = false;

version (Win32) const bool Win32 = true;
else const bool Win32 = false;

version (Win64) const bool Win64 = true;
else const bool Win64 = false;

version (Windows) const bool Windows = true;
else const bool Windows = false;

version (Posix) const bool Posix = true;
else const bool Posix = true;



//Rest
version (BigEndian) const bool BigEndian = true;
else const bool BigEndian = false;

version (LittleEndian) const bool LittleEndian = true;
else const bool LittleEndian = false;

version (D_Coverage) const bool D_Coverage = true;
else const bool D_Coverage = false;

version (D_Ddoc) const bool D_Ddoc = true;
else const bool D_Ddoc = false;

version (D_InlineAsm_X86) const bool D_InlineAsm_X86 = true;
else const bool D_InlineAsm_X86 = false;

version (D_InlineAsm_X86_64) const bool D_InlineAsm_X86_64 = true;
else const bool D_InlineAsm_X86_64 = false;

version (D_LP64) const bool D_LP64 = true;
else const bool D_LP64 = false;

version (D_PIC) const bool D_PIC = true;
else const bool D_PIC = false;

version (GNU_BitsPerPointer32) const bool GNU_BitsPerPointer32 = true;
else const bool GNU_BitsPerPointer32 = false;

version (GNU_BitsPerPointer64) const bool GNU_BitsPerPointer64 = true;
else const bool GNU_BitsPerPointer64 = false;

version (all) const bool all = true;
else const bool D_InlineAsm_X86_64 = false;

version (none) const bool D_InlineAsm_X86_64 = true;
else const bool none = false;

version (Tango)
{
	const bool Tango = true;
	const bool Phobos = false;
	
	version (PhobosCompatibility) const bool PhobosCompatibility = true;
	else const bool PhobosCompatibility = false;	
}

else
{
	const bool Tango = false;
	const bool Phobos = true; 
	const bool PhobosCompatibility = false;
}

template platform ()
{
	static if (aix)
		const platform = "aix";
	
	else static if (cygwin)
		const platform = "cygwin";
	
	else static if (darwin)
		const platform = "darwin";
	
	else static if (freebsd)
		const platform = "freebsd";
	
	else static if (linux)
		const platform = "linux";
	
	else static if (solaris)
		const platform = "solaris";
	
	else static if (Windows)
		const platform = "windows";
}