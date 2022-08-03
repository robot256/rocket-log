local events = require("__flib__.event")
local tables = require("__flib__.table")
local util = require("util")


local function clear_older(player_index, older_than)
  local force_index = game.players[player_index].force.index
  local initial_size = #global.history
  global.history = tables.filter(global.history, function(v)
      return v.force_index ~= force_index or v.launch_time >= older_than
    end,
    true)
  return initial_size - #global.history
end


function OnRocketLaunched(event)
  --game.print("Handling rocket launched event")
  --game.write_file("launchpad_structs.txt", tostring(game.tick).." LAUNCH:\n" .. serpent.block(event), true)
  local log_data = {
    launch_time = event.tick,
    force_index = game.forces[event.force_name].index,
    launchpad_id = event.unit_number,
    launchpad = event.launchpad,
    origin_zone_id = event.zone_index,
    origin_zone_name = event.zone_name,
    origin_zone_icon = remote.call("space-exploration", "get_zone_icon", {zone_index = event.zone_index}),
    origin_position = event.launchpad.position,
    contents = util.table.deepcopy(event.launched_contents),
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
  table.insert(global.history, log_data)
end

function OnRocketCrashed(event)
  log(tostring(game.tick)..": Rocket crashed!")
  log(serpent.block(event))
  
  -- Update most recent launch from this launchpad to reflect that it crashed
  for idx = #global.history, 1, -1 do
    if global.history[idx].launchpad_id == event.unit_number then
      local log_data = global.history[idx]
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
  events.register(rocket_event, OnRocketLaunched)
  local crash_event = remote.call("space-exploration", "get_on_cargo_rocket_padless_event")
  events.register(crash_event, OnRocketCrashed)
end

return {
  clear_older = clear_older,
}
