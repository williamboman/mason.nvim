const VERSION = "v0.18.3";

const exitNotSupported = () => {
    console.error(chalk.red(`${os.platform()} ${os.arch()} is currently not supported.`));
    process.exit(1);
};

const target = (() => {
    switch (os.platform()) {
        case "win32": {
            exitNotSupported();
            break;
        }
        case "darwin":
            switch (os.arch()) {
                case "arm64":
                    return "terraform-ls_0.18.3_darwin_arm64.zip";
                case "x64":
                    return "terraform-ls_0.18.3_darwin_amd64.zip";
                default: {
                    exitNotSupported();
                    break;
                }
            }
        default:
            switch (os.arch()) {
                case "arm64":
                    return "terraform-ls_0.18.3_linux_arm64.zip";
                default:
                    return "terraform-ls_0.18.3_linux_amd64.zip";
            }
    }
})();

const downloadUrl = `https://github.com/hashicorp/terraform-ls/releases/download/${VERSION}/${target}`;

await $`wget -O terraform-ls.zip ${downloadUrl}`;
await $`unzip terraform-ls.zip -d terraform-ls`;
await $`rm terraform-ls.zip`;
