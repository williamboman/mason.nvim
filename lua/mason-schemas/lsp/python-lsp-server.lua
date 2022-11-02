-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.
-- stylua: ignore start
return {["$schema"] = "http://json-schema.org/draft-07/schema#",description = "This server can be configured using the `workspace/didChangeConfiguration` method. Each configuration option is described below. Note, a value of `null` means that we do not set a value and thus use the plugin's default value.",properties = {["pylsp.configurationSources"] = {default = { "pycodestyle" },description = "List of configuration sources to use.",items = {enum = { "pycodestyle", "flake8" },type = "string"},type = "array",uniqueItems = true},["pylsp.plugins.autopep8.enabled"] = {default = true,description = "Enable or disable the plugin (disabling required to use `yapf`).",type = "boolean"},["pylsp.plugins.flake8.config"] = {default = vim.NIL,description = "Path to the config file that will be the authoritative config source.",type = { "string", "null" }},["pylsp.plugins.flake8.enabled"] = {default = false,description = "Enable or disable the plugin.",type = "boolean"},["pylsp.plugins.flake8.exclude"] = {default = {},description = "List of files or directories to exclude.",items = {type = "string"},type = "array"},["pylsp.plugins.flake8.executable"] = {default = "flake8",description = "Path to the flake8 executable.",type = "string"},["pylsp.plugins.flake8.filename"] = {default = vim.NIL,description = "Only check for filenames matching the patterns in this list.",type = { "string", "null" }},["pylsp.plugins.flake8.hangClosing"] = {default = vim.NIL,description = "Hang closing bracket instead of matching indentation of opening bracket's line.",type = { "boolean", "null" }},["pylsp.plugins.flake8.ignore"] = {default = {},description = "List of errors and warnings to ignore (or skip).",items = {type = "string"},type = "array"},["pylsp.plugins.flake8.indentSize"] = {default = vim.NIL,description = "Set indentation spaces.",type = { "integer", "null" }},["pylsp.plugins.flake8.maxLineLength"] = {default = vim.NIL,description = "Maximum allowed line length for the entirety of this run.",type = { "integer", "null" }},["pylsp.plugins.flake8.perFileIgnores"] = {default = {},description = 'A pairing of filenames and violation codes that defines which violations to ignore in a particular file, for example: `["file_path.py:W305,W304"]`).',items = {type = "string"},type = { "array" }},["pylsp.plugins.flake8.select"] = {default = vim.NIL,description = "List of errors and warnings to enable.",items = {type = "string"},type = { "array", "null" },uniqueItems = true},["pylsp.plugins.jedi.auto_import_modules"] = {default = { "numpy" },description = "List of module names for jedi.settings.auto_import_modules.",items = {type = "string"},type = "array"},["pylsp.plugins.jedi.env_vars"] = {default = vim.NIL,description = "Define environment variables for jedi.Script and Jedi.names.",type = { "object", "null" }},["pylsp.plugins.jedi.environment"] = {default = vim.NIL,description = "Define environment for jedi.Script and Jedi.names.",type = { "string", "null" }},["pylsp.plugins.jedi.extra_paths"] = {default = {},description = "Define extra paths for jedi.Script.",items = {type = "string"},type = "array"},["pylsp.plugins.jedi_completion.cache_for"] = {default = { "pandas", "numpy", "tensorflow", "matplotlib" },description = "Modules for which labels and snippets should be cached.",items = {type = "string"},type = "array"},["pylsp.plugins.jedi_completion.eager"] = {default = false,description = "Resolve documentation and detail eagerly.",type = "boolean"},["pylsp.plugins.jedi_completion.enabled"] = {default = true,description = "Enable or disable the plugin.",type = "boolean"},["pylsp.plugins.jedi_completion.fuzzy"] = {default = false,description = "Enable fuzzy when requesting autocomplete.",type = "boolean"},["pylsp.plugins.jedi_completion.include_class_objects"] = {default = false,description = "Adds class objects as a separate completion item.",type = "boolean"},["pylsp.plugins.jedi_completion.include_function_objects"] = {default = false,description = "Adds function objects as a separate completion item.",type = "boolean"},["pylsp.plugins.jedi_completion.include_params"] = {default = true,description = "Auto-completes methods and classes with tabstops for each parameter.",type = "boolean"},["pylsp.plugins.jedi_completion.resolve_at_most"] = {default = 25,description = "How many labels and snippets (at most) should be resolved?",type = "integer"},["pylsp.plugins.jedi_definition.enabled"] = {default = true,description = "Enable or disable the plugin.",type = "boolean"},["pylsp.plugins.jedi_definition.follow_builtin_imports"] = {default = true,description = "If follow_imports is True will decide if it follow builtin imports.",type = "boolean"},["pylsp.plugins.jedi_definition.follow_imports"] = {default = true,description = "The goto call will follow imports.",type = "boolean"},["pylsp.plugins.jedi_hover.enabled"] = {default = true,description = "Enable or disable the plugin.",type = "boolean"},["pylsp.plugins.jedi_references.enabled"] = {default = true,description = "Enable or disable the plugin.",type = "boolean"},["pylsp.plugins.jedi_signature_help.enabled"] = {default = true,description = "Enable or disable the plugin.",type = "boolean"},["pylsp.plugins.jedi_symbols.all_scopes"] = {default = true,description = "If True lists the names of all scopes instead of only the module namespace.",type = "boolean"},["pylsp.plugins.jedi_symbols.enabled"] = {default = true,description = "Enable or disable the plugin.",type = "boolean"},["pylsp.plugins.jedi_symbols.include_import_symbols"] = {default = true,description = "If True includes symbols imported from other libraries.",type = "boolean"},["pylsp.plugins.mccabe.enabled"] = {default = true,description = "Enable or disable the plugin.",type = "boolean"},["pylsp.plugins.mccabe.threshold"] = {default = 15,description = "The minimum threshold that triggers warnings about cyclomatic complexity.",type = "integer"},["pylsp.plugins.preload.enabled"] = {default = true,description = "Enable or disable the plugin.",type = "boolean"},["pylsp.plugins.preload.modules"] = {default = {},description = "List of modules to import on startup",items = {type = "string"},type = "array",uniqueItems = true},["pylsp.plugins.pycodestyle.enabled"] = {default = true,description = "Enable or disable the plugin.",type = "boolean"},["pylsp.plugins.pycodestyle.exclude"] = {default = {},description = "Exclude files or directories which match these patterns.",items = {type = "string"},type = "array",uniqueItems = true},["pylsp.plugins.pycodestyle.filename"] = {default = {},description = "When parsing directories, only check filenames matching these patterns.",items = {type = "string"},type = "array",uniqueItems = true},["pylsp.plugins.pycodestyle.hangClosing"] = {default = vim.NIL,description = "Hang closing bracket instead of matching indentation of opening bracket's line.",type = { "boolean", "null" }},["pylsp.plugins.pycodestyle.ignore"] = {default = {},description = "Ignore errors and warnings",items = {type = "string"},type = "array",uniqueItems = true},["pylsp.plugins.pycodestyle.indentSize"] = {default = vim.NIL,description = "Set indentation spaces.",type = { "integer", "null" }},["pylsp.plugins.pycodestyle.maxLineLength"] = {default = vim.NIL,description = "Set maximum allowed line length.",type = { "integer", "null" }},["pylsp.plugins.pycodestyle.select"] = {default = vim.NIL,description = "Select errors and warnings",items = {type = "string"},type = { "array", "null" },uniqueItems = true},["pylsp.plugins.pydocstyle.addIgnore"] = {default = {},description = "Ignore errors and warnings in addition to the specified convention.",items = {type = "string"},type = "array",uniqueItems = true},["pylsp.plugins.pydocstyle.addSelect"] = {default = {},description = "Select errors and warnings in addition to the specified convention.",items = {type = "string"},type = "array",uniqueItems = true},["pylsp.plugins.pydocstyle.convention"] = {default = vim.NIL,description = "Choose the basic list of checked errors by specifying an existing convention.",enum = { "pep257", "numpy", vim.NIL },type = { "string", "null" }},["pylsp.plugins.pydocstyle.enabled"] = {default = false,description = "Enable or disable the plugin.",type = "boolean"},["pylsp.plugins.pydocstyle.ignore"] = {default = {},description = "Ignore errors and warnings",items = {type = "string"},type = "array",uniqueItems = true},["pylsp.plugins.pydocstyle.match"] = {default = "(?!test_).*\\.py",description = "Check only files that exactly match the given regular expression; default is to match files that don't start with 'test_' but end with '.py'.",type = "string"},["pylsp.plugins.pydocstyle.matchDir"] = {default = "[^\\.].*",description = "Search only dirs that exactly match the given regular expression; default is to match dirs which do not begin with a dot.",type = "string"},["pylsp.plugins.pydocstyle.select"] = {default = vim.NIL,description = "Select errors and warnings",items = {type = "string"},type = { "array", "null" },uniqueItems = true},["pylsp.plugins.pyflakes.enabled"] = {default = true,description = "Enable or disable the plugin.",type = "boolean"},["pylsp.plugins.pylint.args"] = {default = {},description = "Arguments to pass to pylint.",items = {type = "string"},type = "array",uniqueItems = false},["pylsp.plugins.pylint.enabled"] = {default = false,description = "Enable or disable the plugin.",type = "boolean"},["pylsp.plugins.pylint.executable"] = {default = vim.NIL,description = "Executable to run pylint with. Enabling this will run pylint on unsaved files via stdin. Can slow down workflow. Only works with python3.",type = { "string", "null" }},["pylsp.plugins.rope_completion.eager"] = {default = false,description = "Resolve documentation and detail eagerly.",type = "boolean"},["pylsp.plugins.rope_completion.enabled"] = {default = false,description = "Enable or disable the plugin.",type = "boolean"},["pylsp.plugins.yapf.enabled"] = {default = true,description = "Enable or disable the plugin.",type = "boolean"},["pylsp.rope.extensionModules"] = {default = vim.NIL,description = "Builtin and c-extension modules that are allowed to be imported and inspected by rope.",type = { "string", "null" }},["pylsp.rope.ropeFolder"] = {default = vim.NIL,description = "The name of the folder in which rope stores project configurations and data.  Pass `null` for not using such a folder at all.",items = {type = "string"},type = { "array", "null" },uniqueItems = true}},title = "Python Language Server Configuration",type = "object"}