public class InputVerifier {

    private bool modVersionValid { get; set; }
    private bool basePackageValid { get; set; }
    private bool modIDValid { get; set; }
    private string[] keyWords;
    private string[] disallowedLiterals;
    public string failedString {get; set;}
    public bool errorOnRegularExpression {get; set;}

    public InputVerifier () {
        this.keyWords = {"abstract", "continue", "for", "new", "switch", "assert", "default", "if", "package", 
        "synchronized", "boolean", "do", "goto", "private", "this", "break", "double", "implements", "protected", 
        "throw", "byte", "else", "import", "public", "throws", "case", "enum", "instanceof", "return", "transient", 
        "catch", "extends", "int", "short", "try", "char", "final", "interface", "static", "void", "class", 
        "finally", "long", "strictfp", "volatile", "const", "float", "native", "super", "while"};
        this.disallowedLiterals = {"true", "false", "null"};
        this.errorOnRegularExpression = false;
    }

    public bool verifyBasePackage (string stringToCheck) {
        MatchInfo keyWordsMatchInfo;
        string totalKeyWords = "(";
        for (int i = 0; i < this.keyWords.length - 1; i++) {
            totalKeyWords += "\\b" + this.keyWords[i] + "\\b|";
        }
        totalKeyWords += "\\b" + this.keyWords[this.keyWords.length - 1] + "\\b)";

        try {
                // Regex for checking keywords
                Regex keyWordRegex = new Regex(totalKeyWords, RegexCompileFlags.CASELESS);
                
                if (keyWordRegex.match(stringToCheck, 0, out keyWordsMatchInfo)) {
                    foreach (var matchedKeyWord in keyWordsMatchInfo.fetch_all ()) {
                        string checkForUnderscoresPattern = "(" + matchedKeyWord + "_)";
                        Regex checkForUnderscoresRegex = new Regex (checkForUnderscoresPattern, RegexCompileFlags.CASELESS);
                        if (!checkForUnderscoresRegex.match (stringToCheck)) {
                            this.failedString = matchedKeyWord;
                            return false;
                        }
                    }
                }

                MatchInfo disallowedLiteralsMatchInfo;
                string totalLiterals = "(";
                for (int i = 0; i < this.disallowedLiterals.length - 1; i++) {
                    totalLiterals += "\\b" + this.disallowedLiterals[i] + "\\b|";
                }
                totalLiterals += "\\b" + this.disallowedLiterals[this.disallowedLiterals.length - 1] + "\\b)";

                // Regex for checking keywords
                Regex literalsRegex = new Regex(totalLiterals, RegexCompileFlags.CASELESS);
                
                if (literalsRegex.match(stringToCheck, 0 , out disallowedLiteralsMatchInfo)) {
                    string matchedLiteral = disallowedLiteralsMatchInfo.fetch (0);
                    if (matchedLiteral != null) this.failedString = matchedLiteral;
                    return false;
                }

                if (hasSpaces (stringToCheck)) return false;
        } catch (RegexError regexError) {
            log(null, LogLevelFlags.LEVEL_DEBUG, "❌  There was an error on the regular expression when checking for base package string validity" + regexError.message);
            this.errorOnRegularExpression = true;
        } 

        return true;
    }

    public bool hasSpaces (string stringToCheck) {
        string regexPattern = "(\\s)";
        try {
            Regex spaceRegex = new Regex (regexPattern, RegexCompileFlags.CASELESS);
            if (spaceRegex.match(stringToCheck)) return true;
            else return false;
        } catch (RegexError regexError) {
            log(null, LogLevelFlags.LEVEL_DEBUG, "❌  There was an error on the regular expression when checking for spaces on the string." + regexError.message);
            this.errorOnRegularExpression = true;
        }
        return false;
    }
}