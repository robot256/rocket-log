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
  game.print("Handling rocket launched event")
  local struct = event.struct
  local log_data = {
    launch_time = game.tick,
    force_index = struct.container.force.index,
    launchpad_id = struct.unit_number,
    launchpad = struct.container,
    origin_zone_id = struct.zone.index,
    origin_zone_name = struct.zone.name,
    origin_zone_icon = remote.call("space-exploration", "get_zone_icon", {zone_index = struct.zone.index}),
    origin_position = struct.container.position,
    contents = util.table.deepcopy(struct.launched_contents),
    target_zone_id = struct.destination.zone.index,
    target_zone_name = struct.destination.zone.name,
    target_zone_icon = remote.call("space-exploration", "get_zone_icon", {zone_index = struct.destination.zone.index}),
    target_position = struct.launching_to_destination.position,
    landingpad_name = struct.launching_to_destination.landing_pad_name,  -- Nil if launching to general area
    landingpad = struct.launching_to_destination.landing_pad and struct.launching_to_destination.landing_pad.container,
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
