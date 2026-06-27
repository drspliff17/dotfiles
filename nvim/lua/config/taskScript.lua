-- Task Script binds

-- Run Task
local function task_run()
  local cwd = vim.fn.getcwd()
  local task_file = cwd .. "/ds_task.json"
  local stat = vim.uv.fs_stat(task_file)
  if not stat then
    return
  end
  print("Context: " .. cwd)
  local task = vim.fn.input("Task: ")
  if string.len(task) == 0 then
    return
  end
  local runMode = "-t"
  if task:match("^%d+$") then
    runMode = "-i"
  end
  vim.system({
    "task",
    "-t",
    cwd,
    "-r",
    runMode,
    task,
  })

  print("Task: Running " .. task .. " [" .. cwd .. "]")
end

-- Init/Add Task
local function task_create()
  local cwd = vim.fn.getcwd()
  local task_file = cwd .. "/ds_task.json"
  local stat = vim.uv.fs_stat(task_file)
  local tstr

  if not stat then
    tstr = "Taskfile Init"
  else
    tstr = "Taskfile Add"
  end

  print("Context: " .. cwd)
  local title = vim.fn.input(tstr .. ": Enter Task Title: ")
  if string.len(title) == 0 then
    return
  end

  local command = vim.fn.input(tstr .. ": Enter Task Command: ")
  if string.len(command) == 0 then
    return
  end

  if stat and stat.type == "file" then
    vim.system({
      "task",
      "-np",
      "-t",
      cwd,
      "-a",
      title,
      command,
    })
    print("Task: Added " .. title .. " ➡️ [" .. cwd .. "]")
  else
    vim.system({
      "task",
      "-i",
      cwd,
      title,
      command,
    })
    print("Task: Init " .. title .. " ➡️ [" .. cwd .. "]")
  end
end

local function task_delete()
  local cwd = vim.fn.getcwd()
  local task_file = cwd .. "/ds_task.json"
  local stat = vim.uv.fs_stat(task_file)

  if not stat then
    return
  end

  print("Context: " .. cwd)

  local input = vim.fn.input("Taskfile Remove: Enter Index(es): ")
  if input == "" then
    return
  end

  local indices = {}
  for index in input:gmatch("%S+") do
    table.insert(indices, tonumber(index))
  end

  table.sort(indices, function(a, b)
    return a > b
  end)

  for _, index in ipairs(indices) do
    vim
      .system({
        "task",
        "-t",
        cwd,
        "-d",
        tostring(index),
      })
      :wait()
  end
end

local function task_list()
  local cwd = vim.fn.getcwd()
  local task_file = cwd .. "/ds_task.json"
  local stat = vim.uv.fs_stat(task_file)

  if not stat then
    return
  end

  vim.system({
    "task",
    "-t",
    cwd,
    "-df",
  })
end

local function task_delete_file()
  local cwd = vim.fn.getcwd()
  local task_file = cwd .. "/ds_task.json"
  local stat = vim.uv.fs_stat(task_file)

  if not stat then
    return
  end
  print("Context: " .. task_file)
  local input = vim.fn.input("Confirm task file deletion? (leave blank to abort)")
  if string.len(input) == 0 then
    return
  end

  vim.system({
    "rm",
    task_file,
  })

  print("Deleted " .. task_file)
end

vim.keymap.set("n", "<leader>io", task_run, { desc = "Run Task In CWD" })
vim.keymap.set("n", "<leader>ii", task_create, { desc = "Create Task In CWD" })
vim.keymap.set("n", "<leader>ir", task_delete, { desc = "Remove Task(s) In CWD" })
vim.keymap.set("n", "<leader>il", task_list, { desc = "List Tasks In CWD" })
vim.keymap.set("n", "<leader>iq", task_delete_file, { desc = "Delete Taskfile In CWD" })

require("which-key").add({
  { "<leader>i", group = "Task Runner" },
})
