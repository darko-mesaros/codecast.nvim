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
          -- Create a test snippet
          test_dir = vim.fn.expand('$HOME') .. '/.codecast_test_snippets'
          test_file = test_dir .. '/test_snippet.txt'
          -- Ensure directory exists
          vim.fn.mkdir(test_dir, 'p')
          -- Create test file with content
          local file = io.open(test_file, 'w')
          if file then
              file:write('test content')
              file:close()
          end

          -- Setup codecast with test directory
          codecast.setup({
              snippets_dir = test_dir
          })
      end)

      after_each(function()
          -- Cleanup
          if test_dir then
              vim.fn.delete(test_dir, 'rf')
          end
      end)

      -- TODO: This test keeps failing. Not sure why. For some reason it gets [buffnr].snippets = nil

      -- it('should read snippet content correctly', function()
      --     -- Create a new buffer
      --     local bufnr = vim.api.nvim_create_buf(false, true)
      --
      --     -- Make it the current buffer
      --     vim.api.nvim_set_current_buf(bufnr)
      --
      --     -- Set up buffer-local snippets variable
      --     vim.b[bufnr] = {
      --         snippets = {
      --             {
      --                 name = vim.fn.fnamemodify(test_file, ":t"),
      --                 path = test_file
      --             }
      --         }
      --     }
      --
      --     -- Set cursor to first line
      --     vim.api.nvim_win_set_cursor(0, {1, 0})
      --
      --     -- Try to insert the snippet
      --     local success = codecast.insert_snippet(bufnr, 'instant')
      --
      --     -- Assertions
      --     assert.is_true(success)
      --     assert.equals('test content', table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n'))
      --
      --     -- Clean up
      --     vim.api.nvim_buf_delete(bufnr, { force = true })
      -- end)
      --
      it('should handle missing snippets gracefully', function()
          local bufnr = vim.api.nvim_create_buf(false, true)
          local success = codecast.insert_snippet(bufnr, 'instant')
          assert.is_false(success)
          vim.api.nvim_buf_delete(bufnr, { force = true })
      end)

      it('should handle invalid buffer numbers', function()
          local success = codecast.insert_snippet(-1, 'instant')
          assert.is_false(success)
      end)

      it('should handle missing snippet files', function()
          local bufnr = vim.api.nvim_create_buf(false, true)
          vim.b[bufnr] = {
              snippets = {
                  {
                      name = "nonexistent.txt",
                      path = "/nonexistent/path/to/file.txt"
                  }
              }
          }
          vim.api.nvim_win_set_cursor(0, {1, 0})
          local success = codecast.insert_snippet(bufnr, 'instant')
          assert.is_false(success)
          vim.api.nvim_buf_delete(bufnr, { force = true })
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
