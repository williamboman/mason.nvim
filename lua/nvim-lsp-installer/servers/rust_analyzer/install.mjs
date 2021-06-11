const VERSION = "2021-05-10";

const target = (() => {
  switch (os.platform()) {
    case "darwin":
      return "rust-analyzer-mac.gz";
    case "win32": {
      console.error(chalk.red("Windows not currently supported."));
      process.exit(1);
      break;
    }
    default:
      return "rust-analyzer-linux.gz";
  }
})();

const unpackedTarget = target.replace(/\.gz$/, "");

const downloadUrl = `https://github.com/rust-analyzer/rust-analyzer/releases/download/${VERSION}/${target}`;

await $`wget ${downloadUrl}`;
await $`gunzip ${target}`;
await $`chmod +x ${unpackedTarget}`;
await $`mv ${unpackedTarget} rust-analyzer`;
