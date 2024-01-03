---@type Provider
return {
    github = require "mason.providers.client.gh",
    npm = require "mason.providers.client.npm",
    pypi = require "mason.providers.client.pypi",
    rubygems = require "mason.providers.client.rubygems",
    golang = require "mason.providers.client.golang",
    openvsx = require "mason.providers.client.openvsx",
}
