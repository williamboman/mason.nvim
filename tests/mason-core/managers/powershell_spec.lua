local stub = require "luassert.stub"
local spy = require "luassert.spy"
local match = require "luassert.match"
local mock = require "luassert.mock"
local spawn = require "mason-core.spawn"

describe("powershell manager", function()
    local function powershell()
        package.loaded["mason-core.managers.powershell"] = nil
        return require "mason-core.managers.powershell"
    end

    it("should use pwsh if available", function()
        stub(spawn, "pwsh", function() end)
        stub(spawn, "powershell", function() end)
        stub(vim.fn, "executable")
        vim.fn.executable.on_call_with("pwsh").returns(1)

        powershell().command "echo 'Is this bash?'"

        assert.spy(spawn.pwsh).was_called(1)
        assert.spy(spawn.powershell).was_called(0)
    end)

    it(
        "should use powershell if pwsh is not availble",
        async_test(function()
            stub(spawn, "pwsh", function() end)
            stub(spawn, "powershell", function() end)
            stub(vim.fn, "executable")
            vim.fn.executable.on_call_with("pwsh").returns(0)

            powershell().command "echo 'Is this bash?'"

            assert.spy(spawn.pwsh).was_called(0)
            assert.spy(spawn.powershell).was_called(1)
        end)
    )

    it("should use the provided spawner for commands", function()
        spy.on(spawn, "pwsh")
        local custom_spawn = mock.new { pwsh = mockx.just_runs }
        stub(vim.fn, "executable")
        vim.fn.executable.on_call_with("pwsh").returns(1)
        powershell().command("echo 'Is this bash?'", {}, custom_spawn)

        assert.spy(spawn.pwsh).was_called(0)
        assert.spy(custom_spawn.pwsh).was_called(1)
    end)

    it("should use the provided spawner scripts", function()
        spy.on(spawn, "pwsh")
        local custom_spawn = mock.new { pwsh = mockx.just_runs }
        stub(vim.fn, "executable")
        vim.fn.executable.on_call_with("pwsh").returns(1)
        powershell().script("echo 'Is this bash?'", {}, custom_spawn)

        assert.spy(spawn.pwsh).was_called(0)
        assert.spy(custom_spawn.pwsh).was_called(1)
    end)

    it("should provide default powershell options via script stdin", function()
        local stdin = mock.new { write = mockx.just_runs, close = mockx.just_runs }
        stub(spawn, "pwsh", function(args)
            args.on_spawn(nil, { stdin })
        end)
        stub(vim.fn, "executable")
        vim.fn.executable.on_call_with("pwsh").returns(1)

        powershell().script "echo 'Is this bash?'"

        assert.spy(spawn.pwsh).was_called(1)
        assert.spy(stdin.write).was_called(3)
        assert.spy(stdin.write).was_called_with(match.is_ref(stdin), " $ProgressPreference = 'SilentlyContinue'; ")
        assert
            .spy(stdin.write)
            .was_called_with(match.is_ref(stdin), " [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; ")
        assert.spy(stdin.write).was_called_with(match.is_ref(stdin), "echo 'Is this bash?'")
        assert.spy(stdin.close).was_called(1)
    end)

    it("should provide default powershell options via command interface", function()
        stub(spawn, "pwsh", function() end)
        stub(vim.fn, "executable")
        vim.fn.executable.on_call_with("pwsh").returns(1)

        powershell().command "echo 'Is this bash?'"

        assert.spy(spawn.pwsh).was_called(1)
        vim.pretty_print(spawn.pwsh)
        assert.spy(spawn.pwsh).was_called_with(match.tbl_containing {
            "-NoProfile",
            "-Command",
            " $ProgressPreference = 'SilentlyContinue';  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; echo 'Is this bash?'",
        })
    end)
end)
