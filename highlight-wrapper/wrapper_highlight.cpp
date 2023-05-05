#include "wrapper_highlight.h"
#include "highlight/src/include/codegenerator.h"
#include "highlight/src/include/datadir.h"
#include "highlight/src/include/version.h"
#include "goutils.h"
#include <os/log.h>
#include <cstdio>
#include <iostream>
#include <regex>
#include <magic.h>
#include <filesystem>

#define EXPORT __attribute__((visibility("default")))

#define IO_ERROR_REPORT_LENGTH 5

static os_log_t sLog = os_log_create("org.sbarex.QLMarkdown", "C Wrapper");

static DataDir dataDir;
static highlight::CodeGenerator *generator = nullptr;

static string lastSuffix;

bool inlineCSS = false;
bool formattingEnabled;

static bool endsWith(const std::string& str, const std::string& suffix)
{
    return str.size() >= suffix.size() && 0 == str.compare(str.size()-suffix.size(), suffix.size(), suffix);
}

vector <string> collectPluginPaths2(DataDir *data_Dir, const vector<string>& plugins)
{
    vector<string> absolutePaths;
    for (const auto & plugin : plugins) {
        if (Platform::fileExists(plugin)) {
            absolutePaths.push_back(plugin);
        } else {
            absolutePaths.push_back(data_Dir->getPluginPath(plugin+".lua"));
        }
    }
    return absolutePaths;
}

char *get_highlight_version() {
    return strdup(highlight::Info::getVersion().c_str());
}
char *get_highlight_website() {
    return strdup(highlight::Info::getWebsite().c_str());
}
char *get_highlight_email() {
    return strdup(highlight::Info::getEmail().c_str());
}

const char *get_lua_info() {
    return LUA_COPYRIGHT;
}

void highlight_init(const char *search_dir) {
    string pp = realpath(search_dir, nullptr);
    if (!endsWith(pp, "/")) {
        pp += Platform::pathSeparator;
    }
    os_log_debug(sLog, "Initializing search dirs with `%{public}s`.", pp.c_str());
    dataDir.initSearchDirectories(pp);

    // call before printInstalledLanguages!
    dataDir.loadFileTypeConfig("filetypes");
}

int highlight_init_generator() {
    highlight_release_generator();
    os_log_debug(sLog, "Init generator.");
    generator = highlight::CodeGenerator::getInstance ( highlight::OutputType::HTML );

    generator->setHTMLAttachAnchors ( false );
    generator->setHTMLOrderedList ( false );
    generator->setHTMLInlineCSS ( inlineCSS );
    generator->setHTMLEnclosePreTag ( false );
    generator->setHTMLAnchorPrefix ( "l" );
    generator->setHTMLClassName ( "hl" );

    generator->setValidateInput ( false );
    generator->setNumberWrappedLines ( true );

    generator->setStyleInputPath ( "" );
    generator->setStyleOutputPath ( "" );
    generator->setIncludeStyle ( true );
    generator->setPrintLineNumbers ( false, 1 );
    generator->setPrintZeroes ( false );
    generator->setFragmentCode ( true );
    generator->setOmitVersionComment ( true );
    generator->setIsolateTags ( false );

    generator->setKeepInjections ( false);
    generator->setPreformatting ( highlight::WRAP_DISABLED,
                                  ( generator->getPrintLineNumbers() ) ?
                                  80 - 5 : 80,
                                  0 );

    //generator->setEncoding ( options.getEncoding() );
    generator->setBaseFont ( "" ) ;
    generator->setBaseFontSize ( "10" ) ;
    generator->setLineNumberWidth ( 5 );
    generator->disableTrailingNL(0);
    generator->setPluginParameter("");

    int getLineRangeStart = 0;
    int getLineRangeEnd = 0;
    if (getLineRangeStart>0 && getLineRangeEnd>0){
        generator->setStartingInputLine(getLineRangeStart);
        generator->setMaxInputLineCnt(getLineRangeEnd);
    }

    /** list of plugin file names */
    vector <string> userPlugins;
    const  vector <string> pluginFileList=collectPluginPaths2( &dataDir, userPlugins);

    for (const auto & i : pluginFileList) {
        if ( !generator->initPluginScript(i) ) {
            os_log_error(sLog, "%{public}s in %{public}s", generator->getPluginScriptError().c_str(), i.c_str());

            return EXIT_FAILURE;
        }
    }

/*
    if ( options.printOnlyStyle() ) {
        if (!options.formatSupportsExtStyle()) {
            cerr << "highlight: output format supports no external styles.\n";
            return EXIT_FAILURE;
        }
        bool useStdout =  getStyleOutFilename =="stdout" || options.forceStdout();
        string cssOutFile=options.getOutDirectory()  + getStyleOutFilename;
        bool success=generator->printExternalStyle ( useStdout?"":cssOutFile );
        if ( !success ) {
            cerr << "highlight: Could not write " << cssOutFile <<".\n";
            return EXIT_FAILURE;
        }
        return EXIT_SUCCESS;
    }
    */

    string getIndentScheme;
    formattingEnabled = generator->initIndentationScheme ( getIndentScheme );
    if ( !formattingEnabled && !getIndentScheme.empty() ) {
        os_log_error(sLog, "Undefined indentation scheme %{public}s.", getIndentScheme.c_str());
        /*
        cerr << "highlight: Undefined indentation scheme "
             << getIndentScheme
             << ".\n";
         */
        return EXIT_FAILURE;
    }
    
    return EXIT_SUCCESS;
}

const char *highlight_get_current_theme(void) {
    return generator->getStyleName().c_str();
}

int highlight_set_current_theme(const char *theme) {
    string themePath;
    if (strlen(theme) == 0) {
        return EXIT_FAILURE;
    }
    if (Platform::fileExists(theme)) {
        themePath = theme;
    } else {
        string full_theme_name = theme;
        if (!endsWith(full_theme_name, ".theme")) {
            full_theme_name += ".theme";
        }
        themePath = dataDir.getThemePath(full_theme_name);
    }

    if (!generator) {
        if (highlight_init_generator() != EXIT_SUCCESS) {
            return EXIT_FAILURE;
        }
    }

    if ( !generator->initTheme ( themePath ) ) {
        os_log_error(sLog, "%{public}s", generator->getThemeInitError().c_str());
        printf("ERROR FOR theme %s\n", themePath.c_str());
        return EXIT_FAILURE;
    } else {
        os_log_debug(sLog, "Using theme `%{public}s`.", themePath.c_str());
        // printf("using theme %s\n", themePath.c_str());
    }
    return EXIT_SUCCESS;
}

void highlight_release_generator(void) {
    delete generator;
    generator = nullptr;
}

void highlight_format_style(void *context, ResultCallback callback, const char *background) {
    int exit_code = 0;
    char *content = highlight_format_style2(&exit_code, background);
    callback(context, content, 0);
    free(content);
}

EXPORT char *highlight_format_style2(int *exit_code, const char *background)
{
    if (!generator) {
        if (highlight_init_generator() != EXIT_SUCCESS) {
            *exit_code = EXIT_FAILURE;
            return nullptr;
        }
    }

    string content = generator->getStyleDefinition() + "\n" + generator->readUserStyleDef();

    if (background != nullptr) {
        std::regex reg("background-color:#[a-f0-9]{6};");
        string replace = background;
        if (!replace.empty()) {
            replace = "background-color: " + string(background) + ";";
        }
        content = regex_replace(content, reg, replace);
    }

    *exit_code = EXIT_SUCCESS;
    return strdup(content.c_str());
}

void highlight_format_string(const char *code, const char *language, void *context, ResultCallback callback, int export_fragment = 1)
{
    int exit_code = 0;
    char *result = highlight_format_string2(code, language, &exit_code, export_fragment);

    callback(context, result, exit_code);

    free(result);
}

static string analyzeFile ( const string& file )
{
    string firstLine;
    stringstream cin_bufcopy;

    //  This copies all the data to a new buffer, uses the data to get the
    //  first line, then makes cin use the new buffer that underlies the
    //  stringstream instance
    cin_bufcopy << file;
    getline ( cin_bufcopy, firstLine );
    cin_bufcopy.seekg ( 0, ios::beg );
    cin.rdbuf ( cin_bufcopy.rdbuf() );

    StringMap::iterator it;
    boost::xpressive::sregex rex;
    boost::xpressive::smatch what;
    for ( it=dataDir.assocByShebang.begin(); it!=dataDir.assocByShebang.end(); it++ ) {
        rex = boost::xpressive::sregex::compile( it->first );
        if ( boost::xpressive::regex_search( firstLine, what, rex )  ) return it->second;
    }
    return "";
}

static string guessFileType( const string& suffix, const char *code)
{
    string lcSuffix = StringTools::change_case(suffix);
    if (dataDir.assocByExtension.count(lcSuffix)) {
        return dataDir.assocByExtension[lcSuffix];
    }

    string shebang = analyzeFile(code);
    if (!shebang.empty()) {
        return shebang;
    }

    return lcSuffix;
}

char *highlight_format_string2(const char *code, const char *language, int *exit_code, int export_fragment = 1) {
    string outDirectory;

    bool initError=false, IOError=false;
    unsigned int numBadFormatting=0;

    if (!generator) {
        if (highlight_init_generator() != EXIT_SUCCESS) {
            *exit_code = EXIT_FAILURE;
            return nullptr;
        }
    }

    generator->setFragmentCode ( export_fragment );
    generator->setHTMLEnclosePreTag ( !export_fragment );
    generator->setPreformatting ( highlight::WRAP_DISABLED,
                                  ( generator->getPrintLineNumbers() ) ?
                                  80 - 5 : 80,
                                  0 );

    vector<string> badFormattedFiles, badInputFiles, badOutputFiles;
    std::set<string> usedFileNames;
    string outFilePath;
    outFilePath = "";

    string suffix = language;
    // convert string to lower case
    std::for_each(suffix.begin(), suffix.end(), [](char & c){
        c = ::tolower(c);
    });
    
    if (suffix.front() == '{' && suffix.back() == '}') {
        // remove r-markdown curly braces
        std::size_t found1 = suffix.find_first_of(','); // arguments separator
        std::size_t found2 = suffix.find_first_of(' ');
        std::size_t found = min(found1, found2);
        if (found != std::string::npos) {
            suffix = suffix.substr(1, found - 1);
        } else {
            suffix.pop_back();
            suffix.erase(0, 1);
        }
    }
    
    if (suffix == "c++") {
        suffix = "cpp";
    } else if (suffix == "ascr" || suffix == "scpt") {
        suffix = "applescript";
    } else if (suffix == "plist" ) {
        suffix = "xml";
    } else if (suffix == "m" ) {
        suffix = "objc";
    } else if (suffix == "javascript" ) {
        suffix = "js";
    }
    generator->setFilesCnt(1);

    string getFallbackSyntax = "txt";

    suffix = guessFileType( suffix, code );

    if ( suffix != lastSuffix || suffix.empty() ) {
        string langDefPath= dataDir.getLangPath ( suffix+".lang" );

        if (!Platform::fileExists(langDefPath) && !getFallbackSyntax.empty()) {
            langDefPath = dataDir.getLangPath ( getFallbackSyntax+".lang" );
        }

        highlight::LoadResult loadRes= generator->loadLanguage( langDefPath );

        if ( loadRes==highlight::LOAD_FAILED_REGEX ) {
            os_log_error(sLog, "Regex error (%{public}s) in %{public}s.lang", generator->getSyntaxRegexError().c_str(), suffix.c_str());
            /*
            cerr << "highlight: Regex error ( "
                 << generator->getSyntaxRegexError()
                 << " ) in "<<suffix<<".lang\n";
            initError = true;
             */
            *exit_code = EXIT_FAILURE;
            return nullptr;
        } else if ( loadRes==highlight::LOAD_FAILED_LUA ) {
            os_log_error(sLog, "Lua error (%{public}s) in %{public}s.lang", generator->getSyntaxLuaError().c_str(), suffix.c_str());
            /*
            cerr << "highlight: Lua error ( "
                 << generator->getSyntaxLuaError()
                 << " ) in "<<suffix<<".lang\n";
            initError = true;
             */
            *exit_code = EXIT_FAILURE;
            return nullptr;
        } else if ( loadRes==highlight::LOAD_FAILED ) {
            // do also ignore error msg if --syntax parameter should be skipped
            //if ( ! (options.forceOutput() || options.quietMode() || options.isSkippedExt ( suffix )) ) {
            os_log_error(sLog, "Unknown source file extension %{public}s", suffix.c_str());
            /*
            cerr << "highlight: Unknown source file extension \""
                 << suffix
                 << "\". Consider the --force or --syntax"
                 << " option.\n";
             */
            //}
            //if ( !options.forceOutput() ) {
            //initError = true;
            *exit_code = EXIT_FAILURE;
            return nullptr;
            //}
        }

        string encoding= "UTF-8";

        //syntax definition setting:
        string encodingHint= generator->getSyntaxEncodingHint();
        if (!encodingHint.empty()) {
            encoding = encodingHint;
        }

        // filetypes.conf setting has higher priority:
        encodingHint= dataDir.getEncodingHint(suffix);
        if (!encodingHint.empty()) {
            encoding = encodingHint;
        }
        generator->setEncoding (encoding);
    }

    generator->setTitle ( "filename" );
    generator->setKeyWordCase ( StringTools::CASE_UNCHANGED );

    string result = generator->generateString ( code );

    if ( formattingEnabled && !generator->formattingIsPossible() ) {
        if ( numBadFormatting++ < IO_ERROR_REPORT_LENGTH ) {
            badFormattedFiles.push_back ( outFilePath );
        }
    }

    if ( numBadFormatting ) {
        // printIOErrorReport ( numBadFormatting, badFormattedFiles, "reformat", "<stdout>" );
    }

    vector<string> posTestErrors = generator->getPosTestErrors();
    if (!posTestErrors.empty()){
        IOError = true;
        // printIOErrorReport ( posTestErrors.size(), posTestErrors, "validate", "<stdin>" );
    }

    //generator->loadLanguage ( "/usr/local/share/highlight/langDefs/c.lang" );       //EDIT language definition
    //generator->setFragmentCode(1);  // -f
    //generator->disableTrailingNL(1);

    // printf("%s\n", generator->generateString("#include <ciao.h>").c_str());

    // printf("%s\n", result.c_str());
    *exit_code = ( initError || IOError ) ? EXIT_FAILURE : EXIT_SUCCESS;
    return strdup(result.c_str());
}

int highlight_list_themes( void *context, ResultThemeListCallback callback) {
    int count;
    ReleaseThemeInfoList release;
    HThemeInfo **themes;
    int exit_code = highlight_list_themes2(&themes, &count, &release);
    callback(context, (const HThemeInfo **)themes, count, exit_code);

    release(themes, count);

    return exit_code;
}

static HThemeInfo *allocate_theme_info() {
    auto *theme_info = (HThemeInfo *)calloc(1, sizeof(HThemeInfo));
    theme_info->name = nullptr;
    theme_info->desc = nullptr;
    theme_info->path = nullptr;
    return theme_info;
}

static void release_theme_info(HThemeInfo *theme_info) {
    free(theme_info->name);
    theme_info->name = nullptr;
    free(theme_info->desc);
    theme_info->desc = nullptr;
    free(theme_info->path);
    theme_info->path = nullptr;

    free(theme_info);
}

static void release_theme_info_list(HThemeInfo **themes, int count) {
    int n;
    for (n = 0; n < count; n++) {
        release_theme_info(themes[n]);
    }
    free(themes);
}

int highlight_list_themes2(HThemeInfo ***theme_list, int *count, ReleaseThemeInfoList *release) {
    *theme_list = nullptr;
    *count = 0;
    *release = release_theme_info_list;

    string base_path16 = dataDir.getThemePath("", true);
    string where = dataDir.getThemePath("");
    string wildcard = "*.theme";
    vector <string> filePaths;
    string searchDir = where + wildcard;

    bool directoryOK = Platform::getDirectoryEntries ( filePaths, searchDir, true );
    if ( !directoryOK ) {
        os_log_error(sLog, "Could not access directory %{public}s.", searchDir.c_str());
        return EXIT_FAILURE;
    }

    sort ( filePaths.begin(), filePaths.end() );
    string suffix, desc;
    Diluculum::LuaValueMap categoryMap;

    std::set<string> categoryNames;

    istringstream valueStream;

    *count = filePaths.size();
    auto **themes = (HThemeInfo **)calloc(*count, sizeof(HThemeInfo *));
    int j = 0;

    for (const auto& filePath : filePaths) {
        HThemeInfo *theme;
        try {
            theme = allocate_theme_info();
            
            Diluculum::LuaState ls;
            highlight::SyntaxReader::initLuaState(ls, filePath, "");
            ls.doFile(filePath);
            desc = ls["Description"].value().asString();

            if (ls["Categories"].value() !=Diluculum::Nil) {
                categoryMap = ls["Categories"].value().asTable();
                for(Diluculum::LuaValueMap::const_iterator it = categoryMap.begin(); it != categoryMap.end(); ++it)
                {
                    string category = it->second.asString();
                    if (category == "light") {
                        theme->appearance = 1;
                    } else if (category == "dark") {
                        theme->appearance = 2;
                    }
                }
            }

            suffix = (filePath).substr ( where.length() ) ;
            suffix = suffix.substr ( 1, suffix.length()- wildcard.length() );

            theme->name = strdup(suffix.c_str());
            theme->desc = strdup(desc.c_str());
            theme->path = strdup(filePath.c_str());
            theme->base16 = filePath.rfind(base_path16, 0) == 0 ? 1 : 0;

            themes[j] = theme;
            j++;
        } catch (std::runtime_error &error) {
            os_log_error(sLog, "Failed to read '%{public}s': %{public}s", filePath.c_str(), error.what());
            release_theme_info(theme);
        }
    }

    *theme_list = themes;
    *count = j;

    return EXIT_SUCCESS;
}

static HThemeProperty *parse_theme_property(Diluculum::LuaValueMap lua) {
    auto *property = (HThemeProperty *)calloc(1, sizeof(HThemeProperty));
    Diluculum::LuaValue value;
    value = lua["Colour"];
    if (value != Diluculum::Nil) {
        property->color = strdup(value.asString().c_str());
    }

    value = lua["Bold"];
    if (value != Diluculum::Nil) {
        property->bold = value.asBoolean();
    } else {
        property->bold = -1;
    }

    value = lua["Italic"];
    if (value != Diluculum::Nil) {
        property->italic = value.asBoolean();
    } else {
        property->italic = -1;
    }

    value = lua["Underline"];
    if (value != Diluculum::Nil) {
        property->underline = value.asBoolean();
    } else {
        property->underline = -1;
    }

    return property;
}

static void release_theme_property(HThemeProperty *property) {
    if (property == nullptr) {
        return;
    }
    free(property->color);
    property->color = nullptr;
    free(property);
}

/**
 * Allocate an empty theme.
 * @return
 */
static HTheme *allocate_theme() {
    auto *theme = (HTheme *)calloc(1, sizeof(HTheme));
    theme->name = nullptr;
    theme->desc = nullptr;
    theme->path = nullptr;

    theme->appearance = HThemeAppearance::not_set;
    theme->standalone = 0;
    theme->base16 = 0;

    theme->plain = nullptr;
    theme->canvas = nullptr;
    theme->number = nullptr;
    theme->string = nullptr;
    theme->escape = nullptr;
    theme->preProcessor = nullptr;
    theme->stringPreProc = nullptr;
    theme->blockComment = nullptr;
    theme->lineComment = nullptr;
    theme->lineNum = nullptr;
    theme->operatorProp = nullptr;
    theme->interpolation = nullptr;

    theme->keywords = nullptr;
    theme->keyword_count = 0;
    return theme;
}

/**
 * Release a theme.
 * @param theme
 */
static void release_theme(HTheme *theme) {
    if (theme == nullptr) {
        return;
    }
    free(theme->name);
    theme->name = nullptr;
    free(theme->desc);
    theme->desc = nullptr;
    free(theme->path);
    theme->path = nullptr;

    release_theme_property(theme->plain);
    theme->plain = nullptr;
    release_theme_property(theme->canvas);
    theme->canvas = nullptr;
    release_theme_property(theme->number);
    theme->number = nullptr;
    release_theme_property(theme->string);
    theme->string = nullptr;
    release_theme_property(theme->escape);
    theme->escape = nullptr;
    release_theme_property(theme->preProcessor);
    theme->preProcessor = nullptr;
    release_theme_property(theme->stringPreProc);
    theme->stringPreProc = nullptr;
    release_theme_property(theme->blockComment);
    theme->blockComment = nullptr;
    release_theme_property(theme->lineComment);
    theme->lineComment = nullptr;
    release_theme_property(theme->lineNum);
    theme->lineNum = nullptr;
    release_theme_property(theme->operatorProp);
    theme->operatorProp = nullptr;
    release_theme_property(theme->interpolation);
    theme->interpolation = nullptr;

    int i;
    for (i=0; i<theme->keyword_count; i++) {
        release_theme_property(theme->keywords[i]);
        theme->keywords[i] = nullptr;
    }
    free(theme->keywords);
    theme->keywords = nullptr;
    theme->keyword_count = 0;

    free(theme);
}

int highlight_get_theme( const char *theme_name, void *context, ResultThemeCallback callback) {
    int exit_code = 0;
    ReleaseTheme release = nullptr;
    HTheme *theme = highlight_get_theme2(theme_name, &exit_code, &release);
    callback(context, theme, exit_code);

    (*release)(theme);
    return exit_code;
}

HTheme *highlight_get_theme2( const char *theme_name, int *exit_code, ReleaseTheme *release) {
    *release = release_theme;

    string themeFile;
    if (Platform::fileExists(theme_name)) {
        themeFile = std::__fs::filesystem::canonical(theme_name);
    } else {
        string full_theme_name = theme_name;
        if (!endsWith(full_theme_name, ".theme")) {
            full_theme_name += ".theme";
        }

        full_theme_name = dataDir.getThemePath( full_theme_name, false );
        if (Platform::fileExists(full_theme_name)) {
            themeFile = std::__fs::filesystem::canonical(full_theme_name);
        } else {
            *exit_code = EXIT_FAILURE;
            return nullptr;
        }
    }

    //string themesDir = dataDir.getThemePath("");
    //string themeFile = themesDir + theme_name + ".theme";

    string name = themeFile;

    // Remove directory if present.
    string::size_type Pos = name.find_last_of( Platform::pathSeparator );
    if ( Pos != string::npos ) {
        name.erase(0, Pos + 1);
    }
    // Remove extension if present.
    const size_t period_idx = name.rfind('.');
    if (string::npos != period_idx)
    {
        name.erase(period_idx);
    }

    Diluculum::LuaState ls;
    highlight::SyntaxReader::initLuaState(ls, themeFile, "");
    try {
        ls.doFile(themeFile);
    } catch(std::runtime_error &error) {
        os_log_error(sLog, "Unable to parse lua file '%{public}s: %{public}s.'", themeFile.c_str(), error.what());
        *exit_code = EXIT_FAILURE;
        return nullptr;
    }
    HTheme *theme = allocate_theme();

    Diluculum::LuaValue prop;

    prop = ls["Name"].value();
    if (prop != Diluculum::Nil) {
        theme->name = strdup(prop.asString().c_str());
    } else {
        theme->name = strdup(name.c_str());
    }
    prop = ls["Description"].value();
    if (prop != Diluculum::Nil) {
        theme->desc = strdup(prop.asString().c_str());
    }
    theme->path = strdup(themeFile.c_str());

    string base_path = dataDir.getThemePath("", false);
    theme->standalone = themeFile.rfind(base_path, 0) == 0 ? 1 : 0;
    string base_path16 = dataDir.getThemePath("", true);
    theme->base16 = themeFile.rfind(base_path16, 0) == 0 ? 1 : 0;

    prop = ls["Categories"].value();
    if (prop != Diluculum::Nil) {
        Diluculum::LuaValueMap categoryMap;
        categoryMap = prop.asTable();
        for (Diluculum::LuaValueMap::const_iterator it = categoryMap.begin(); it != categoryMap.end(); ++it)
        {
            string category = it->second.asString();
            if (category == "light") {
                theme->appearance = HThemeAppearance::light;
            } else if (category == "dark") {
                theme->appearance = HThemeAppearance::dark;
            }
        }
    }

    prop = ls["Default"].value();
    if (prop != Diluculum::Nil) {
        theme->plain = parse_theme_property(prop.asTable());
    }
    prop = ls["Canvas"].value();
    if (prop != Diluculum::Nil) {
        theme->canvas = parse_theme_property(prop.asTable());
    }
    prop = ls["Number"].value();
    if (prop != Diluculum::Nil) {
        theme->number = parse_theme_property(prop.asTable());
    }
    prop = ls["String"].value();
    if (prop != Diluculum::Nil) {
        theme->string = parse_theme_property(prop.asTable());
    }
    prop = ls["Escape"].value();
    if (prop != Diluculum::Nil) {
        theme->escape = parse_theme_property(prop.asTable());
    }
    prop = ls["PreProcessor"].value();
    if (prop != Diluculum::Nil) {
        theme->preProcessor = parse_theme_property(prop.asTable());
    }
    prop = ls["StringPreProc"].value();
    if (prop != Diluculum::Nil) {
        theme->stringPreProc = parse_theme_property(prop.asTable());
    }
    prop = ls["BlockComment"].value();
    if (prop != Diluculum::Nil) {
        theme->blockComment = parse_theme_property(prop.asTable());
    }
    prop = ls["LineComment"].value();
    if (prop != Diluculum::Nil) {
        theme->lineComment = parse_theme_property(prop.asTable());
    }
    prop = ls["LineNum"].value();
    if (prop != Diluculum::Nil) {
        theme->lineNum = parse_theme_property(prop.asTable());
    }
    prop = ls["Operator"].value();
    if (prop != Diluculum::Nil) {
        theme->operatorProp = parse_theme_property(prop.asTable());
    }
    prop = ls["Interpolation"].value();
    if (prop != Diluculum::Nil) {
        theme->interpolation = parse_theme_property(prop.asTable());
    }

    prop = ls["Keywords"].value();
    if (prop != Diluculum::Nil){
        Diluculum::LuaValueMap keywordsMap;
        keywordsMap = prop.asTable();

        int i = 0;
        for (Diluculum::LuaValueMap::const_iterator it = keywordsMap.begin(); it != keywordsMap.end(); ++it)
        {
            i++;
        }

        theme->keywords = (HThemeProperty **)calloc(i, sizeof(HThemeProperty *));
        theme->keyword_count = i;

        i = 0;
        for (Diluculum::LuaValueMap::const_iterator it = keywordsMap.begin(); it != keywordsMap.end(); ++it)
        {
            Diluculum::LuaValueMap t;
            t = it->second.asTable();
            // printf("->%s\n", t["Colour"].asString().c_str());
            theme->keywords[i] = parse_theme_property(t);
            i++;
        }
    }

    *exit_code = EXIT_SUCCESS;
    return theme;
}

/**
 * Save a theme property to file.
 * @param file
 * @param name Name of the property.
 * @param property
 * @return
 */
static int save_theme_property(ofstream &file, const char *name, HThemeProperty *property) {
    if (property == nullptr) {
        return 0;
    }
    if (name != nullptr) {
        file << name
             << "\t=";
    }
    file << "\t{ ";
    int i = 0;
    if (property->color) {
        file << "Colour=\""
             << property->color
             << "\"";
        i++;
    }
    if (property->bold >= 0) {
        file << (i > 0 ? ", " : "")
             << "Bold="
             << (property->bold ? "true" : "false");
    }
    if (property->italic >= 0) {
        file << (i > 0 ? ", " : "")
             << "Italic="
             << (property->italic ? "true" : "false");
    }
    if (property->underline >= 0) {
        file << (i > 0 ? ", " : "")
             << "Underline="
             << (property->underline ? "true" : "false");
    }
    file << " }";
    if (name != nullptr) {
        file << "\n";
    }
    return 1;
}

int highlight_save_theme( const char *filename, const HTheme *theme) {
    ofstream file;
    file.open(filename, ios::out);
    if (!file.is_open()) {
        return EXIT_FAILURE;
    }

    file << "Description\t=\t\""
         << theme->desc
         << "\"\n";
    file << "Categories\t=\t{"
         << (theme->appearance > 0 ? (theme->appearance == 1 ? "\"light\"" : "\"dark\"") : "")
         << "}\n\n";
    save_theme_property(file, "Default", theme->plain);
    save_theme_property(file, "Canvas", theme->canvas);
    save_theme_property(file, "Number", theme->number);
    save_theme_property(file, "String", theme->string);
    save_theme_property(file, "Escape", theme->escape);
    save_theme_property(file, "PreProcessor", theme->preProcessor);
    save_theme_property(file, "StringPreProc", theme->stringPreProc);
    save_theme_property(file, "BlockComment", theme->blockComment);
    save_theme_property(file, "LineComment", theme->lineComment);
    save_theme_property(file, "LineNum", theme->lineNum);
    save_theme_property(file, "Operator", theme->operatorProp);
    save_theme_property(file, "Interpolation", theme->interpolation);

    file << "\n";

    file << "Keywords = {\n";
    int i;
    for (i = 0; i < theme->keyword_count; i++) {
        if (save_theme_property(file, nullptr, theme->keywords[i]) > 0) {
            if (i+1 < theme->keyword_count) {
                file << ",";
            }
            file << "\n";
        }
    }
    file << "}\n\n";
    file.close();

    return EXIT_SUCCESS;
}


char *highlight_get_current_font(void) {
    return generator ? strdup(generator->getBaseFont().c_str()) : nullptr;
}
void highlight_set_current_font(const char *font, const char *font_size) {
    if (generator != nullptr) {
        generator->setBaseFont(font);
        if (font_size != nullptr) {
            highlight_set_current_font_size(font_size);
        }
    }
}

char *highlight_get_current_font_size(void) {
    return generator ? strdup(generator->getBaseFontSize().c_str()) : nullptr;
}
void highlight_set_current_font_size(const char *font_size) {
    generator->setBaseFontSize(font_size);
}

int highlight_get_print_line_numbers(void) {
    return generator ? generator->getPrintLineNumbers() : 0;
}
void highlight_set_print_line_numbers(int state) {
    if (generator) {
        generator->setPrintLineNumbers(state > 0, 1);
    }
}

void highlight_set_formatting_mode(int wrap_at_characters, int tab_replace_spaces) {
    if (!generator) {
        return;
    }
    generator->setPreformatting ( wrap_at_characters > 0 ? highlight::WRAP_SIMPLE : highlight::WRAP_DISABLED,
                                  ( generator->getPrintLineNumbers() ) ?
                                  wrap_at_characters - 5 : wrap_at_characters,
                                  tab_replace_spaces );
}

char *magic_guess_language(const char *buffer, const char *magic_database) {
    magic_t cookie = magic_open(MAGIC_NONE);
    if (cookie == nullptr) {
        os_log_error(sLog, "libmagic: %{public}s", magic_error(cookie));
        return nullptr;
    }

    const char *magic = nullptr;
    string lang = "-";

    if (magic_load(cookie, magic_database) != 0) {
        os_log_error(sLog, "libmagic: %{public}s", magic_error(cookie));
        goto exit_func;
    }

    magic = magic_buffer(cookie, buffer, strlen(buffer));
    if (magic == nullptr) {
        os_log_error(sLog, "libmagic: %{public}s", magic_error(cookie));
        goto exit_func;
    }

    lang = magic;
    if (lang.find("Algol") != std::string::npos) {
        lang = "algol";
    } else if (lang.find("assembler source") != std::string::npos) {
        lang = "assembler";
    } else if (lang.find("C source") != std::string::npos) {
        lang = "c";
    } else if (lang.find("C++ source") != std::string::npos) {
        lang = "cpp";
    } else if (lang.find("Objective-C source") != std::string::npos) {
        lang = "objc";
    } else if (lang.find("Clojure") != std::string::npos) {
        lang = "clojure";
    } else if (lang.find("fish shell script") != std::string::npos) {
        lang = "fish";
    } else if (lang.find("shell script") != std::string::npos || lang.find("ash script") != std::string::npos) {
        lang = "sh";
    } else if (lang.find("zsh script") != std::string::npos) {
        lang = "zsh";
    } else if (lang.find("awk script") != std::string::npos) {
        lang = "awk";
    } else if (lang.find("perl script") != std::string::npos) {
        lang = "perl";
    } else if (lang.find("Tcl/Tk script") != std::string::npos || lang.find("Tcl script") != std::string::npos) {
        lang = "tcl";
    } else if (lang.find("PHP script") != std::string::npos) {
        lang = "php";
    } else if (lang.find("diff output") != std::string::npos) {
        lang = "diff";
    } else if (lang.find("Erlang") != std::string::npos) {
        lang = "erlang";
    } else if (lang.find("FORTRAN") != std::string::npos) {
        lang = "fortran";
    } else if (lang.find("Java source") != std::string::npos) {
        lang = "java";
    } else if (lang.find("Node.js script") != std::string::npos || lang.find("JavaScript") != std::string::npos) {
        lang = "js";
    } else if (lang.find("KML") != std::string::npos) {
        lang = "xml";
    } else if (lang.find("Lisp/Scheme") != std::string::npos) {
        lang = "lisp";
    } else if (lang.find("Lua script") != std::string::npos) {
        lang = "lua";
    } else if (lang.find("makefile script") != std::string::npos) {
        lang = "make";
    } else if (lang.find("OCaml") != std::string::npos) {
        lang = "ocaml";
    } else if (lang.find("Pascal source") != std::string::npos) {
        lang = "pas";
    } else if (lang.find("Perl script") != std::string::npos || lang.find("Perl5 module") != std::string::npos || lang.find("Perl POD document") != std::string::npos) {
        lang = "perl";
    } else if (lang.find("Python script") != std::string::npos) {
        lang = "python";
    } else if (lang.find("Ruby script") != std::string::npos) {
        lang = "ruby";
    } else if (lang.find("TeX") != std::string::npos) {
        lang = "tex";
    }
    exit_func:
    magic_close(cookie);

    return lang != "-" ? strdup(lang.c_str()) : nullptr;
}

char *enry_guess_language(const char *buffer) {
    initEnryEngine();

    GoSlice content;
    content.data = (void *)buffer;
    content.len = strlen(buffer);
    content.cap = content.len;
    char *language = nullptr;
    language = guessWithEnry(content);
    return language;
}

char *magic_get_mime_by_file(const char *filename, const char *magic_database) {
    magic_t cookie = magic_open(MAGIC_MIME_TYPE);
    if (cookie == nullptr) {
        os_log_error(sLog, "libmagic: %{public}s", magic_error(cookie));
        return nullptr;
    }

    const char *magic = nullptr;
    string mime = "";

    if (magic_load(cookie, magic_database) != 0) {
        os_log_error(sLog, "libmagic: %{public}s", magic_error(cookie));
        goto exit_func;
    }

    magic = magic_file(cookie, filename);
    if (magic == nullptr) {
        os_log_error(sLog, "libmagic: %{public}s", magic_error(cookie));
        goto exit_func;
    } else {
        mime = magic;
    }

    exit_func:
    magic_close(cookie);

    return mime != "" ? strdup(mime.c_str()) : nullptr;
}
