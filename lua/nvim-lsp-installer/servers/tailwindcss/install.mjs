const VERSION = "v0.6.12"

const downloadUrl = `https://github.com/tailwindlabs/tailwindcss-intellisense/releases/download/${VERSION}/vscode-tailwindcss-${VERSION.replace(/^v/, "")}.vsix`

await $`wget -O tailwindcss-intellisense.vsix ${downloadUrl}`
await $`unzip tailwindcss-intellisense.vsix -d tailwindcss`
await $`rm tailwindcss-intellisense.vsix`
