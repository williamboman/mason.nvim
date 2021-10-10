local Data = require "nvim-lsp-installer.data"
local M = {}

M.NodeType = Data.enum {
    "NODE",
    "CASCADING_STYLE",
    "VIRTUAL_TEXT",
    "HL_TEXT",
    "KEYBIND_HANDLER",
}

function M.Node(children)
    return {
        type = M.NodeType.NODE,
        children = children,
    }
end

function M.HlTextNode(lines_with_span_tuples)
    if type(lines_with_span_tuples[1]) == "string" then
        -- this enables a convenience API for just rendering a single line (with just a single span)
        lines_with_span_tuples = { { lines_with_span_tuples } }
    end
    return {
        type = M.NodeType.HL_TEXT,
        lines = lines_with_span_tuples,
    }
end

function M.Text(lines)
    return M.HlTextNode(Data.list_map(function(line)
        return { { line, "" } }
    end, lines))
end

M.CascadingStyle = Data.enum {
    "INDENT",
    "CENTERED",
}

function M.CascadingStyleNode(styles, children)
    return {
        type = M.NodeType.CASCADING_STYLE,
        styles = styles,
        children = children,
    }
end

function M.VirtualTextNode(virt_text)
    return {
        type = M.NodeType.VIRTUAL_TEXT,
        virt_text = virt_text,
    }
end

function M.When(condition, a)
    if condition then
        if type(a) == "function" then
            return a()
        else
            return a
        end
    end
    return M.Node {}
end

function M.Keybind(key, effect, payload, is_global)
    return {
        type = M.NodeType.KEYBIND_HANDLER,
        key = key,
        effect = effect,
        payload = payload,
        is_global = is_global or false,
    }
end

function M.EmptyLine()
    return M.Text { "" }
end

function M.Table(rows)
    local col_maxwidth = {}
    for i = 1, #rows do
        local row = rows[i]
        for j = 1, #row do
            local col = row[j]
            local content = col[1]
            col_maxwidth[j] = math.max(#content, col_maxwidth[j] or 0)
        end
    end

    for i = 1, #rows do
        local row = rows[i]
        for j = 1, #row do
            local col = row[j]
            local content = col[1]
            col[1] = content .. string.rep(" ", (col_maxwidth[j] - #content) + 1) -- +1 for default minimum padding
        end
    end

    return M.HlTextNode(rows)
end

return M
