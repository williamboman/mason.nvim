# Changelog

## [1.3.0](https://github.com/williamboman/mason.nvim/compare/v1.2.1...v1.3.0) (2023-06-18)


### Features

* **health:** add advice for Debian/Ubuntu regarding python3 venv ([#1358](https://github.com/williamboman/mason.nvim/issues/1358)) ([6f3853e](https://github.com/williamboman/mason.nvim/commit/6f3853e5ae8c200e29d2e394e479d9c3f8e018f5))

## [1.2.1](https://github.com/williamboman/mason.nvim/compare/v1.2.0...v1.2.1) (2023-06-13)


### Bug Fixes

* **providers:** fix some client providers and add some more ([#1354](https://github.com/williamboman/mason.nvim/issues/1354)) ([6f44955](https://github.com/williamboman/mason.nvim/commit/6f4495590a0f9e121b483c9b1236fbabbd80da7a))

## [1.2.0](https://github.com/williamboman/mason.nvim/compare/v1.1.1...v1.2.0) (2023-06-13)


### Features

* **command:** improve completion for :MasonInstall ([#1353](https://github.com/williamboman/mason.nvim/issues/1353)) ([13e26c8](https://github.com/williamboman/mason.nvim/commit/13e26c81ff5074ee8f095a791cd37fc1cec37377))


### Bug Fixes

* **async:** always check channel state ([#1351](https://github.com/williamboman/mason.nvim/issues/1351)) ([f503346](https://github.com/williamboman/mason.nvim/commit/f5033463bb911a136e577fc6f339328f162e2b4a))
* **command:** run :MasonUpdate synchronously in headless mode ([#1347](https://github.com/williamboman/mason.nvim/issues/1347)) ([0276793](https://github.com/williamboman/mason.nvim/commit/02767937fc2e1b214c854a8fdde26ae1d3529dd6))
* **functional:** strip_prefix and strip_suffix should not use patterns ([#1352](https://github.com/williamboman/mason.nvim/issues/1352)) ([f99b702](https://github.com/williamboman/mason.nvim/commit/f99b70233e49db2229350bb82d9ddc6e2f4131c0))

## [1.1.1](https://github.com/williamboman/mason.nvim/compare/v1.1.0...v1.1.1) (2023-05-29)


### Bug Fixes

* **ui:** improve search mode UI and remove redundant whitespaces ([#1332](https://github.com/williamboman/mason.nvim/issues/1332)) ([a18c031](https://github.com/williamboman/mason.nvim/commit/a18c031c72a3c7576ba5dc60ee30de8290c8757c))

## [1.1.0](https://github.com/williamboman/mason.nvim/compare/v1.0.1...v1.1.0) (2023-05-18)


### Features

* **installer:** lock package installation ([#1290](https://github.com/williamboman/mason.nvim/issues/1290)) ([227f8a9](https://github.com/williamboman/mason.nvim/commit/227f8a9aaae495f481c768f8346edfceaf6d2951))
* **ui:** add keymap setting for toggling package installation log ([#1268](https://github.com/williamboman/mason.nvim/issues/1268)) ([48bb1cc](https://github.com/williamboman/mason.nvim/commit/48bb1cc33a1fefe94f5ce4972446a1c6ad849f15))
* **ui:** add search mode ([#1306](https://github.com/williamboman/mason.nvim/issues/1306)) ([3b59f25](https://github.com/williamboman/mason.nvim/commit/3b59f25d435fb1b8d36c4cc26410c3569f0bd795))
* **ui:** display "update all" hint ([#1296](https://github.com/williamboman/mason.nvim/issues/1296)) ([e634134](https://github.com/williamboman/mason.nvim/commit/e634134312bb936f472468a401c9cae6485ab54b))


### Bug Fixes

* **sources:** don't skip installation if fixed version is not currently installed ([#1297](https://github.com/williamboman/mason.nvim/issues/1297)) ([9c5edf1](https://github.com/williamboman/mason.nvim/commit/9c5edf13c2e6bd5223eebfeb4557ccc841acaa0e))
* **ui:** use vim.cmd("") for nvim-0.7.0 compatibility ([#1307](https://github.com/williamboman/mason.nvim/issues/1307)) ([e60b855](https://github.com/williamboman/mason.nvim/commit/e60b855bfa8c7d34387200daa6e54a5e22d3da05))

## [1.0.1](https://github.com/williamboman/mason.nvim/compare/v1.0.0...v1.0.1) (2023-04-26)


### Bug Fixes

* **pypi:** also provide install_extra_args to pypi.install ([#1263](https://github.com/williamboman/mason.nvim/issues/1263)) ([646ef07](https://github.com/williamboman/mason.nvim/commit/646ef07907e0960987c13c0b13f69eb808cc66ad))
