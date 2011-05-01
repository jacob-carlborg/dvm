/**
 * Copyright: Copyright (c) 2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Jan 9, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.dvm.ShellScript;

import tango.io.device.File;
import tango.text.convert.Format : format = Format;

import dvm.core._;

class ShellScript
{
	string path;	
	private string content_;
	
	string content ()
	{
		return content_;
	}
	
	private string content (string content)
	{
		return content_ = content;
	}
	
	this (string path = "")
	{
		this.path = path;
	}
	
	ShellScript allArgs (bool quote = true)
	{
		append(Sh.allArgs);
		return this;
	}
	
	ShellScript comment (string c)
	{
		append(Sh.comment(c));
		return this;
	}
	
	ShellScript declareVariable (string name, string value = "", bool local = false)
	{
		append(Sh.declareVariable(name, value, local)).nl;
		return this;
	}
	
	ShellScript echoOff ()
	{
		if (Sh.echoOff != "")
			append(Sh.echoOff).nl;

		return this;
	}
	
	ShellScript exec (string name, string args = "", string a = "")
	{
		append(Sh.exec(name, args, a));
		return this;
	}
	
	ShellScript export_ (string name, string content, bool quote = true)
	{
		append(Sh.export_(name, content, quote));
		return this;
	}
	
	ShellScript exportPath (string name, string[] args ...)
	{
		string content ;
		
		foreach (i, arg ; args)
		{
			if (i != args.length - 1)
				content ~= arg ~ Sh.separator;

			else
				content ~=  arg;
		}
		
		return export_(name, content);
	}
	
	ShellScript ifFileIsNotEmpty (string path, void delegate () ifBlock, void delegate () elseBlock = null)
	{
		ifStatement("-s " ~ path, ifBlock, elseBlock);
		return this;
	}
	
	ShellScript ifStatement (string condition, void delegate () ifBlock, void delegate () elseBlock = null)
	{
		append(format("if [[ {} ]] ; then", condition)).nl.indent;
		ifBlock();
		nl;
		
		if (elseBlock)
		{
			append("else").nl.indent;
			elseBlock();
			nl;
		}
		
		append("fi");

		return this;
	}
	
	ShellScript printError (string message, bool singleQuote = false)
	{
		auto quote = singleQuote ? "'" : `"`;
		append(format(`echo {}Error: {}{} >&2`, quote, message, quote));
		return this;
	}
	
	ShellScript shebang ()
	{
		if (Sh.shebang != "")
			append(Sh.shebang).nl;

		return this;
	}
	
	ShellScript source (string path)
	{
		append(Sh.source(path));		
		return this;
	}
	
	ShellScript variable (string name, bool quote = true)
	{
		append(Sh.variable(name, quote));
		return this;
	}
	
	ShellScript write ()
	{
		File.set(path, content);
		return this;
	}
	
	ShellScript append (Args...) (Args args)
	{
		static const string fmt = "{}{}{}{}{}{}{}{}"
					  "{}{}{}{}{}{}{}{}"
					  "{}{}{}{}{}{}{}{}";
		
		static assert (Args.length <= fmt.length / 2, "dvm.dvm.ShellScript :: too many arguments");
		
		content_ ~= format(fmt[0 .. args.length * 2], args);
		
		return this;
	}
	
	ShellScript nl ()
	{
		append('\n');
		return this;
	}
	
	ShellScript indent ()
	{
		append('\t');
		return this;
	}
}
	
struct Sh
{
	static:
		
	string quote (string str)
	{
		return format(`"{}"`, str);
	}
		
	version (Posix)
	{
		const shebang = "#!/bin/sh";
		const echoOff = "";
		const separator = ":";
		
		string allArgs (bool quote = true)
		{
			return quote ? `"$@"` : "$@";
		}
		
		string comment (string c)
		{
			return "# " ~ c;
		}
		
		string declareVariable (string name, string value = "", bool local = false)
		{
			string loc = local ? "local " : "";
			
			if (value == "")
				return loc ~ name;
			
			return format("{}{}={}", loc, name, value); 
		}
		
		string exec (string name, string args = "", string a = "")
		{
			a = a == "" ? "" : format("-a {} ", a);
			args = args == "" ? "" : ' ' ~ args;

			return format("exec {}{}{}", a, name, args);
		}
		
		string export_ (string name, string value, bool quote = true)
		{
			return format("{}=\"{}\"\nexport {}", name, value, name);
		}
		
		string source (string path, bool quote = true)
		{			
			return format(". {}", path);
		}
		
		string exec (string command)
		{
			return format("exec {}", command);
		}
		
		string ifStatement (string condition, string delegate () ifBlock, string delegate () elseBlock = null)
		{
			if (elseBlock is null)
				return format("if [[ {} ]] ; then\n\t{}\nfi", condition, ifBlock());
			
			return format("if [[ {} ]] ; then\n\t{}\nelse\n\t{}\nfi", condition, ifBlock(), elseBlock());
		}
		
		string ifFileIsNotEmpty (string path, string delegate () ifBlock, string delegate () elseBlock = null)
		{
			return ifStatement("-s " ~ path, ifBlock, elseBlock);
		}
		
		string variable (string name, bool quote = true)
		{
			return quote ? format(`"${}"`, name) : '$' ~ name;
		}
	}
		
	else version (Windows)
	{
		const shebang = "";
		const echoOff = "@echo off";
		const separator = ":";
		
		string allArgs (bool quote = true)
		{
			return "%*";
		}
		
		string command (string c)
		{
			return "rem " ~ c;
		}
		
		string declareVariable (string name, string value = "", bool local = false)
		{
			return format("set {}={}", name, value); 
		}
		
		void export_ (string name, string content, bool quote = true)
		{
			return format("set {}={}", name, content);
		}
		
		string source (string path)
		{
			return format("call {}", path);
		}
		
		string exec (string command)
		{
			return source(command);
		}
		
		string ifFileIsNotEmpty (string path, string delegate () block)
		{			
			return format("if exist {} {}", path, block());
		}
	}
}	

private:

/*string format (Args ...) (Args args)
{
	static const string fmt = "{}{}{}{}{}{}{}{}"
		  					  "{}{}{}{}{}{}{}{}"
			  				  "{}{}{}{}{}{}{}{}";

	static assert (Args.length <= fmt.length / 2, "dvm.dvm.ShellScript :: too many arguments");

	return format(fmt[0 .. args.length * 2], args);
}*/