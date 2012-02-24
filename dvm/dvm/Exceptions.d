/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Nov 14, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.dvm.Exceptions;

import mambo.core.string;

class DvmException : Exception
{
	template Constructor ()
	{
		this (string message, string file, long line)
		{
			super(message, file, line);
		}
	}

	mixin Constructor;
}

class MissingArgumentException : DvmException
{
	mixin Constructor;
}

class InvalidOptionException : DvmException
{
	mixin Constructor;
}