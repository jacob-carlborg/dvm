/**
 * Copyright: Copyright (c) 2009-2011 Jacob Carlborg.
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
		enum Version = true;
	}
	else
	{
		enum Version = false;
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
version (DigitalMars) enum DigitalMars = true;
else enum DigitalMars = false;

version (GNU) enum GNU = true;
else enum GNU = false;

version (LDC) enum LDC = true;
else enum LDC = false;

version (LLVM) enum LLVM = true;
else enum LLVM = false;

version (D_Version2) enum D_Version2 = true;
else enum D_Version2 = false;



//Processors 
version (PPC) enum PPC = true;
else enum PPC = false;

version (PPC64) enum PPC64 = true;
else enum PPC64 = false;

version (SPARC) enum SPARC = true;
else enum SPARC = false;

version (SPARC64) enum SPARC64 = true;
else enum SPARC64 = false;

version (X86) enum X86 = true;
else enum X86 = false;

version (X86_64) enum X86_64 = true;
else enum X86_64 = false;



//Operating Systems
version (aix) enum aix = true;
else enum aix = false;

version (cygwin) enum cygwin = true;
else enum cygwin = false;

version (darwin) enum darwin = true;
else enum darwin = false;

version (freebsd) enum freebsd = true;
else enum freebsd = false;

version (linux) enum linux = true;
else enum linux = false;

version (solaris) enum solaris = true;
else enum solaris = false;

version (Unix) enum Unix = true;
else enum Unix = false;

version (Win32) enum Win32 = true;
else enum Win32 = false;

version (Win64) enum Win64 = true;
else enum Win64 = false;

version (Windows) enum Windows = true;
else enum Windows = false;

version (Posix) enum Posix = true;
else enum Posix = true;



//Rest
version (BigEndian) enum BigEndian = true;
else enum BigEndian = false;

version (LittleEndian) enum LittleEndian = true;
else enum LittleEndian = false;

version (D_Coverage) enum D_Coverage = true;
else enum D_Coverage = false;

version (D_Ddoc) enum D_Ddoc = true;
else enum D_Ddoc = false;

version (D_InlineAsm_X86) enum D_InlineAsm_X86 = true;
else enum D_InlineAsm_X86 = false;

version (D_InlineAsm_X86_64) enum D_InlineAsm_X86_64 = true;
else enum D_InlineAsm_X86_64 = false;

version (D_LP64) enum D_LP64 = true;
else enum D_LP64 = false;

version (D_PIC) enum D_PIC = true;
else enum D_PIC = false;

version (GNU_BitsPerPointer32) enum GNU_BitsPerPointer32 = true;
else enum GNU_BitsPerPointer32 = false;

version (GNU_BitsPerPointer64) enum GNU_BitsPerPointer64 = true;
else enum GNU_BitsPerPointer64 = false;

version (all) enum all = true;
else enum D_InlineAsm_X86_64 = false;

version (none) enum D_InlineAsm_X86_64 = true;
else enum none = false;

version (Tango)
{
	enum Tango = true;
	enum Phobos = false;
	
	version (PhobosCompatibility) enum PhobosCompatibility = true;
	else enum PhobosCompatibility = false;	
}

else
{
	enum Tango = false;
	enum Phobos = true; 
	enum PhobosCompatibility = false;
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