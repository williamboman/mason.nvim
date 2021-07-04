const VERSION = "1.2.0";

const target = (() => {
    const platform = os.platform();
    switch (platform) {
        case "win32": {
            console.error(chalk.red(`${platform} is not yet supported.`));
            process.exit(1);
        }
        case "darwin":
            return `haskell-language-server-wrapper-macOS.gz`;
        default:
            return `haskell-language-server-wrapper-Linux.gz`;
    }
})();

const downloadUrl = `https://github.com/haskell/haskell-language-server/releases/download/${VERSION}/${target}`;

await $`wget -O hls.gz ${downloadUrl}`;
await $`gunzip hls.gz`;
await $`chmod +x hls`
