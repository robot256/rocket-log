local rocket_gui_button = require("gui/mod_gui_button")

-- Migrate landing pad references to new entities that are not at the same position as the old ones
local function landingpad_hash(entry)
  return tostring(entry.target_zone_id)..":"..entry.landingpad_name..":"..tostring(entry.target_position.x)..","..tostring(entry.target_position.y)
end

function migrate_landingpads()
  log("Migrating Rocket Log landing pad entity references")

  local landingpad_cache = {}  -- Cache new landing pad references

  for _,entry in pairs(storage.history) do
    
    if entry.landingpad_name and entry.target_position then
      local hash = landingpad_hash(entry)
      local new_landingpad = landingpad_cache[hash]
      if not new_landingpad then
        local surface = remote.call("space-exploration", "zone_get_surface", {zone_index=entry.target_zone_id})
        if surface then
          local found_pad = surface.find_entities_filtered{name="cargo-landing-pad", position=entry.target_position, limit=1}[1]
          if found_pad then
            local new_name = remote.call("space-exploration", "get_landing_pad_name", {unit_number=found_pad.unit_number})
            if new_name and new_name == entry.landingpad_name then
              new_landingpad = found_pad
            else
              log("Looking for "..entry.landingpad_name..", found "..tostring(new_name))
            end
          end
        end
        if not new_landingpad then
          new_landingpad = "none"
        end
        landingpad_cache[hash] = new_landingpad
      end
      if new_landingpad ~= "none" then
        entry.landingpad = new_landingpad
      end
    end
    
  end

  log("Migrated "..#storage.history.." rocket log history entries for the following landingpads:")
  log(serpent.block(landingpad_cache))

  -- Also destroy all mod gui buttons so it can be recreated with the new handler system
  rocket_gui_button.destroy_all_mod_gui_buttons()

end
