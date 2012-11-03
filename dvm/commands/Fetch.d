/**
 * Copyright: Copyright (c) 2010-2011 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Nov 8, 2010
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
module dvm.commands.Fetch;

import tango.core.Exception;
import tango.io.device.File;
import tango.io.model.IConduit;
import Path = tango.io.Path;
import tango.net.InternetAddress;
import tango.net.device.Socket;
import tango.net.http.HttpGet;
import tango.net.http.HttpConst;
import tango.text.convert.Format : format = Format;
import Regex = tango.text.Regex;

import dvm.commands.Command;
import dvm.core._;
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
	
	void execute ()
	{
		if (args.first == "dmc")
			fetchDMC;

		else
		{
			string filename = buildFilename;
			string url = buildUrl(filename);
			fetch(url, Path.join(".", filename));
		}
	}
	
protected:

	const dmcArchiveName = "dm852c.zip";
	
	void fetchDMC (string destinationPath=".")
	{
		auto url = "http://ftp.digitalmars.com/Digital_Mars_C++/Patch/" ~ dmcArchiveName;
		fetch(url, Path.join(destinationPath, dmcArchiveName));
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
		auto page = new HttpGet(url);
		page.setTimeout(30f);
		auto buffer = page.open;
		
		scope(exit)
			page.close;
		
		checkPageStatus(page, url);

		// load in chunks in order to display progress
		int contentLength = page.getResponseHeaders.getInt(HttpHeader.ContentLength);

		const int width = 40;
		int num = width;

		version (Posix)
		{
			const clearLine = "\033[1K"; // clear backwards
			const saveCursor = "\0337";
			const restoreCursor = "\0338";
		}
		
		else
		{
			const clearLine = "\r";
			
			// Leaving these empty string causes a linker error:
			// http://d.puremagic.com/issues/show_bug.cgi?id=4315
			const saveCursor = "\0";
			const restoreCursor = "\0";
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
		
		return "dmd." ~ ver ~ ".zip";
	}
	
	string buildUrl (string filename)
	{
		auto url = githubUrl(filename);

		if (urlExists(url))
			return url;

		return digitalMarsUrl(filename);
	}

	string digitalMarsUrl (string filename)
	{
		return "http://ftp.digitalmars.com/" ~ filename;
	}

	string githubUrl (string filename)
	{
		return "http://cloud.github.com/downloads/D-Programming-Language/dmd/" ~ filename;
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
			return args.first = vers ~ "." ~ getLatestDMDVersion(vers);
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
		auto pattern = `https:\/\/github\.com/downloads/D-Programming-Language/dmd/(dmd\.` ~ dVersion ~ `\.(\d+)\.zip)`;
		
		if (auto result = getLatestDMDVersionImpl(pattern))
			return result;
			
		pattern = `http:\/\/ftp\.digitalmars\.com\/(dmd\.` ~ dVersion ~ `\.(\d+)\.zip)`;
		
		if (auto result = getLatestDMDVersionImpl(pattern))
			return result;
			
		throw new DvmException("Failed to get the latest DMD version.", __FILE__, __LINE__);
	}
	
	private string getLatestDMDVersionImpl (string pattern)
	{
		scope page = new HttpGet("http://www.digitalmars.com/d/download.html");
		auto content = cast(string) page.read;

		auto regex = new Regex.Regex(pattern);
		string vers = null;

		foreach (line ; content.split('\n'))
			if (regex.test(line))
				if (regex[2] > vers)
					vers = regex[2];

		return vers;
	}

	void validateArguments (string errorMessage = null)
	{
		if (errorMessage.empty())
			errorMessage = "Cannot fetch a compiler without specifying a version";

		if (args.empty)
			throw new DvmException(errorMessage, __FILE__, __LINE__);
	}
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