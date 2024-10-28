-- tests/codecast_spec.lua
describe('CodeCast.nvim', function()
    -- Load required modules
    local assert = require('luassert')
    local codecast
    
    -- Setup before running any tests
    before_each(function()
        -- Reload the module before each test to ensure clean state
        package.loaded['codecast'] = nil
        codecast = require('codecast')
        
        -- Create a new buffer for each test
        vim.cmd('new')
    end)

    -- Cleanup after each test
    after_each(function()
        -- Close the test buffer
        vim.cmd('bdelete!')
        
        -- Reset CodeCast state
        if codecast.active_timer then
            codecast.active_timer:stop()
            codecast.active_timer:close()
            codecast.active_timer = nil
        end
    end)

    -- Helper function to create a temporary file
    local function create_temp_file(content)
        local tmp_dir = vim.fn.expand('$HOME') .. '/.codecast_test_snippets'
        vim.fn.mkdir(tmp_dir, 'p')
        local file_path = tmp_dir .. '/test_snippet.txt'
        local file = io.open(file_path, 'w')
        if file then
            file:write(content)
            file:close()
            return tmp_dir, file_path
        end
        return nil, nil
    end

    -- Helper function to clean up temporary files
    local function cleanup_temp_files(dir)
        if dir then
            vim.fn.delete(dir, 'rf')
        end
    end

    -- Helper function to get buffer content
    local function get_buffer_content()
        return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
    end

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
            assert.equals('typewriter', codecast.config.default_insert_mode)
        end)
    end)

    describe('snippet management', function()
        local test_dir, test_file

        before_each(function()
            test_dir, test_file = create_temp_file('test content')
            if test_dir then
                codecast.setup({
                    snippets_dir = test_dir
                })
            end
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
    end)

    describe('keybindings', function()
        it('should register custom keybindings', function()
            codecast.setup({
                keybindings = {
                    show_snippets = '<leader>t'
                }
            })
            
            local map = vim.fn.maparg('<Leader>t', 'n')
            assert.is_true(#map > 0)
        end)
    end)
end)
