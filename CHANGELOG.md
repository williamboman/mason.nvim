# Changelog

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
