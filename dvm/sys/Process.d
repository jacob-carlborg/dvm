/**
 * Copyright: Copyright (c) 2009-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 21, 2009
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.sys.Process;

import tango.sys.Process;

/// Copies environment to new process.
/// Waits for process to finish.
/// Params: 'args' is same as in tango.sys.Process.new(true, char[][] args...)
/// Returns: Process.Result (containing status code and reason the process ended)
Process.Result system(string[] args...)
{
    Process p;
    auto result = system(p, args);
    p.close;
    return result;
}

/// Has extra param to retreive the Process object used so you can obtain extra information.
/// Make sure to call p.close() when you're done with it.
Process.Result system(out Process p, string[] args...)
{
    p = new Process(true, args);
    p.redirect = Redirect.None;
    p.execute();
    auto result = p.wait();
    return result;
}
