local flib_gui = require("__flib__.gui")
local mod_gui = require("__core__.lualib.mod-gui")
local gui_handlers = require("gui/handlers")

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
        log("Removed rocket log mod gui button from "..player.name)
        break
      end
    end
    return
  end
  
  -- Button already exists
  if flow.rocket_log then
    log("Left in place rocket log mod gui button from "..player.name)
    return
  end
  
  -- Add button
  flib_gui.add(flow, 
    {
      type = "sprite-button",
      name = "rocket_log",
      style = "slot_button",
      sprite = "rocket-log-gui-button",
      handler = gui_handlers.open_rocket_log,
      tooltip = { "rocket-log.mod-gui-tooltip" }
    }
  )
  log("Added rocket log mod gui button to "..player.name)
end

local function destroy_all_mod_gui_buttons()
  for _,player in pairs(game.players) do
    local flow = mod_gui.get_button_flow(player)
    for _,n in pairs(flow.children_names) do
      if n == "rocket_log" then
        flow.rocket_log.destroy()
        log("Removed rocket log mod gui button from "..player.name)
        break
      end
    end
  end
end

-- Check to add button when new players join
script.on_event(defines.events.on_player_joined_game, function(event)
  local player = game.players[event.player_index]
  add_mod_gui_button(player)
end)

-- Check to add button when technology researched
script.on_event(defines.events.on_research_finished, function(event)
  if event.research.name == UNLOCK_TECH_NAME then
    for _, player in pairs(event.research.force.players) do
      add_mod_gui_button(player)
    end
  end
end)

-- Check to remove button when technology unresearched
script.on_event(defines.events.on_research_reversed, function(event)
  if event.research.name == UNLOCK_TECH_NAME then
    for _, player in pairs(event.research.force.players) do
      add_mod_gui_button(player)
    end
  end
end)

return {
    add_mod_gui_button = add_mod_gui_button,
    destroy_all_mod_gui_buttons = destroy_all_mod_gui_buttons
}
