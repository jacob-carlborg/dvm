/**
 * Copyright: Copyright (c) 2011 Nick Sabalausky. All rights reserved.
 * Authors: Nick Sabalausky
 * Version: Initial created: Jun 4, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.util.DvmRegistry;

version (Windows):

/// DVM-Specific Registry Utilities

import tango.io.Console;
import tango.io.Stdout;
import tango.text.Util;
import tango.text.Unicode;

import mambo.core._;
import Path = dvm.io.Path;
import dvm.io.Console;
import dvm.util.Registry;
import dvm.util.Windows;
import dvm.util.Util;

private string dvmEnvVar = "DVM";

void updateEnvironment (string binDir, string dmdDir="")
{
	string dvmEnvVarExpand = "%"~dvmEnvVar~"%";
	binDir = Path.native(binDir.dup);
	dmdDir = Path.native(dmdDir.dup);
	string dvmEnvValue = (dmdDir == "")? binDir : dmdDir~";"~binDir;

	scope envKey = new RegistryKey(RegRoot.HKEY_CURRENT_USER, "Environment");
	envKey.setValue(dvmEnvVar, dvmEnvValue);
	
	if (envKey.valueExists("PATH"))
	{
		auto path = envKey.getValue("PATH");

		if (path.type != RegValueType.SZ && path.type != RegValueType.EXPAND_SZ)
			throw new RegistryException(envKey.toString ~ `\PATH`, false, "Expected type REG_SZ or REG_EXPAND_SZ, not " ~ dvm.util.Registry.toString(path.type));
		
		if (path.asString.find(dvmEnvVarExpand) == size_t.max)
			envKey.setValueExpand("PATH", dvmEnvVarExpand ~ ";" ~ path.asString);
	}

	else
		envKey.setValueExpand("PATH", dvmEnvVarExpand);
}

/// Returns empty string if there's no default compiler
string getDefaultCompilerPath()
{
	scope envKeyRead = new RegistryKey(RegRoot.HKEY_CURRENT_USER, "Environment", RegKeyOpenMode.Open, RegKeyAccess.Read);
	if (envKeyRead.valueExists(dvmEnvVar))
	{
		auto pathValue = envKeyRead.getValue(dvmEnvVar);

		if (pathValue.type == RegValueType.SZ || pathValue.type == RegValueType.EXPAND_SZ)
		{
			auto bothPaths = pathValue.asString;
			auto sepIndex = find(bothPaths, ";");
			
			if (sepIndex < sepIndex.max)
				return bothPaths[0..sepIndex];
		}
	}
	
	return "";
}

bool isDMDDir(string path)
{
	path = expandEnvironmentStrings(path);
	
	foreach (singlePath; split(path, ";"))
	{
		Path.native(singlePath);
		if (singlePath.length != 0 && singlePath[$-1] != '\\')
			singlePath ~= '\\';
		
		if (Path.exists(singlePath) && Path.isFolder(singlePath))
		{
			if ( (Path.exists(singlePath~"dmd.exe") && Path.isFile(singlePath~"dmd.exe")) ||
				 (Path.exists(singlePath~"dmd.bat") && Path.isFile(singlePath~"dmd.bat")) )
				return true;
		}
	}
	
	return false;
}

void checkSystemPath()
{
	auto envKeyPath = `SYSTEM\CurrentControlSet\Control\Session Manager\Environment`;
	scope envKeyRead = new RegistryKey(RegRoot.HKEY_LOCAL_MACHINE, envKeyPath, RegKeyOpenMode.Open, RegKeyAccess.Read);
	if (envKeyRead.valueExists("PATH"))
	{
		auto pathValue = envKeyRead.getValue("PATH");

		if (pathValue.type != RegValueType.SZ && pathValue.type != RegValueType.EXPAND_SZ)
			throw new RegistryException(envKeyRead.toString ~ `\PATH`, false, "Expected type REG_SZ or REG_EXPAND_SZ, not " ~ dvm.util.Registry.toString(pathValue.type));
		
		// Check each path
		string[] pathsWithDMD;
		string[] pathsWithoutDMD;
		foreach (path; split(pathValue.asString, ";"))
		{
			if(isDMDDir(path))
				pathsWithDMD ~= path;
			else
				pathsWithoutDMD ~= path;
		}
		
		// DMD found in system PATH?
		if (pathsWithDMD.length > 0)
		{
			println("Your system PATH appears to already contain DMD:");
			
			foreach (path; pathsWithDMD)
				println("  ", path);
				
			println("");
			println("The above path(s) must be removed from your system PATH or else DVM won't");
			println("be able to set your \"default\" compiler. (However, you can still use DVM");
			println("to set your \"current\" compiler.)");
			println("");
			println("Would you like DVM to automatically remove those existing DMD entries from");
			println("your system path? (If 'yes', this will affect ALL USERS on this computer.)");
			println("");
			
			bool shouldRemoveDMD = promptYesNo();

			// Remove DMD paths from system PATH?
			if (shouldRemoveDMD)
			{
				string newValue = "";
				foreach (path; pathsWithoutDMD)
				{
					if (newValue != "")
						newValue ~= ';';
						
					newValue ~= path;
				}
				
				try
				{
					scope envKeyRW = new RegistryKey(RegRoot.HKEY_LOCAL_MACHINE, envKeyPath);
					envKeyRW.setValueExpand("PATH", newValue);
				}
				catch(Exception e)
				{
					println("DVM was unable to edit your system PATH.");
					println("(Maybe you don't have sufficient privileges?)");
					println("");
					println("You'll have to remove the DMD from your system PATH manually,");
					println("or contact your system administrator.");
					println("");
				}
			}
		}
	}
}