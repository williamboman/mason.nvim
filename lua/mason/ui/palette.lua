local M = {}

M.highlight_groups = {
    NvimInstallerHeader = { bold = true, fg = "#222222", bg = "#DCA561" },
    NvimInstallerHeaderSecondary = { bold = true, fg = "#222222", bg = "#56B6C2" },

    NvimInstallerHighlight = { fg = "#56B6C2" },
    NvimInstallerHighlightBlock = { bg = "#56B6C2", fg = "#222222" },
    NvimInstallerHighlightBlockBold = { bg = "#56B6C2", fg = "#222222", bold = true },

    NvimInstallerHighlightSecondary = { fg = "#DCA561" },
    NvimInstallerHighlightBlockSecondary = { bg = "#DCA561", fg = "#222222" },
    NvimInstallerHighlightBlockBoldSecondary = { bg = "#DCA561", fg = "#222222", bold = true },

    NvimInstallerLink = { link = "NvimInstallerHighlight" },

    NvimInstallerMuted = { fg = "#888888" },
    NvimInstallerMutedBlock = { bg = "#888888", fg = "#222222" },
    NvimInstallerMutedBlockBold = { bg = "#888888", fg = "#222222", bold = true },

    NvimInstallerError = { fg = "#f44747" },

    NvimInstallerHeading = { bold = true },
}

local function hl(highlight)
    return function(text)
        return { text, highlight }
    end
end

-- aliases
M.none = hl ""
M.header = hl "NvimInstallerHeader"
M.header_secondary = hl "NvimInstallerHeaderSecondary"
M.muted = hl "NvimInstallerMuted"
M.muted_block = hl "NvimInstallerMutedBlock"
M.muted_block_bold = hl "NvimInstallerMutedBlockBold"
M.highlight = hl "NvimInstallerHighlight"
M.highlight_block = hl "NvimInstallerHighlightBlock"
M.highlight_block_bold = hl "NvimInstallerHighlightBlockBold"
M.highlight_block_secondary = hl "NvimInstallerHighlightBlockSecondary"
M.highlight_block_bold_secondary = hl "NvimInstallerHighlightBlockBoldSecondary"
M.highlight_secondary = hl "NvimInstallerHighlightSecondary"
M.error = hl "NvimInstallerError"
M.heading = hl "NvimInstallerHeading"

setmetatable(M, {
    __index = function(self, key)
        self[key] = hl(key)
        return self[key]
    end,
})

return M
