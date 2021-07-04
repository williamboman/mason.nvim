const VERSION = "1.2.0";

const target = (() => {
    const platform = os.platform();
    switch (platform) {
        case "win32": {
            console.error(chalk.red(`${platform} is not yet supported.`));
            process.exit(1);
        }
        case "darwin":
            return `haskell-language-server-macOS-${VERSION}.tar.gz`;
        default:
            return `haskell-language-server-Linux-${VERSION}.tar.gz`;
    }
})();

const downloadUrl = `https://github.com/haskell/haskell-language-server/releases/download/${VERSION}/${target}`;

await $`wget -O hls.tar.gz ${downloadUrl}`;
await $`tar -xf hls.tar.gz`;
await $`rm hls.tar.gz`;
await $`chmod +x haskell*`;

const scriptContent = `#!/usr/bin/env bash
PATH="$PATH:${__dirname}" "${__dirname}/haskell-language-server-wrapper" --lsp`;

await fs.writeFile("./hls", scriptContent);
await $`chmod +x hls`
