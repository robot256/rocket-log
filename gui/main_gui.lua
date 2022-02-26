local gui = require("__flib__.gui-beta")
local toolbar = require("gui/toolbar")
local events_table = require("gui/events_table")

local function header(gui_id)
  return {
    type = "flow",
    ref = {"titlebar"},
    children = {
      {type = "label", style = "frame_title", caption = {"rocket-log.header"}, ignored_by_interaction = true},
      {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
      {
        type = "sprite-button",
        style = "frame_action_button",
        sprite = "utility/close_white",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        actions = {
          on_click = { type = "generic", action = "close-window", gui_id = gui_id },
        }
      }
    }
  }
end

local function open_gui(player)
  local gui_id = "gui-" .. player.name
  if not global.guis[gui_id] then
    --game.print(tostring(game.tick).." creating new gui")
    
    local gui_contents = {
      {
        type = "frame",
        direction = "vertical",
        ref = { "window" },
        children = {
          header(gui_id),
          toolbar.create_toolbar(gui_id),
          {
            type = "tabbed-pane",
            ref = { "tabs", "pane" },
            children = {
              {
                tab = {
                  type = "tab",
                  caption = { "rocket-log.tab-events" }
                },
                content = {
                  type = "flow",
                  direction = "vertical",
                  ref = { "tabs", "events_contents" }
                }
              },
              {
                tab = {
                  type = "tab",
                  caption = { "rocket-log.tab-summary" }
                },
                content = {
                  type = "flow",
                  direction = "vertical",
                  ref = { "tabs", "summary_contents" }
                }
              }
            }
          },
        }
      }
    }
    global.guis[gui_id] = {
      gui_id = gui_id,
      gui = gui.build(player.gui.screen, gui_contents),
      player = player
    }
  end
  local rocket_log_gui = global.guis[gui_id].gui
  if player.opened and player.opened ~= rocket_log_gui.window then
    --game.print(tostring(game.tick).." closing other gui before opening rocketlog")
    player.opened = nil
  end
  toolbar.refresh(gui_id)
  rocket_log_gui.window.visible = true
  rocket_log_gui.titlebar.drag_target = rocket_log_gui.window
  rocket_log_gui.window.force_auto_center()
  player.opened = rocket_log_gui.window
  --game.print(tostring(player.opened))
  --game.print(tostring(game.tick).." showing rocketlog gui")
  events_table.create_events_table(gui_id)
  
end

local function destroy_gui(gui_id)
  if global.guis[gui_id] then
    --game.print(tostring(game.tick).." hiding gui")
    local rocket_log_gui = global.guis[gui_id].gui
    rocket_log_gui.window.visible = false
    if global.guis[gui_id].player.opened == rocket_log_gui.window then
      global.guis[gui_id].player.opened = nil
      --game.print(tostring(game.tick).." player cleared")
    end
    --global.guis[gui_id] = nil
  --else
    --game.print(tostring(game.tick).." no gui to hide")
  end
end

local function close_gui(player)
  local gui_id = "gui-" .. player.name
  -- Ignore close requests if we are not already open
  if global.guis[gui_id] and global.guis[gui_id].gui.window.visible then
    destroy_gui(gui_id)
  end
end

local function open_or_close_gui(player, always_open)
  local gui_id = "gui-" .. player.name
  if (not always_open) and global.guis[gui_id] and global.guis[gui_id].gui.window.visible then
    destroy_gui(gui_id)  -- Hide existing gui
  else
    open_gui(player)   -- Create new or show existing gui
  end
end

-- Close all player GUIs so they can be recreated (for migrations)
local function kill_all_guis()
  for gui_id, gui_data in pairs(global.guis) do
    gui_data.gui.window.destroy()
  end
  global.guis = {}
end

local function refresh_all_guis()
  for gui_id, gui_data in pairs(global.guis) do
    if gui_data.gui.visible then
      toolbar.refresh(gui_id)
    end
  end
end

local function handle_action(action, event)
  if action.action == "close-window" then
      destroy_gui(action.gui_id)
  end
  if action.action == "open-rocket-log" then -- mod-gui-button
    local player = game.players[event.player_index]
    open_or_close_gui(player, event.control or event.shift)
  end
end

gui.hook_events(function(event)
	local action = gui.read_action(event)
	if action then
    if action.type == "generic" then
      handle_action(action, event)
    elseif action.type == "table" then
      events_table.handle_action(action, event)
    elseif action.type == "toolbar" then
      toolbar.handle_action(action, event)
    end
	end
end)

return {
  open_or_close_gui = open_or_close_gui,
  open = open_gui,
  close = close_gui,
  kill_all_guis = kill_all_guis,
  refresh_all_guis = refresh_all_guis
}
