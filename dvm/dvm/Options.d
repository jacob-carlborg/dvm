/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 15, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.dvm.Options;

import std.exception : assumeUnique;
import std.path : baseName;
import std.process : environment;

import tango.sys.Environment;
import tango.sys.HomeFolder;

import dvm.io.Path;

enum Shell
{
    invalid,
    unkown,
    bash,
    zsh
}

class Options
{
    enum indentation = "    ";
    enum numberOfIndentations = 1;
    enum path = Path();

    private static Options instance_;

    bool verbose = false;
    bool tango = false;
    bool isDefault = false;

    bool force = false;
    bool decline = false;
    bool latest = false;
    bool compileDebug = false;

    private Shell shell_;

    version (D_LP64)
        bool is64bit = true;

    else
        bool is64bit = false;

    version (OSX)
        enum platform = "osx";

    else version (FreeBSD)
        enum platform = "freebsd";

    else version (linux)
        enum platform = "linux";

    else version (Windows)
        enum platform = "windows";

    else
        static assert (false, "Platform not supported");

	private this () {}

	static Options instance ()
	{
		if (instance_)
			return instance_;

		return instance_ = new typeof(this);
	}

    Shell shell()
    {
        if (shell_ != Shell.invalid)
            return shell_;

        if ("SHELL" in environment)
        {
            with(Shell) switch (environment["SHELL"].baseName)
            {
                case "bash": return shell_ = bash;
                case "zsh": return shell_ = zsh;
                default: return shell_ = unkown;
            }
        }

        return shell_ = Shell.unkown;
    }
}

private struct Path
{
    enum bin = "bin";
    enum bin32 = "bin32";
    enum bin64 = "bin64";
    enum src = "src";
    enum lib = "lib";
    enum lib32 = "lib32";
    enum lib64 = "lib64";
    enum import_ = "import";
    enum license = "license.txt";
    enum readme = "README.TXT";
    enum std = "std";
    enum object_di = "object.di";

    version (Posix)
    {
        enum libExtension = ".a";
        enum tangoLibName = "libtango";
        enum pathSeparator = ":";
        enum confName = "dmd.conf";
        enum scriptExtension = "";
        enum executableExtension = "";
    }

    else
    {
        enum libExtension = ".lib";
        enum tangoLibName = "tango";
        enum pathSeparator = ";";
        enum confName = "sc.ini";
        enum scriptExtension = ".bat";
        enum executableExtension = ".exe";
    }

    private
    {
        string home_;
        string dvm_;
        string env_;
        string compilers_;
        string archives_;
        string result_;
        string tmp_;
        string scripts_;
        string binDir_;
        string dvmScript_;
        string dvmExecutable_;
        string conf_;
        string tangoZip_;
        string tangoTmp_;
        string tangoBob_;
        string tangoLib_;
        string tangoSrc_;
        string tangoObject_;
        string tangoVendor_;
        string tangoUnarchived_;
        string defaultEnv_;
        string defaultBin_;

        version (Posix)
        {
            enum string dvmDir = ".dvm";
            enum string dvmExecName = "dvm";
        }

        else version (Windows)
        {
            enum string dvmDir = "dvm";
            enum string dvmExecName = "_dvm";
        }
    }

    string home ()
    {
        if (home_.length > 0)
            return home_;

        version (Posix)
            return home_ = homeFolder.assumeUnique;

        version (Windows)
            return home_ = standard(Environment.get("APPDATA"));
    }

    string dvm ()
    {
        if (dvm_.length > 0)
            return dvm_;

        return dvm_ = join(home, dvmDir).assumeUnique;
    }

    string dvmExecutable ()
    {
        if (dvmExecutable_.length > 0)
            return dvmExecutable_;

        return dvmExecutable_ = join(binDir, dvmExecName ~ executableExtension).assumeUnique;
    }

    string dvmScript ()
    {
        if (dvmScript_.length > 0)
            return dvmScript_;

        version (Posix)
            auto dir = scripts;

        version (Windows)
            auto dir = binDir;

        return dvmScript_ = join(dir, "dvm" ~ scriptExtension).assumeUnique;
    }

    string env ()
    {
        if (env_.length > 0)
            return env_;

        return env_ = join(dvm, "env").assumeUnique;
    }

    string compilers ()
    {
        if (compilers_.length > 0)
            return compilers_;

        return compilers_ = join(dvm, "compilers").assumeUnique;
    }

    string archives ()
    {
        if (archives_.length > 0)
            return archives_;

        return archives_ = join(dvm, "archives").assumeUnique;
    }

    string result ()
    {
        if (result_.length > 0)
            return result_;

        return result_ = join(tmp, "result" ~ scriptExtension).assumeUnique;
    }

    string scripts ()
    {
        if (scripts_.length > 0)
            return scripts_;

        return scripts_ = join(dvm, "scripts").assumeUnique;
    }

    string binDir ()
    {
        if (binDir_.length > 0)
            return binDir_;

        return binDir_ = join(dvm, "bin").assumeUnique;
    }

    string tmp ()
    {
        if (tmp_.length > 0)
            return tmp_;

        return tmp_ = join(dvm, "tmp").assumeUnique;
    }

    string conf ()
    {
        if (conf_.length > 0)
            return conf_;

        return conf_ = join(bin, confName).assumeUnique;
    }

    string tangoZip ()
    {
        if (tangoZip_.length > 0)
            return tangoZip_;

        return tangoZip_ = join(tmp, "tango.zip").assumeUnique;
    }

    string tangoTmp ()
    {
        if (tangoTmp_.length > 0)
            return tangoTmp_;

        return tangoTmp_ = join(tangoUnarchived, "trunk").assumeUnique;
    }

    string tangoUnarchived ()
    {
        if (tangoUnarchived_.length > 0)
            return tangoUnarchived_;

        return tangoUnarchived_ = join(tmp, "tango", "head").assumeUnique;
    }

    string tangoBob ()
    {
        if (tangoBob_.length > 0)
            return tangoBob_;

        auto suffix = Options.instance.is64bit ? "64" : "32";
        auto path = join(tangoTmp, "build", "bin").assumeUnique;

        version (OSX)
            path = join(path, "osx" ~ suffix).assumeUnique;

        else version (FreeBSD)
            path = join(path, "freebsd" ~ suffix).assumeUnique;

        else version (linux)
            path = join(path, "linux" ~ suffix).assumeUnique;

        else version (Windows)
            path = join(path, "win" ~ suffix).assumeUnique;

        else
            static assert(false, "Unhandled platform for installing Tango");

        return tangoBob_ = join(path, "bob" ~ executableExtension).assumeUnique;
    }

    string tangoLib ()
    {
        if (tangoLib_.length > 0)
            return tangoLib_;

        return tangoLib_ = join(tangoTmp, tangoLibName ~ libExtension).assumeUnique;
    }

    string tangoSrc ()
    {
        if (tangoSrc_.length)
            return tangoSrc_;

        return tangoSrc_ = join(tangoTmp, "tango").assumeUnique;
    }

    string tangoObject ()
    {
        if (tangoObject_.length > 0)
            return tangoObject_;

        return tangoObject_ = join(tangoTmp, object_di).assumeUnique;
    }

    string tangoVendor ()
    {
        if (tangoVendor_.length > 0)
            return tangoVendor_;

        return tangoVendor_ = join(tangoSrc, "core", "vendor", std).assumeUnique;
    }

    string defaultEnv ()
    {
        if (defaultEnv_.length > 0)
            return defaultEnv_;

        return defaultEnv_ = join(env, "default").assumeUnique;
    }

    string defaultBin ()
    {
        if (defaultBin_.length > 0)
            return defaultBin_;

        return defaultBin_ = join(binDir, "dvm-default-dc" ~ scriptExtension).assumeUnique;
    }
}
