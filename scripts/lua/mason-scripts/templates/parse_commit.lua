local _ = require "mason-core.functional"

local linkify = _.gsub([[#(%d+)]], function(issue)
    return ("[#%d](https://github.com/williamboman/mason.nvim/issues/%d)"):format(issue, issue)
end)

return {
    parse_commit = function(commit_str)
        local commit =
            _.compose(_.zip_table { "sha", "commit_date", "author_name", "subject" }, _.split "\t")(commit_str)

        return (_.dedent [[
        [`%s`](https://github.com/williamboman/mason.nvim/commit/%s) %s - %s by %s
        ]]):format(commit.sha, commit.sha, commit.commit_date, linkify(commit.subject), commit.author_name)
    end,
}
