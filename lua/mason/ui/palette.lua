local M = {}

local function hl(highlight)
    return function(text)
        return { text, highlight }
    end
end

-- aliases
M.none = hl ""
M.header = hl "MasonHeader"
M.header_secondary = hl "MasonHeaderSecondary"
M.muted = hl "MasonMuted"
M.muted_block = hl "MasonMutedBlock"
M.muted_block_bold = hl "MasonMutedBlockBold"
M.highlight = hl "MasonHighlight"
M.highlight_block = hl "MasonHighlightBlock"
M.highlight_block_bold = hl "MasonHighlightBlockBold"
M.highlight_block_secondary = hl "MasonHighlightBlockSecondary"
M.highlight_block_bold_secondary = hl "MasonHighlightBlockBoldSecondary"
M.highlight_secondary = hl "MasonHighlightSecondary"
M.error = hl "MasonError"
M.warning = hl "MasonWarning"
M.heading = hl "MasonHeading"

setmetatable(M, {
    __index = function(self, key)
        self[key] = hl(key)
        return self[key]
    end,
})

return M
