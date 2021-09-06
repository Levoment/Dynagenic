using Gee;
using Soup;
using Json;

public class LoaderVersions {

    private string _loaderVersionString;

    public string loaderVersionString {
        get { return _loaderVersionString; }
        set { _loaderVersionString = value; }
    }

    private string _mappingsVersionString;

    public string mappingsVersionString {
        get { return _mappingsVersionString; }
        set { _mappingsVersionString = value; }
    }

    public string loaderVersion {get; set;}

    public string onlyTheVersionString {get; set;}

    private string versionString;

    
    /**
     * Constructor
     *
     * @param versionString = the version of the game for which the loader and mappings versions will be looked up for
     */
    public LoaderVersions (string versionString) {
        this.versionString = versionString;

        // URL to gather the loader versions from
        string url = "https://meta.fabricmc.net/v1/versions/loader/" + this.versionString;

        // Create an HTTP session to get the loader and mapping versions
        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", url);

        // send the HTTP request and wait for response
        session.send_message (message);

        // TODO add an error message if the connection was not sucessful

        string messageData = (string) message.response_body.data;

        Parser jsonParser = new Parser();
        try {
            if (jsonParser.load_from_data(messageData)) {
                // Get the root node:
                Json.Node node = jsonParser.get_root ();
                processNode(node);
            } else {
                // TODO add an error indicating that the data could not be parsed
            }
        } catch (GLib.Error error) {
            // TODO display the error
        }

        // Check if the loader version exists
        if (this._loaderVersionString != null) {
            // Let's get the version only
            string versionOnlyRegexPattern = "(.*)(?=\\+)";
            MatchInfo versionOnlyMatchInfo;
            try {
                Regex versionOnlyRegex = new Regex (versionOnlyRegexPattern, RegexCompileFlags.CASELESS);
                if (versionOnlyRegex.match (this._loaderVersionString, 0, out versionOnlyMatchInfo)) {
                    string versionOnly = versionOnlyMatchInfo.fetch (0);
                    if (versionOnly != null) {
                        this.loaderVersion = versionOnly;
                    }
                }
            } catch (RegexError regexError) {

            }
        }
        setOnlyTheVersionString ();
    }

    private void processNode(Json.Node node) {
        // Versions are an array of objects
        Json.Array jsonArray = node.get_array();

        // Variable to know which is the last build
        int64 lastBuild = 0;

        // For each node in the array
        foreach (unowned Json.Node nodeElement in jsonArray.get_elements()) {
            // Get the object
            Json.Object jsonObject = nodeElement.get_object();

            // Get the loader object
            unowned Json.Object loaderObject = jsonObject.get_object_member("loader");
            // Get the mappings object
            unowned Json.Object mappingsObject = jsonObject.get_object_member("mappings");
            // Get the build number
            int64 loaderBuild = loaderObject.get_int_member("build");
            // If the build is greater than the last one
            if (loaderBuild > lastBuild) {
                // Add the loader
                this._loaderVersionString = loaderObject.get_string_member("version");
                // Add the mappings
                this._mappingsVersionString = mappingsObject.get_string_member("version");
                lastBuild = loaderBuild;
            }
        }
    }

    private void setOnlyTheVersionString () {
        try {
            string unstableVersionsPattern = "(\\d{2}+[a-zA-Z]{1}+\\d{2}+[a-zA-Z].*)";
            MatchInfo unstableVersionsMatchInfo;
            Regex regex = new Regex (unstableVersionsPattern, RegexCompileFlags.CASELESS);
            if (regex.match (this.versionString, 0, out unstableVersionsMatchInfo)) {
                this.onlyTheVersionString = unstableVersionsMatchInfo.fetch (0);
                return;
            }

            string stableVersionsPattern = "(\\d+.+\\d+.\\d|\\d+[.]+\\d.)";
            MatchInfo stableVersionsMatchInfo;
            regex = new Regex (stableVersionsPattern, RegexCompileFlags.CASELESS);
            if (regex.match (this.versionString, 0, out stableVersionsMatchInfo)) {
                this.onlyTheVersionString = stableVersionsMatchInfo.fetch (0);
            }
        } catch (RegexError regexError) {

        }
    }
}