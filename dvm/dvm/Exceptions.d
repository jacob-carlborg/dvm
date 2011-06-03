/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Nov 14, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.dvm.Exceptions;

import dvm.core.string;

class DvmException : Exception
{
	this (string message, string file, long line)
	{
		super(message, file, line);
	}
}

class MissingArgumentException : DvmException
{
	this (string msg, string file, long line)
	{
		super(msg, file, line);
	}
}