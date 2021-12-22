/**
 * Copyright: Copyright (c) 2021 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Dec 21, 2011
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.fetchers.dmc;

import dvm.commands.fetchers.base;

class Dmc : Base
{
    this(string[] args)
    {
        super(args);
    }

    override void fetch()
    {
        enum dmcArchiveName = "dm852c.zip";

        auto url = "http://ftp.digitalmars.com/Digital_Mars_C++/Patch/" ~ dmcArchiveName;
        fetch(url, Path.join(destinationPath, dmcArchiveName).assumeUnique);
    }
}
