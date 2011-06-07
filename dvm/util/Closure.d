/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Aug 15, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.util.Closure;

version (Tango)
{
	import tango.core.Tuple;
	import tango.core.Traits;
}

else
{
	import std.typetuple;
	import std.traits;
	
	alias ReturnType ReturnTypeOf;
	alias ParameterTypeTuple ParameterTupleOf;
}


class Closure (ARGS...)
{
	static assert (ARGS.length > 0);
	
	private
	{
		alias ReturnTypeOf!(ARGS[0]) ReturnType;
		
		static if (ARGS.length >= 2)
			alias Tuple!(ReturnType delegate (ARGS), ARGS[1 .. $]) NEW_ARGS;
			
		else
			alias Tuple!(ReturnType delegate (ARGS)) NEW_ARGS;
	}
	
	NEW_ARGS args;
	
	this ()
	{
		
	}
	
	this (NEW_ARGS args)
	{
		this.args = args;
	}	
	
	ReturnType opCall (ARGS[0] dg)
	{
		assert(args[0]);
		
		static if (NEW_ARGS.length == 1)
			return args[0](dg);
			
		else
			return args[0](dg, args[1 .. $]);
	}
}