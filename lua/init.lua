-- codecast.nvim
local M = {}
local popup = require('plenary.popup')
local scan = require('plenary.scandir')

M.NAME = "CodeCast.nvim"
M.VERSION = "0.0.1"

-- Configuration
M.config = {
    snippets_dir = vim.fn.stdpath('config') .. '/codecast/snippets',
    typewriter_speed = 50, -- milliseconds between characters
    default_insert_mode = 'typewriter', -- 'instant' or 'typewriter'
}

-- Store active timer and typing state globally
M.active_timer = nil
M.is_typing = false
M.is_paused = false
M.typing_state = {
    lines = nil,
    current_line = 1,
    current_char = 1,
    start_line = 0,
    win = nil,
    callback = nil
}

-- Utility function to read file content
local function read_file(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content
end

-- Function to get all snippet files
local function get_snippets()
    local snippets = {}
    local files = scan.scan_dir(M.config.snippets_dir, { depth = 1, search_pattern = "%.%w+$" })
    for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ":t")
        snippets[#snippets + 1] = {
            name = name,
            path = file
        }
    end
    return snippets
end

-- Function to stop the typewriter effect
function M.stop_typewriter()
    if M.active_timer then
        M.active_timer:stop()
        M.active_timer:close()
        M.active_timer = nil
        M.is_typing = false
        M.is_paused = false
        vim.api.nvim_echo({{'CodeCast: Typing stopped', 'WarningMsg'}}, false, {})
    end
end

-- Function to pause the typewriter effect
function M.pause_typewriter()
    if M.active_timer and M.is_typing and not M.is_paused then
        M.active_timer:stop()
        M.is_paused = true
        M.is_typing = false
        vim.api.nvim_echo({{'CodeCast: Typing paused', 'WarningMsg'}}, false, {})
    end
end

-- Function to resume the typewriter effect
function M.resume_typewriter()
    if M.active_timer and M.is_paused then
        M.is_typing = true
        M.is_paused = false
        
        -- Restart the timer with the stored state
        M.active_timer:start(0, M.config.typewriter_speed, vim.schedule_wrap(function()
            M.type_next_char()
        end))
        
        vim.api.nvim_echo({{'CodeCast: Typing resumed', 'WarningMsg'}}, false, {})
    end
end

-- Function to type the next character
function M.type_next_char()
    if not M.is_typing then
        return
    end

    local state = M.typing_state
    if state.current_line > #state.lines then
        M.stop_typewriter()
        if state.callback then state.callback() end
        return
    end

    local line = state.lines[state.current_line]
    if state.current_char > #line then
        state.current_line = state.current_line + 1
        state.current_char = 1
        -- Update cursor position to next line
        vim.api.nvim_win_set_cursor(state.win, {state.start_line + state.current_line, 0})
        -- Center the cursor line in the window
        vim.cmd('normal! zz')
        return
    end

    local partial_line = string.sub(line, 1, state.current_char)
    vim.api.nvim_buf_set_lines(0, state.start_line + state.current_line - 1, 
                              state.start_line + state.current_line, false, 
                              {partial_line})
    
    -- Update cursor position within the current line
    vim.api.nvim_win_set_cursor(state.win, {state.start_line + state.current_line, 
                                           state.current_char - 1})
    state.current_char = state.current_char + 1
    
    -- Keep the cursor line centered
    vim.cmd('normal! zz')
end

-- Create snippet selector window
function M.show_snippet_selector()
    local snippets = get_snippets()
    local width = 60
    local height = #snippets + 2
    local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
    
    local bufnr = vim.api.nvim_create_buf(false, true)
    local win_id = popup.create(bufnr, {
        title = "CodeCast Snippets",
        line = math.floor(((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        minwidth = width,
        minheight = height,
        borderchars = borderchars,
    })

    -- Fill buffer with snippet names
    local lines = {}
    for i, snippet in ipairs(snippets) do
        lines[i] = string.format("%d. %s", i, snippet.name)
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    -- Set up keymaps
    local opts = { noremap = true, silent = true }
    -- Normal insert (instant)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<CR>', string.format(
        [[<cmd>lua require('codecast').insert_snippet(%d, 'instant')<CR>]], bufnr
    ), opts)
    -- Typewriter effect insert
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader><CR>', string.format(
        [[<cmd>lua require('codecast').insert_snippet(%d, 'typewriter')<CR>]], bufnr
    ), opts)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q', '<cmd>q<CR>', opts)

    -- Store snippets data
    vim.b[bufnr].snippets = snippets
    
    -- Add a helpful message at the bottom of the popup
    local help_msg = {"", "Press <CR> for instant insert, <leader><CR> for typewriter effect"}
    vim.api.nvim_buf_set_lines(bufnr, height-2, height, false, help_msg)
end

-- Typewriter effect function
function M.typewriter_effect(text, callback)
    -- Stop any existing typewriter effect
    if M.is_typing then
        M.stop_typewriter()
    end

    -- Initialize typing state
    M.typing_state = {
        lines = vim.split(text, "\n"),
        current_line = 1,
        current_char = 1,
        start_line = vim.api.nvim_win_get_cursor(0)[1] - 1,
        win = vim.api.nvim_get_current_win(),
        callback = callback
    }

    -- Insert all lines as empty strings first
    local empty_lines = {}
    for i = 1, #M.typing_state.lines do
        empty_lines[i] = ""
    end
    vim.api.nvim_buf_set_lines(0, M.typing_state.start_line, M.typing_state.start_line, 
                              false, empty_lines)

    -- Set up mappings
    local function setup_mappings()
        vim.keymap.set({'n', 'i', 'v'}, '<C-c>', M.stop_typewriter, { silent = true })
        vim.keymap.set({'n', 'i', 'v'}, '<Esc>', M.stop_typewriter, { silent = true })
        vim.keymap.set({'n', 'i', 'v'}, '<C-p>', M.pause_typewriter, { silent = true })
        vim.keymap.set({'n', 'i', 'v'}, '<C-g>', M.resume_typewriter, { silent = true })
    end

    local function cleanup_mappings()
        vim.keymap.del({'n', 'i', 'v'}, '<C-c>')
        vim.keymap.del({'n', 'i', 'v'}, '<Esc>')
        vim.keymap.del({'n', 'i', 'v'}, '<C-p>')
        vim.keymap.del({'n', 'i', 'v'}, '<C-g>')
    end

    setup_mappings()
    M.is_typing = true
    M.is_paused = false
    
    M.active_timer = vim.loop.new_timer()
    M.active_timer:start(0, M.config.typewriter_speed, vim.schedule_wrap(function()
        M.type_next_char()
    end))
end

-- Insert selected snippet
function M.insert_snippet(bufnr, mode)
    local snippets = vim.b[bufnr].snippets
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local selected = snippets[current_line]
    
    if selected then
        local content = read_file(selected.path)
        vim.cmd('q') -- Close popup
        
        if mode == 'typewriter' or (mode == nil and M.config.default_insert_mode == 'typewriter') then
            -- Use typewriter effect
            M.typewriter_effect(content)
        else
            -- Instant insert
            local pos = vim.api.nvim_win_get_cursor(0)
            local line = pos[1] - 1
            vim.api.nvim_buf_set_lines(0, line, line, false, vim.split(content, "\n"))
        end
    end
end

-- Setup function with improved initialization
function M.setup(opts)
    -- Merge user config with defaults
    M.config = vim.tbl_extend('force', M.config, opts or {})
    
    -- Create snippets directory structure
    local snippets_dir = M.config.snippets_dir
    if not vim.fn.isdirectory(snippets_dir) then
        vim.fn.mkdir(snippets_dir, 'p')
        print(string.format("CodeCast: Created snippets directory at %s", snippets_dir))
    end

    -- Create default keymaps
    vim.api.nvim_set_keymap('n', '<leader>cc', '<cmd>lua require("codecast").show_snippet_selector()<CR>', 
        { noremap = true, silent = true, desc = "Show CodeCast Snippets" })
end

return M
