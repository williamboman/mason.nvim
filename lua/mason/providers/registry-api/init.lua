local api = require "mason-registry.api"

---@type Provider
return {
    github = {
        get_latest_release = function(repo)
            return api.github.releases.latest { repo = repo }
        end,
        get_all_release_versions = function(repo)
            return api.github.releases.all { repo = repo }
        end,
        get_latest_tag = function(repo)
            return api.github.tags.latest { repo = repo }
        end,
        get_all_tags = function(repo)
            return api.github.tags.all { repo = repo }
        end,
    },
    npm = {
        get_latest_version = function(pkg)
            return api.npm.versions.latest { package = pkg }
        end,
        get_all_versions = function(pkg)
            return api.npm.versions.all { package = pkg }
        end,
    },
    pypi = {
        get_latest_version = function(pkg)
            return api.pypi.versions.latest { package = pkg }
        end,
        get_all_versions = function(pkg)
            return api.pypi.versions.all { package = pkg }
        end,
    },
    rubygems = {
        get_latest_version = function(gem)
            return api.rubygems.versions.latest { gem = gem }
        end,
        get_all_versions = function(gem)
            return api.rubygems.versions.all { gem = gem }
        end,
    },
    packagist = {
        get_latest_version = function(pkg)
            return api.packagist.versions.latest { pkg = pkg }
        end,
        get_all_versions = function(pkg)
            return api.packagist.versions.all { pkg = pkg }
        end,
    },
    crates = {
        get_latest_version = function(crate)
            return api.crate.versions.latest { crate = crate }
        end,
        get_all_versions = function(crate)
            return api.crate.versions.all { crate = crate }
        end,
    },
    golang = {
        get_all_versions = function(pkg)
            return api.golang.versions.all { pkg = api.encode_uri_component(pkg) }
        end,
    },
    openvsx = {
        get_latest_version = function(namespace, extension)
            return api.openvsx.versions.latest { namespace = namespace, extension = extension }
        end,
        get_all_versions = function(namespace, extension)
            return api.openvsx.versions.all { namespace = namespace, extension = extension }
        end,
    },
}
