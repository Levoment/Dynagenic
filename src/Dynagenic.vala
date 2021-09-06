using Gtk;
using Gdk;
using Archive;

public class Dynagenic : Gtk.Application {

    private Versions versions;
    private LoaderVersions loaderVersions;
    private ApiVersions apiVersions;

    private ComboBoxText minecraftVersionsComboBox;
    private Gtk.Button generateProjectGtkButton;
    private Gtk.Button continueGtkButton;
    private Gtk.Dialog couldNotFindApiVersionGtkDialog;
    private Gtk.Button noGtkButton;
    private Gtk.HeaderBar mainWindowHeaderBar;
    private Gtk.ApplicationWindow main_window; 

    private Gtk.Entry modVersionGtkEntry;
    private Gtk.Entry basePackageGtkEntry;
    private Gtk.Entry archivesBasenameGtkEntry;
    private Gtk.Entry modIDGtkEntry;
    private Gtk.Entry modNameGtkEntry;
    private Gtk.Entry authorsGtkEntry;
    private Gtk.Entry homepageGtkEntry;
    private Gtk.Entry sourcesGtkEntry;
    private Gtk.Entry licenseGtkEntry;
    private Gtk.Entry mainClassNameGtkEntry;

    private Gtk.Label gradlePropertiesMinecraftVersionGtkLabel;
    private Gtk.Label gradlePropertiesYarnMappingsGtkLabel;
    private Gtk.Label gradlePropertiesLoaderVersionGtkLabel;
    private Gtk.Label gradlePropertiesFabricApiVersionGtkLabel;


    private string modJsonPath;
    private string mixinJsonPath;
    private string mainClassFilePath;
    private string mixinClassFilePath;
    private string gradlePropertiesFilePath;
    private string buildGradleFilePath;

    private string[] listOfDirectoriesToMove = {};
    private string[] listOfFilesToMove = {};

    private string pathToSaveProjectTo;

    private bool continueGeneratingProject;
    private bool canGenerateProject;

    private File[] listOfFilesToDelete;
    private Gee.List<File> listOfFoldersToRemove;

    private Gee.List<string> listOfFilesToNotDelete;
    private Gee.List<string> listOfFoldersToNotDelete;

    private const string BRAND_STYLESHEET = "
    * {
        font-size: large;
    }
      ";

    
    public Dynagenic () {
        Object (
            application_id: "com.github.levoment.dynagenic",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {

        Gtk.Builder builder = new Gtk.Builder();


        string fileToLoad = "";
    
        try {
            // Get the data directories
            string[] dataDirs = Environment.get_system_data_dirs ();
            log(null, LogLevelFlags.LEVEL_DEBUG, "🔷  Listing data dirs in the OS");
            // For each data directory, try to find the MainApplication.glade file
            foreach (string dataDir in dataDirs) {
                log(null, LogLevelFlags.LEVEL_DEBUG, @"🔷  Datadir: $dataDir");
                File file = File.new_for_path (dataDir + "/dynagenic/resources/MainApplication.glade");
                if (file.query_exists ()) {
                    fileToLoad = dataDir + "/dynagenic/resources/MainApplication.glade";
                    log(null, LogLevelFlags.LEVEL_DEBUG, "✔️  MainApplication.glade was found in: " + dataDir + "/dynagenic/resources");
                    break;
                } else {
                    log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Could not find MainApplication.glade in: " + dataDir + "/dynagenic/resources");
                }
            } 

            if (fileToLoad == "") {
                log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Could not find MainApplication.glade in any of the system data directories.");
                log(null, LogLevelFlags.LEVEL_DEBUG, @"🔷  Attempting to get MainApplication.glade from same directory");
                fileToLoad = "MainApplication.glade";
                if (!(File.new_for_path (Environment.get_current_dir () + "/MainApplication.glade").query_exists ())) {
                    log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Could not find MainApplication.glade in the current directory.");
                    // Try to get the MainApplication.glade file from the appimage
                    string appDirPath = GLib.Environment.get_variable ("APPDIR");
                    if (!(File.new_for_path (appDirPath + "/usr/share/dynagenic/resources/MainApplication.glade").query_exists())) {
                        log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Could not find MainApplication.glade in the app image mount point: " + appDirPath + "usr/share/dynagenic/resources/MainApplication.glade");
                    } else {
                        fileToLoad = appDirPath + "/usr/share/dynagenic/resources/MainApplication.glade";
                    }
                } else {
                    fileToLoad = "MainApplication.glade";
                    log(null, LogLevelFlags.LEVEL_DEBUG, "✔️  MainApplication.glade was found in: " + Environment.get_current_dir ());
                }
            }

            builder.add_from_file(fileToLoad);

            this.main_window = builder.get_object ("MainApplicationWindow") as Gtk.ApplicationWindow;
            this.main_window.application = this;

            // Set the main window width
            int width;
            int height;
            main_window.get_size (out width, out height);
            main_window.set_default_size (width + 100, height + 50);
            this.main_window.show_all ();

            // Get the Gtk.Switch for the stable versions
            var showOnlyStableVersionsGtkSwitch = builder.get_object("showOnlyStableVersionsGtkSwitch") as Gtk.Switch;
            bool onlyStableVersions = showOnlyStableVersionsGtkSwitch.state;
            showOnlyStableVersionsGtkSwitch.state_set.connect(switchChange);

            // Get the ComboBoxText for the Minecraft version
            this.minecraftVersionsComboBox = builder.get_object ("minecraftVersionGtkComboBox") as Gtk.ComboBoxText;

            // Set the signal for the combobox when a selection change occurs
            this.minecraftVersionsComboBox.changed.connect(onVersionSelected);

            // Get the generateProjectGtkButton
            this.generateProjectGtkButton = builder.get_object ("generateProjectGtkButton") as Gtk.Button;

            // Apply style to Generate Project Button
            //  StyleContext buttonStyleContext = this.generateProjectGtkButton.get_style_context ();
            //  CssProvider buttonCSSProvider = new CssProvider();

            //  buttonCSSProvider.load_from_data(
            //  "@define-color buttonAndTitleBarColor shade (#64baff, 0.85);" +
            //  " button {"            +
            //  "   color: alpha (white, 1.0);" +
            //  "   background: shade (@buttonAndTitleBarColor, 0.95);" +
            //  "   border-color: alpha (#000, 0.2);" +
            //  "   text-shadow: 0 1.0px alpha (#000, 0.2);" +
            //  "}");

            //  buttonStyleContext.add_provider(buttonCSSProvider, Gtk.STYLE_PROVIDER_PRIORITY_USER);

            // Continue button
            this.continueGtkButton = builder.get_object ("continueGtkButton") as Gtk.Button;
            // Apply style to Continue Button
            //  StyleContext continueButtonStyleContext = this.continueGtkButton.get_style_context ();
            //  CssProvider continueButtonCSSProvider = new CssProvider();

            //  continueButtonCSSProvider.load_from_data(
            //  " button {
            //      color: alpha (white, 1.0);
            //      background: shade (@error_color, 1.0);
            //      border-color: alpha (#000, 0.2);
            //      text-shadow: 0 1.0px alpha (#000, 0.2);
            //  }");
            //  continueButtonStyleContext.add_provider(continueButtonCSSProvider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
            this.continueGtkButton.clicked.connect (continueGtkButtonClicked);

            this.generateProjectGtkButton.clicked.connect (generateProjectButtonClicked);

            // Could not find API version dialog
            this.couldNotFindApiVersionGtkDialog = builder.get_object ("couldNotFindApiVersionGtkDialog") as Gtk.Dialog;

            // Get all the Gtk.Entry widgets
            this.modVersionGtkEntry = builder.get_object ("modVersionGtkEntry") as Gtk.Entry;
            this.basePackageGtkEntry = builder.get_object ("basePackageGtkEntry") as Gtk.Entry;
            this.archivesBasenameGtkEntry = builder.get_object ("archivesBasenameGtkEntry") as Gtk.Entry;
            this.modIDGtkEntry = builder.get_object ("modIDGtkEntry") as Gtk.Entry;
            this.modNameGtkEntry = builder.get_object ("modNameGtkEntry") as Gtk.Entry;
            this.authorsGtkEntry = builder.get_object ("authorsGtkEntry") as Gtk.Entry;
            this.homepageGtkEntry = builder.get_object ("homepageGtkEntry") as Gtk.Entry;
            this.sourcesGtkEntry = builder.get_object ("sourcesGtkEntry") as Gtk.Entry;
            this.licenseGtkEntry = builder.get_object ("licenseGtkEntry") as Gtk.Entry;
            this.mainClassNameGtkEntry = builder.get_object ("mainClassNameGtkEntry") as Gtk.Entry;

            // Apply theme
            var provider = new Gtk.CssProvider ();
            Screen screen = Gdk.Screen.get_default();
            try {
                provider.load_from_data (BRAND_STYLESHEET);
                Gtk.StyleContext.add_provider_for_screen (screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (Error e) {
                log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Could not create CSS provider: %s", e.message);
            }

            // Get the header bar
            this.mainWindowHeaderBar = builder.get_object ("mainWindowHeaderBar") as Gtk.HeaderBar;

            // Get the No Gtk button
            this.noGtkButton = builder.get_object ("noGtkButton") as Gtk.Button;
            noGtkButton.clicked.connect (noGtkButtonClicked);

            // Get the Gradle Properties labels
            this.gradlePropertiesMinecraftVersionGtkLabel = builder.get_object ("gradlePropertiesMinecraftVersionGtkLabel") as Gtk.Label;
            this.gradlePropertiesYarnMappingsGtkLabel = builder.get_object ("gradlePropertiesYarnMappingsGtkLabel") as Gtk.Label;
            this.gradlePropertiesLoaderVersionGtkLabel = builder.get_object ("gradlePropertiesLoaderVersionGtkLabel") as Gtk.Label;
            this.gradlePropertiesFabricApiVersionGtkLabel = builder.get_object ("gradlePropertiesFabricApiVersionGtkLabel") as Gtk.Label;

            // Get the versions
            this.versions = new Versions(onlyStableVersions);

            // Check if we have a list of versions
            if (this.versions != null) {
                // Iterate through the list of versions
                foreach (var entry in versions.versionsMap) {
                    // Add them to the ComboBox
                    minecraftVersionsComboBox.append_text(entry);
                }
            }

        } catch (GLib.Error error) {
            log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Error loading Glade file: " + error.message);
        }
    }

    public static int main (string[] args) {
        var app = new Dynagenic ();
        
        return app.run (args);
    }

    public bool switchChange(bool state) {
        // Get the versions
        this.versions = new Versions(state);
        this.minecraftVersionsComboBox.remove_all();
        // Iterate through the list of versions
        foreach (var entry in versions.versionsMap) {
            // Add them to the ComboBox
            this.minecraftVersionsComboBox.append_text(entry);
        }
        return false;
    }

    public void onVersionSelected() {
        // Clear the Gradle Properties labels
        this.gradlePropertiesMinecraftVersionGtkLabel.set_label ("");
        this.gradlePropertiesYarnMappingsGtkLabel.set_label ("");
        this.gradlePropertiesLoaderVersionGtkLabel.set_label ("");
        this.gradlePropertiesFabricApiVersionGtkLabel.set_label ("");

        string versionString = this.minecraftVersionsComboBox.get_active_text();
        if (versionString != null) {
            // Set the Minecraft version
            this.gradlePropertiesMinecraftVersionGtkLabel.set_label (versionString);
            // Get the versions
            this.loaderVersions = new LoaderVersions(versionString);
            // Set the Mappings and Loader version
            this.gradlePropertiesYarnMappingsGtkLabel.set_label (this.loaderVersions.mappingsVersionString);
            this.gradlePropertiesLoaderVersionGtkLabel.set_label (this.loaderVersions.loaderVersionString);
            
            // Get the API version
            this.apiVersions = new ApiVersions(versionString);

            if (!this.apiVersions.hasAPIVersion) {
                this.gradlePropertiesFabricApiVersionGtkLabel.set_label ("⚠️ Could not find a Fabric API version for the selected Minecraft version");
                showCouldNotFindApiVersionGtkDialog ();
            } else {
                this.continueGeneratingProject = true;
                this.gradlePropertiesFabricApiVersionGtkLabel.set_label (this.apiVersions.apiVersionString);
            }
        }
    }

    public void showMessageDialogForMissingFields(string missingField) {
        MessageDialog messageDialog = new MessageDialog(main_window, 
        DialogFlags.DESTROY_WITH_PARENT, 
        MessageType.ERROR,
        ButtonsType.CLOSE,
        @"$missingField is a required field to create a project.");
        messageDialog.run ();
        messageDialog.destroy ();
    }

    public void generateProjectButtonClicked () {
        if (continueGeneratingProject) {
            if (this.minecraftVersionsComboBox.get_active_text () == null) {
                showMessageDialogForMissingFields("Minecraft version");
                return;
            }
    
            if (this.modVersionGtkEntry.get_text ().dup ().strip () == "") {
                showMessageDialogForMissingFields("Mod version");
                return;
            }
    
            if (this.basePackageGtkEntry.get_text ().dup ().strip () == "") {
                showMessageDialogForMissingFields("Base package (maven_group)");
                return;
            }
    
            if (this.modIDGtkEntry.get_text ().dup ().strip () == "") {
                showMessageDialogForMissingFields("Mod ID");
                return;
            }
    
            if (this.modNameGtkEntry.get_text ().dup ().strip () == "") {
                showMessageDialogForMissingFields("Mod name");
                return;
            }
    
            if (this.archivesBasenameGtkEntry.get_text ().dup ().strip () == "") {
                showMessageDialogForMissingFields("Archives basename");
                return;
            }

            if (this.mainClassNameGtkEntry.get_text ().dup ().strip () == "") {
                showMessageDialogForMissingFields("Main class name");
                return;
            }
    
            chooseWhereToSaveProject ();
            if (this.canGenerateProject) {
                generateProject ();
            }
        }
    }

    private void chooseWhereToSaveProject () {
        FileChooserNative fileChooserNative = new FileChooserNative ("Save Fabric project to...", this.main_window, FileChooserAction.SELECT_FOLDER, "Save", "Cancel");
        int response = fileChooserNative.run ();
        if (response == Gtk.ResponseType.ACCEPT) {
            if (fileChooserNative.get_filename () != null) {
                this.pathToSaveProjectTo = fileChooserNative.get_filename ();
                this.canGenerateProject = true;
            } else {
                this.canGenerateProject = false;
            }
        } else {
            this.canGenerateProject = false;
        }
    }

    public void showErrorOnRegularExpressionMessageDialog (string failedString) {
        MessageDialog messageDialog = new MessageDialog(main_window, 
        DialogFlags.DESTROY_WITH_PARENT, 
        MessageType.ERROR,
        ButtonsType.CLOSE,
        @"There was an error when evaluating a regular expression on \"$failedString\". To get more details, run the program on debug mode with G_MESSAGES_DEBUG=all and re-create the problem.");
        messageDialog.run ();
        messageDialog.destroy ();
    }

    private void generateProject () {
        // First check whether the inputs are valid
        string modVersion = this.modVersionGtkEntry.get_text ().dup ().strip ();
        string basePackage = this.basePackageGtkEntry.get_text ().dup ().strip ();
        string modID = this.modIDGtkEntry.get_text ().dup ().strip ();
        string mainClassName = this.mainClassNameGtkEntry.get_text ().dup ().strip ();

        InputVerifier inputVerifier = new InputVerifier ();

        // Check mod version validity
        if (inputVerifier.hasSpaces (modVersion)) {
            stdout.printf(@"$modVersion\n");
            showCannotContainSpacesMessageDialog ("Mod version");
            return;
        } else {
            if (inputVerifier.errorOnRegularExpression) {
                // Reset the value
                inputVerifier.errorOnRegularExpression = false;
                showErrorOnRegularExpressionMessageDialog ("Mod version");
                return;
            }
        }

        // Check basepackage validity
        if (!inputVerifier.verifyBasePackage (basePackage)) {

            if (inputVerifier.errorOnRegularExpression) {
                // Reset the value
                inputVerifier.errorOnRegularExpression = false;
                showErrorOnRegularExpressionMessageDialog ("Base package");
                return;
            }

            string failedString = inputVerifier.failedString;
            if (failedString != null) {
                MessageDialog messageDialog = new MessageDialog(main_window, 
                DialogFlags.DESTROY_WITH_PARENT, 
                MessageType.ERROR,
                ButtonsType.CLOSE,
                @"\"$failedString\" cannot be in the base package name.");
                messageDialog.run ();
                messageDialog.destroy ();
            } else {
                showCannotContainSpacesMessageDialog ("Base package");
            } 
            return;
        }

        // Check mod id validity
        if (inputVerifier.hasSpaces (modID)) {
            showCannotContainSpacesMessageDialog ("Mod ID");
            return;
        } else {
            if (inputVerifier.errorOnRegularExpression) {
                // Reset the value
                inputVerifier.errorOnRegularExpression = false;
                showErrorOnRegularExpressionMessageDialog ("Mod version");
                return;
            }
        }

        if (inputVerifier.hasSpaces(mainClassName)) {
            showCannotContainSpacesMessageDialog ("Main class name");
            return;
        }

        getTheFabricExampleProject ();
    }

    private void showCannotContainSpacesMessageDialog (string failedCheck) {
        MessageDialog messageDialog = new MessageDialog(main_window, 
                DialogFlags.DESTROY_WITH_PARENT, 
                MessageType.ERROR,
                ButtonsType.CLOSE,
                @"$failedCheck cannot contain spaces.");
                messageDialog.run ();
                messageDialog.destroy ();
    }

    private void getTheFabricExampleProject () {
        string url = "https://github.com/FabricMC/fabric-example-mod/archive/master.zip";
        log(null, LogLevelFlags.LEVEL_DEBUG, @"🔷  Downloading Fabric Example Project from: $url");

        // Create an HTTP session to get the api version
        var session = new Soup.Session ();

        try {
            Soup.Request request = session.request (url);
            InputStream stream = request.send ();

            // Mod name
            string modName = this.modNameGtkEntry.get_text ().dup ();
        
            File fileToSaveTo = File.new_for_path (pathToSaveProjectTo + @"/$modName.zip");
            FileOutputStream os = fileToSaveTo.replace (null, false, FileCreateFlags.REPLACE_DESTINATION);

            os.splice (stream, OutputStreamSpliceFlags.CLOSE_TARGET);

            // Extract zip file
            extractZipFile (pathToSaveProjectTo + @"/$modName.zip");

            // Replace mod id
            replaceModInformation ();

            // Create folders and files in their correct locations
            createFoldersAndFiles();

            string pathSeparator = GLib.Path.DIR_SEPARATOR_S;

            MessageDialog messageDialog = new MessageDialog(main_window, 
                DialogFlags.DESTROY_WITH_PARENT, 
                MessageType.INFO,
                ButtonsType.CLOSE,
                @"✔️ Project created successfully and saved on: $pathToSaveProjectTo$pathSeparator$modName");
                messageDialog.run ();
                messageDialog.destroy ();

        } catch (GLib.Error error) {
            log(null, LogLevelFlags.LEVEL_DEBUG, "❌  There was an error when trying to save the Fabric Project. " + error.message);
        }
        // TODO add an error message if the connection was not sucessful
    }

    /*
        Code from https://valadoc.org/libarchive/Archive.WriteDisk.html example
    */
    private void extractZipFile (string filename) {
        string modName = this.modNameGtkEntry.get_text ().dup ().strip ();
        string mainClassName = this.mainClassNameGtkEntry.get_text ().dup ().strip ();
        string modID = this.modIDGtkEntry.get_text ().dup ().strip ();

        // Request files to delete
        this.listOfFoldersToRemove = new Gee.ArrayList<File> ();
        delete_directory (this.pathToSaveProjectTo + "/" + modName);

        // Once the files are done being requested delete them
        foreach (var fileToDelete in this.listOfFilesToDelete) {
            try {
                log(null, LogLevelFlags.LEVEL_DEBUG, "🗋 Deleting file: %s", fileToDelete.get_path ());
                fileToDelete.@delete ();
            } catch (Error error) {
                log(null, LogLevelFlags.LEVEL_DEBUG, "❌  IOError when deleting files: %s", error.message);
                
            }
        }

        while (!listOfFoldersToRemove.is_empty) {
            // Delete all folders
            for (int i = 0; i < listOfFoldersToRemove.size; i++) {
                try {
                    log(null, LogLevelFlags.LEVEL_DEBUG, "📁 Deleting folder: %s", listOfFoldersToRemove.@get (i).get_path ());
                    listOfFoldersToRemove.@get (i).@delete ();
                    listOfFoldersToRemove.remove_at (i);
                } catch (FileError error) {
                    log(null, LogLevelFlags.LEVEL_DEBUG, "❌  %s", error.message);
                }  catch (IOError error) {
                    if (error.code == IOError.NOT_FOUND) listOfFoldersToRemove.remove_at (i);
                    log(null, LogLevelFlags.LEVEL_DEBUG, "❌  %s", error.message);
                } catch (Error error) {
                    log(null, LogLevelFlags.LEVEL_DEBUG, "❌  %s", error.message);
                }
            }
        }

        
        log(null, LogLevelFlags.LEVEL_DEBUG, @"🔷  Extracting downloaded file...");
        // Select which attributes we want to restore.
        Archive.ExtractFlags flags;
        flags = Archive.ExtractFlags.TIME;
        flags |= Archive.ExtractFlags.PERM;
        flags |= Archive.ExtractFlags.ACL;
        flags |= Archive.ExtractFlags.FFLAGS;

        Archive.Read archive = new Archive.Read ();
        archive.support_format_all ();
        archive.support_filter_all ();

        Archive.WriteDisk extractor = new Archive.WriteDisk ();
        extractor.set_options (flags);
        extractor.set_standard_lookup ();

        if (archive.open_filename (filename, 10240) != Archive.Result.OK) {
            log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Error opening %s: %s (%d)", filename, archive.error_string (), archive.errno ());
            showIOError (@"Error opening " + filename + archive.error_string() + archive.errno ().to_string ());
            return;
        }

        unowned Archive.Entry entry;
        Archive.Result last_result;
        while ((last_result = archive.next_header (out entry)) == Archive.Result.OK) {    

            entry.set_pathname (this.pathToSaveProjectTo + "/" + entry.pathname ());
            

            // Replace the main path
            entry.set_pathname (entry.pathname ().replace ("fabric-example-mod-master/", modName + "/"));

            if ("modid" in entry.pathname ().down ()) {
                entry.set_pathname (entry.pathname ().replace ("modid", modID));
            }

            if ("ExampleMod.java".down () in entry.pathname ().down ()) {
                entry.set_pathname (entry.pathname ().replace ("ExampleMod.java", mainClassName + ".java"));
                this.mainClassFilePath = entry.pathname ();
            }

            if ("ExampleMixin.java".down () in entry.pathname ().down ()) {
                this.mixinClassFilePath = entry.pathname ();
            }

            if ("fabric.mod.json".down () in entry.pathname ().down ()) {
                this.modJsonPath = entry.pathname ();
            }

            if ("mixins.json".down () in entry.pathname ().down ()) {
                this.mixinJsonPath = entry.pathname ();
            }

            if ("gradle.properties".down () in entry.pathname ().down ()) {
                this.gradlePropertiesFilePath = entry.pathname ();
            }

            if ("build.gradle".down () in entry.pathname ().down ()) {
                this.buildGradleFilePath = entry.pathname ();
            }

            

            string newPathName = entry.pathname ();
            log(null, LogLevelFlags.LEVEL_DEBUG, @"📁 $newPathName");

            if ("/" in newPathName.substring (newPathName.length - 1) || "\\" in newPathName.substring (newPathName.length - 1)) {
                string pathPattern = "(?<=net.fabricmc.example.)(.*[\\S])";
                MatchInfo matchInfo;
                try {
                    Regex regex = new Regex (pathPattern, RegexCompileFlags.CASELESS);
                    if (regex.match (newPathName, 0, out matchInfo)) {
                        foreach (var matchedEntry in matchInfo.fetch_all ()) {
                            this.listOfDirectoriesToMove += newPathName;
                        }
                    }
                } catch (RegexError regexError) {
                    log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Regex error when trying to get list of folders to move");
                    showRegexError (@"Regex error when trying to get list of folders to move: @(regexError.message)");
                }
            } else {
                string pathPattern = "(?<=net.fabricmc.example.)(.*[\\S])";
                MatchInfo matchInfo;
                try {
                    Regex regex = new Regex (pathPattern, RegexCompileFlags.CASELESS);
                    if (regex.match (newPathName, 0, out matchInfo)) {
                        foreach (var matchedEntry in matchInfo.fetch_all ()) {
                            this.listOfFilesToMove += newPathName;
                        }
                    }
                } catch (RegexError regexError) {
                    log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Regex error when trying to get list of files to move");
                    showRegexError (@"Regex error when trying to get list of files to move: $(regexError.message)");
                }
            }

            

            if (extractor.write_header (entry) != Archive.Result.OK) {
                continue;
            }

            uint8[] buffer = null;
            size_t buffer_length;
            Posix.off_t offset;
            while (archive.read_data_block (out buffer, out offset) == Archive.Result.OK) {
                if (extractor.write_data_block (buffer, offset) != Archive.Result.OK) {
                    break;
                }
            }
        }

        if (last_result != Archive.Result.EOF) {
            log(null, LogLevelFlags.LEVEL_DEBUG, "❌  Error: %s (%d)", archive.error_string (), archive.errno ());
            showIOError (@"Error opening " + filename + archive.error_string () + archive.errno ().to_string ());
        }
    }

    private void replaceModInformation () {
        // For mod json file
        File modJsonInputFile = File.new_for_path (this.modJsonPath);
        File modJsonOutputFile = File.new_for_path (this.modJsonPath);

        // For mixin json file
        File mixinJsonInputFile = File.new_for_path (this.mixinJsonPath);
        File mixinJsonOutputFile = File.new_for_path (this.mixinJsonPath);

        // For the main class file
        File mainClassInputFile = File.new_for_path (this.mainClassFilePath);
        File mainClassOutputFile = File.new_for_path (this.mainClassFilePath);

        // For the mixin class file
        File mixinClassInputFile = File.new_for_path (this.mixinClassFilePath);
        File mixinClassOutputFile = File.new_for_path (this.mixinClassFilePath);

        // For the gradle properties file
        File gradlePropertiesInputFile = File.new_for_path (this.gradlePropertiesFilePath);
        File gradlePropertiesOutputFile = File.new_for_path (this.gradlePropertiesFilePath);

        // For the build gradle file
        File buildGradleInputFile = File.new_for_path (this.buildGradleFilePath);
        File buildGradleOutputFile = File.new_for_path (this.buildGradleFilePath);

        // Strings that will go in the files
        string modID = this.modIDGtkEntry.get_text ().dup ().strip ();
        string modName = this.modNameGtkEntry.get_text ().dup ().strip ();
        string authors = this.authorsGtkEntry.get_text ().dup ().strip ();
        string homepage = this.homepageGtkEntry.get_text ().dup ().strip ();
        string sources = this.sourcesGtkEntry.get_text ().dup ().strip ();
        string license = this.licenseGtkEntry.get_text ().dup ().strip ();
        string basePackage = this.basePackageGtkEntry.get_text ().dup ().strip ();
        string mainClassName = this.mainClassNameGtkEntry.get_text ().dup ().strip ();
        string modVersion = this.modVersionGtkEntry.get_text ().dup ().strip ();
        string archivesBaseName = this.archivesBasenameGtkEntry.get_text ().dup ().strip ();

        try {
            FileInputStream inputStream = modJsonInputFile.read ();
            DataInputStream dataInputStream = new DataInputStream (inputStream);
            string line;
            string allLinesOfTheFile = "";

            while ((line = dataInputStream.read_line ()) != null) {
                if ("\"name\":".down () in line.down ()) {
                    line = line.replace ("Example Mod", modName);
                }
                if ("\"homepage\":".down () in line.down ()) {
                    line = line.replace ("https://fabricmc.net/", homepage);
                }
                if ("\"sources\":".down () in line.down ()) {
                    line = line.replace ("https://github.com/FabricMC/fabric-example-mod", sources);
                }
                if ("\"license\":".down () in line.down () && (license != null && license != "")) {
                    line = line.replace ("CC0-1.0", license);
                }
                // Check for main entry point
                if ("\"net.fabricmc.example.ExampleMod\"".down () in line.down () && (mainClassName != null && mainClassName != "")) {
                    // Replace main entry point
                    line = line.replace ("net.fabricmc.example.ExampleMod", basePackage + "." + mainClassName);
                }

                if ("\"Me!\"".down () in line.down () && (authors != null && authors != "")) {
                    
                    string[] listOfAuthors = authors.split (",");
                    if (listOfAuthors != null) {
                        if (listOfAuthors.length > 1) {
                            // Keep indentation
                            int indentation = line.index_of ("Me");
                            line = "";
                            for (int i = 0; i < indentation; i++) {
                                line += " ";
                            }

                            for (int i = 0; i < listOfAuthors.length; i++) {
                                string author = listOfAuthors[i].strip ();
                                line += "\"" + author + "\", ";
                            }
                            line = line.substring (0, line.last_index_of (", ") - 1) + "\"";
                        } else {
                            line = line.replace ("Me!", listOfAuthors[0].strip ());
                        }
                    } else {
                        line = line.replace ("Me!", "");
                    }
                }

                if ("\"minecraft".down () in line.down () && this.loaderVersions.loaderVersion != null) {
                    string minecraftVersionRegexPattern = "(?<=\")(=?\\d.+)(?=\")";
                    string versionString = this.minecraftVersionsComboBox.get_active_text();

                    string regexPattern = "(\\d{2}+[a-zA-Z]{1}+\\d{2}+[a-zA-z].*)";
                    Regex minecraftVersionRegex = new Regex (regexPattern, RegexCompileFlags.CASELESS);

                    if (minecraftVersionRegex.match (versionString)) {
                        int indentation = line.index_of ("\"minecraft");
                        line = "";
                        for (int i = 0; i < indentation; i++) {
                            line += " ";
                        }
                        line += "\"minecraft\": ";
                        if ("20w" in versionString) line += "\"1.16.x\"";
                        if ("19w" in versionString) line += "\"1.15.x\"";
                        
                    } else if ("1.16-" in versionString) {
                        int indentation = line.index_of ("\"minecraft");
                        line = "";
                        for (int i = 0; i < indentation; i++) {
                            line += " ";
                        }
                        line += "\"minecraft\": ";
                        line += "\"1.16.x\"";
                    }
                    else {
                        minecraftVersionRegex = new Regex (minecraftVersionRegexPattern, RegexCompileFlags.CASELESS);
                        line = minecraftVersionRegex.replace (line, line.length, 0, versionString);
                    }
                }

                allLinesOfTheFile += line + "\n";
            }

            // Replace mod id in the string
            allLinesOfTheFile = allLinesOfTheFile.replace ("modid", modID);

            // Write the file again
            FileOutputStream fileOutputStream = modJsonOutputFile.replace (null, false, FileCreateFlags.REPLACE_DESTINATION);
            DataOutputStream dataOutputString = new DataOutputStream (fileOutputStream);
            dataOutputString.put_string (allLinesOfTheFile);
            fileOutputStream.close ();

            /* 
            * Read the mixin template
            */
            inputStream = mixinJsonInputFile.read ();
            dataInputStream = new DataInputStream (inputStream);
            line = "";
            allLinesOfTheFile = "";

            while ((line = dataInputStream.read_line ()) != null) {
                if ("net.fabricmc.example.mixin".down () in line.down ()) {
                    line = line.replace ("net.fabricmc.example.mixin", basePackage + ".mixin");
                }
                allLinesOfTheFile += line + "\n";
            }

            // Write the mixin template
            fileOutputStream = mixinJsonOutputFile.replace (null, false, FileCreateFlags.REPLACE_DESTINATION);
            dataOutputString = new DataOutputStream (fileOutputStream);
            dataOutputString.put_string (allLinesOfTheFile);
            fileOutputStream.close ();

            /* 
            * Read the main class template
            */
            inputStream = mainClassInputFile.read ();
            dataInputStream = new DataInputStream (inputStream);
            line = "";
            allLinesOfTheFile = "";

            while ((line = dataInputStream.read_line ()) != null) {
                if ("public class ExampleMod".down () in line.down ()) {
                    line = line.replace ("ExampleMod", mainClassName);
                }
                if ("package net.fabricmc.example".down () in line.down ()) {
                    line = line.replace ("package net.fabricmc.example", "package "+ basePackage);
                }

                allLinesOfTheFile += line + "\n";
            }

            // Write the main class template
            fileOutputStream = mainClassOutputFile.replace (null, false, FileCreateFlags.REPLACE_DESTINATION);
            dataOutputString = new DataOutputStream (fileOutputStream);
            dataOutputString.put_string (allLinesOfTheFile);
            fileOutputStream.close ();

            /* 
            * Read the mixin class template
            */
            inputStream = mixinClassInputFile.read ();
            dataInputStream = new DataInputStream (inputStream);
            line = "";
            allLinesOfTheFile = "";

            while ((line = dataInputStream.read_line ()) != null) {
                if ("package net.fabricmc.example.mixin".down () in line.down ()) {
                    line = line.replace ("package net.fabricmc.example.mixin", "package "+ basePackage + ".mixin");
                }

                allLinesOfTheFile += line + "\n";
            }

            // Write the main class template
            fileOutputStream = mixinClassOutputFile.replace (null, false, FileCreateFlags.REPLACE_DESTINATION);
            dataOutputString = new DataOutputStream (fileOutputStream);
            dataOutputString.put_string (allLinesOfTheFile);
            fileOutputStream.close ();
            
            /* 
            * Read the gradle.properties file
            */
            inputStream = gradlePropertiesInputFile.read ();
            dataInputStream = new DataInputStream (inputStream);
            line = "";
            allLinesOfTheFile = "";

            while ((line = dataInputStream.read_line ()) != null) {
                // Place minecraft version
                if ("minecraft_version".down () in line.down ()) {
                    int indentation = line.down ().index_of ("minecraft_version".down ());
                    line = "";
                    for (int i = 0; i < indentation; i++) {
                        line += " ";
                    }
                    string versionString = this.minecraftVersionsComboBox.get_active_text();

                    if ("-" in versionString) {
                        line += "minecraft_version=" + versionString;
                    } else {
                        line += "minecraft_version=" + this.loaderVersions.onlyTheVersionString;
                    }
                }

                // Place yarn mappings version
                if ("yarn_mappings".down () in line.down ()) {
                    int indentation = line.down ().index_of ("yarn_mappings".down ());
                    line = "";
                    for (int i = 0; i < indentation; i++) {
                        line += " ";
                    }

                    line += "yarn_mappings=" + this.loaderVersions.mappingsVersionString;
                }

                // Place yarn mappings version
                if ("loader_version".down () in line.down ()) {
                    int indentation = line.down ().index_of ("loader_version".down ());
                    line = "";
                    for (int i = 0; i < indentation; i++) {
                        line += " ";
                    }

                    line += "loader_version=" + this.loaderVersions.loaderVersionString;
                }

                // Place mod version
                if ("mod_version".down () in line.down ()) {
                    int indentation = line.down ().index_of ("mod_version".down ());
                    line = "";
                    for (int i = 0; i < indentation; i++) {
                        line += " ";
                    }

                    line += "mod_version=" + modVersion;
                }

                // Place base package
                if ("maven_group".down () in line.down ()) {
                    int indentation = line.down ().index_of ("maven_group".down ());
                    line = "";
                    for (int i = 0; i < indentation; i++) {
                        line += " ";
                    }

                    line += "maven_group=" + basePackage;
                }

                // Place archives base name
                if ("archives_base_name".down () in line.down ()) {
                    int indentation = line.down ().index_of ("archives_base_name".down ());
                    line = "";
                    for (int i = 0; i < indentation; i++) {
                        line += " ";
                    }

                    line += "archives_base_name=" + archivesBaseName;
                }

                // Place the fabric api version
                if ("fabric_version".down () in line.down () && this.apiVersions.apiVersionString != null) {
                    int indentation = line.down ().index_of ("fabric_version".down ());
                    line = "";
                    for (int i = 0; i < indentation; i++) {
                        line += " ";
                    }

                    line += "fabric_version=" + this.apiVersions.apiVersionString;
                }

                allLinesOfTheFile += line + "\n";
            }

            

            // Write the gradle properties template
            fileOutputStream = gradlePropertiesOutputFile.replace (null, false, FileCreateFlags.REPLACE_DESTINATION);
            dataOutputString = new DataOutputStream (fileOutputStream);
            dataOutputString.put_string (allLinesOfTheFile);
            fileOutputStream.close ();

            // Check if using an older name version for the API
            //  if (this.apiVersions.usingAnOlderVersion) {

            //      /* 
            //      * Read the build gradle file
            //      */
            //      inputStream = buildGradleInputFile.read ();
            //      dataInputStream = new DataInputStream (inputStream);
            //      line = "";
            //      allLinesOfTheFile = "";

            //      while ((line = dataInputStream.read_line ()) != null) {
            //          if ("modImplementation \"net.fabricmc.fabric-api:fabric-api".down () in line.down ()) {
            //              line = line.replace ("net.fabricmc.fabric-api:fabric-api", "net.fabricmc:fabric ");
            //          }

            //          allLinesOfTheFile += line + "\n";
            //      }

            //      // Write the build gradle file
            //      fileOutputStream = buildGradleOutputFile.replace (null, false, FileCreateFlags.REPLACE_DESTINATION);
            //      dataOutputString = new DataOutputStream (fileOutputStream);
            //      dataOutputString.put_string (allLinesOfTheFile);
            //      fileOutputStream.close ();
            //  }


        } catch (RegexError regexError) {
            log(null, LogLevelFlags.LEVEL_DEBUG, @"❌  Regex error when trying to write mod template: $(regexError.message)");
            showRegexError (@"Regex error when trying to write mod template: $(regexError.message)");
        } catch (Error e) {
            log(null, LogLevelFlags.LEVEL_DEBUG, @"❌  Error when trying to write mod template: $(e.message)");
            showIOError (@"Error when trying to write mod template: " + e.message);
        } 
    }

    private void createFoldersAndFiles () {
        string modName = this.modNameGtkEntry.get_text ().dup ().strip ();
        string rootPath = this.pathToSaveProjectTo + "/" + modName + "/src/main/java";
        string basePackage = this.basePackageGtkEntry.get_text ().dup ().strip ();

        this.listOfFilesToNotDelete = new Gee.ArrayList<string>();
        this.listOfFoldersToNotDelete = new Gee.ArrayList<string>();

        string changingPath = rootPath;
        string[] listOfFoldersToCreate = basePackage.split (".");
        if (listOfFoldersToCreate != null) {
            foreach (var folder in listOfFoldersToCreate) {
                try {
                    File file = File.new_for_path (changingPath + "/" + folder);
                    file.make_directory ();
                    changingPath = file.get_path ();
                    this.listOfFoldersToNotDelete.add (changingPath);
                } catch (IOError error) {
                    if (error.code == IOError.EXISTS) {
                        log(null, LogLevelFlags.LEVEL_DEBUG, "❌ %s", error.message) ;
                        changingPath = changingPath + "/" + folder;
                        this.listOfFoldersToNotDelete.add (changingPath);
                    }
                } catch (Error e) {
                    log(null, LogLevelFlags.LEVEL_DEBUG, "❌  IOError: %s", e.message);
                    showIOError (e.message);
                }
            }

            string newRootPath = changingPath;

            string mainClassName = this.mainClassNameGtkEntry.get_text ().dup ().strip ();

            try {
                // Copy main class
                File originalFile = File.new_for_path (rootPath + "/net/fabricmc/example/" + mainClassName + ".java");
                File copyOfFile = File.new_for_path (newRootPath + "/" + mainClassName + ".java");
                originalFile.copy (copyOfFile, FileCopyFlags.OVERWRITE);
                this.listOfFilesToNotDelete.add (copyOfFile.get_path ());

                // Create mixin directory
                File directory = File.new_for_path (newRootPath + "/mixin");
                directory.make_directory ();
                this.listOfFoldersToNotDelete.add (directory.get_path ());

                // Copy mixin class
                File originalMixinFile = File.new_for_path (rootPath + "/net/fabricmc/example/mixin/ExampleMixin.java");
                File copyOfMixinFile = File.new_for_path (newRootPath + "/mixin/ExampleMixin.java");
                originalMixinFile.copy (copyOfMixinFile, FileCopyFlags.OVERWRITE);
                this.listOfFilesToNotDelete.add (copyOfMixinFile.get_path ());

                // Delete mixin class
                //  originalMixinFile = File.new_for_path (rootPath + "/net/fabricmc/example/mixin/ExampleMixin.java");
                //  originalMixinFile.@delete ();
                //  // Delete mixin folder
                //  directory = File.new_for_path (rootPath + "/net/fabricmc/example/mixin");
                //  directory.@delete ();
                // Delete main class
                //originalFile.@delete ();

                // Create a list to delete
                listOfFilesToDelete = {};
                listOfFoldersToRemove = new Gee.ArrayList<File> ();
                File rootFile = File.new_for_path (this.pathToSaveProjectTo + "/" + modName + "/src/main/java/net/");
                if (!this.listOfFoldersToRemove.contains (rootFile)) this.listOfFoldersToRemove.add (rootFile);
                delete_directory (this.pathToSaveProjectTo + "/" + modName + "/src/main/java/net/");

                // Once the files are done being requested delete them
                foreach (var fileToDelete in this.listOfFilesToDelete) {
                    if (!(fileToDelete.get_path () in listOfFilesToNotDelete)) {
                        try {
                            fileToDelete.@delete ();
                        } catch (Error error) {
                            log(null, LogLevelFlags.LEVEL_DEBUG, "❌  IOError when deleting files: %s", error.message);
                            showIOError ("Error when deleting files: " + error.message);
                        }
                    }
                }

                for (int i = 0; i < this.listOfFoldersToRemove.size; i++) {
                    foreach (string folderToNotDelete in this.listOfFoldersToNotDelete) {
                        if (folderToNotDelete.strip () == this.listOfFoldersToRemove.@get (i).get_path ().strip ()) {
                            this.listOfFoldersToRemove.remove_at (i);
                        }
                    }
                }

                while (!this.listOfFoldersToRemove.is_empty) {
                    // Delete all folders
                    for (int i = 0; i < this.listOfFoldersToRemove.size; i++) {
                        try {
                            this.listOfFoldersToRemove.@get (i).@delete ();
                            this.listOfFoldersToRemove.remove_at (i);
                        }catch (FileError error) {
                            //log(null, LogLevelFlags.LEVEL_DEBUG, "❌  %s", error.message);
                        }  catch (IOError error) {
                            if (error.code == IOError.NOT_FOUND) this.listOfFoldersToRemove.remove_at (i);
                            //log(null, LogLevelFlags.LEVEL_DEBUG, "❌  %s", error.message);
                        } catch (Error error) {
                            //log(null, LogLevelFlags.LEVEL_DEBUG, "❌  %s", error.message);
                        }
                    }
                }

                // Delete example folder
                //  File folderToDelete = File.new_for_path(this.pathToSaveProjectTo + "/" + modName + "/src/main/java/net/fabricmc/example");
                //  folderToDelete.@delete();
                //  // Delete fabricmc folder
                //  folderToDelete = File.new_for_path (this.pathToSaveProjectTo + "/" + modName + "/src/main/java/net/fabricmc");
                //  folderToDelete.@delete ();
                //  // Delete net folder
                //  folderToDelete = File.new_for_path (this.pathToSaveProjectTo + "/" + modName + "/src/main/java/net");
                //  folderToDelete.@delete ();
            } catch (Error error) {
                log(null, LogLevelFlags.LEVEL_DEBUG, "❌  IOError: %s", error.message);
                showIOError (error.message);
            }
        }
    }

    public void continueGtkButtonClicked () {
        this.continueGeneratingProject = true;
        this.couldNotFindApiVersionGtkDialog.hide ();
    }

    public void noGtkButtonClicked () {
        this.continueGeneratingProject = false;
        this.couldNotFindApiVersionGtkDialog.hide ();
    }

    private void showCouldNotFindApiVersionGtkDialog () {
        //  if (this.main_window.get_default_widget () != null) {
        //      this.couldNotFindApiVersionGtkDialog.show ();
        //  }
        this.couldNotFindApiVersionGtkDialog.show ();
    }

    private void showIOError (string message) {
        MessageDialog messageDialog = new MessageDialog(main_window, 
        DialogFlags.DESTROY_WITH_PARENT, 
        MessageType.ERROR,
        ButtonsType.CLOSE,
        @"IOError: $message");
        messageDialog.run ();
        messageDialog.destroy ();
    }

    private void showRegexError (string message) {
        MessageDialog messageDialog = new MessageDialog(main_window, 
        DialogFlags.DESTROY_WITH_PARENT, 
        MessageType.ERROR,
        ButtonsType.CLOSE,
        @"Regex error: @message");
        messageDialog.run ();
        messageDialog.destroy ();
    }

    private void delete_directory (string startPath) {

        var dir = File.new_for_path (startPath);

        try {
            // Get directory entries
            var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME,
                                                        FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
            FileInfo info;
            while ((info = enumerator.next_file ()) != null) {

                // Append the files found so far to the list of files to delete

                File currentFile = enumerator.get_child (info);

                if (currentFile.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS) == GLib.FileType.DIRECTORY) {
                    if (!this.listOfFoldersToRemove.contains (currentFile)) this.listOfFoldersToRemove.add (currentFile);
                    delete_directory (currentFile.get_path ());
                }

                if (currentFile.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS) == GLib.FileType.REGULAR) {
                    this.listOfFilesToDelete += currentFile;
                }
            }
            
        } catch (IOError error) {
            if (error.code == IOError.NOT_FOUND) {
                log(null, LogLevelFlags.LEVEL_DEBUG, "❌  IOError when getting files to delete: %s", error.message);
            }
        } catch (Error error) {
            log(null, LogLevelFlags.LEVEL_DEBUG, "❌  IOError when getting files to delete: %s", error.message);
            showIOError ("Error when getting files to delete: " + error.message);
        }
    }

 }