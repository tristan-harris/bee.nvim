local M = {}
M.bees_list = {}
local conf = {character="🐝", speed=10, width=2, height=1, color="none", blend=100}

local buzz = function(bee, speed)
    local timer = vim.loop.new_timer()
    local new_bee = { name = bee, timer = timer }
    table.insert(M.bees_list, new_bee)

    local buzz_period = 1000 / (speed or conf.speed)
    vim.loop.timer_start(timer, 1000, buzz_period, vim.schedule_wrap(function()
        if vim.api.nvim_win_is_valid(bee) then
            local config = vim.api.nvim_win_get_config(bee)
            local col, row = config["col"][false], config["row"][false]

            math.randomseed(os.time()*bee)
            local angle = 2 * math.pi * math.random()
            local s = math.sin(angle)
            local c = math.cos(angle)

            if row < 0 and s < 0 then
              row = vim.o.lines
            end

            if row > vim.o.lines  and s > 0 then
              row = 0
            end

            if col < 0 and c < 0 then
              col = vim.o.columns
            end

            if col > vim.o.columns and c > 0 then
              col = 0
            end

            config["row"] = row + 0.5 * s
            config["col"] = col + 1 * c

            vim.api.nvim_win_set_config(bee, config)
        end
    end))
end

M.summon = function(speed, color)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf , 0, 1, true , {conf.character})

    local bee = vim.api.nvim_open_win(buf, false, {
        relative='cursor', style='minimal', row=1, col=1, width=conf.width, height=conf.height
    })
    vim.cmd("hi Bee"..bee.." guifg=" .. (color or conf.color) .. " guibg=none blend=" .. conf.blend)
    vim.api.nvim_win_set_option(bee, 'winhighlight', 'Normal:Bee'..bee)

    buzz(bee, speed)
end

M.fly_home = function()
    local last_bee = M.bees_list[#M.bees_list]

    if not last_bee then
        vim.notify("No bees buzzing.")
        return
    end

    local bee = last_bee['name']
    local timer = last_bee['timer']
    table.remove(M.bees_list, #M.bees_list)
    timer:stop()

    vim.api.nvim_win_close(bee, true)
end

M.all_fly_home = function()
    if #M.bees_list <= 0 then
        vim.notify("No bees buzzing.")
        return
    end

    while (#M.bees_list > 0) do
        M.fly_home()
    end
end

M.setup = function(opts)
    conf = vim.tbl_deep_extend('force', conf, opts or {})
end

return M
