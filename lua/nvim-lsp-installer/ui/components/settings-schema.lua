-- Here be dragons
local Ui = require "nvim-lsp-installer.core.ui"
local _ = require "nvim-lsp-installer.core.functional"

local property_type_highlights = {
    ["string"] = "String",
    ["string[]"] = "String",
    ["boolean"] = "Boolean",
    ["number"] = "Number",
    ["integer"] = "Number",
}

local function resolve_type(property_schema)
    if vim.tbl_islist(property_schema.type) then
        return table.concat(property_schema.type, " | ")
    elseif property_schema.type == "array" then
        if property_schema.items then
            return ("%s[]"):format(property_schema.items.type)
        else
            return property_schema.type
        end
    end

    return property_schema.type or "N/A"
end

local function Indent(indentation, children)
    -- create a list table with as many "INDENT" entries as the numeric indentation variable
    local indent = {}
    for _ = 1, indentation do
        table.insert(indent, "INDENT")
    end
    return Ui.CascadingStyleNode(indent, children)
end

---@param server ServerState
---@param schema table
---@param key string|nil
---@param level number
---@param key_width number @The width the key should occupate in the UI to produce an even column.
---@param compound_key string|nil
local function ServerSettingsSchema(server, schema, key, level, key_width, compound_key)
    level = level or 0
    compound_key = ("%s%s"):format(compound_key or "", key or "")
    local toggle_expand_keybind = Ui.Keybind(
        "<CR>",
        "TOGGLE_SERVER_SCHEMA_SETTING",
        { name = server.name, key = compound_key }
    )
    local node_is_expanded = server.expanded_schema_properties[compound_key]
    local key_prefix = node_is_expanded and "↓ " or "→ "

    if (schema.type == "object" or schema.type == nil) and schema.properties then
        local nodes = {}
        if key then
            -- This node belongs to some parent object - render a heading for it.
            -- It'll act as the anchor for its children.
            local heading = Ui.HlTextNode {
                key_prefix .. key,
                node_is_expanded and "LspInstallerLabel" or "",
            }
            nodes[#nodes + 1] = heading
            nodes[#nodes + 1] = toggle_expand_keybind
        end

        -- All level 0 nodes are expanded by default - otherwise we'd not render anything at all
        if level == 0 or node_is_expanded then
            local max_property_length = 0
            local sorted_properties = {}
            for property in pairs(schema.properties) do
                max_property_length = math.max(max_property_length, vim.api.nvim_strwidth(property))
                sorted_properties[#sorted_properties + 1] = property
            end
            -- TODO sort at moment of insert?
            table.sort(sorted_properties)
            for _, property in ipairs(sorted_properties) do
                nodes[#nodes + 1] = Indent(level, {
                    ServerSettingsSchema(
                        server,
                        schema.properties[property],
                        property,
                        level + 1,
                        max_property_length,
                        compound_key
                    ),
                })
            end
        end
        return Ui.Node(nodes)
    elseif schema.oneOf then
        local nodes = {}
        for i, alternative_schema in ipairs(schema.oneOf) do
            nodes[#nodes + 1] = ServerSettingsSchema(
                server,
                alternative_schema,
                ("%s (alt. %d)"):format(key, i),
                level,
                key_width,
                compound_key
            )
        end
        return Ui.Node(nodes)
    else
        -- Leaf node (aka any type that isn't an object)
        local type = resolve_type(schema)
        local heading
        local label = (key_prefix .. key .. (" "):rep(key_width)):sub(1, key_width + 5) -- + 5 to account for key_prefix plus some extra whitespace
        if schema.default ~= nil then
            heading = Ui.HlTextNode {
                {
                    {
                        label,
                        node_is_expanded and "LspInstallerLabel" or "",
                    },
                    {
                        " default: ",
                        "Comment",
                    },
                    {
                        vim.json.encode(schema.default),
                        property_type_highlights[type] or "LspInstallerMuted",
                    },
                },
            }
        else
            heading = Ui.HlTextNode {
                label,
                node_is_expanded and "LspInstallerLabel" or "",
            }
        end

        return Ui.Node {
            heading,
            toggle_expand_keybind,
            Ui.When(node_is_expanded, function()
                local description = _.map(function(line)
                    return { { line, "Comment" } }
                end, vim.split(schema.description or "No description available.", "\n"))

                local type_highlight = property_type_highlights[type] or "LspInstallerMuted"

                local table_rows = {
                    { { "type", "LspInstallerMuted" }, { type, type_highlight } },
                }

                if vim.tbl_islist(schema.enum) then
                    for idx, enum in ipairs(schema.enum) do
                        local enum_description = ""
                        if schema.enumDescriptions and schema.enumDescriptions[idx] then
                            enum_description = "- " .. schema.enumDescriptions[idx]
                        end
                        table_rows[#table_rows + 1] = {
                            { idx == 1 and "possible values" or "", "LspInstallerMuted" },
                            { vim.json.encode(enum), type_highlight },
                            { enum_description, "Comment" },
                        }
                    end
                end

                return Indent(level, {
                    Ui.HlTextNode(description),
                    Ui.Table(table_rows),
                })
            end),
        }
    end
end

return ServerSettingsSchema
