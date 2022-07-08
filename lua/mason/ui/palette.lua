local M = {}

M.highlight_groups = {
    MasonHeader = { bold = true, fg = "#222222", bg = "#DCA561" },
    MasonHeaderSecondary = { bold = true, fg = "#222222", bg = "#56B6C2" },

    MasonHighlight = { fg = "#56B6C2" },
    MasonHighlightBlock = { bg = "#56B6C2", fg = "#222222" },
    MasonHighlightBlockBold = { bg = "#56B6C2", fg = "#222222", bold = true },

    MasonHighlightSecondary = { fg = "#DCA561" },
    MasonHighlightBlockSecondary = { bg = "#DCA561", fg = "#222222" },
    MasonHighlightBlockBoldSecondary = { bg = "#DCA561", fg = "#222222", bold = true },

    MasonLink = { link = "MasonHighlight" },

    MasonMuted = { fg = "#888888" },
    MasonMutedBlock = { bg = "#888888", fg = "#222222" },
    MasonMutedBlockBold = { bg = "#888888", fg = "#222222", bold = true },

    MasonError = { fg = "#f44747" },

    MasonHeading = { bold = true },
}

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
M.heading = hl "MasonHeading"

setmetatable(M, {
    __index = function(self, key)
        self[key] = hl(key)
        return self[key]
    end,
})

return M
