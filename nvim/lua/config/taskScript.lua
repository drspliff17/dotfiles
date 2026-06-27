-- Task Script binds

-- Run Task
local function task_run()
  local task = vim.fn.input("Task: ")
  if string.len(task) == 0 then
    return
  end
  local cwd = vim.fn.getcwd()
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

  print("Task: Running " .. task)
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
      "-t",
      cwd,
      "-a",
      title,
      command,
    })
    print("Task: Added " .. title)
  else
    vim.system({
      "task",
      "-i",
      cwd,
      title,
      command,
    })
    print("Task: Init " .. title)
  end
end

vim.keymap.set("n", "<leader>io", task_run, { desc = "Run Task In CWD" })
vim.keymap.set("n", "<leader>ii", task_create, { desc = "Create Task In CWD" })

require("which-key").add({
  { "<leader>i", group = "Task" },
})
