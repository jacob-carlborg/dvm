/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Nov 8, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.Install;

import tango.core.Exception;
import tango.io.Stdout;
import tango.io.device.File;
import tango.net.http.HttpGet;
import tango.sys.Common;
import tango.sys.Environment;
import tango.sys.Process;
import tango.sys.win32.Types;
import tango.util.compress.Zip : extractArchive;

import mambo.util.Version;

import dvm.commands.Command;
import dvm.commands.DmcInstall;
import dvm.commands.DvmInstall;
import dvm.commands.Fetch;
import dvm.commands.Use;
import mambo.core._;
import dvm.dvm.Wrapper;
import dvm.dvm._;
import Path = dvm.io.Path;
import dvm.util.Util;

class Install : Fetch
{
    private
    {
        string archivePath;
        string tmpCompilerPath;
        string installPath_;
        string binDestination_;
        Wrapper wrapper;
        string ver;
    }

    this ()
    {
        super("install", "Install one or many D versions.");
    }

    override void execute ()
    {
        // special case for the installation of dvm itself or dmc
        if (args.any() && (args.first == "dvm" || args.first == "dmc"))
        {
            if (args.first == "dvm")
                (new DvmInstall).invoke(args);

            else
                (new DmcInstall).invoke(args);

            return;
        }

        install;
    }

    void install (string ver = "")
    {
        if(ver == "")
            ver = getDMDVersion();

        this.ver = ver;

        auto filename = buildFilename(ver);
        auto url = buildUrl(ver, filename);

        archivePath = Path.join(options.path.archives, filename);

        fetch(url, archivePath);
        println("Installing: dmd-", ver);

        unpack;
        moveFiles;
        installWrapper;

        version (Posix)
            setPermissions;

        installEnvironment(createEnvironment);

        if (options.tango)
            installTango;
    }

private:

    void unpack ()
    {
        tmpCompilerPath = Path.join(options.path.tmp, "dmd-" ~ ver);
        verbose("Unpacking:");
        verbose(options.indentation, "source: ", archivePath);
        verbose(options.indentation, "destination: ", tmpCompilerPath, '\n');
        extractArchive(archivePath, tmpCompilerPath);
    }

    void moveFiles ()
    {
        auto dmd = ver.length > 0 && ver[0] == '2' ? "dmd2" : "dmd";
        auto root = Path.join(tmpCompilerPath, dmd);
        auto platformRoot = Path.join(root, Options.platform);

        if (!Path.exists(platformRoot))
            throw new DvmException(mambo.core.string.format(`The platform "{}" is not compatible with the compiler dmd {}`, Options.platform, ver), __FILE__, __LINE__);

        auto binSource = getBinSource(platformRoot);

        auto srcSource = Path.join(root, options.path.src);
        auto srcDest = Path.join(installPath, options.path.src);

        verbose("Moving:");

        foreach (path ; getLibSources(platformRoot))
        {
            auto dest = Path.join(installPath, options.platform, path.destination);
            Path.move(path.source, dest);
        }

        Path.move(binSource, binDestination);
        Path.move(srcSource, srcDest);
    }

    void installWrapper ()
    {
        wrapper.target = Path.join(binDestination, "dmd" ~ options.path.executableExtension);
        wrapper.path = Path.join(options.path.dvm, options.path.bin, "dmd-") ~ ver;

        version (Windows)
            wrapper.path ~= ".bat";

        verbose("Installing wrapper: " ~ wrapper.path);
        try
        {
            wrapper.write;
        }
        catch (Exception ex)
        {
            import std.regex;
            if (matchFirst(ex.toString(), r"dmd-[\d\.]\.bat"))
            {
                println("Error installing - did you remember to 'dvm install dvm' first?");
            }
            throw ex;
        }
    }

    void setPermissions ()
    {
        verbose("Setting permissions:");

        setExecutableIfExists(Path.join(binDestination, "ddemangle"));
        setExecutableIfExists(Path.join(binDestination, "dman"));
        setExecutableIfExists(Path.join(binDestination, "dmd"));
        setExecutableIfExists(Path.join(binDestination, "dumpobj"));
        setExecutableIfExists(Path.join(binDestination, "dustmite"));
        setExecutableIfExists(Path.join(binDestination, "obj2asm"));
        setExecutableIfExists(Path.join(binDestination, "rdmd"));
        setExecutableIfExists(Path.join(binDestination, "shell"));

        setExecutableIfExists(wrapper.path);
    }

    void installEnvironment (ShellScript sh)
    {
        sh.path = options.path.env;
        Path.createPath(sh.path);
        sh.path = Path.join(sh.path, "dmd-" ~ ver ~ options.path.scriptExtension);

        verbose("Installing environment: ", sh.path);
        sh.write;
    }

    ShellScript createEnvironment ()
    {
        auto sh = new ShellScript;
        sh.echoOff;

        auto envPath = binDestination;
        auto binPath = Path.join(options.path.dvm, options.path.bin);

        version (Posix)
            sh.exportPath("PATH", envPath, binPath, Sh.variable("PATH", false));

        version (Windows)
        {
            Path.native(envPath);
            Path.native(binPath);
            sh.exportPath("DVM",  envPath, binPath).nl;
            sh.exportPath("PATH", envPath, Sh.variable("PATH", false));
        }

        return sh;
    }

    void installTango ()
    {
        verbose("Installing Tango");

        fetchTango;
        unpackTango;
        setupTangoEnvironment;
        buildTango;
        moveTangoFiles;
        patchDmdConfForTango;
    }

    void fetchTango ()
    {
        enum tangoUrl = "http://dsource.org/projects/tango/changeset/head/trunk?old_path=%2F&format=zip";
        fetch(tangoUrl, options.path.tangoZip);
    }

    void unpackTango ()
    {
        verbose("Unpacking:");
        verbose(options.indentation, "source: ", options.path.tangoZip);
        verbose(options.indentation, "destination: ", options.path.tangoTmp, '\n');
        extractArchive(options.path.tangoZip, options.path.tangoUnarchived);
    }

    void setupTangoEnvironment ()
    {
        verbose(format(`Installing "{}" as the temporary D compiler`, ver));
        auto path = Environment.get("PATH");
        path = binDestination ~ options.path.pathSeparator ~ path;
        Environment.set("PATH", path);
    }

    void buildTango ()
    {
        version (Posix)
        {
            verbose("Setting permission:");
            permission(options.path.tangoBob, "+x");
        }

        verbose("Building Tango...");

        string[] tangoBuildOptions = ["-r=dmd"[], "-c=dmd", "-u", "-q", "-l=" ~ options.path.tangoLibName];

        version (Posix)
            tangoBuildOptions ~= options.is64bit ? "-m=64" : "-m=32";

        auto process = new Process(true, options.path.tangoBob ~ tangoBuildOptions ~ "."[]);
        process.workDir = options.path.tangoTmp;
        process.execute;

        auto result = process.wait;

        if (options.verbose || result.reason != Process.Result.Exit)
        {
            println("Output of the Tango build:", "\n");
            Stdout.copy(process.stdout).flush;
            println();
            println("Process ", process.programName, '(', process.pid, ')', " exited with:");
            println(options.indentation, "reason: ", result);
            println(options.indentation, "status: ", result.status, "\n");
        }
    }

    void moveTangoFiles ()
    {
        verbose("Moving:");

        auto importDest = Path.join(installPath, options.path.import_);

        auto tangoSource = options.path.tangoSrc;
        auto tangoDest = Path.join(importDest, "tango");


        auto objectSrc = options.path.tangoObject;
        auto objectDest = Path.join(importDest, options.path.object_di);

        auto vendorSrc = options.path.tangoVendor;
        auto vendorDest = Path.join(importDest, options.path.std);

        auto libPath = options.is64bit ? options.path.lib64 : options.path.lib32;

        Path.move(options.path.tangoLib, Path.join(installPath, options.platform, libPath, options.path.tangoLibName ~ options.path.libExtension));
        Path.move(vendorSrc, vendorDest);
        Path.move(tangoSource, tangoDest);
        Path.move(objectSrc, objectDest);
    }

    void patchDmdConfForTango ()
    {
        auto dmdConfPath = Path.join(binDestination, options.path.confName);

        verbose("Patching: ", dmdConfPath);

        string newInclude = "-I%@P%/../../import";
        string newArgs = " -defaultlib=tango -debuglib=tango -version=Tango";
        string content = cast(string) File.get(dmdConfPath);

        string oldInclude1 = "-I%@P%/../../src/phobos";
        string oldInclude2 = "-I%@P%/../../src/druntime/import";
        version (Windows)
        {
            oldInclude1 = '"' ~ oldInclude1 ~ '"';
            oldInclude2 = '"' ~ oldInclude2 ~ '"';
            newInclude  = '"' ~ newInclude  ~ '"';
        }

        auto src = newInclude ~ newArgs;

        content = content.slashSafeSubstitute(oldInclude1, src);
        content = content.slashSafeSubstitute(oldInclude2, "");

        File.set(dmdConfPath, content);
    }

    string installPath ()
    {
        if (installPath_.length > 0)
            return installPath_;

        return installPath_ = Path.join(options.path.compilers, "dmd-" ~ ver);
    }

    void permission (string path, string mode)
    {
        version (Posix)
        {
            verbose(options.indentation, "mode: " ~ mode);
            verbose(options.indentation, "file: " ~ path, '\n');

            Path.permission(path, mode);
        }
    }

    SourceDestination[] getLibSources (string platformRoot)
    {
        SourceDestination[] paths;

        if (auto path = getLibSource(platformRoot, options.path.lib))
            paths ~= path;

        if (auto path = getLibSource(platformRoot, options.path.lib32))
            paths ~= path;

        if (auto path = getLibSource(platformRoot, options.path.lib64))
            paths ~= path;

        if (paths.isEmpty)
            throw new DvmException("Could not find any library paths", __FILE__, __LINE__);

        return paths;
    }

    SourceDestination getLibSource (string platformRoot, string libPath)
    {
        auto path = Path.join(platformRoot, libPath);

        if (Path.exists(path))
            return SourceDestination(path, libPath);

        else
            return SourceDestination.invalid;
    }

    string getBinSource (string platformRoot)
    {
        string binPath = Path.join(platformRoot, options.path.bin);

        if (Path.exists(binPath))
            return binPath;

        if (options.is64bit)
        {
            binPath = Path.join(platformRoot, options.path.bin64);

            if (Path.exists(binPath))
                return binPath;

            else
                throw new DvmException("There is no 64bit compiler available on this platform", __FILE__, __LINE__);
        }

        binPath = Path.join(platformRoot, options.path.bin32);

        if (Path.exists(binPath))
            return binPath;

        throw new DvmException("Could not find the binrary path: " ~ binPath, __FILE__, __LINE__);
    }

    void setExecutableIfExists (string path)
    {
        if (Path.exists(path))
            permission(path, "+x");
    }

    void validateArguments (string errorMessage = null)
    {
        if (errorMessage.isEmpty)
            errorMessage = "Cannot install a compiler without specifying a version";

        super.validateArguments(errorMessage);
    }

    struct SourceDestination
    {
        string source;
        string destination;

        bool isValid ()
        {
            return source.any && destination.any;
        }

        bool opCast (T : bool) ()
        {
            return isValid;
        }

        static SourceDestination invalid ()
        {
            return SourceDestination(null, null);
        }
    }

    string binDestination ()
    {
        return binDestination_ = binDestination_.any ? binDestination_ : Path.join(installPath, options.platform, options.path.bin);
    }
}
