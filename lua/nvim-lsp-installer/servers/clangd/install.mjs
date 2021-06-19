const VERSION = "12.0.0";

const target = (() => {
  const platform = os.platform();
  switch (platform) {
    case "darwin":
      return `https://github.com/clangd/clangd/releases/download/${VERSION}/clangd-mac-${VERSION}.zip`;
    case "win32": {
      console.error(chalk.red(`${platform} is not yet supported.`));
      process.exit(1);
    }
    default:
      return `https://github.com/clangd/clangd/releases/download/${VERSION}/clangd-linux-${VERSION}.zip`;
  }
})();

await $`wget -O clangd.zip ${target}`;
await $`unzip clangd.zip`;
await $`rm clangd.zip`;
await $`mv clangd_${VERSION} clangd`;
