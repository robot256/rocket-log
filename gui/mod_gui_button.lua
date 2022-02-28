local mod_gui = require("__core__.lualib.mod-gui")
local events = require("__flib__.event")

local UNLOCK_TECH_NAME = "se-rocket-launch-pad"


local function add_mod_gui_button(player)
  local flow = mod_gui.get_button_flow(player)
  
  -- Player only gets button if they have reseached cargo rockets AND have the setting enabled
  if (not player.force.technologies[UNLOCK_TECH_NAME]) or 
     (not player.force.technologies[UNLOCK_TECH_NAME].researched) or
     (not player.mod_settings["rocket-log-mod-button"] or not player.mod_settings["rocket-log-mod-button"].value) then
    local index = nil
    for _,n in pairs(flow.children_names) do
      if n == "rocket_log" then
        flow.rocket_log.destroy()
        break
      end
    end
    return
  end
  
  -- Button already exists
  if flow.rocket_log then
    return
  end
  
  -- Add button
  flow.add {
    type = "sprite-button",
    name = "rocket_log",
    style = "slot_button",
    sprite = "rocket-log-gui-button",
    tags = {
      [script.mod_name] = {
        flib = {
          on_click = { type = "generic", action = "open-rocket-log" }
        }
      }
    },
    tooltip = { "rocket-log.mod-gui-tooltip" }
  }
end

-- Check to add button when new players join
events.on_player_joined_game( function(event)
  local player = game.players[event.player_index]
  add_mod_gui_button(player)
end)

-- Check to add button when technology researched
events.on_research_finished( function(event)
  if event.research.name == UNLOCK_TECH_NAME then
    for _, player in pairs(event.research.force.players) do
      add_mod_gui_button(player)
    end
  end
end)

-- Check to remove button when technology unresearched
events.on_research_reversed( function(event)
  if event.research.name == UNLOCK_TECH_NAME then
    for _, player in pairs(event.research.force.players) do
      add_mod_gui_button(player)
    end
  end
end)

-- Check to add or remove button when player changes setting
events.on_runtime_mod_setting_changed( function(event)
  if event.setting == "rocket-log-mod-button" and event.player_index and game.players[event.player_index] then
    add_mod_gui_button(game.players[event.player_index])
  end
end)

return {
    add_mod_gui_button = add_mod_gui_button
}
