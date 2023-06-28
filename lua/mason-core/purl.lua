local Optional = require "mason-core.optional"
local Result = require "mason-core.result"
local _ = require "mason-core.functional"

local M = {}

-- Fully spec-compliant parser for purls (https://github.com/package-url/purl-spec)

---@param str string
local function parse_hex(str)
    return tonumber(str, 16)
end

---@param char string
local function percent_encode(char)
    return ("%%%x"):format(string.byte(char, 1, 1))
end

local decode_percent_encoding = _.gsub("%%([A-Fa-f0-9][A-Fa-f0-9])", _.compose(string.char, parse_hex))
local encode_percent_encoding = _.gsub("[!#$&'%(%)%*%+;=%?@%[%] ]", percent_encode)

local function validate_conan(purl)
    if purl.namespace and not _.path({ "qualifiers", "channel" }, purl) then
        return Result.failure "Missing channel qualifier."
    elseif not purl.namespace and _.path({ "qualifiers", "channel" }, purl) then
        return Result.failure "Missing namespace."
    end
    return Result.success(purl)
end

local function validate_cran(purl)
    if not purl.version then
        return Result.failure "Missing version."
    end
    return Result.success(purl)
end

local function validate_swift(purl)
    if not purl.namespace then
        return Result.failure "Missing namespace."
    end
    if not purl.version then
        return Result.failure "Missing version."
    end
    return Result.success(purl)
end

---@class Purl
---@field scheme '"pkg"'
---@field type string
---@field namespace string?
---@field name string
---@field version string?
---@field qualifiers table<string, string>?
---@field subpath string?

---@param str string
local function split_once_right(str, char)
    for i = #str, 1, -1 do
        if str:sub(i, i) == char then
            local segment = str:sub(i + 1, #str)
            return str:sub(1, i - 1), segment
        end
    end
    return str
end

---@param str string
local function split_once_left(str, char)
    for i = 1, #str do
        if str:sub(i, i) == char then
            local segment = str:sub(1, i - 1)
            return segment, str:sub(i + 1)
        end
    end
    return str
end

local function left_trim(char, str)
    for i = 1, #str do
        if str:sub(i, i) ~= char then
            return i
        end
    end
    return #str + 1
end

local function right_trim(char, str)
    for i = #str, 1, -1 do
        if str:sub(i, i) ~= char then
            return i
        end
    end
    return #str + 1
end

---@param char string
---@param str string
local function trim(char, str)
    return str:sub(left_trim(char, str), right_trim(char, str))
end

local parse_subpath = _.compose(
    _.join "/",
    _.filter_map(function(segment)
        if segment == "." or segment == ".." or segment == "" then
            return Optional.empty()
        end
        return Optional.of(decode_percent_encoding(segment))
    end),
    _.split "/",
    _.partial(trim, "/")
)

local parse_qualifiers = _.compose(
    _.evolve {
        checksum = _.split ",",
    },
    _.from_pairs,
    _.filter_map(function(pair)
        local key, value = split_once_left(pair, "=")
        if value ~= nil and value ~= "" then
            return Optional.of { _.to_lower(key), decode_percent_encoding(value) }
        else
            return Optional.empty()
        end
    end),
    _.split "&"
)

local parse_namespace = _.compose(
    _.join "/",
    _.filter_map(function(segment)
        if segment == "" then
            return Optional.empty()
        end
        return Optional.of(decode_percent_encoding(segment))
    end),
    _.split "/"
)

local pypi = _.evolve {
    name = _.compose(_.to_lower, _.gsub("_", "-")),
}

local huggingface = _.evolve {
    version = _.to_lower,
}

local azuredatabricks = _.evolve {
    name = _.to_lower,
    namespace = _.to_lower,
}

local bitbucket = _.evolve {
    name = _.to_lower,
    namespace = _.to_lower,
}

local github = _.evolve {
    name = _.to_lower,
    namespace = _.to_lower,
}

local composer = _.evolve {
    name = _.to_lower,
    namespace = _.to_lower,
}

local is_mlflow_azuredatabricks = _.all_pass {
    _.prop_eq("type", "mlflow"),
    _.path_satisfies(_.matches "^https?://.*azuredatabricks%.net", { "qualifiers", "repository_url" }),
}

local type_validations = _.cond {
    { _.prop_eq("type", "conan"), validate_conan },
    { _.prop_eq("type", "cran"), validate_cran },
    { _.prop_eq("type", "swift"), validate_swift },
    { _.T, Result.success },
}

local type_transforms = _.cond {
    { _.prop_eq("type", "bitbucket"), bitbucket },
    { _.prop_eq("type", "composer"), composer },
    { _.prop_eq("type", "github"), github },
    { _.prop_eq("type", "pypi"), pypi },
    { _.prop_eq("type", "huggingface"), huggingface },
    { is_mlflow_azuredatabricks, azuredatabricks },
    { _.T, _.identity },
}

local type_specific_transforms = _.compose(type_validations, type_transforms)

---@param raw_purl string
---@return Result # Result<Purl>
function M.parse(raw_purl)
    -- Implementation of recommended parsing algo
    -- https://github.com/package-url/purl-spec/blob/master/PURL-SPECIFICATION.rst#how-to-parse-a-purl-string-in-its-components
    local remainder, subpath = split_once_right(raw_purl, "#")
    if subpath then
        subpath = parse_subpath(subpath)
    end

    local remainder, qualifiers = split_once_right(remainder, "?")
    if qualifiers then
        qualifiers = parse_qualifiers(qualifiers)
        if not _.all(_.matches "^[a-zA-Z%-_%.][0-9a-zA-Z%-_%.]*$", _.keys(qualifiers)) then
            return Result.failure "Malformed purl (invalid qualifier names)."
        end
    end

    local scheme, remainder = split_once_left(remainder, ":")
    if not remainder then
        return Result.failure "Malformed purl (missing type, namespace, name, version components)."
    end
    if scheme ~= "pkg" then
        return Result.failure "Malformed purl (invalid scheme)."
    end
    remainder = trim("/", remainder)

    local type, remainder = split_once_left(remainder, "/")
    if not remainder then
        return Result.failure "Malformed purl (missing namespace, name, version components)"
    end
    type = _.to_lower(type)

    local remainder, version = split_once_right(remainder, "@")
    if version then
        version = decode_percent_encoding(version)
    end

    local remainder, name = split_once_right(remainder, "/")
    if not name then
        name = remainder
        remainder = nil
    end
    if name == "" then
        return Result.failure "Malformed purl (missing name)."
    end
    name = decode_percent_encoding(name)

    local namespace = remainder
    if namespace then
        namespace = parse_namespace(namespace)
    end

    return type_specific_transforms {
        scheme = scheme,
        type = type,
        namespace = namespace,
        name = name,
        version = version,
        qualifiers = qualifiers,
        subpath = subpath,
    }
end

local stringify_qualifiers = _.compose(
    _.join "&",
    _.sort_by(_.identity),
    _.map(_.compose(_.join "=", _.evolve { _.identity, encode_percent_encoding })),
    _.to_pairs,
    _.evolve {
        checksum = _.join ",",
    }
)

---@param purl Purl
---@return string
function M.compile(purl)
    local str = "pkg:"
    str = str .. purl.type .. "/"
    if purl.namespace then
        str = str .. encode_percent_encoding(purl.namespace) .. "/"
    end
    str = str .. purl.name
    if purl.version then
        str = str .. "@" .. encode_percent_encoding(purl.version)
    end
    if purl.qualifiers then
        str = str .. "?" .. stringify_qualifiers(purl.qualifiers)
    end
    if purl.subpath then
        str = str .. "#" .. purl.subpath
    end
    return str
end

return M
