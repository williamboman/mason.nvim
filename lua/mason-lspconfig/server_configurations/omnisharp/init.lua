return function(install_dir, config)
    return {
        cmd = { config.use_modern_net == false and "omnisharp-mono" or "omnisharp" },
    }
end
