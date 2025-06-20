-- Migrate the old get_contents format to the new get_contents format.

for index=1,#storage.history do
  local new_contents = {}
  for name,count in pairs(storage.history[index].contents) do
    table.insert(new_contents, {name=name, count=count, quality="normal"})
  end
  table.sort(new_contents, function(a, b) return a.count > b.count end)
  storage.history[index].contents = new_contents
end
