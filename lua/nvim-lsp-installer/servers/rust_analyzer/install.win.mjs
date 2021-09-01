import { getDownloadUrl } from "./common.mjs";

// TODO: can this be... less hacky?
$.shell = "powershell.exe";
$.prefix = "";
$.quote = (a) => a;

await $`wget -O rust-analyzer.exe.gz ${getDownloadUrl()}`;
await $`gzip -fd rust-analyzer.exe.gz`;
