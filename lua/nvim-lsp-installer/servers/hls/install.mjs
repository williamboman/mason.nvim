const VERSION = "1.3.0";

const target = (() => {
    const platform = os.platform();
    switch (platform) {
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
HLS_DIR=$(dirname "$0")
export PATH=$PATH:$HLS_DIR
haskell-language-server-wrapper --lsp`;

await fs.writeFile("./hls", scriptContent);
await $`chmod +x hls`
