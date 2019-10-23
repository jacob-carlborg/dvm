/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 19, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.DvmInstall;

import std.algorithm : each, filter, map;
import std.array : array;
import std.file : exists, thisExePath;
import std.path : buildPath;

import tango.io.device.File;
import tango.sys.HomeFolder;

import mambo.core._;
import Path = dvm.io.Path;
import dvm.commands.Command;
import dvm.dvm.Exceptions;
import dvm.dvm.ShellScript;
import dvm.dvm.Options;
import dvm.util.Util;
version (Windows) import DvmRegistry = dvm.util.DvmRegistry;
version (Windows) import dvm.util.Windows;

class DvmInstall : Command
{
    private
    {
        enum postInstallInstructions = import("post_install_instructions.txt");
        enum failedInstallInstructions = import("failed_install_instructions.txt");

        version (Posix)
            enum dvmScript = import("dvm.sh");

        else
            enum dvmScript = import("dvm.bat");
    }

    override void execute ()
    {
        install;
    }

private:

    void install ()
    {
        if (Path.exists(options.path.dvm))
            return update;

        verbose("Installing dvm to: ", options.path.dvm);
        createPaths;
        copyExecutable;
        writeScript;

        version (Posix)
        {
            setPermissions;
            installBashInclude(createBashInclude);
        }

        version (Windows)
            setupRegistry;
    }

    void update ()
    {
        createPaths;
        copyExecutable;
        writeScript;
        setPermissions;

        version (Windows)
            setupRegistry;
    }

    void createPaths ()
    {
        verbose("Creating paths:");

        createPath(options.path.dvm);
        createPath(options.path.archives);
        createPath(Path.join(options.path.dvm, options.path.bin).assumeUnique);
        createPath(options.path.compilers);
        createPath(options.path.env);
        createPath(options.path.scripts);

        verbose();
    }

    void copyExecutable ()
    {
        verbose("Copying executable:");
        verbose("thisExePath: ", thisExePath);
        copy(thisExePath, options.path.dvmExecutable);
    }

    void writeScript ()
    {
        verbose("Writing script to: ", options.path.dvmScript);
        File.set(options.path.dvmScript, dvmScript);
    }

    void setPermissions ()
    {
        verbose("Setting permissions:");
        permission(options.path.dvmScript, "+x");
        permission(options.path.dvmExecutable, "+x");
    }

    version (Posix)
        void installBashInclude (ShellScript sh)
        {
            static string defaultProfile()
            {
                with(Shell) switch (Options.instance.shell)
                {
                    case bash: return ".bash_profile";
                    case zsh: return ".zprofile";
                    default: throw new DvmException("Failed to identify a " ~
                        "default shell profile file", __FILE__, __LINE__);
                }
            }

            enum potentialShellProfileFiles = [
                [".bashrc", ".bash_profile"],
                [".zshrc", ".zprofile"]
            ];

            const home = homeFolder.assumeUnique;
            alias toFullPath = path => home.buildPath(path);

            auto existingPofilePaths = potentialShellProfileFiles
                .map!(files => files.map!toFullPath)
                .map!(files => files.find!exists)
                .filter!(files => !files.empty)
                .map!(files => files.front);

            auto profilePaths = existingPofilePaths.empty ?
                [home.buildPath(defaultProfile)] : existingPofilePaths.array;

            verbose("Installing dvm in the shell loading file(s): ", profilePaths.join(", "));
            profilePaths.each!(path => File.append(path, sh.content));
            println(postInstallInstructions);
        }

    void createPath (string path)
    {
        verbose(options.indentation, path);
        if(!Path.exists(path))
            Path.createFolder(path);
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

    void copy (string source, string destination)
    {
        verbose(options.indentation, "source: ", source);
        verbose(options.indentation, "destination: ", destination, '\n');

        Path.copy(source, destination);
    }

    ShellScript createBashInclude ()
    {
        auto sh = new ShellScript;
        sh.nl.nl;
        sh.comment("This loads DVM into a shell session.").nl;

        sh.ifFileIsNotEmpty(options.path.dvmScript, {
            sh.source(options.path.dvmScript);
        });

        return sh;
    }

    version (Windows)
        void setupRegistry ()
        {
            auto defaultCompilerPath = DvmRegistry.getDefaultCompilerPath();
            DvmRegistry.updateEnvironment(options.path.binDir, defaultCompilerPath);
            DvmRegistry.checkSystemPath();
            broadcastSettingChange("Environment");
            println("DVM has now been installed.");
            println("To use dvm, you may need to open a new command prompt.");
        }
}
