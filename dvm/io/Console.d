/**
 * Copyright: Copyright (c) 2011 Nick Sabalausky. All rights reserved.
 * Authors: Nick Sabalausky
 * Version: Initial created: Jun 4, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.io.Console;

import std.exception : assumeUnique;
import std.stdio : writeln;
import std.uni : toLower;

import tango.io.Console;
import tango.io.Stdout;
import tango.text.Util;

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
string prompt(string promptMsg, bool delegate(const(char)[]) accept=null, string rejectedMsg="")
{
    char[] input;
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

    return input.assumeUnique;
}

/// Returns 'true' for "Yes"
/// Obeys --force and --decline
bool promptYesNo()
{
    bool matches(char ch, const(char)[] str)
    {
        str = toLower(str);
        return str != "" && str[0] == ch;
    }

    bool accept(const(char)[] str)
    {
        return matches('y', str) || matches('n', str);
    }

    auto options = Options.instance;

    if (options.decline)
    {
        writeln("[Declining, 'no']");
        return false;
    }

    if (options.force)
    {
        writeln("[Forcing, 'yes']");
        return true;
    }

    auto response = prompt("Yes/No?>", &accept);
    return matches('y', response);
}
