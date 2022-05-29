# tflint

## Installing TFLint plugins

TFLint has [third party plugins](https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/plugins.md) which are not installed by default.

To install TFLint plugins, there's a convenient `:TFLintInit` command that does this for you. It will use Neovim's
current working directory to locate the plugins to install (according to `tflint --init`):

```
:TFLintInit
```

The `:TFLintInit` command will only be available once the `tflint` server has been set up.
