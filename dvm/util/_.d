/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Sep 14, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.util._;

public:
	
import dvm.util.Closure;
import dvm.util.Ctfe;

import dvm.util.OptionParser;
import dvm.util.Util;

version (Windows):
	import dvm.util.DvmRegistry;
	import dvm.util.Windows;