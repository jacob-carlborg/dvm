/**
 * Copyright: Copyright (c) 2011 Nick Sabalausky. All rights reserved.
 * Authors: Nick Sabalausky
 * Version: Initial created: Jun 4, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.io.Console;

import tango.io.Console;
import tango.io.Stdout;
import tango.text.Util;
import tango.text.Unicode;

import mambo.core._;
import dvm.dvm.Options;
import dvm.util.Util;

/++
Easy general-purpose function to prompt user for input.
Optionally supports custom validation.

Get input from the user:
	auto result = prompt("Enter Text>");

Get validated input. Won't return until user enters valid input:
	bool accept(string input)
	{
		input = toLower(input);
		return input == "coffee" || input == "tea";
	}
	auto result = prompt("What beverage?", &accept, "Not on menu, try again!");
+/
string prompt(string promptMsg, bool delegate(string) accept=null, string rejectedMsg="")
{
	string input;
	while (true)
	{
		Stdout(promptMsg).flush;
		Cin.readln(input);
		input = trim(input);
		
		if (accept is null)
			break;
		else
		{
			if (accept(input))
				break;
			else
			{
				Stdout.newline;
				if (rejectedMsg != "")
					Stdout.formatln(rejectedMsg, input);
			}
		}
	}
	
	return input;
}

/// Returns 'true' for "Yes"
/// Obeys --force and --decline
bool promptYesNo()
{
	bool matches(char ch, string str)
	{
		str = toLower(str);
		return str != "" && str[0] == ch;
	}
	
	bool accept(string str)
	{
		return matches('y', str) || matches('n', str);
	}

	auto options = Options.instance;
	
	if (options.decline)
	{
		println("[Declining, 'no']");
		return false;
	}

	if (options.force)
	{
		println("[Forcing, 'yes']");
		return true;
	}
	
	auto response = prompt("Yes/No?>", &accept);
	return matches('y', response);
}