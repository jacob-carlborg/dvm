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

import dvm.core._;
import Path = dvm.io.Path;
import dvm.commands.Command;
import dvm.dvm.Exceptions;
import dvm.dvm.ShellScript;
import dvm.sys.Process;
import dvm.util.Util;

class DvmInstall : Command
{	
	private
	{
		const postInstallInstrcutions = import("post_install_instructions.txt");
		const failedInstallInstrcutions = import("failed_install_instructions.txt");

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
			throw new DvmException(format(`Cannot install dvm to "{}", path already exists.`, options.path.dvm), __FILE__, __LINE__);
		
		verbose("installing dvm to: ", options.path.dvm);
		createPaths;
		copyExecutable;
		writeScript;
		setPermissions;
		installBashInclude(createBashInclude);
	}
	
	void createPaths ()
	{
		verbose("creating paths:");

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
		verbose("copying executable:");
		copy(getProcessPath, options.path.dvmExecutable);
	}
	
	void writeScript ()
	{
		verbose("writing script to: ", options.path.dvmScript);
		File.set(options.path.dvmScript, dvmScript);
	}

	void setPermissions ()
	{
		verbose("setting permissions:");
		permission(options.path.dvmScript, "+x");
		permission(options.path.dvmExecutable, "+x");
	}
	
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
											bashrc, bash_profile, "\n\n", failedInstallInstrcutions), __FILE__, __LINE__);
		
		verbose("installing dvm in the shell loading file: ", shPath);
		File.append(shPath, sh.content);
		
		println(postInstallInstrcutions);
	}
	
	void createPath (string path)
	{
		verbose(options.indentation, path);
		Path.createFolder(path);
	}
	
	void permission (string path, string mode)
	{
		verbose(options.indentation, "mode: " ~ mode);
		verbose(options.indentation, "file: " ~ path, '\n');
		
		Path.permission(path, mode);
	}
	
	void copy (string source, string destination)
	{		
		verbose(options.indentation, "source: ", source);
		verbose(options.indentation, "destination: ", destination, '\n');
		assert(Path.isFile(source));
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
}