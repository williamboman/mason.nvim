---@param config table
return function(config)
    local install_dir = config["install_dir"]

    return {
        bundle_path = install_dir,
    }
end
