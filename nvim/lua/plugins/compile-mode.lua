return {
  "ej-shafran/compile-mode.nvim",
  version = "^5.0.0",

  dependencies = {
    "nvim-lua/plenary.nvim",
  },

  config = function()
    ---@module "compile-mode"
    ---@type CompileModeOpts
    vim.g.compile_mode = {
      default_command = function()
        local ft = vim.bo.filetype

        if ft == "odin" then
          if vim.fn.isdirectory("src") == 1 then
            return "odin build src"
          end
          return "odin build ."
        end

        return ""
      end,

      -- Control how ANSI escape sequences are handled in compilation output.
      ansi_color = {
        kind = "filter",
      },

      -- Expand commands like :!
      bang_expansion = false,

      -- Additional entering/leaving directory regexes.
      directory_change_matchers = {},

      -- Additional error regexes.
      error_regexp_table = {},

      -- Filename regexes to ignore errors from.
      error_ignore_file_list = {},

      -- Minimum error level to jump to.
      error_threshold = require("compile-mode").level.WARNING,

      -- Automatically jump to the first error.
      auto_jump_to_first_error = false,

      -- How long to highlight an error location.
      error_locus_highlight = 500,

      -- Use diagnostics instead of opening compilation buffer.
      use_diagnostics = false,

      -- :Recompile falls back to :Compile if there is no previous command.
      recompile_no_fail = true,

      -- Ask to save unsaved buffers before compiling.
      ask_about_save = true,

      -- Ask before interrupting an already-running command.
      ask_to_interrupt = true,

      -- Compilation buffer name.
      buffer_name = "*compilation*",

      -- Time format shown in compilation buffer.
      time_format = "%a %b %e %H:%M:%S",

      -- Maximum number of lines in compilation buffer.
      max_lines = 20,

      -- Regexes to hide from compilation output.
      hidden_output = {},

      -- Environment passed to commands.
      environment = nil,

      -- Clear environment before running.
      clear_environment = false,

      -- Completion support.
      input_word_completion = true,

      -- Hide compilation buffer from buffer list.
      hidden_buffer = true,

      -- Focus compilation buffer after starting.
      focus_compilation_buffer = true,

      -- Keep compilation buffer scrolled to the end.
      auto_scroll = true,

      -- Wrap NextError / PrevError around.
      use_circular_error_navigation = false,

      -- Debug logging.
      debug = false,

      -- Run command using a PTY.
      use_pseudo_terminal = true,

      -- OSC handling.
      ansi_osc = {
        kind = "render",
        handlers = {},
      },
    }

    -- Compilation window size
    local compile_ui_group = vim.api.nvim_create_augroup("compile_mode_ui", { clear = true })

    local function resize_compile_window(buf)
      vim.schedule(function()
        for _, win in ipairs(vim.fn.win_findbuf(buf)) do
          if vim.api.nvim_win_is_valid(win) then
            -- Compilation window = ~20% of editor height.
            local height = math.max(6, math.floor(vim.o.lines * 0.20))

            vim.api.nvim_win_set_height(win, height)

            -- Prevent Neovim from growing this split automatically.
            vim.wo[win].winfixheight = true
          end
        end
      end)
    end

    -- First time compile-mode creates the compilation buffer.
    vim.api.nvim_create_autocmd("FileType", {
      group = compile_ui_group,
      pattern = "compilation",

      callback = function(ev)
        if vim.b[ev.buf].compilation_main_buffer then
          resize_compile_window(ev.buf)
        end
      end,
    })

    -- Handle reopening an existing compilation buffer.
    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = compile_ui_group,

      callback = function(ev)
        if vim.b[ev.buf].compilation_main_buffer then
          resize_compile_window(ev.buf)
        end
      end,
    })

    -- Compile-command input
    local async = require("plenary.async")
    local compile_utils = require("compile-mode.utils")
    local Snacks = require("snacks")

    local original_compile_input = compile_utils.input
    local bottom_compile_input = async.wrap(function(opts, callback)
      Snacks.input(
        vim.tbl_deep_extend("force", opts, {
          icon = "",
          icon_pos = false,
          prompt_pos = "left",
          expand = false,
          win = {
            style = "input",
            position = "bottom",
            height = 1,
            width = 0,
            border = "top",

            keys = {
              ctrl_q = {
                "<C-q>",
                "cancel",
                mode = { "i", "n" },
              },
            },
          },
        }),
        callback
      )
    end, 2)

    compile_utils.input = function(opts)
      if opts.prompt == "Compile command: " then
        return bottom_compile_input(opts)
      end
      return original_compile_input(opts)
    end
  end,
}
