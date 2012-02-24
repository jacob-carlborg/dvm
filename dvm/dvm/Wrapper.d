/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 16, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.dvm.Wrapper;

import mambo.core._;
import dvm.dvm.ShellScript;
import dvm.io.Path;

struct Wrapper
{
	string path;
	string target;
	
	private ShellScript sh;
	
	static Wrapper opCall (string path = "", string target = "")
	{
		Wrapper wrapper;
		
		wrapper.path = path;
		wrapper.target = target;
		
		return wrapper;
	}
	
	void write ()
	{
		createContent;
		sh.path = path;
		sh.write;
	}
	
	private void createContent ()
	{
		native(path);
		native(target);
		
		sh = new ShellScript(path);
		auto dmd = "dmd";
		auto dmdPath = Sh.quote(target);

		sh.shebang;
		sh.echoOff;
		sh.nl;
		
		sh.ifFileIsNotEmpty(dmdPath, {
			sh.exec(dmdPath, Sh.allArgs);
		}, {
			sh.printError(format(`Missing target: "{}"`, target), true);
		});
	}
}