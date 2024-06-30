local events = require("__flib__.event")

rocket_log_gui = require("gui/main_gui")
rocket_log = require("scripts/rocket_log")
rocket_gui_button = require("gui/mod_gui_button")

events.on_init(function()
  global.guis = {}
  global.history = {}
  init_events()
  -- When first installing the mod, add button for any player who has researched cargo rockets
  for _, player in pairs(game.players) do
    rocket_gui_button.add_mod_gui_button(player)
  end
  global.max_size = settings.global["rocket-log-retention-depth"].value
end)

events.on_load(init_events)

events.on_configuration_changed(function()
  init_events()
  rocket_log_gui.kill_all_guis()
  -- Make sure everybody has the right GUI button after an update
  for _, player in pairs(game.players) do
    rocket_gui_button.add_mod_gui_button(player)
  end
  -- Make sure the current setting of retention depth is respected
  global.max_size = settings.global["rocket-log-retention-depth"].value
  rocket_log.clear_excess_all()
end)

events.register("rocket-log-open", function(event)
	rocket_log_gui.open_or_close_gui(game.players[event.player_index])
end)

events.on_gui_closed(function(event)
  local player = game.players[event.player_index]
  -- Close ourselves if any custom window is closed.
  if event.gui_type == defines.gui_type.custom then
    rocket_log_gui.close(player)
  end
end)

events.on_gui_opened(function(event)
  local player = game.players[event.player_index]
  -- Try to close ourselves if another window is opened.
  if event.gui_type ~= defines.gui_type.custom then
    rocket_log_gui.close(player)
  end
end)


-- Check to add or remove button when player changes setting
events.on_runtime_mod_setting_changed( function(event)
  if event.setting == "rocket-log-mod-button" then
    if event.player_index and game.players[event.player_index] then
      rocket_log_gui.add_mod_gui_button(game.players[event.player_index])
    end
  elseif event.setting == "rocket-log-retention-depth" then
    global.max_size = settings.global["rocket-log-retention-depth"].value
    rocket_log.clear_excess_all()
    rocket_log_gui.refresh_all_guis()
  end
end)


------------------------------------------------------------------------------------
--                    FIND LOCAL VARIABLES THAT ARE USED GLOBALLY                 --
--                              (Thanks to eradicator!)                           --
------------------------------------------------------------------------------------
--setmetatable(_ENV,{
--  __newindex=function (self,key,value) --locked_global_write
--    error('\n\n[ER Global Lock] Forbidden global *write*:\n'
--      .. serpent.line{key=key or '<nil>',value=value or '<nil>'}..'\n')
--    end,
--  __index   =function (self,key) --locked_global_read
--    error('\n\n[ER Global Lock] Forbidden global *read*:\n'
--      .. serpent.line{key=key or '<nil>'}..'\n')
--    end ,
--  })

if script.active_mods["gvv"] then require("__gvv__.gvv")() end
