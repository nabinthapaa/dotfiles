function Breadcrumb()
  -- Get the full path of the current file
  local full_path = vim.fn.expand('%:p')

  -- Split the path into parts by directory separator
  local path_parts = {}
  for part in full_path:gmatch("[^/]+") do
    table.insert(path_parts, part)
  end

  -- Get the last two directories and the file name
  local breadcrumb = ""
  if #path_parts > 2 then
    breadcrumb = table.concat(path_parts, '/', #path_parts - 2)
  else
    breadcrumb = table.concat(path_parts, '/')
  end

  return breadcrumb
end

-- Register the Lua function to set winbar
vim.api.nvim_set_option('winbar', '%{%v:lua.Breadcrumb()%}')

return {}
