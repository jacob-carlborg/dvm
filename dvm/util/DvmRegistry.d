/**
 * Copyright: Copyright (c) 2009 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 21, 2009
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.util.DvmRegistry;

version (Windows) {} else
	static assert(false, "dvm.util.DvmRegistry is only for Windows");

/// DVM-Specific Registry Utilities

import dvm.core._;
import dvm.util.Util;
import Path = dvm.io.Path;
version (Windows) import dvm.util.Registry;
version (Windows) import dvm.util.Windows;

void updateEnvironment(string binDir, string dmdDir="")
{
	string dvmEnvVar = "DVM";
	string dvmEnvVarExpand = "%"~dvmEnvVar~"%";
	binDir = Path.native(binDir.dup);
	dmdDir = Path.native(dmdDir.dup);
	string dvmEnvValue = (dmdDir == "")? binDir : dmdDir~";"~binDir;

	scope envKey = new RegistryKey(RegRoot.HKEY_CURRENT_USER, "Environment");
	envKey.setValue(dvmEnvVar, dvmEnvValue);
	
	if(envKey.valueExists("PATH"))
	{
		auto path = envKey.getValue("PATH");
		if(path.type != RegValueType.SZ && path.type != RegValueType.EXPAND_SZ)
		{
			throw new RegistryException(
				envKey.toString~`\PATH`, false,
				"Expected type REG_SZ or REG_EXPAND_SZ, not "~
				dvm.util.Registry.toString(path.type)
			);
		}
		
		if(path.asString.find(dvmEnvVarExpand) == size_t.max)
			envKey.setValueExpand("PATH", dvmEnvVarExpand~";"~path.asString);
	}
	else
	{
		envKey.setValueExpand("PATH", dvmEnvVarExpand);
	}
	
	broadcastSettingChange("Environment");
}
