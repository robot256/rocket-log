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
  toolbar.refresh(gui_id)
  rocket_log_gui.window.visible = true
  rocket_log_gui.titlebar.drag_target = rocket_log_gui.window
  rocket_log_gui.window.force_auto_center()
  events_table.create_events_table(gui_id)
end

local function destroy_gui(gui_id)
  local rocket_log_gui = global.guis[gui_id].gui
  rocket_log_gui.window.visible = false
  --global.guis[gui_id] = nil
end

local function open_or_close_gui(player, always_open)
  if always_open then
    open_gui(player)  -- Create new or show existing
  else
    local gui_id = "gui-" .. player.name
    if global.guis[gui_id] then
      local rocket_log_gui = global.guis[gui_id].gui
      if rocket_log_gui.window.visible then
        rocket_log_gui.window.visible = false  -- Hide existing
      else
        open_gui(player)  -- Show existing
      end
    else
      open_gui(player)  -- Create new
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
  open = open_gui
}
