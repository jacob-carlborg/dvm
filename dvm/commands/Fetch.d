/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Nov 8, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.Fetch;

import std.algorithm : splitter;
import std.string : split;
import std.regex;

import tango.core.Exception;
import tango.io.device.File;
import tango.io.model.IConduit;
import Path = tango.io.Path;
import tango.net.InternetAddress;
import tango.net.device.Socket;
import tango.net.http.HttpGet;
import tango.net.http.HttpConst;

import dvm.commands.Command;
import mambo.core._;
import dvm.util._;
import dvm.dvm._;

class Fetch : Command
{
    this (string name, string summary = "")
    {
        super(name, summary);
    }

    this ()
    {
        super("fetch", "Fetch a D compiler but don't install it.");
    }

    override void execute ()
    {
        if (args.any && args.first == "dmc")
            fetchDMC;

        else
        {
            auto version_ = getDMDVersion();
            string filename = buildFilename(version_);
            string url = buildUrl(version_, filename);
            fetch(url, Path.join(".", filename).assumeUnique);
        }
    }

protected:

    enum userAgent = buildUserAgent();
    enum dmcArchiveName = "dm852c.zip";

    void fetchDMC (string destinationPath=".")
    {
        auto url = "http://ftp.digitalmars.com/Digital_Mars_C++/Patch/" ~ dmcArchiveName;
        fetch(url, Path.join(destinationPath, dmcArchiveName).assumeUnique);
    }

    void fetch (string source, string destination)
    {
        if (Path.exists(destination))
            return;

        if (options.verbose)
        {
            println("Fetching:");
            println(options.indentation, "source: ", source);
            println(options.indentation, "destination: ", destination, '\n');
        }

        else
            println("Fetching: ", source);

        createPath(Path.parse(destination).folder);
        writeFile(downloadFile(source), destination);
    }

    void[] downloadFile (string url)
    {
        static void print (A...)(A args)
        {
            import tango.io.Stdout;

            static enum string fmt = "{}{}{}{}{}{}{}{}"
                                     "{}{}{}{}{}{}{}{}"
                                     "{}{}{}{}{}{}{}{}";

            static assert (A.length <= fmt.length / 2, "mambo.io.print :: too many arguments");

            Stdout.format(fmt[0 .. args.length * 2], args).flush;
        }

        auto page = new HttpGet(url);
        page.setTimeout(30f);
        page.getRequestHeaders.add(HttpHeader.UserAgent, userAgent);
        auto buffer = page.open;

        scope(exit)
            page.close;

        checkPageStatus(page, url);

        // load in chunks in order to display progress
        int contentLength = page.getResponseHeaders.getInt(HttpHeader.ContentLength);

        enum width = 40;
        int num = width;

        version (Posix)
        {
            enum clearLine = "\033[1K"; // clear backwards
            enum saveCursor = "\0337";
            enum restoreCursor = "\0338";
        }

        else
        {
            enum clearLine = "\r";

            // Leaving these empty string causes a linker error:
            // http://d.puremagic.com/issues/show_bug.cgi?id=4315
            enum saveCursor = "\0";
            enum restoreCursor = "\0";
        }

        print(saveCursor);

        int bytesLeft = contentLength;
        int chunkSize = bytesLeft / num;

        while (bytesLeft > 0)
        {
            buffer.load(chunkSize > bytesLeft ? bytesLeft : chunkSize);
            bytesLeft -= chunkSize;
            int i = 0;

            print(clearLine ~ restoreCursor ~ saveCursor);
            print("[");

            for ( ; i < (width - num); i++)
                print("=");

            print('>');

            for ( ; i < width; i++)
                print(" ");

            print("]");
            print(" ", (contentLength - bytesLeft) / 1024, "/", contentLength / 1024, " KB");

            num--;
        }

        println(restoreCursor);
        println();

        return buffer.slice;
    }

    void writeFile (void[] data, string filename)
    {
        auto file = new File(filename, File.WriteCreate);
        scope(exit) file.close();
        file.write(data);
    }

    string buildFilename (string ver="")
    {
        if (ver == "")
            ver = getDMDVersion;

        auto filename = format("dmd.{}.{}.zip", ver, platformForArchive);
        auto url = buildUrl(ver, filename);

        return urlExists(url) ? filename : format("dmd.{}.zip", ver);
    }

    string buildUrl (string version_, string filename)
    {
        auto url = dlangUrl(version_, filename);

        if (urlExists(url))
            return url;

        return digitalMarsUrl(filename);
    }

    string digitalMarsUrl (string filename)
    {
        return "http://ftp.digitalmars.com/" ~ filename;
    }

    string dlangUrl (string version_, string filename)
    {
        enum baseUrl = "http://downloads.dlang.org/";
        string releases = "releases";

        if (isPreRelease(version_))
        {
            releases = "pre-releases";
            version_ = version_.split("-").first;
        }

        return format(baseUrl ~ "{}/{}.x/{}/{}", releases, version_.first, version_, filename);
    }

    void createPath (string path)
    {
        if (!Path.exists(path))
            Path.createPath(path);
    }

    void checkPageStatus (HttpGet page, string url)
    {
        if (page.getStatus == 404)
            throw new IOException(format(`The resource with URL "{}" could not be found.`, url));

        else if (!page.isResponseOK)
            throw new IOException(format(`An unexpected error occurred. The resource "{}" responded with the message "{}" and the status code {}.`, url, page.getResponse.getReason, page.getResponse.getStatus));
    }

    bool urlExists (string url, float timeout = 5f)
    {
        scope page = new HttpGet(url);
        page.setTimeout(timeout);
        page.enableRedirect();
        page.open();

        return page.isResponseOK;
    }

    string getDMDVersion ()
    {
        if (options.latest)
        {
            auto vers = getDVersion;
            return args.first = getLatestDMDVersion(vers);
        }

        else
        {
            validateArguments();
            return args.first;
        }
    }

    string getDVersion ()
    {
        return args.empty() ? "2" : args.first;
    }

    string getLatestDMDVersion (string dVersion)
    {
        enum mirrors = [
            "http://downloads.dlang.org/releases/LATEST",
            "http://ftp.digitalmars.com/LATEST"
        ];

        static string fetchFromMirror(string url)
        {
            scope page = new HttpGet(url);
            page.setTimeout(5f);
            page.enableRedirect();
            page.open();

            return page.isResponseOK ? cast(string) page.read : null;
        }

        foreach (mirror ; mirrors)
        {
            if (auto content = fetchFromMirror(mirror))
                return content;
        }

        throw new DvmException("Failed to get the latest DMD version.", __FILE__, __LINE__);
    }

    void validateArguments (string errorMessage = null)
    {
        if (errorMessage.isEmpty)
            errorMessage = "Cannot fetch a compiler without specifying a version";

        if (args.empty)
            throw new DvmException(errorMessage, __FILE__, __LINE__);
    }

    bool isPreRelease (string version_)
    {
        immutable parts = version_.split("-");

        if (parts.length != 2)
            return false;

        immutable suffix = parts[1];

        return suffix.first == 'b' || suffix.startsWith("rc");
    }

    string platformForArchive()
    {
        auto platform = options.platform;

        version (FreeBSD)
            platform ~= options.is64bit ? "-64" : "-32";

        return platform;
    }
}

string buildUserAgent ()
{
    import std.system;
    import std.string;

    version (X86) auto architecture = "i386";
    else version (X86_64) auto architecture = "x86_64";
    else static assert("Unhandled platform");

    return format("dvm/%s (%s-%s)", dvm.dvm.Version.Version, architecture, os);
}

template FetchImpl ()
{
    void execute ()
    {
        auto filename = buildFilename;
        auto url = buildUrl(filename);
        fetch(url, join(".", filename));
    }

    protected void fetch (string source, string destination)
    {
        writeFile(downloadFile(source), destination);
    }

    private void[] downloadFile (string url)
    {
        auto page = new HttpGet(url);

        if (!page.isResponseOK())
            throw new IOException(format("{}", page.getResponse.getStatus));

        return page.read;
    }

    private void writeFile (void[] data, string filename)
    {
        auto file = new File(filename, File.WriteCreate);
        file.write(data);
    }

    private string buildFilename ()
    {
        return "dmd." ~ args.first ~ ".zip";
    }

    private string buildUrl (string filename)
    {
        return "http://ftp.digitalmars.com/" ~ filename;
    }
}
