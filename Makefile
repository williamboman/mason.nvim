INSTALL_ROOT_DIR:=$(shell pwd)/tests/fixtures/mason
NVIM_HEADLESS:=nvim --headless --noplugin -u tests/minimal_init.vim

dependencies:
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim dependencies/pack/vendor/start/plenary.nvim
	git clone --depth 1 https://github.com/nvim-neotest/neotest dependencies/pack/vendor/start/neotest

.PHONY: clean_dependencies
clean_dependencies:
	rm -rf dependencies

.PHONY: clean_fixtures
clean_fixtures:
	rm -rf "${INSTALL_ROOT_DIR}"

.PHONY: clean
clean: clean_fixtures clean_dependencies

.PHONY: test
test: clean_fixtures dependencies
	INSTALL_ROOT_DIR=${INSTALL_ROOT_DIR} $(NVIM_HEADLESS) -c "call RunTests()"

# vim:noexpandtab
