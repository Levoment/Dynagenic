using Gee;
using Soup;
using Json;

public class ApiVersions {

    private string _apiVersionString;

    // If using an older version, the name convention for files changes
    private bool _usingAnOlderVersion;

    private bool _hasAPIVersion;

    public string apiVersionString {
        get { return _apiVersionString; }
        set { _apiVersionString = value; }
    }

    public bool hasAPIVersion {
        get { return _hasAPIVersion; }
        set { _hasAPIVersion = value; }
    }

    private string versionString;

    private string pathToFile;

    
    /**
     * Constructor
     *
     * @param versionString = the version of the game for which the api will be looked up for
     */
    public ApiVersions (string versionString) {
        this.versionString = versionString;

        string fileToLoad = "";

        // Get the data directories
        string[] dataDirs = Environment.get_system_data_dirs ();
        log(null, LogLevelFlags.LEVEL_DEBUG, "🔷  Listing data dirs in the OS");
        // For each data directory, try to find the ApiVersions.json file
        foreach (string dataDir in dataDirs) {
            log(null, LogLevelFlags.LEVEL_DEBUG, @"🔷  Datadir: $dataDir");
            File file = File.new_for_path (dataDir + "/dynagenic/resources/ApiVersions.json");
            if (file.query_exists ()) {
                fileToLoad = dataDir + "/dynagenic/resources/ApiVersions.json";
                log(null, LogLevelFlags.LEVEL_DEBUG, "✔️  ApiVersions.json was found in: " + dataDir + "/dynagenic/resources");
                break;
            } else {
                log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Could not find ApiVersions.json in: " + dataDir + "/dynagenic/resources");
            }
        } 

        if (fileToLoad == "") {
            log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Could not find ApiVersions.json in any of the system data directories.");
            log(null, LogLevelFlags.LEVEL_DEBUG, @"🔷  Attempting to get ApiVersions.json from same directory");
            fileToLoad = "ApiVersions.json";
            if (!(File.new_for_path (Environment.get_current_dir () + "/ApiVersions.json").query_exists ())) {
                log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Could not find ApiVersions.json in the current directory.");
                // Try to get ApiVersions.json from the appimage mount point
                string appDirPath = GLib.Environment.get_variable ("APPDIR");
                if (!(File.new_for_path (appDirPath + "/usr/share/dynagenic/resources/ApiVersions.json").query_exists())) {
                    log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Could not find ApiVersions.json in the app image mount point");
                } else {
                    log(null, LogLevelFlags.LEVEL_DEBUG, "✔️  ApiVersions.json was found in: " + appDirPath + "/usr/share/dynagenic/resources/ApiVersions.json");
                    fileToLoad = appDirPath + "/usr/share/dynagenic/resources/ApiVersions.json";
                    // Try to save the file to the current directory
                    try {
                        File apiVersionsFile = File.new_for_path (fileToLoad);
                        // Copy the file to the current folder
                        log(null, LogLevelFlags.LEVEL_DEBUG, "🔷  Saving file to: " + GLib.Path.get_dirname(Environment.get_variable ("ARGV0")) + "/ApiVersions.json");
                        apiVersionsFile.copy (File.new_for_path(GLib.Path.get_dirname(Environment.get_variable ("ARGV0")) + "/ApiVersions.json"), FileCopyFlags.OVERWRITE);
                    } catch (GLib.Error error) {
                        log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Could not save ApiVersions.json to the current directory");
                    }
                }
            } else {
                fileToLoad = "ApiVersions.json";
                log(null, LogLevelFlags.LEVEL_DEBUG, "✔️  ApiVersions.json was found in: " + Environment.get_current_dir ());
            }
        }

        File file = File.new_for_path (fileToLoad);
        this.pathToFile = fileToLoad;

        try {
            // Open file for reading 
            var dis = new DataInputStream (file.read ());
            string line;
            string fullMessage = "";
            // Read line by line
            while ((line = dis.read_line (null)) != null) {
                fullMessage += line + "\n";
            }
            parseJSON(fullMessage);
        } catch (Error e) {
            log(null, LogLevelFlags.LEVEL_DEBUG, @"❌  Error when reading file containing the API versions " + e.message);
        }

        if (this._apiVersionString == null) {
            log(null, LogLevelFlags.LEVEL_DEBUG, "🔷  Version not found in cached file. Looking for version online...");
            gatherVersions();
        }
        
        if (this._apiVersionString != null) {
            stdout.printf(@"Fabric API version for the selected Minecraft version is: $apiVersionString\n");
            this._hasAPIVersion = true;
        } else {
            log(null, LogLevelFlags.LEVEL_DEBUG, @"❌  A Fabric API version for: $versionString could not be found.");
            this._hasAPIVersion = false;
        }
    }

    private void gatherVersions() {
         // Write to a file
         try {
            File apiVersionsFile = File.new_for_uri ("https://blissful-goodall-d1cc57.netlify.app/Versions.json");
            File fileToSave = File.new_for_path(GLib.Path.get_dirname(Environment.get_variable ("ARGV0")) + "/ApiVersions.json");
            FileOutputStream outputStream = fileToSave.replace (null, false, FileCreateFlags.REPLACE_DESTINATION);
            var dataInputStream = new DataInputStream (apiVersionsFile.read ());
            var dataStream = new DataOutputStream(outputStream);
            string line;
            string allLines = "";
            // Read lines until end of file (null) is reached
            while ((line = dataInputStream.read_line (null)) != null) {
                allLines += line + "\n";
            }
            dataInputStream.close ();
            Json.Generator generator = new Json.Generator ();
            Parser jsonParser = new Parser();
            
            try {
                if (jsonParser.load_from_data(allLines)) {
                    // Get the root node:
                    Json.Node node = jsonParser.get_root ();
                    // Set indentation and prettify
                    generator.indent_char = 9;
                    generator.indent = 1;
                    generator.pretty = true;
                    // Set the root node
                    generator.set_root (node);
                    // Get the prettified JSON
                    string prettifiedJSON = generator.to_data (null);
                    // Write the prettified JSON to a file
                    dataStream.put_string(prettifiedJSON);
                    // Close the streams
                    dataStream.close ();
                    outputStream.close ();
                } else {
                    log(null, LogLevelFlags.LEVEL_DEBUG, "❌  There was an error parsing the data");
                }
            } catch (GLib.Error error) {
                // TODO display the error
                log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Data could not be parsed: " + error.message); 
            }
            parseJSON(allLines);
         } catch (Error error) {
            log(null, LogLevelFlags.LEVEL_DEBUG, "❌  There was an error when trying to write the Fabric API versions file to the current directory. " + error.message);
         }
    }

    private void parseJSON(string stringData) {
        if (stringData != null) {
            Parser jsonParser = new Parser();
            try {
                if (jsonParser.load_from_data(stringData)) {
                    // Get the root node:
                    Json.Node node = jsonParser.get_root ();
                    processNode(node);
                } else {
                    log(null, LogLevelFlags.LEVEL_DEBUG, "❌  There was an error parsing the data");
                }
            } catch (GLib.Error error) {
                // TODO display the error
                log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Data could not be parsed: " + error.message); 
            }
        } else {
            log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Passed string data was null");
        }
    }

    private void processNode(Json.Node node) {
        // Versions are an object
        Json.Object jsonObject = node.get_object();
        // Get the object containing the API versions for the given game version
        Json.Object versionObject = jsonObject.get_object_member (this.versionString);

        string latestApiVersion = versionObject.get_string_member ("LatestVersion");
        if (latestApiVersion.strip () != "") {
            this._apiVersionString = latestApiVersion.strip ();
        }
    }
}