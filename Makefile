INSTALL_ROOT_DIR:=$(shell pwd)/tests/fixtures/lsp_servers
NVIM_HEADLESS:=nvim --headless --noplugin -u tests/minimal_init.vim

dependencies:
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim dependencies/pack/vendor/start/plenary.nvim

.PHONY: clean_dependencies
clean_dependencies:
	rm -rf dependencies

.PHONY: clean_servers
clean_servers:
	rm -rf "${INSTALL_ROOT_DIR}"

.PHONY: clean
clean: clean_servers clean_dependencies

.PHONY: test
test: clean_servers dependencies
	INSTALL_ROOT_DIR=${INSTALL_ROOT_DIR} $(NVIM_HEADLESS) -c "call RunTests()"

# vim:noexpandtab
