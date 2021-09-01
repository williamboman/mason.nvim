import { getDownloadUrl } from "./common.mjs";

await $`wget -O rust-analyzer.gz ${getDownloadUrl()}`;
await $`gzip -fd rust-analyzer.gz`;
await $`chmod +x rust-analyzer`;
