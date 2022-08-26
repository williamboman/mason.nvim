-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.
-- stylua: ignore start
return {properties = {["powershell.bugReporting.project"] = {default = "https://github.com/PowerShell/vscode-powershell",description = "Specifies the URL of the GitHub project in which to generate bug reports.",type = "string"},["powershell.buttons.showPanelMovementButtons"] = {default = false,description = "Show buttons in the editor title-bar for moving the panel around.",type = "boolean"},["powershell.buttons.showRunButtons"] = {default = true,description = "Show the Run and Run Selection buttons in the editor title-bar.",type = "boolean"},["powershell.codeFolding.enable"] = {default = true,description = "Enables syntax based code folding. When disabled, the default indentation based code folding is used.",type = "boolean"},["powershell.codeFolding.showLastLine"] = {default = true,description = "Shows the last line of a folded section similar to the default VSCode folding style. When disabled, the entire folded region is hidden.",type = "boolean"},["powershell.codeFormatting.addWhitespaceAroundPipe"] = {default = true,description = "Adds a space before and after the pipeline operator ('|') if it is missing.",type = "boolean"},["powershell.codeFormatting.alignPropertyValuePairs"] = {default = true,description = "Align assignment statements in a hashtable or a DSC Configuration.",type = "boolean"},["powershell.codeFormatting.autoCorrectAliases"] = {default = false,description = "Replaces aliases with their aliased name.",type = "boolean"},["powershell.codeFormatting.ignoreOneLineBlock"] = {default = true,description = 'Does not reformat one-line code blocks, such as "if (...) {...} else {...}".',type = "boolean"},["powershell.codeFormatting.newLineAfterCloseBrace"] = {default = true,description = "Adds a newline (line break) after a closing brace.",type = "boolean"},["powershell.codeFormatting.newLineAfterOpenBrace"] = {default = true,description = "Adds a newline (line break) after an open brace.",type = "boolean"},["powershell.codeFormatting.openBraceOnSameLine"] = {default = true,description = "Places open brace on the same line as its associated statement.",type = "boolean"},["powershell.codeFormatting.pipelineIndentationStyle"] = {default = "NoIndentation",description = "Multi-line pipeline style settings (default: NoIndentation).",enum = { "IncreaseIndentationForFirstPipeline", "IncreaseIndentationAfterEveryPipeline", "NoIndentation", "None" },type = "string"},["powershell.codeFormatting.preset"] = {default = "Custom",description = "Sets the codeformatting options to follow the given indent style in a way that is compatible with PowerShell syntax. For more information about the brace styles please refer to https://github.com/PoshCode/PowerShellPracticeAndStyle/issues/81.",enum = { "Custom", "Allman", "OTBS", "Stroustrup" },type = "string"},["powershell.codeFormatting.trimWhitespaceAroundPipe"] = {default = false,description = "Trims extraneous whitespace (more than 1 character) before and after the pipeline operator ('|').",type = "boolean"},["powershell.codeFormatting.useConstantStrings"] = {default = false,description = "Use single quotes if a string is not interpolated and its value does not contain a single quote.",type = "boolean"},["powershell.codeFormatting.useCorrectCasing"] = {default = false,description = "Use correct casing for cmdlets.",type = "boolean"},["powershell.codeFormatting.whitespaceAfterSeparator"] = {default = true,description = "Adds a space after a separator (',' and ';').",type = "boolean"},["powershell.codeFormatting.whitespaceAroundOperator"] = {default = true,description = "Adds spaces before and after an operator ('=', '+', '-', etc.).",type = "boolean"},["powershell.codeFormatting.whitespaceAroundPipe"] = {default = true,deprecationMessage = "Please use the \"powershell.codeFormatting.addWhitespaceAroundPipe\" setting instead. If you've used this setting before, we have moved it for you automatically.",description = "REMOVED. Please use the \"powershell.codeFormatting.addWhitespaceAroundPipe\" setting instead. If you've used this setting before, we have moved it for you automatically.",type = "boolean"},["powershell.codeFormatting.whitespaceBeforeOpenBrace"] = {default = true,description = "Adds a space between a keyword and its associated scriptblock expression.",type = "boolean"},["powershell.codeFormatting.whitespaceBeforeOpenParen"] = {default = true,description = "Adds a space between a keyword (if, elseif, while, switch, etc) and its associated conditional expression.",type = "boolean"},["powershell.codeFormatting.whitespaceBetweenParameters"] = {default = false,description = "Removes redundant whitespace between parameters.",type = "boolean"},["powershell.codeFormatting.whitespaceInsideBrace"] = {default = true,description = "Adds a space after an opening brace ('{') and before a closing brace ('}').",type = "boolean"},["powershell.cwd"] = {default = vim.NIL,description = "An explicit start path where the PowerShell Extension Terminal will be launched. Both the PowerShell process and the shell's location will be set to this directory. Predefined variables can be used (i.e. ${fileDirname} to use the current opened file's directory).",type = "string"},["powershell.debugging.createTemporaryIntegratedConsole"] = {default = false,description = "Determines whether a temporary PowerShell Extension Terminal is created for each debugging session. Useful for debugging PowerShell classes and binary modules.",type = "boolean"},["powershell.developer.bundledModulesPath"] = {description = "Specifies an alternate path to the folder containing modules that are bundled with the PowerShell extension (i.e. PowerShell Editor Services, PSScriptAnalyzer, Plaster)",type = "string"},["powershell.developer.editorServicesLogLevel"] = {default = "Normal",description = "Sets the logging verbosity level for the PowerShell Editor Services host executable.  Valid values are 'Diagnostic', 'Verbose', 'Normal', 'Warning', 'Error', and 'None'",enum = { "Diagnostic", "Verbose", "Normal", "Warning", "Error", "None" },type = "string"},["powershell.developer.editorServicesWaitForDebugger"] = {default = false,description = "Launches the language service with the /waitForDebugger flag to force it to wait for a .NET debugger to attach before proceeding.",type = "boolean"},["powershell.developer.featureFlags"] = {default = {},description = "An array of strings that enable experimental features in the PowerShell extension.",items = {type = "string"},type = "array"},["powershell.developer.waitForSessionFileTimeoutSeconds"] = {default = 240,description = "When the PowerShell extension is starting up, it checks for a session file in order to connect to the language server. This setting determines how long until checking for the session file times out. (default is 240 seconds or 4 minutes)",type = "number"},["powershell.enableProfileLoading"] = {default = true,description = "Loads user and system-wide PowerShell profiles (profile.ps1 and Microsoft.VSCode_profile.ps1) into the PowerShell session. This affects IntelliSense and interactive script execution, but it does not affect the debugger.",type = "boolean"},["powershell.helpCompletion"] = {default = "BlockComment",description = "Controls the comment-based help completion behavior triggered by typing '##'. Set the generated help style with 'BlockComment' or 'LineComment'. Disable the feature with 'Disabled'.",enum = { "Disabled", "BlockComment", "LineComment" },type = "string"},["powershell.integratedConsole.focusConsoleOnExecute"] = {default = true,description = "Switches focus to the console when a script selection is run or a script file is debugged. This is an accessibility feature. To disable it, set to false.",type = "boolean"},["powershell.integratedConsole.forceClearScrollbackBuffer"] = {description = "Use the vscode API to clear the terminal since that's the only reliable way to clear the scrollback buffer. Turn this on if you're used to 'Clear-Host' clearing scroll history as well as clear-terminal-via-lsp.",type = "boolean"},["powershell.integratedConsole.showOnStartup"] = {default = true,description = "Shows the Extension Terminal when the PowerShell extension is initialized. When disabled, the pane is not opened on startup, but the Extension Terminal is still created in order to power the extension's features.",type = "boolean"},["powershell.integratedConsole.startInBackground"] = {default = false,description = "Starts the Extension Terminal in the background. WARNING: If this is enabled, to access the terminal you must run the 'Show Extension Terminal' command, and once shown it cannot be put back into the background. This option completely hides the Extension Terminal from the terminals pane. You are probably looking for the 'showOnStartup' option instead.",type = "boolean"},["powershell.integratedConsole.suppressStartupBanner"] = {default = false,description = "Do not show the Powershell Extension Terminal banner on launch",type = "boolean"},["powershell.integratedConsole.useLegacyReadLine"] = {default = false,description = "Falls back to the legacy ReadLine experience. This will disable the use of PSReadLine in the PowerShell Extension Terminal.",type = "boolean"},["powershell.pester.codeLens"] = {default = true,description = "This setting controls the appearance of the 'Run Tests' and 'Debug Tests' CodeLenses that appears above Pester tests.",type = "boolean"},["powershell.pester.debugOutputVerbosity"] = {default = "Diagnostic",description = "Defines the verbosity of output to be used when debugging a test or a block. For Pester 5 and newer the default value Diagnostic will print additional information about discovery, skipped and filtered tests, mocking and more.",enum = { "None", "Minimal", "Normal", "Detailed", "Diagnostic" },type = "string"},["powershell.pester.outputVerbosity"] = {default = "FromPreference",description = "Defines the verbosity of output to be used. For Pester 5 and newer the default value FromPreference, will use the Output settings from the $PesterPreference defined in the caller context, and will default to Normal if there is none. For Pester 4 the FromPreference and Normal options map to All, and Minimal option maps to Fails.",enum = { "FromPreference", "None", "Minimal", "Normal", "Detailed", "Diagnostic" },type = "string"},["powershell.pester.useLegacyCodeLens"] = {default = true,description = "Use a CodeLens that is compatible with Pester 4. Disabling this will show 'Run Tests' on all It, Describe and Context blocks, and will correctly work only with Pester 5 and newer.",type = "boolean"},["powershell.powerShellAdditionalExePaths"] = {additionalProperties = {type = "string"},description = "Specifies a list of versionName / exePath pairs where exePath points to a non-standard install location for PowerShell and versionName can be used to reference this path with the powershell.powerShellDefaultVersion setting.",type = "object"},["powershell.powerShellDefaultVersion"] = {description = "Specifies the PowerShell version name, as displayed by the 'PowerShell: Show Session Menu' command, used when the extension loads e.g \"Windows PowerShell (x86)\" or \"PowerShell Core 7 (x64)\". You can specify additional PowerShell executables by using the \"powershell.powerShellAdditionalExePaths\" setting.",type = "string"},["powershell.powerShellExePath"] = {default = "",deprecationMessage = 'Please use the "powershell.powerShellAdditionalExePaths" setting instead.',description = 'REMOVED: Please use the "powershell.powerShellAdditionalExePaths" setting instead.',scope = "machine",type = "string"},["powershell.promptToUpdatePackageManagement"] = {default = false,deprecationMessage = "This prompt has been removed as it's no longer strictly necessary to upgrade the PackageManagement module.",description = "REMOVED: Specifies whether you should be prompted to update your version of PackageManagement if it's under 1.4.6.",type = "boolean"},["powershell.promptToUpdatePowerShell"] = {default = true,description = "Specifies whether you should be prompted to update your version of PowerShell.",type = "boolean"},["powershell.scriptAnalysis.enable"] = {default = true,description = "Enables real-time script analysis from PowerShell Script Analyzer. Uses the newest installed version of the PSScriptAnalyzer module or the version bundled with this extension, if it is newer.",type = "boolean"},["powershell.scriptAnalysis.settingsPath"] = {default = "PSScriptAnalyzerSettings.psd1",description = "Specifies the path to a PowerShell Script Analyzer settings file. To override the default settings for all projects, enter an absolute path, or enter a path relative to your workspace.",type = "string"},["powershell.sideBar.CommandExplorerExcludeFilter"] = {default = {},description = "Specify array of Modules to exclude from Command Explorer listing.",items = {type = "string"},type = "array"},["powershell.sideBar.CommandExplorerVisibility"] = {default = true,description = "Specifies the visibility of the Command Explorer in the PowerShell Side Bar.",type = "boolean"},["powershell.startAsLoginShell.linux"] = {default = false,description = "Starts the PowerShell extension's underlying PowerShell process as a login shell, if applicable.",type = "boolean"},["powershell.startAsLoginShell.osx"] = {default = true,description = "Starts the PowerShell extension's underlying PowerShell process as a login shell, if applicable.",type = "boolean"},["powershell.startAutomatically"] = {default = true,description = "Starts PowerShell extension features automatically when a PowerShell file opens. If false, to start the extension, use the 'PowerShell: Restart Current Session' command. IntelliSense, code navigation, Extension Terminal, code formatting, and other features are not enabled until the extension starts.",type = "boolean"},["powershell.useX86Host"] = {default = false,deprecationMessage = 'This setting was removed when the PowerShell installation searcher was added. Please use the "powershell.powerShellAdditionalExePaths" setting instead.',description = "REMOVED: Uses the 32-bit language service on 64-bit Windows. This setting has no effect on 32-bit Windows or on the PowerShell extension debugger, which has its own architecture configuration.",type = "boolean"}},title = "PowerShell",type = "object"}