local events_table = require("gui/events_table")
local time_filter = require("filter-time")
local rocket_log = require("rocket_log")

local function refresh(gui_id)
  events_table.create_events_table(gui_id)
  -- gui_contents.scroll_pane.scroll_to_bottom() -- Doesn't work. Perhaps needs to wait a tick?
end

local function handle_action(action, event)
  local rocket_log_gui = global.guis[action.gui_id]
  if action.action == "clear-older" then
    local older_than = game.tick - time_filter.ticks(rocket_log_gui.gui.filter.time_period.selected_index)
    local player = game.players[event.player_index]
    local force = player.force
    rocket_log.clear_older(event.player_index, older_than)
    force.print { "rocket-log.player-cleared-history", player.name }
  end
  if action.action == "refresh" then
    refresh(action.gui_id)
  end
  if action.action == "filter" then
    if action.filter == "item" and game.item_prototypes[action.value] then
      rocket_log_gui.gui.filter.item.elem_value = action.value
      action.action = "apply-filter"
    end
    if action.filter == "zone" then
      rocket_log_gui.gui.filter.zone_name.text = action.value
      action.action = "apply-filter"
    end
  end
  if action.action == "apply-filter" then
    refresh(action.gui_id)
  end
  if action.action == "clear-filter" then
    local filter_guis = rocket_log_gui.gui.filter
    filter_guis.zone_name.text = ""
    filter_guis.item.elem_value = nil
    refresh(action.gui_id)
  end
end

local function create_toolbar(gui_id)
  return {
    type = "flow",
    direction = "vertical",
    children = {
      {
        type = "flow",
        direction = "horizontal",
        children = {
          {
            type = "label",
            caption = { "rocket-log.filter-time-period-label" }
          },
          {
            type = "drop-down",
            items = time_filter.time_period_items,
            selected_index = time_filter.default_index,
            ref = { "filter", "time_period" },
            actions = {
              on_selection_state_changed = { type = "toolbar", action = "refresh", gui_id = gui_id }
            }
          },
          {
            type = "button",
            caption = { "rocket-log.refresh" },
            tooltip = { "rocket-log.refresh" },
            actions = {
              on_click = { type = "toolbar", action = "refresh", gui_id = gui_id }
            }
          },
          {
            type = "button",
            style = "red_button",
            caption = { "rocket-log.clear-older" },
            actions = {
              on_click = { type = "toolbar", action = "clear-older", gui_id = gui_id }
            }
          }
        }
      },
      {
        type = "flow",
        direction = "horizontal",
        children = {
          {
            type = "flow",
            direction = "vertical",
            children = {
                {
                  type = "label",
                  caption = { "rocket-log.filter-zone-name" }
                },
                {
                  type = "textfield",
                  tooltip = { "rocket-log.filter-zone-name" },
                  ref = { "filter", "zone_name" },
                  actions = {
                    on_confirmed = {
                        type = "toolbar", action = "apply-filter", gui_id = gui_id,
                        filter = "zone_name"
                    }
                  }
                }
            }
          },
          {
            type = "flow",
            direction = "horizontal",
            children = {
              {
                type = "label",
                caption = { "rocket-log.filter-item-label" }
              },
              {
                type = "choose-elem-button",
                elem_type = "item",
                tooltip = { "rocket-log.filter-item-tooltip" },
                ref = { "filter", "item" },
                actions = {
                  on_elem_changed = {
                      type = "toolbar", action = "apply-filter", gui_id = gui_id,
                      filter = "item"
                  }
                }
              },
              {
                type = "button",
                caption = { "rocket-log.filter-clear" },
                tooltip = { "rocket-log.filter-clear" },
                actions = {
                  on_click = { type = "toolbar", action = "clear-filter", gui_id = gui_id }
                }
              }
            }
          }
        }
      },
    }
  }
end

return {
    handle_action = handle_action,
    create_toolbar = create_toolbar
}
