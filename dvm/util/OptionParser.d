/**
 * Copyright: Copyright (c) 2010-211 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 15, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.util.OptionParser;

import tango.text.Arguments;
import tango.text.convert.Format;
import tango.io.Stdout;

import mambo.core._;
import mambo.util.Traits;

import dvm.dvm.Options;
import dvm.dvm.Exceptions;

class OptionParser
{
	string banner;
//	string[] separator;

	private
	{
		alias Format format;
		Arguments arguments;
		void delegate (string[] args) argsDg;
		string helpText;
		Option[] options;
	}	
	
	this ()
	{
		arguments = new Arguments;
	}
	
	OptionParser separator (string[] args ...)
	{
		foreach (arg ; args)
			buildHelpText(arg);
		
		return this;
	}
	
	OptionParser on (char shortOption, string longOption, string helpText, void delegate () dg)
	{		
		arguments(longOption).aliased(shortOption).help(helpText).bind(dg);
		buildHelpText(shortOption, longOption, helpText);
		
		return this;
	}
	
	OptionParser on (string longOption, string helpText, void delegate () dg)
	{		
		arguments(longOption).help(helpText).bind(dg);
		buildHelpText(longOption, helpText);
		
		return this;
	}
	
	OptionParser on (char shortOption, string longOption, string helpText, void delegate (string) dg)
	{	
		arguments(longOption).aliased(shortOption).help(helpText).params(1).bind(cast(string delegate (string)) dg);
		buildHelpText(shortOption, longOption, helpText);
		
		return this;
	}
	
	OptionParser on (string longOption, string helpText, void delegate (string) dg)
	{	
		arguments(longOption).help(helpText).params(1).bind(cast(string delegate (string)) dg);
		buildHelpText(longOption, helpText);
		
		return this;
	}
	
	OptionParser on (void delegate (string[]) dg)
	{
		argsDg = dg;		
		return this;
	}
	
	OptionParser parse (string input, bool sloppy = false)
	{
		if (!arguments.parse(input, sloppy))
			throw new InvalidOptionException(arguments.errors(&stderr.layout.sprint), __FILE__, __LINE__);

		handleArgs(arguments(null).assigned);
		
		return this;
	}
	
	OptionParser parse (string[] input, bool sloppy = false)
	{
		if (!arguments.parse(input, sloppy))
			throw new InvalidOptionException(arguments.errors(&stderr.layout.sprint), __FILE__, __LINE__);

		handleArgs(arguments(null).assigned);

		return this;
	}
	
	string toString ()
	{
		return format("{}\n{}", banner, buildHelpText);
	}
	
	private void handleArgs (string[] args)
	{
		if (argsDg) argsDg(args);
	}
	
	private void buildHelpText (char shortOption, string longOption, string helpText)
	{
		options ~= Option(shortOption, longOption, helpText);
	}
	
	private void buildHelpText (string option, string helpText)
	{
		buildHelpText(char.init, option, helpText);
	}
	
	private void buildHelpText (string str)
	{
		buildHelpText("", str);
	}
	
	private string buildHelpText ()
	{
		string help;
		auto len = lengthOfLongestOption;
		auto indentation = Options.instance.indentation;
		auto numberOfIndentations = Options.instance.numberOfIndentations;
		
		foreach (option ; options)
		{
			if (option.longOption.length == 0 && option.shortOption == char.init)
				help ~= format("{}\n", option.helpText);
			
			else if (option.shortOption == char.init)
				help ~= format("{}--{}{}{}{}\n",
							indentation ~ indentation,
							option.longOption,
							" ".repeat(len - option.longOption.length),
							indentation.repeat(numberOfIndentations),
							option.helpText);
			
			else
				help ~= format("{}-{}, --{}{}{}{}\n",
							indentation,
							option.shortOption,
							option.longOption,
							" ".repeat(len - option.longOption.length),
							indentation.repeat(numberOfIndentations),
							option.helpText);
		}
		
		return help;
	}
	
	private size_t lengthOfLongestOption ()
	{
		size_t len;
		
		foreach (option ; options)
			if (option.longOption.length > len)
				len = option.longOption.length;
		
		return len;
	}
}

private:
	
struct Option
{
	char shortOption;
	string longOption;
	string helpText;
}