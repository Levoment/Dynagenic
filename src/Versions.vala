using Gee;
using Soup;
using Json;

public class Versions {

    // Map containing the Minecraft versions and whether it is a stable version or not
    private Gee.List<string>  _versionsMap = new Gee.ArrayList<string> ();

    public Gee.List<string> versionsMap {
        get { return _versionsMap; }
        set { _versionsMap = value; }
    }

    private bool stableVersionsOnly;
    
    /**
     * Constructor
     *
     * @param stableVersionsOnly = true means only stable versions will be added. false means all available versions will be added.
     */
    public Versions (bool stableVersionsOnly) {
        this.stableVersionsOnly = stableVersionsOnly;
        // URL to gather the versions from
        string url = "https://meta.fabricmc.net/v1/versions/game";

        // Create an HTTP session to get the game versions
        var session = new Soup.Session ();
        var message = new Soup.Message ("GET", url);

        // send the HTTP request and wait for response
        session.send_message (message);

        // TODO add an error message if the connection was not sucessful

        string messageData = (string) message.response_body.data;

        // output the result to stdout 
        //stdout.write (message.response_body.data);

        // If we only want to show the stable versions
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
    }

    private void processNode(Json.Node node) {
        // Versions are an array of objects
        Json.Array jsonArray = node.get_array();
        // For each node in the array
        foreach (unowned Json.Node nodeElement in jsonArray.get_elements()) {
            // Get the object
            Json.Object jsonObject = nodeElement.get_object();
            // For each element in the object
            foreach(unowned string elementInObject in jsonObject.get_members()) {
                // Check whether the version is stable or unstable
                switch (elementInObject) {
                    case "stable":
                    // Get the boolean indicating whether it is stable or not
                    unowned Json.Node item = jsonObject.get_member (elementInObject);
                    // If it is a stable version and we want stable versions
                    if (item.get_boolean() && this.stableVersionsOnly) {
                        // Let's get the version
                        unowned string versionString = jsonObject.get_string_member ("version");
                        // Let's add it to the map of versions
                        _versionsMap.add(versionString);
                    } else if (!this.stableVersionsOnly) {
                        // We want all versions, let's add it
                        unowned string versionString = jsonObject.get_string_member ("version");
                        _versionsMap.add(versionString);
                    }
                    break;
                }
                
            }
        }
    }
}