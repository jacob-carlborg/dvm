/**
 * Copyright: Copyright (c) 2011 Nick Sabalausky. All rights reserved.
 * Authors: Nick Sabalausky
 * Version: Initial created: Jun 4, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.util.DvmRegistry;

version (Windows):

/// DVM-Specific Registry Utilities

import dvm.core._;
import Path = dvm.io.Path;
import dvm.util.Registry;
import dvm.util.Windows;
import dvm.util.Util;

void updateEnvironment (string binDir, string dmdDir="")
{
	string dvmEnvVar = "DVM";
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

	broadcastSettingChange("Environment");
}