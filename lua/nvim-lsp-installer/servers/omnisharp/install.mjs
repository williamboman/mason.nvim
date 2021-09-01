import { getDownloadUrl } from "./common.mjs";

await $`wget -O omnisharp.zip ${getDownloadUrl()}`;
await $`unzip omnisharp.zip -d omnisharp`;
await $`chmod +x omnisharp/run`;
await $`rm omnisharp.zip`;
