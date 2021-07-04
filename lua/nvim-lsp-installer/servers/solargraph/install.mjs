await $`git clone --depth 1 https://github.com/castwide/solargraph.git .`;

await $`bundle config set --local without 'development'`;
await $`bundle config set --local path 'vendor/bundle'`;
await $`bundle install`;

await fs.writeFile(
  "./solargraph",
  `#!/usr/bin/env bash
cd "$(dirname "$0")" || exit 1
bundle exec solargraph $*`
);

await $`chmod +x solargraph`;
