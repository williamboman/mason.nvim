-- Function to split a version string into its components
local function split_version(version)
    local parts = {}
    for part in version:gmatch "[^.]+" do
        table.insert(parts, tonumber(part) or part)
    end
    return parts
end

-- Function to compare two versions
local function compare_versions(version1, version2)
    local v1_parts = split_version(version1)
    local v2_parts = split_version(version2)
    local len = math.max(#v1_parts, #v2_parts)

    for i = 1, len do
        local v1_part = v1_parts[i] or 0
        local v2_part = v2_parts[i] or 0

        if v1_part < v2_part then
            return -1
        elseif v1_part > v2_part then
            return 1
        end
    end

    return 0
end

-- Function to check a version against a single specifier
local function check_single_specifier(version, specifier)
    local operator, spec_version = specifier:match "^([<>=!]+)%s*(.+)$"
    local comp_result = compare_versions(version, spec_version)

    if operator == "==" then
        return comp_result == 0
    elseif operator == "!=" then
        return comp_result ~= 0
    elseif operator == "<=" then
        return comp_result <= 0
    elseif operator == "<" then
        return comp_result < 0
    elseif operator == ">=" then
        return comp_result >= 0
    elseif operator == ">" then
        return comp_result > 0
    else
        error("Invalid operator in version specifier: " .. operator)
    end
end

-- Function to check a version against multiple specifiers
local function check_version(version, specifiers)
    for specifier in specifiers:gmatch "[^,]+" do
        if not check_single_specifier(version, specifier:match "^%s*(.-)%s*$") then
            return false
        end
    end
    return true
end

return {
    check_version = check_version,
}
