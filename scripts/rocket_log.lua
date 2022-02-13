local events = require("__flib__.event")
local tables = require("__flib__.table")
local util = require("util")


local function clear_older(player_index, older_than)
  -- TODO: Auto-delete events after 6h or so?
  local force_index = game.players[player_index].force.index
  global.history = tables.filter(global.history, function(v)
      return v.force_index ~= force_index or v.launch_time >= older_than
    end,
    true)
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

function init_events()
  local rocket_event = remote.call("space-exploration", "get_on_cargo_rocket_launched_event")
  events.register(rocket_event, OnRocketLaunched)
end

return {
  clear_older = clear_older,
}
