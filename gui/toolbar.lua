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
    if action.filter == "zone_index" then
      rocket_log_gui.gui.filter.zone_index.text = (action.value and tostring(action.value)) or ""
      action.action = "apply-filter"
    end
    if action.filter == "zone_name" then
      rocket_log_gui.gui.filter.zone_name.text = action.value
      action.action = "apply-filter"
    end
  end
  if action.action == "apply-filter" then
    -- Validate the zone index selection
    if rocket_log_gui.gui.filter.zone_index.text ~= "" then
      local zone_index = tonumber(rocket_log_gui.gui.filter.zone_index.text)
      local zone = remote.call("space-exploration", "get_zone_from_zone_index", {zone_index = zone_index})
      if zone then
        -- Update name field to match if the zone is good
        rocket_log_gui.gui.filter.zone_name.text = zone.name
        rocket_log_gui.gui.filter.zone_icon.sprite = remote.call("space-exploration", "get_zone_icon", {zone_index = zone_index})
      else
        filter_guis.zone_index.text = ""
        rocket_log_gui.gui.filter.zone_icon.sprite = "utility/missing_icon"
      end
    end
    refresh(action.gui_id)
  end
  if action.action == "clear-filter" then
    local filter_guis = rocket_log_gui.gui.filter
    filter_guis.zone_name.text = ""
    filter_guis.item.elem_value = nil
    filter_guis.zone_index.text = ""
    rocket_log_gui.gui.filter.zone_icon.sprite = "utility/missing_icon"
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
            type = "sprite-button",
            sprite = "utility/refresh",
            style = "item_and_count_select_confirm",
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
            type = "label",
            caption = { "rocket-log.filter-zone-label" }
          },
          {
            type = "sprite-button",
            sprite = "utility/missing_icon",
            tooltip = { "rocket-log.filter-zone-icon-tooltip" },
            ref = { "filter", "zone_icon" },
            actions = {
              on_click = { type = "toolbar", action = "select-zone", gui_id = gui_id }
            }
          },
          {
            type = "textfield",
            tooltip = { "rocket-log.filter-zone-index-tooltip" },
            numeric = true,
            style = "very_short_number_textfield",
            ref = { "filter", "zone_index" },
            actions = {
              on_confirmed = {
                  type = "toolbar", action = "apply-filter", gui_id = gui_id
              }
            }
          },
          {
            type = "textfield",
            tooltip = { "rocket-log.filter-zone-text-tooltip" },
            ref = { "filter", "zone_name" },
            actions = {
              on_confirmed = {
                  type = "toolbar", action = "apply-filter", gui_id = gui_id
              }
            }
          },
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
                  type = "toolbar", action = "apply-filter", gui_id = gui_id
              }
            }
          },
          {
            type = "sprite-button",
            sprite = "se-search-close-white",
            hovered_sprite = "se-search-close-black",
            clicked_sprite="se-search-close-black",
            tooltip = { "rocket-log.filter-clear" },
            actions = {
              on_click = { type = "toolbar", action = "clear-filter", gui_id = gui_id }
            }
          }
        }
      }
    }
  }
end

return {
    handle_action = handle_action,
    create_toolbar = create_toolbar
}
