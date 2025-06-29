local M = {}

M.sudo_exec = function(cmd, print_output)
    vim.fn.saveinput()
    local passwd = vim.fn.inputsecret("Password: ")
    vim.fn.restoreinput()
    if not passwd or #passwd == 0 then
        print("Invalid password, sudo aborted")
        return false
    end
    local ok, res = pcall(function()
        return vim.system(
            { "sh", "-c", string.format("echo '%s' | sudo -p '' -S %s", passwd, cmd) }
        ):wait()
    end)
    if not ok or res.code ~= 0 then
        print("\r\n")
        print(not ok and res or res.stderr)
        return false
    end
    if print_output then print("\r\n", res.stderr) end
    return true
end

M.sudo_write = function(tmpfile, filepath)
    if not tmpfile then tmpfile = vim.fn.tempname() end
    if not filepath then filepath = vim.fn.expand("%") end
    if not filepath or #filepath == 0 then
        print("Error: No file name")
        return
    end
    local cmd = string.format("dd if=%s of=%s bs=1048576",
        vim.fn.shellescape(tmpfile),
        vim.fn.shellescape(filepath)
    )
    vim.api.nvim_exec2(string.format("write! %s", tmpfile), { output = true })
    if sudo_exec(cmd) then
        vim.cmd.checktime()
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<ESC>", true, false, true), 
            "n", 
            true
        )
    end
    vim.fn.delete(tmpfile)
end

vim.api.nvim_set_keymap("c", "w!!", "<ESC>:lua require'utils'.sudo_write()<CR>", { silent = false })

return M
