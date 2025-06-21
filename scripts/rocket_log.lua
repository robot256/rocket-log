local tables = require("__flib__.table")
local util = require("util")


local function clear_excess(force_id)
  local max_size = storage.max_size
  if not max_size or max_size < 1 then return end
  --game.print("Purging history of force "..tostring(force_id).." down to "..tostring(max_size).." entries")
  local found_count = 0
  local deleted_count = 0
  -- Newest entries are at end of list, count backwards
  -- This also means that when we remove an entry, the indexes of the items we have yet to check don't change.
  for index=#storage.history,1,-1 do
    if storage.history[index].force_index == force_id then
      found_count = found_count + 1
      if found_count > max_size then
        table.remove(storage.history, index)
        deleted_count = deleted_count + 1
  --      print("deleted entry "..tostring(index))
      else
  --      print("did not delete entry "..tostring(index))
      end
    end
  end
  return deleted_count, found_count
end

local function clear_excess_all()
  local initial_size = #storage.history
  for _,force in pairs(game.forces) do
    clear_excess(force.index)
  end
  local final_size = #storage.history
  if final_size < initial_size then
    game.print({"rocket-log.setting-cleared-history",initial_size-final_size,initial_size,storage.max_size})
  end
end

function OnRocketLaunched(event)
  --game.print("Handling rocket launched event")
  --game.write_file("launchpad_structs.txt", tostring(game.tick).." LAUNCH:\n" .. serpent.block(event), true)
  local launch_contents = util.table.deepcopy(event.launched_contents)
  table.sort(launch_contents, function(a, b) return a.count > b.count end)
  local log_data = {
    launch_time = event.tick,
    force_index = game.forces[event.force_name].index,
    launchpad_id = event.unit_number,
    launchpad = event.launchpad,
    origin_zone_id = event.zone_index,
    origin_zone_name = event.zone_name,
    origin_zone_icon = remote.call("space-exploration", "get_zone_icon", {zone_index = event.zone_index}),
    origin_position = event.launchpad.position,
    contents = launch_contents,
    target_zone_id = event.destination_zone_index,
    target_zone_name = event.destination_zone_name,
    target_zone_icon = event.destination_zone_index and remote.call("space-exploration", "get_zone_icon", {zone_index = event.destination_zone_index}),
    target_position = event.destination_position,
    landingpad_name = event.landing_pad_name,  -- Nil if launching to general area
    landingpad = event.landing_pad,  -- Nil if launching to general area
    launch_trigger = nil,
    launched_players = {},
    landing_failed = nil,
  }
  table.insert(storage.history, log_data)
  clear_excess(log_data.force_index)
end

function OnRocketCrashed(event)
  --log(tostring(game.tick)..": Rocket crashed!")
  --log(serpent.block(event))
  
  -- Update most recent launch from this launchpad to reflect that it crashed
  for idx = #storage.history, 1, -1 do
    local log_data = storage.history[idx]
    if log_data.launchpad_id == event.unit_number then
      if log_data.landingpad_name then
        -- This was a recent launch targeting a launchpad, update log entry
        log_data.landing_failed = true
        log_data.target_position = event.destination_position
    --    game.print(tostring(game.tick)..": Recording rocket crash of "..event.zone_name.." launchpad "..tostring(event.unit_number))
      else
    --    game.print(tostring(game.tick)..": Ignoring rocket crash event launched from "..event.zone_name.." launchpad "..tostring(event.unit_number))
      end
      break
    elseif event.tick > log_data.launch_time + 2000 then
      -- No recent launches in the record
    --  game.print(tostring(game.tick)..": Ignoring rocket crash event launched from "..event.zone_name.." launchpad "..tostring(event.unit_number))
      break
    end
  end
end


function init_events()
  local rocket_event = remote.call("space-exploration", "get_on_cargo_rocket_launched_event")
  script.on_event(rocket_event, OnRocketLaunched)
  local crash_event = remote.call("space-exploration", "get_on_cargo_rocket_padless_event")
  script.on_event(crash_event, OnRocketCrashed)
end

return {
  clear_excess_all = clear_excess_all,
}
