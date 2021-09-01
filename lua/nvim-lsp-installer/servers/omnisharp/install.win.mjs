import { getDownloadUrl } from "./common.mjs";

// TODO: can this be... less hacky?
$.shell = "powershell.exe";
$.prefix = "";
$.quote = (a) => a;

await $`wget -O omnisharp.zip ${getDownloadUrl()}`;
await $`tar -xvf omnisharp.zip`;
await $`rm omnisharp.zip`;
