local events = require("__flib__.event")

rocket_log_gui = require("gui/main_gui")
require("rocket_log")
require("gui/mod_gui_button")

events.on_init(function()
    global.guis = {}
    global.history = {}
    global.rockets = {}
    init_events()
end)
events.on_load(init_events)
events.on_configuration_changed(init_events)

events.register("rocket-log-open", function(event)
	rocket_log_gui.open_or_close_gui(game.players[event.player_index])
end)


------------------------------------------------------------------------------------
--                    FIND LOCAL VARIABLES THAT ARE USED GLOBALLY                 --
--                              (Thanks to eradicator!)                           --
------------------------------------------------------------------------------------
setmetatable(_ENV,{
  __newindex=function (self,key,value) --locked_global_write
    error('\n\n[ER Global Lock] Forbidden global *write*:\n'
      .. serpent.line{key=key or '<nil>',value=value or '<nil>'}..'\n')
    end,
  __index   =function (self,key) --locked_global_read
    error('\n\n[ER Global Lock] Forbidden global *read*:\n'
      .. serpent.line{key=key or '<nil>'}..'\n')
    end ,
  })

if script.active_mods["gvv"] then require("__gvv__.gvv")() end
