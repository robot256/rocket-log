-- Migrate the old get_contents format to the new get_contents format.
log("Migrating Rocket Log item contents data format. This might take a while")

for _,entry in pairs(storage.history) do
  local new_contents = {}
  for name,count in pairs(entry.contents) do
    table.insert(new_contents, {name=name, count=count, quality="normal"})
  end
  table.sort(new_contents, function(a, b) return a.count > b.count end)
  entry.contents = new_contents
end

log("Migrated contents of "..#storage.history.." rocket log history entries.")
