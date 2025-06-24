local flib_gui = require("__flib__.gui")
local toolbar = require("gui/toolbar")
local events_table = require("gui/events_table")
local gui_handlers = require("gui/handlers")

local function header(gui_id)
  return {
    type = "flow",
    name = "titlebar",
    children = {
      {type = "label", style = "frame_title", caption = {"rocket-log.header"}, ignored_by_interaction = true},
      {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
      {
        type = "sprite-button",
        style = "frame_action_button",
        sprite = "utility/close",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        handler = gui_handlers.close_window,
        tags = {
            gui_id = gui_id
        }
      }
    }
  }
end

local function open_gui(player)
  local gui_id = "gui-" .. player.name
  if not storage.guis[gui_id] then
    --game.print(tostring(game.tick).." creating new gui")
    log("Creating new gui for "..gui_id)
    local gui_contents = {
      {
        type = "frame",
        direction = "vertical",
        name = "rocket-log-window",
        children = {
          header(gui_id),
          toolbar.create_toolbar(gui_id),
          {
            type = "tabbed-pane",
            name = "tabs_pane",
            children = {
              {
                tab = {
                  type = "tab",
                  caption = { "rocket-log.tab-events" }
                },
                content = {
                  type = "flow",
                  direction = "vertical",
                  name = "events_contents"
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
                  name = "summary_contents"
                }
              }
            }
          },
        }
      }
    }
    local _,new_gui = flib_gui.add(player.gui.screen, gui_contents)
    log(new_gui.name)
    local filter_guis = {
      time_period = new_gui.toolbar.row1.filter_time_period,
      origin_list = new_gui.toolbar.row2.filter_origin_list,
      target_list = new_gui.toolbar.row2.filter_target_list,
      item = new_gui.toolbar.row2.filter_item,
      stats = new_gui.toolbar.row1.filter_stats
    }
    storage.guis[gui_id] = {
      gui_id = gui_id,
      gui = new_gui,
      player = player,
      filter_guis = filter_guis,
      events_contents = new_gui.tabs_pane.events_contents,
      summary_contents = new_gui.tabs_pane.summary_contents
    }
  end
  local rocket_log_gui = storage.guis[gui_id]
  if player.opened and player.opened ~= rocket_log_gui.gui then
    --game.print(tostring(game.tick).." closing other gui before opening rocketlog")
    player.opened = nil
  end
  toolbar.refresh(gui_id)
  rocket_log_gui.gui.visible = true
  rocket_log_gui.gui.titlebar.drag_target = rocket_log_gui.gui
  rocket_log_gui.gui.force_auto_center()
  player.opened = rocket_log_gui.gui
  --game.print(tostring(player.opened))
  --game.print(tostring(game.tick).." showing rocketlog gui")
  events_table.create_events_table(gui_id)
  
end

local function destroy_gui(gui_id)
  if storage.guis[gui_id] then
    --game.print(tostring(game.tick).." hiding gui")
    local rocket_log_gui = storage.guis[gui_id]
    rocket_log_gui.gui.visible = false
    if storage.guis[gui_id].player.opened == rocket_log_gui.gui then
      storage.guis[gui_id].player.opened = nil
      --game.print(tostring(game.tick).." player cleared")
    end
    --storage.guis[gui_id] = nil
  --else
    --game.print(tostring(game.tick).." no gui to hide")
  end
end

local function close_gui(player)
  local gui_id = "gui-" .. player.name
  -- Ignore close requests if we are not already open
  if storage.guis[gui_id] and storage.guis[gui_id].gui.visible then
    destroy_gui(gui_id)
  end
end

local function open_or_close_gui(player, always_open)
  local gui_id = "gui-" .. player.name
  if (not always_open) and storage.guis[gui_id] and storage.guis[gui_id].gui.visible then
    destroy_gui(gui_id)  -- Hide existing gui
  else
    open_gui(player)   -- Create new or show existing gui
  end
end

-- Close all player GUIs so they can be recreated (for migrations)
local function kill_all_guis()
  for gui_id, gui_data in pairs(storage.guis) do
    gui_data.gui.destroy()
  end
  storage.guis = {}
end

local function refresh_all_guis()
  for gui_id, gui_data in pairs(storage.guis) do
    if gui_data.gui.visible then
      toolbar.refresh(gui_id)
    end
  end
end


-- Handle actions when clicking the mod gui button or close button
function gui_handlers.close_window(event)
  local gui_id = event.element.tags.gui_id
  destroy_gui(gui_id)
end

function gui_handlers.open_rocket_log(event)
  local player = game.players[event.player_index]
  open_or_close_gui(player, event.control or event.shift)
end

-- Handle actions when clicking on the launch and landing pad buttons
function gui_handlers.view_position(event)
  local player = event.player_index and game.players[event.player_index]
  local action = event.element.tags.action
  local zone_name = event.element.tags.zone_name
  local position = event.element.tags.position
  --game.print(tostring(game.tick)..tostring(player.opened))
  
  if player and (action == "remote-view" or action == "container-gui") and
     remote.call("space-exploration", "remote_view_is_unlocked", {player=player}) then
    --game.print(tostring(game.tick).." closing rocketlog gui because remote view")
    close_gui(player)  -- Must close the GUI before entering remote view for the first time, or the controller becomes disconnected.
    remote.call("space-exploration", "remote_view_start", {player=player, zone_name=zone_name, position=position, freeze_history=true})
    
    if action == "container-gui" and event.button == defines.mouse_button_type.right then
      local surface = remote.call("space-exploration", "zone_get_surface", {zone_index = remote.call("space-exploration", "get_zone_from_name", {zone_name=zone_name}).index})
      if surface and surface.valid then
        local container = surface.find_entities_filtered{type={"container","cargo-landing-pad"}, position=position, limit=1}
        if container and container[1] and container[1].valid then
          --game.print(tostring(game.tick).." opening launchpad gui")
          player.opened = container[1]
        end
      end
    end
  end
end

flib_gui.add_handlers(gui_handlers, function(e, handler)
    handler(e)
end)

return {
  open_or_close_gui = open_or_close_gui,
  open = open_gui,
  close = close_gui,
  kill_all_guis = kill_all_guis,
  refresh_all_guis = refresh_all_guis
}
