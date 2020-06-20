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

    public bool usingAnOlderVersion {
        get { return _usingAnOlderVersion; }
        set { _usingAnOlderVersion = value; }
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
            File apiVersionsFile = File.new_for_uri ("https://addons-ecs.forgesvc.net/api/v2/addon/306612/files");
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
        // Versions are an array of objects
        Json.Array jsonArray = node.get_array();

        checkSnapshot(jsonArray);
        checkPreReleases(jsonArray);
        checkReleaseCandidates(jsonArray);
        checkNormalReleases(jsonArray);
    }

    private void checkNormalReleases(Json.Array jsonArray) {
        log(null, LogLevelFlags.LEVEL_DEBUG, "🔷  Checking for normal releases");

        // Variable to know which is the last build
        int lastBuild = 0;

        // Variable to store the captured string
        MatchInfo matchInfo;

        // For each node in the array
        foreach (unowned Json.Node nodeElement in jsonArray.get_elements()) {
            // Get the object
            Json.Object jsonObject = nodeElement.get_object();

            // Get the display name string
            unowned string displayName = jsonObject.get_string_member("displayName");

            try {
               // This pattern matches and captures versions with forms like 1.15.2 or 1.15
               // (?<=\[)(\d{1,2}+\.\d{1,2}|\d{1,2}+\.\d{1,2}+\.\d{1,2})(?=\])
               string regexPattern = "(?<=\\[)(\\d{1,2}+\\.\\d{1,2}|\\d{1,2}+\\.\\d{1,2}+\\.\\d{1,2})(?=\\])";
               // Regex case insensitive
               Regex displayNameRegex = new Regex(regexPattern, RegexCompileFlags.CASELESS);
               // Check if we have a match
               if (displayNameRegex.match(displayName, 0, out matchInfo)) {
                   string displayMatch = matchInfo.fetch (0);
                   if (this.versionString == displayMatch) {
                       log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  Game version ($versionString) matched in: $displayName");

                        // Check the build version
                        MatchInfo buildVersionMatchInfo;
                        int buildVersion = 0;
                        // Match anything after "build " until reaching a single double quote character
                        string buildVersionPattern = "(?<=build\\s)(.*)";
                        Regex buildVersionRegex =  new Regex(buildVersionPattern, RegexCompileFlags.CASELESS);
                        log(null, LogLevelFlags.LEVEL_DEBUG, @"🔷  Checking for build version in: $displayName");
                        if (buildVersionRegex.match(displayName, 0, out buildVersionMatchInfo)) {
                            log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  A build was found in the string: $displayName");
                            if (buildVersionMatchInfo != null) {
                                string matchedBuildVersion = buildVersionMatchInfo.fetch (0);
                                int matchBuildNumber = int.parse (matchedBuildVersion);
                                if (matchBuildNumber != 0) {
                                    buildVersion = matchBuildNumber;
                                    log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  Build version parsed is: $buildVersion");
                                } else {
                                    log(null, LogLevelFlags.LEVEL_DEBUG, @"❌  Build version could not be parsed from: $displayName");
                                }
                            }
                        }

                        if (buildVersion > lastBuild) {
                            // The file name for the api
                            unowned string apiFileName = jsonObject.get_string_member("fileName");
                            // MatchInfo for extracting the version
                            MatchInfo versionStringMatchInfo;
                            // Matches anything after fabric-api or fabric-, but before .jar. Does not include api- in the result captured group string
                            string regexFileNamePattern = "(?<=fabric-api-|fabric-)([^-api].*)(?=.jar)";
                            Regex fileNameRegex = new Regex(regexFileNamePattern, RegexCompileFlags.CASELESS);
                            log(null, LogLevelFlags.LEVEL_DEBUG, "🔷  Parsing filename to extract API version information");
                            log(null, LogLevelFlags.LEVEL_DEBUG, @"🔷  Filename being parsed is: $apiFileName");
                            if (fileNameRegex.match(apiFileName, 0, out versionStringMatchInfo)) {
                                log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  Found API version information in: $apiFileName");
                                log(null, LogLevelFlags.LEVEL_DEBUG, "🔷  Checking for the API version string format");
                                // Create a new regex to check if we are on a newer version of the API
                                string newApiVersionPattern = "\\bapi-\\b";
                                Regex newApiVersionRegex = new Regex(newApiVersionPattern, RegexCompileFlags.CASELESS);
                                if (newApiVersionRegex.match(apiFileName)) {
                                    log(null, LogLevelFlags.LEVEL_DEBUG, "🆗  API version string format is the new one 'fabric-api-*");
                                    this._usingAnOlderVersion = false;
                                }
                                else {
                                    log(null, LogLevelFlags.LEVEL_DEBUG, "🆗  API version string format is the old one 'fabric-*");
                                    this._usingAnOlderVersion = true;
                                }
                                if (versionStringMatchInfo != null) {
                                    string matchedFileName = versionStringMatchInfo.fetch (0);
                                    // Set the api version string
                                    this._apiVersionString = matchedFileName;
                                    lastBuild = buildVersion;
                                    
                                }
                            } else {
                                log(null, LogLevelFlags.LEVEL_DEBUG, @"❌  No API version information could be found in: $$apiFileName");
                            }
                        }
                   }
               }
            } catch (RegexError regexError) {

            }
        }

    }

    private void checkPreReleases(Json.Array jsonArray) {
        log(null, LogLevelFlags.LEVEL_DEBUG, "🔷  Checking for pre releases");

         // Variable to know which is the last build
         int lastBuild = 0;

         // Variable to store the captured string
         MatchInfo matchInfo;
 
         // For each node in the array
         foreach (unowned Json.Node nodeElement in jsonArray.get_elements()) {
             // Get the object
             Json.Object jsonObject = nodeElement.get_object();
 
             // Get the display name string
             unowned string displayName = jsonObject.get_string_member("displayName");

             try {
                // This pattern matches and captures versions with forms like 1.15.2-pre1/2 or 1.15-pre5/6/7 or 1.15-pre3/b or 1.14.2 Pre-Release 2 or 1.15.2-pre1
                // (?<=\[)(.+?(?=-pre|Pre-Release))
                string regexPattern = "(?<=\\[)(.+?(?=-pre|Pre-Release))";
                // Regex case insensitive
                Regex displayNameRegex = new Regex(regexPattern, RegexCompileFlags.CASELESS);
                
                // Check if we have a match
                if (displayNameRegex.match(displayName, 0, out matchInfo)) {
                    string matchedGameVersion = matchInfo.fetch (0);
                    //(.+?(?=-pre|Pre-Release))
                    string selectionGameVersionRegexPattern = "(.+?(?=-pre| Pre-Release))";
                    MatchInfo selectionMatchInfo; 
                    // Regex for extracting the game version from the selection
                    Regex selectionRegex = new Regex(selectionGameVersionRegexPattern, RegexCompileFlags.CASELESS);
                    if (selectionRegex.match(this.versionString, 0, out selectionMatchInfo)) {
                        string matchedSelectedGameVersion = selectionMatchInfo.fetch (0);
                        if (matchedSelectedGameVersion == matchedGameVersion) {
                            log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  Game version ($versionString) matched in: $displayName");
                            MatchInfo preReleaseMatchInfo;
                            string preReleaseVersionString = this.versionString.substring(this.versionString.length - 1);
                            // This pattern matches the number/s of the pre release
                            string preReleaseRegexPattern = "(?<=-pre|Pre-Release ).*(?=\\])";
                            // Create a regex to check for the pre release version
                            Regex preReleaseRegex = new Regex(preReleaseRegexPattern, RegexCompileFlags.CASELESS);
                            // Check for the pre release version
                            if (preReleaseRegex.match(displayName, 0, out preReleaseMatchInfo)) {
                                string matchedPreReleaseVersionString = preReleaseMatchInfo.fetch (0);
                                if (preReleaseVersionString in matchedPreReleaseVersionString) {
                                    // Versions match
                                    log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  The selected pre release version ($versionString) was found in: $displayName");
                                    
                                    // Check the build version
                                    MatchInfo buildVersionMatchInfo;
                                    int buildVersion = 0;
                                    // Match anything after "build " until reaching a single double quote character
                                    string buildVersionPattern = "(?<=build\\s)(.*)";
                                    Regex buildVersionRegex =  new Regex(buildVersionPattern, RegexCompileFlags.CASELESS);
                                    log(null, LogLevelFlags.LEVEL_DEBUG, @"🔷  Checking for build version in: $displayName");
                                    if (buildVersionRegex.match(displayName, 0, out buildVersionMatchInfo)) {
                                        log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  A build was found in the string: $displayName");
                                        if (buildVersionMatchInfo != null) {
                                            string matchedBuildVersion = buildVersionMatchInfo.fetch (0);
                                            int matchBuildNumber = int.parse (matchedBuildVersion);
                                            if (matchBuildNumber != 0) {
                                                buildVersion = matchBuildNumber;
                                                log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  Build version parsed is: $buildVersion");
                                            } else {
                                                log(null, LogLevelFlags.LEVEL_DEBUG, @"❌  Build version could not be parsed from: $displayName");
                                            }
                                        }
                                    }

                                    if (buildVersion > lastBuild) {
                                        // The file name for the api
                                        unowned string apiFileName = jsonObject.get_string_member("fileName");
                                        // MatchInfo for extracting the version
                                        MatchInfo versionStringMatchInfo;
                                        // Matches anything after fabric-api or fabric-, but before .jar. Does not include api- in the result captured group string
                                        string regexFileNamePattern = "(?<=fabric-api-|fabric-)([^-api].*)(?=.jar)";
                                        Regex fileNameRegex = new Regex(regexFileNamePattern, RegexCompileFlags.CASELESS);
                                        log(null, LogLevelFlags.LEVEL_DEBUG, "🔷  Parsing filename to extract API version information");
                                        log(null, LogLevelFlags.LEVEL_DEBUG, @"🔷  Filename being parsed is: $apiFileName");
                                        if (fileNameRegex.match(apiFileName, 0, out versionStringMatchInfo)) {
                                            log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  Found API version information in: $apiFileName");
                                            log(null, LogLevelFlags.LEVEL_DEBUG, "🔷  Checking for the API version string format");
                                            // Create a new regex to check if we are on a newer version of the API
                                            string newApiVersionPattern = "\\bapi-\\b";
                                            Regex newApiVersionRegex = new Regex(newApiVersionPattern, RegexCompileFlags.CASELESS);
                                            if (newApiVersionRegex.match(apiFileName)) {
                                                log(null, LogLevelFlags.LEVEL_DEBUG, "🆗  API version string format is the new one 'fabric-api-*");
                                                this._usingAnOlderVersion = false;
                                            }
                                            else {
                                                log(null, LogLevelFlags.LEVEL_DEBUG, "🆗  API version string format is the old one 'fabric-*");
                                                this._usingAnOlderVersion = true;
                                            }
                                            if (versionStringMatchInfo != null) {
                                                string matchedFileName = versionStringMatchInfo.fetch (0);
                                                // Set the api version string
                                                this._apiVersionString = matchedFileName;
                                                lastBuild = buildVersion;
                                                
                                            }
                                        } else {
                                            log(null, LogLevelFlags.LEVEL_DEBUG, @"❌  No API version information could be found in: $$apiFileName");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } catch (RegexError regexError) {

            }
         }
    }

    private void checkReleaseCandidates(Json.Array jsonArray) {
        log(null, LogLevelFlags.LEVEL_DEBUG, "🔷  Checking for release candidate releases");

         // Variable to know which is the last build
         int lastBuild = 0;

         // Variable to store the captured string
         MatchInfo matchInfo;
 
         // For each node in the array
         foreach (unowned Json.Node nodeElement in jsonArray.get_elements()) {
             // Get the object
             Json.Object jsonObject = nodeElement.get_object();
 
             // Get the display name string
             unowned string displayName = jsonObject.get_string_member("displayName");

             try {
                // This pattern matches and captures versions with forms like 1.16-rc1 or 1.16-pre5/6/7/rc1
                // (?<=\\[)(.+?(?=-rc|\\/rc))
                string regexPattern = "(?<=\\[)(.+?(?=-rc|\\/rc))";
                // Regex case insensitive
                Regex displayNameRegex = new Regex(regexPattern, RegexCompileFlags.CASELESS);
                
                // Check if we have a match
                if (displayNameRegex.match(displayName, 0, out matchInfo)) {
                    string matchedGameVersion = matchInfo.fetch (0);
                    // (.+?(?=-rc))
                    string selectionGameVersionRegexPattern = "(.+?(?=-rc))";
                    MatchInfo selectionMatchInfo; 
                    
                    // Regex for extracting the game version from the selection
                    Regex selectionRegex = new Regex(selectionGameVersionRegexPattern, RegexCompileFlags.CASELESS);
                    if (selectionRegex.match(this.versionString, 0, out selectionMatchInfo)) {
                        string matchedSelectedGameVersion = selectionMatchInfo.fetch (0);
                        if (matchedSelectedGameVersion in matchedGameVersion) {
                            log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  Game version ($versionString) matched in: $displayName");
                            MatchInfo releaseCandidateMatchInfo;
                            string releaseCandidateVersionString = this.versionString.substring(this.versionString.length - 1);
                            // This pattern matches the number/s of the release candidate
                            string releaseCandidateRegexPattern = "(?<=-rc|\\/rc).*(?=\\])";
                            // Create a regex to check for the release candidate
                            Regex releaseCandidateRegex = new Regex(releaseCandidateRegexPattern, RegexCompileFlags.CASELESS);
                            // Check for the release candidate version
                            if (releaseCandidateRegex.match(displayName, 0, out releaseCandidateMatchInfo)) {
                                string matchedReleaseCandidateVersionString = releaseCandidateMatchInfo.fetch (0);
                                if (releaseCandidateVersionString in matchedReleaseCandidateVersionString) {

                                    // Versions match
                                    log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  The selected release candidate version ($versionString) was found in: $displayName");
                                    
                                    // Check the build version
                                    MatchInfo buildVersionMatchInfo;
                                    int buildVersion = 0;
                                    // Match anything after "build " until reaching a single double quote character
                                    string buildVersionPattern = "(?<=build\\s)(.*)";
                                    Regex buildVersionRegex =  new Regex(buildVersionPattern, RegexCompileFlags.CASELESS);
                                    log(null, LogLevelFlags.LEVEL_DEBUG, @"🔷  Checking for build version in: $displayName");
                                    if (buildVersionRegex.match(displayName, 0, out buildVersionMatchInfo)) {
                                        log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  A build was found in the string: $displayName");
                                        if (buildVersionMatchInfo != null) {
                                            string matchedBuildVersion = buildVersionMatchInfo.fetch (0);
                                            int matchBuildNumber = int.parse (matchedBuildVersion);
                                            if (matchBuildNumber != 0) {
                                                buildVersion = matchBuildNumber;
                                                log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  Build version parsed is: $buildVersion");
                                            } else {
                                                log(null, LogLevelFlags.LEVEL_DEBUG, @"❌  Build version could not be parsed from: $displayName");
                                            }
                                        }
                                    }

                                    if (buildVersion > lastBuild) {
                                        // The file name for the api
                                        unowned string apiFileName = jsonObject.get_string_member("fileName");
                                        // MatchInfo for extracting the version
                                        MatchInfo versionStringMatchInfo;
                                        // Matches anything after fabric-api or fabric-, but before .jar. Does not include api- in the result captured group string
                                        string regexFileNamePattern = "(?<=fabric-api-|fabric-)([^-api].*)(?=.jar)";
                                        Regex fileNameRegex = new Regex(regexFileNamePattern, RegexCompileFlags.CASELESS);
                                        log(null, LogLevelFlags.LEVEL_DEBUG, "🔷  Parsing filename to extract API version information");
                                        log(null, LogLevelFlags.LEVEL_DEBUG, @"🔷  Filename being parsed is: $apiFileName");
                                        if (fileNameRegex.match(apiFileName, 0, out versionStringMatchInfo)) {
                                            log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  Found API version information in: $apiFileName");
                                            log(null, LogLevelFlags.LEVEL_DEBUG, "🔷  Checking for the API version string format");
                                            // Create a new regex to check if we are on a newer version of the API
                                            string newApiVersionPattern = "\\bapi-\\b";
                                            Regex newApiVersionRegex = new Regex(newApiVersionPattern, RegexCompileFlags.CASELESS);
                                            if (newApiVersionRegex.match(apiFileName)) {
                                                log(null, LogLevelFlags.LEVEL_DEBUG, "🆗  API version string format is the new one 'fabric-api-*");
                                                this._usingAnOlderVersion = false;
                                            }
                                            else {
                                                log(null, LogLevelFlags.LEVEL_DEBUG, "🆗  API version string format is the old one 'fabric-*");
                                                this._usingAnOlderVersion = true;
                                            }
                                            if (versionStringMatchInfo != null) {
                                                string matchedFileName = versionStringMatchInfo.fetch (0);
                                                // Set the api version string
                                                this._apiVersionString = matchedFileName;
                                                lastBuild = buildVersion;
                                                
                                            }
                                        } else {
                                            log(null, LogLevelFlags.LEVEL_DEBUG, @"❌  No API version information could be found in: $$apiFileName");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } catch (RegexError regexError) {

            }
         }
    }

    private void checkSnapshot(Json.Array jsonArray) {
        // Variable to know which is the last build
        int lastBuild = 0;

        // Variable to store the captured string
        MatchInfo matchInfo;

        // For each node in the array
        foreach (unowned Json.Node nodeElement in jsonArray.get_elements()) {
            // Get the object
            Json.Object jsonObject = nodeElement.get_object();

            // Get the display name string
            unowned string displayName = jsonObject.get_string_member("displayName");

            try {
                // This pattern matches and captures versions with forms like 20w14a or 20w14infinite or 20w13a/b
                // Previous pattern \[(\d{2}+[a-zA-Z]{1}+\d{2}+[a-zA-Z]{1})\]
                // Current pattern \[(\d{2}+[a-zA-Z]{1}+\d{2}+[a-zA-z].*)\]
                string regexPattern = "\\[(\\d{2}+[a-zA-Z]{1}+\\d{2}+[a-zA-z].*)\\]";
                // Regex case insensitive
                Regex displayNameRegex = new Regex(regexPattern, RegexCompileFlags.CASELESS);
                // Check if we have a match
                if (displayNameRegex.match(displayName, 0, out matchInfo)) {
                    // Check if matchInfo is not null
                    if (matchInfo != null) {
                        // Get all the captured groups
                        string matchedString = matchInfo.fetch (0);
                        // If the string matches, the corresponding version was found
                        if (this.versionString in matchedString || lastCharacterIsContained(matchedString)) {
                            log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  The selected game version ($versionString) was found in: $displayName");
                            // Check the build version
                            MatchInfo buildVersionMatchInfo;
                            int buildVersion = 0;
                            // Match anything after "build " until reaching a single double quote character
                            string buildVersionPattern = "(?<=build\\s)(.*)";
                            Regex buildVersionRegex =  new Regex(buildVersionPattern, RegexCompileFlags.CASELESS);
                            log(null, LogLevelFlags.LEVEL_DEBUG, @"🔷  Checking for build version in: $displayName");
                            if (buildVersionRegex.match(displayName, 0, out buildVersionMatchInfo)) {
                                log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  A build was found in the string: $displayName");
                                if (buildVersionMatchInfo != null) {
                                    string matchedBuildVersion = buildVersionMatchInfo.fetch (0);
                                    int matchBuildNumber = int.parse (matchedBuildVersion);
                                    if (matchBuildNumber != 0) {
                                        buildVersion = matchBuildNumber;
                                        log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  Build version parsed is: $buildVersion");
                                    } else {
                                        log(null, LogLevelFlags.LEVEL_DEBUG, @"❌  Build version could not be parsed from: $displayName");
                                    }
                                }
                            }

                            if (buildVersion > lastBuild) {
                                // The file name for the api
                                unowned string apiFileName = jsonObject.get_string_member("fileName");
                                // MatchInfo for extracting the version
                                MatchInfo versionStringMatchInfo;
                                // Matches anything after fabric-api or fabric-, but before .jar. Does not include api- in the result captured group string
                                string regexFileNamePattern = "(?<=fabric-api-|fabric-)([^-api].*)(?=.jar)";
                                Regex fileNameRegex = new Regex(regexFileNamePattern, RegexCompileFlags.CASELESS);
                                log(null, LogLevelFlags.LEVEL_DEBUG, "🔷  Parsing filename to extract API version information");
                                log(null, LogLevelFlags.LEVEL_DEBUG, @"🔷  Filename being parsed is: $apiFileName");
                                if (fileNameRegex.match(apiFileName, 0, out versionStringMatchInfo)) {
                                    log(null, LogLevelFlags.LEVEL_DEBUG, @"✔️  Found API version information in: $apiFileName");
                                    log(null, LogLevelFlags.LEVEL_DEBUG, "🔷  Checking for the API version string format");
                                    // Create a new regex to check if we are on a newer version of the API
                                    string newApiVersionPattern = "\\bapi-\\b";
                                    Regex newApiVersionRegex = new Regex(newApiVersionPattern, RegexCompileFlags.CASELESS);
                                    if (newApiVersionRegex.match(apiFileName)) {
                                        log(null, LogLevelFlags.LEVEL_DEBUG, "🆗  API version string format is the new one 'fabric-api-*");
                                        this._usingAnOlderVersion = false;
                                    }
                                    else {
                                        log(null, LogLevelFlags.LEVEL_DEBUG, "🆗  API version string format is the old one 'fabric-*");
                                        this._usingAnOlderVersion = true;
                                    }
                                    if (versionStringMatchInfo != null) {
                                        string matchedFileName = versionStringMatchInfo.fetch (0);
                                        // Set the api version string
                                        this._apiVersionString = matchedFileName;
                                        lastBuild = buildVersion;
                                        
                                    }
                                } else {
                                    log(null, LogLevelFlags.LEVEL_DEBUG, @"❌  No API version information could be found in: $$apiFileName");
                                }
                            }
                        }
                        
                    }
                    
                }

            } catch (RegexError regexError) {
                // Do nothing
            }
        }
    }

    private bool lastCharacterIsContained(string matchedString) {
        string justTheVersion = this.versionString.substring(0, this.versionString.length -1);
        if (!(justTheVersion in matchedString)) return false;

        string lastCharacter = this.versionString.substring(this.versionString.length -1, 1);
        int matchedStringIndex = matchedString.index_of("/" + lastCharacter);
        if (matchedStringIndex != -1) {
            return true;
        } else {
            return false;
        }
    }
}