-   [Contribution policy](#contribution-policy)
-   [Adding a new package](#adding-a-new-package)
    -   [The anatomy of a package](#the-anatomy-of-a-package)
        -   [Package name](#package-name)
        -   [Package homepage](#package-homepage)
        -   [Package categories](#package-categories)
        -   [Package languages](#package-languages)
        -   [Package installer](#package-installer)
-   [Code style](#code-style)
-   [Generated code](#generated-code)
-   [Tests](#tests)
-   [Adding or changing a feature](#adding-or-changing-a-feature)
-   [Commit style](#commit-style)
-   [Pull requests](#pull-requests)

# Contribution policy

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT
RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [BCP 14][bcp14],
[RFC2119][rfc2119], and [RFC8174][rfc8174] when, and only when, they appear in all capitals, as shown here.

[bcp14]: https://tools.ietf.org/html/bcp14
[rfc2119]: https://tools.ietf.org/html/rfc2119
[rfc8174]: https://tools.ietf.org/html/rfc8174

# Adding a new package

Package definitions reside within the `lua/mason-registry` directory. Each package MUST reside in its own directory with
a main entrypoint file `init.lua`. The name of the directory MUST be the same as the package name. The `init.lua` file
MUST return a `Package` (`mason-core.package`) instance.

## The anatomy of a package

Each package consists of a specification ([`PackageSpec`](https://github.com/williamboman/mason.nvim/blob/main/doc/reference.md#packagespec)), describing metadata about
the package as well as its installation instructions. The [`Package`](https://github.com/williamboman/mason.nvim/blob/main/doc/reference.md#package) class encapsulates a
specification and provides utility methods such as `Package:install()` and `Package:check_new_version({callback})`.

### Package name

The name of a package MUST follow the following naming scheme:

1. If the upstream package name is sufficiently unambiguous, or otherwise widely recognized, that name MUST be used
1. If the upstream package provides a single executable with a name that is sufficiently unambiguous, or otherwise
   widely recognized, the name of the executable MUST be used
1. If either the package or executable name is ambiguous, a name where a clarifying prefix or suffix is added SHOULD be
   used
1. As a last resort, the name of the package should be constructed to best convey its target language and scope, e.g.
   `json-lsp` for a JSON language server.

### Package homepage

A package MUST have a homepage associated with it. The homepage SHOULD be a URL to the landing page of a public website.
If no public website exists, the homepage MUST be a URL to the source code of the package (e.g. a GitHub repository).

### Package categories

See: [`Package.Cat`](https://github.com/williamboman/mason.nvim/blob/main/doc/reference.md#packagecat)

A package SHOULD belong to one or more categories. Should no category apply, it is a sign that the package's scope
exceeds that of mason.nvim.

### Package languages

See: [`Package.Lang`](https://github.com/williamboman/mason.nvim/blob/main/doc/reference.md#packagelang)

A package SHOULD belong to one or more languages. There are however situations where no languages apply, in which case
no languages should be applied.

### Package installer

A package installer MUST be a function. It MAY be an asynchronous function that MUST use the `mason-core.async`
implementation. The installer function will be invoked by mason when the package is requested to be installed. It will
be invoked with a single argument of type
[`InstallContext`](https://github.com/williamboman/mason.nvim/blob/main/doc/reference.md#installcontext). The parameter
name of the function MUST be `ctx` (abbreviation of context).

Package installers SHOULD make use of the [built-in
managers](https://github.com/williamboman/mason.nvim/tree/main/lua/mason-core/managers), which provide a high-level API
for common installation instructions.

A package installer MUST provide a "primary source" describing how, and where, the package was installed from. This is
done via the `InstallContext` API (`ctx.receipt:with_primary_source({source})`) or via some other API provided by a
manager. The provided `{source}` MUST be a table with a field `type` that MUST be supported by mason (e.g. `"npm"`,
`"pip3"`).

# Code style

This project adheres to Editorconfig, Selene, and Stylua code style & formatting rules. New patches MUST adhere to these
coding styles.

# Generated code

Some changes such as adding or changing a package definition will require generating some new code. The changes to
generated code MAY be included in a pull request. If it's not included in a pull request, it will automatically be
generated and pushed to your branch before merge.

Generating code can be done on Unix systems like so:

```sh
make generate
```

# Tests

[Tests](https://github.com/williamboman/mason.nvim/tree/main/tests) MAY be added or modified to reflect any new changes.
Tests can be executed on Unix systems like so:

```sh
make test
FILE=tests/mason-core/managers/luarocks_spec.lua make test
```

# Adding or changing a feature

Adding or changing a feature MUST be preceded with an issue where scope and acceptance criteria are agreed upon with
project maintainers before implementation.

# Commit style

Commits SHOULD follow the [conventional commits guidelines](https://www.conventionalcommits.org/en/v1.0.0/).

# Pull requests

Once a pull request is marked as ready for review (i.e. not in draft mode), new changes SHOULD NOT be force-pushed to
the branch. Merge commits SHOULD be preferred over rebases.
