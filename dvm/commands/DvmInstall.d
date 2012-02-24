/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 19, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.DvmInstall;

import tango.io.device.File;
import tango.sys.HomeFolder;
import tango.text.convert.Format : format = Format;
import tango.text.Util;

import mambo.core._;
import Path = dvm.io.Path;
import dvm.commands.Command;
import dvm.dvm.Exceptions;
import dvm.dvm.ShellScript;
import dvm.sys.Process;
import dvm.util.Util;
version (Windows) import DvmRegistry = dvm.util.DvmRegistry;
version (Windows) import dvm.util.Windows;

class DvmInstall : Command
{	
	private
	{
		const postInstallInstructions = import("post_install_instructions.txt");
		const failedInstallInstructions = import("failed_install_instructions.txt");

		version (Posix)
			const dvmScript = import("dvm.sh");
		
		else
			const dvmScript = import("dvm.bat");
	}
	
	void execute ()
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
		createPath(Path.join(options.path.dvm, options.path.bin));
		createPath(options.path.compilers);
		createPath(options.path.env);
		createPath(options.path.scripts);
		
		verbose();
	}

	void copyExecutable ()
	{
		verbose("Copying executable:");
		verbose("getProcessPath: ", getProcessPath);
		copy(getProcessPath, options.path.dvmExecutable);
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
			auto home = homeFolder;
			auto bashrc = Path.join(home, ".bashrc");
			auto bash_profile = Path.join(home, ".bash_profile");
			string shPath;

			if (Path.exists(bashrc))
				shPath = bashrc;

			else if (Path.exists(bash_profile))
				shPath = bash_profile;

			else
				throw new DvmException(format(`Cannot find "{}" or "{}". Please perform the post installation manually by following the instructions below:{}{}`,
												bashrc, bash_profile, "\n\n", failedInstallInstructions), __FILE__, __LINE__);

			verbose("Installing dvm in the shell loading file: ", shPath);
			File.append(shPath, sh.content);

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