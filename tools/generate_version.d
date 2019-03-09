import std.file : exists, mkdirRecurse, readText, write;
import std.path : buildPath;
import std.process : execute, env = environment;
import std.string : strip;

enum outputDirectory = "tmp";
enum versionFile = "version";

void main()
{
    const outputDirectory = env.get("DUB_PACKAGE_DIR", ".").buildPath("tmp");

    mkdirRecurse(outputDirectory);

    outputDirectory
        .buildPath("version")
        .updateIfChanged(generateVersion);
}

string generateVersion()
{
    const result = execute(["git", "describe", "--dirty", "--tags", "--always"]);

    if (result.status != 0)
        throw new Exception("Failed to execute 'git describe'");

    return result.output.strip;
}

void updateIfChanged(const string path, const string content)
{
    const existingContent = path.exists ? path.readText : "";

    if (content != existingContent)
        write(path, content);
}
