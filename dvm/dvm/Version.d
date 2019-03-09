/**
 * Copyright: Copyright (c) 2015 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 24, 2015
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.dvm.Version;

import std.range : drop;
import std.string : strip;

enum Version = import("version").strip.drop(1);
