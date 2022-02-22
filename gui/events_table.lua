local misc = require("__flib__.misc")
local gui = require("__flib__.gui-beta")
local trains = require("__flib__.train")
local time_filter = require("scripts/filter-time")
local summary_gui = require("gui/summary")

-- Handle actions when clicking on the launch and landing pad buttons
local function handle_action(action, event)
  local player = event.player_index and game.players[event.player_index]
  
  if player and (action.action == "remote-view" or action.action == "container-gui") then
    if remote.call("space-exploration", "remote_view_is_unlocked", {player=player}) then
      remote.call("space-exploration", "remote_view_start", {player=player, zone_name=action.zone_name, position=action.position, location_name=action.label, freeze_history=true})
      
      if event.button == defines.mouse_button_type.right then
        if action.action == "container-gui" then
          local surface = remote.call("space-exploration", "zone_get_surface", {zone_index =  remote.call("space-exploration", "get_zone_from_name", {zone_name = action.zone_name}).index})
          if surface and surface.valid then
            local container = surface.find_entities_filtered{type="container", position=action.position, limit=1}
            if container and container[1] and container[1].valid then
              player.opened = container[1]
            end
          end
        else
          player.opened = nil
        end
      end
    end
  end
end

-- Make a button for this item and quantity
local function sprite_button_type_name_amount(type, name, amount, color, gui_id)
  local prototype = nil
  if type == "item" then
    prototype = game.item_prototypes[name]
  elseif type == "virtual-signal" then
    prototype = game.virtual_signal_prototypes[name]
  end
  local sprite = (prototype and (type .. "/" .. name)) or nil
  local tooltip = {"rocket-log.summary-item-tooltip", (prototype and prototype.localised_name) or (type .. "/" .. name), tostring(amount)}
  return {
    type = "sprite-button",
    style = color and "flib_slot_button_" .. color or "flib_slot_button_default",
    sprite = sprite,
    number = amount,
    actions = {
      on_click = { type = "toolbar", action = "filter", filter = type, value = name, gui_id = gui_id }
    },
    tooltip = tooltip
  }
end

-- Makes one row per rocket launch
local function events_row(rocket_data, children, gui_id)
  -- Launch time display
  local launch_time = rocket_data.launch_time
  local timestamp = {
    type = "label",
    caption = misc.ticks_to_timestring(launch_time, true)
  }

  local origin_children = {
  -- Launchpad icon button
    {
      type = "sprite-button",
      sprite = "rocket-log-launchpad-gps",
      --tooltip = {"entity-name.se-rocket-launch-pad"},
      tooltip = {"rocket-log.launchpad-tooltip", rocket_data.origin_zone_name, tostring(rocket_data.launchpad_id), {"control-keys.mouse-button-2-alt-1"}},
      actions = {
        on_click = { type = "table", action = "container-gui", 
            zone_name = rocket_data.origin_zone_name,
            position = rocket_data.launchpad.position
        },
      }
    },
  -- Launch event origin zone
    {
      type = "button",
      caption = {"rocket-log.origin-label", rocket_data.origin_zone_name, rocket_data.origin_zone_icon},
      --tooltip = {"rocket-log.origin-tooltip", rocket_data.origin_zone_name},
      style = "frame_button",
      style_mods = {font_color = { 1,1,1 }, height=34, minimal_width=50, horizontal_align="left", vertical_align="center", top_margin=4, right_padding=3, left_padding=1},
      actions = {
        on_click = { type = "toolbar", action = "filter", filter = "origin", value = rocket_data.origin_zone_name, gui_id = gui_id }
      }
    },
  }
  local origin_flow = {
    type = "flow",
    direction = "horizontal",
    children = origin_children
  }

  -- Launch event target zone
  local target_children = {
    {
      type = "button",
      caption = {"rocket-log.target-label", rocket_data.target_zone_name, rocket_data.target_zone_icon},
      --tooltip = {"rocket-log.target-tooltip", rocket_data.target_zone_name},
      style = "frame_button",
      style_mods = {font_color = { 1,1,1 }, height=34, minimal_width=50, horizontal_align="left", vertical_align="center", top_margin=4, right_padding=3, left_padding=1},
      actions = {
        on_click = { type = "toolbar", action = "filter", filter = "target", value = rocket_data.target_zone_name, gui_id = gui_id }
      }
    }
  }

  -- Landing pad target
  if rocket_data.landingpad_name then
    if rocket_data.landingpad and rocket_data.landingpad.valid then
      table.insert(target_children, 1, {
        type = "sprite-button",
        sprite = "rocket-log-landingpad-gps",
        tooltip = {"rocket-log.landingpad-tooltip", rocket_data.landingpad_name, {"control-keys.mouse-button-2-alt-1"}},
        actions = {
            on_click = { type = "table", action = "container-gui",
                zone_name = rocket_data.target_zone_name,
                position = rocket_data.landingpad.position
            },
        }
      })
    else
      table.insert(target_children, 1, {
        type = "sprite-button",
        sprite = "rocket-log-crosshairs-gps-white",
        hovered_sprite = "rocket-log-crosshairs-gps",
        clicked_sprite = "rocket-log-crosshairs-gps",
        tooltip = {"rocket-log.missing-landingpad"},
        actions = {
            on_click = { type = "table", action = "remote-view",
                zone_name = rocket_data.target_zone_name,
                position = rocket_data.target_position
            },
        }
      })
    end
  else
    table.insert(target_children, 1, {
      type = "sprite-button",
      sprite = "rocket-log-crosshairs-gps-white",
      hovered_sprite = "rocket-log-crosshairs-gps",
      clicked_sprite = "rocket-log-crosshairs-gps",
      tooltip = {"rocket-log.no-landingpad"},
      actions = {
          on_click = { type = "table", action = "remote-view",
              zone_name = rocket_data.target_zone_name,
              position = rocket_data.target_position
          },
      }
    })
  end
  local target_flow = {
    type = "flow",
    direction = "horizontal",
    children = target_children
  }

  -- Launched contents
  local contents_children = {}
  if rocket_data.contents then
    for name, count in pairs(rocket_data.contents) do
      table.insert(contents_children, sprite_button_type_name_amount("item", name, count, nil, gui_id))
    end
  end
  local contents_flow = {
    type = "flow",
    direction = "horizontal",
    children = contents_children
  }

  table.insert(children, timestamp)
  table.insert(children, origin_flow)
  table.insert(children, target_flow)
  table.insert(children, contents_flow)
end

-- Check if this rocket history record meets the selected filters
local function matches_filter(result, filters)
  if result.launch_time < filters.time_period then
    return false
  end

  local check_item = filters.item ~= nil
  local check_origin = filters.origin_index ~= nil
  local check_target = filters.target_index ~= nil
  local matches_item = not check_item
  local matches_origin = not check_origin
  local matches_target = not check_target
  
  if check_item then
    if not matches_item and result.contents then
      matches_item = result.contents[filters.item]
    end
  end
  
  if check_origin then
    matches_origin = (result.origin_zone_id == filters.origin_index)
  end
  
  if check_target then
    matches_target = (result.target_zone_id == filters.target_index)
  end
  
  return matches_item and matches_origin and matches_target
end

local function iterate_backwards_iterator(tbl, i)
  i = i - 1
  if i ~= 0 then
    return i, tbl[i]
  end
end
local function iterate_backwards(tbl)
  return iterate_backwards_iterator, tbl, table_size(tbl) + 1
end

local function create_result_guis(histories, filters, columns, gui_id)
  local children = {}
  local summary = summary_gui.create_new_summary()
  for _, column in pairs(columns) do
    table.insert(children, {
      type = "label",
      caption = { "rocket-log.table-header-" .. column }
    })
  end
  for _, rocket_data in iterate_backwards(histories) do
    if matches_filter(rocket_data, filters) then
      events_row(rocket_data, children, gui_id)
      summary_gui.add_event(rocket_data, summary)
    end
  end
  return children, summary
end

local function create_events_table(gui_id)
  -- Loop through all the histories first and then check current, sort by the tick of last entry
  local rocket_log_gui = global.guis[gui_id]
  local force_index = rocket_log_gui.player.force.index
  local histories = {}
  for _, record in pairs(global.history) do
    if record.force_index == force_index then
      table.insert(histories, record)
    end
  end

  table.sort(histories, function(a, b) return a.launch_time < b.launch_time end)
  
  local filter_guis = rocket_log_gui.gui.filter
  
  local origin_index
  local target_index
  if filter_guis.origin_list.selected_index > 1 then
    local origin_name = filter_guis.origin_list.get_item(filter_guis.origin_list.selected_index)
    origin_name = string.gsub(origin_name, "^(%[.*%] )", "")
    local origin_zone = remote.call("space-exploration", "get_zone_from_name", {zone_name=origin_name})
    origin_index = origin_zone.index
  end
  if filter_guis.target_list.selected_index > 1 then
    local target_name = filter_guis.target_list.get_item(filter_guis.target_list.selected_index)
    target_name = string.gsub(target_name, "^(%[.*%] )", "")
    local target_zone = remote.call("space-exploration", "get_zone_from_name", {zone_name=target_name})
    target_index = target_zone.index
  end
  
  local filters = {
    item = filter_guis.item.elem_value,
    origin_index = origin_index,
    target_index = target_index,
    time_period = game.tick - time_filter.ticks(filter_guis.time_period.selected_index)
  }

  local events_columns =  { "timestamp", "origin", "target", "contents" }
  local summary
  local children_guis, summary = create_result_guis(histories, filters, events_columns, gui_id)
  local tabs = rocket_log_gui.gui.tabs
  tabs.events_contents.clear()
  tabs.summary_contents.clear()

  local summary_children = summary_gui.create_gui(summary, gui_id)
  
  gui.build(tabs.summary_contents, {
    {
      type = "scroll-pane",
      style = "flib_naked_scroll_pane_no_padding",
      ref = { "scroll_pane" },
      vertical_scroll_policy = "always",
      style_mods = {width = 1000, height = 600, padding = 6},
      children = {
        {
          type = "flow",
          direction = "vertical",
          children = summary_children
        }
      }
    }
  })

  return gui.build(tabs.events_contents, {
    {
      type = "scroll-pane",
      style = "flib_naked_scroll_pane_no_padding",
      ref = { "scroll_pane" },
      vertical_scroll_policy = "always",
      style_mods = {width = 1000, height = 600, padding = 6},
      children = {
        {
          type = "table",
          ref = { "events_table" },
          column_count = #events_columns,
          draw_vertical_lines = true,
          draw_horizontal_line_after_headers = true,
          vertical_centering = true,
          style_mods = {right_cell_padding = 3, left_cell_padding = 3},
          children = children_guis
        }
      }
    }
  })
end

return {
  handle_action = handle_action,
  create_events_table = create_events_table
}
