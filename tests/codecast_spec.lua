-- tests/codecast_spec.lua
local assert = require('luassert')
local codecast = require('codecast')

-- Helper function to create a temporary file
local function create_temp_file(content)
    local tmp_dir = vim.fn.expand('$HOME') .. '/.codecast_test_snippets'
    vim.fn.mkdir(tmp_dir, 'p')
    local file_path = tmp_dir .. '/test_snippet.txt'
    local file = io.open(file_path, 'w')
    file:write(content)
    file:close()
    return tmp_dir, file_path
end

-- Helper function to clean up temporary files
local function cleanup_temp_files(dir)
    vim.fn.delete(dir, 'rf')
end

-- Helper function to get buffer content
local function get_buffer_content()
    return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
end

describe('CodeCast.nvim', function()
    -- Setup before each test
    before_each(function()
        -- Create a new buffer for each test
        vim.cmd('new')
        -- Reset CodeCast state
        codecast.is_typing = false
        codecast.is_paused = false
        if codecast.active_timer then
            codecast.active_timer:stop()
            codecast.active_timer:close()
            codecast.active_timer = nil
        end
    end)

    -- Cleanup after each test
    after_each(function()
        -- Close the test buffer
        vim.cmd('bdelete!')
    end)

    describe('configuration', function()
        it('should use default configuration when not configured', function()
            codecast.setup()
            assert.equals(50, codecast.config.typewriter_speed)
            assert.equals('typewriter', codecast.config.default_insert_mode)
            assert.equals('<leader>cc', codecast.config.keybindings.show_snippets)
        end)

        it('should merge custom configuration with defaults', function()
            codecast.setup({
                typewriter_speed = 100,
                keybindings = {
                    show_snippets = '<leader>s'
                }
            })
            assert.equals(100, codecast.config.typewriter_speed)
            assert.equals('<leader>s', codecast.config.keybindings.show_snippets)
            -- Should retain other default values
            assert.equals('typewriter', codecast.config.default_insert_mode)
        end)
    end)

    describe('snippet management', function()
        local test_dir, test_file

        before_each(function()
            -- Create a test snippet
            test_dir, test_file = create_temp_file('test content')
            codecast.setup({
                snippets_dir = test_dir
            })
        end)

        after_each(function()
            cleanup_temp_files(test_dir)
        end)

        it('should create snippets directory if it does not exist', function()
            local new_dir = vim.fn.expand('$HOME') .. '/.codecast_new_test_dir'
            codecast.setup({
                snippets_dir = new_dir
            })
            assert.is_true(vim.fn.isdirectory(new_dir) == 1)
            cleanup_temp_files(new_dir)
        end)

        it('should read snippet content correctly', function()
            local bufnr = vim.api.nvim_create_buf(false, true)
            vim.b[bufnr] = {
                snippets = {{
                    name = 'test_snippet.txt',
                    path = test_file
                }}
            }
            codecast.insert_snippet(bufnr, 'instant')
            assert.equals('test content', get_buffer_content())
        end)
    end)

    describe('typewriter effect', function()
        it('should initialize typing state correctly', function()
            codecast.typewriter_effect('test')
            assert.is_true(codecast.is_typing)
            assert.equals(1, codecast.typing_state.current_line)
            assert.equals(1, codecast.typing_state.current_char)
        end)

        it('should pause typing when requested', function()
            codecast.typewriter_effect('test')
            codecast.pause_typewriter()
            assert.is_true(codecast.is_paused)
            assert.is_false(codecast.is_typing)
        end)

        it('should resume typing from paused state', function()
            codecast.typewriter_effect('test')
            codecast.pause_typewriter()
            codecast.resume_typewriter()
            assert.is_true(codecast.is_typing)
            assert.is_false(codecast.is_paused)
        end)

        it('should stop typing when requested', function()
            codecast.typewriter_effect('test')
            codecast.stop_typewriter()
            assert.is_false(codecast.is_typing)
            assert.is_false(codecast.is_paused)
            assert.is_nil(codecast.active_timer)
        end)

        -- Test for actual typing effect
        it('should type text character by character', function()
            local test_text = 'test'
            codecast.config.typewriter_speed = 0  -- Speed up the test
            codecast.typewriter_effect(test_text)

            -- Wait for typing to complete
            vim.wait(100, function()
                return not codecast.is_typing
            end)

            assert.equals(test_text, get_buffer_content())
        end)
    end)

    describe('keybindings', function()
        it('should register custom keybindings', function()
            codecast.setup({
                keybindings = {
                    show_snippets = '<leader>t'
                }
            })

            -- Check if the mapping exists
            local map = vim.fn.maparg('<Leader>t', 'n')
            assert.is_true(#map > 0)
        end)

        it('should handle multiple stop typing keys', function()
            codecast.setup({
                keybindings = {
                    stop_typing = {'<C-x>', '<C-q>'}
                }
            })

            codecast.typewriter_effect('test')
            assert.is_true(codecast.is_typing)

            -- Simulate pressing one of the stop keys
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-x>', true, false, true), 'x', true)
            vim.wait(100, function() return false end)

            assert.is_false(codecast.is_typing)
        end)
    end)

    describe('snippet selector', function()
        it('should create popup window with correct dimensions', function()
            codecast.show_snippet_selector()
            -- Get the window ID of the popup
            local win_id = vim.fn.win_getid()
            assert.is_not_nil(win_id)

            -- Check window options
            local win_config = vim.api.nvim_win_get_config(win_id)
            assert.equals('popup', win_config.relative)
        end)

        it('should close selector on ESC', function()
            codecast.show_snippet_selector()
            local initial_win_count = #vim.api.nvim_list_wins()

            -- Simulate pressing ESC
            vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes('<ESC>', true, false, true),
                'x',
                true
            )

            vim.wait(100, function() return false end)
            local final_win_count = #vim.api.nvim_list_wins()
            assert.is_true(final_win_count < initial_win_count)
        end)
    end)
end)
