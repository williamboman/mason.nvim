const VERSION = "v1.37.11";

const exitNotSupported = () => {
    console.error(chalk.red(`${os.platform()} ${os.arch()} is currently not supported.`));
    process.exit(1);
};

export const getDownloadUrl = () => {
    const target = (() => {
        switch (os.platform()) {
            case "darwin":
                return "omnisharp-osx.zip";
            case "win32":
                switch (os.arch()) {
                    case "arm64":
                        return "omnisharp-win-arm64.zip";
                    case "x64":
                        return "omnisharp-win-x64.zip";
                    default:
                        return exitNotSupported();
                }
            default:
                switch (os.arch()) {
                    case "arm64":
                        return exitNotSupported();
                    case "x64":
                        return "omnisharp-linux-x64.zip";
                    default:
                        return exitNotSupported();
                }
        }
    })();

    return `https://github.com/OmniSharp/omnisharp-roslyn/releases/download/${VERSION}/${target}`;
};
