const VERSION = "v1.37.11";

const exitNotSupported = () => {
    console.error(
        chalk.red(`${os.platform()} ${os.arch()} is currently not supported.`)
    );
    process.exit(1);
};

const target = (() => {
    switch (os.platform()) {
        case "win32": {
            exitNotSupported();
            break;
        }
        case "darwin":
            return "omnisharp-osx.zip";
        default:
            return "omnisharp-linux-x64.zip";
    }
})();

const downloadUrl = `https://github.com/OmniSharp/omnisharp-roslyn/releases/download/${VERSION}/${target}`;

await $`wget -O omnisharp.zip ${downloadUrl}`;
await $`unzip omnisharp.zip -d omnisharp`;
await $`chmod +x omnisharp/run`;
await $`rm omnisharp.zip`;
