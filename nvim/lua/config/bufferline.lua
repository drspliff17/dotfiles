local bufferline = require("bufferline")
bufferline.setup({
  options = {
    style_preset = bufferline.style_preset.minimal,
    themable = true,
    indicator = { style = "icon", icon = "  " },

    show_buffer_close_icons = false,
    show_close_icon = false,
    show_buffer_icons = false,
    max_name_length = 21,

    separator_style = "thin",
    always_show_bufferline = false,
    auto_toggle_bufferline = true,
    show_duplicate_prefix = true,

    name_formatter = function(buf)
      return " 󰞦 " .. buf.name .. " 󰞦 "
    end,

    custom_filter = function(buf_number, _)
      local buf_bt = vim.bo[buf_number].buftype
      if buf_bt == "terminal" then
        return false
      end
      return true
    end,
  },
})
