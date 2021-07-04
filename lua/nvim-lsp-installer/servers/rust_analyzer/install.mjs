const VERSION = "2021-06-28";

const exitNotSupported = () => {
    console.error(
        chalk.red(`${os.platform()} ${os.arch()} is currently not supported.`)
    );
    process.exit(1);
};

const target = (() => {
    switch (os.platform()) {
        case "darwin":
            switch (os.arch()) {
                case "arm64":
                    return "rust-analyzer-aarch64-apple-darwin.gz";
                case "x64":
                    return "rust-analyzer-x86_64-apple-darwin.gz";
                default: {
                    exitNotSupported();
                    break;
                }
            }
        case "win32": {
            exitNotSupported();
            break;
        }
        default:
            switch (os.arch()) {
                case "arm64":
                    return "rust-analyzer-aarch64-unknown-linux-gnu.gz";
                default:
                    return "rust-analyzer-x86_64-unknown-linux-gnu.gz";
            }
    }
})();

const unpackedTarget = target.replace(/\.gz$/, "");

const downloadUrl = `https://github.com/rust-analyzer/rust-analyzer/releases/download/${VERSION}/${target}`;

await $`wget ${downloadUrl}`;
await $`gunzip ${target}`;
await $`chmod +x ${unpackedTarget}`;
await $`mv ${unpackedTarget} rust-analyzer`;
