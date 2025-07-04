local format = require("__flib__.format")
local flib_gui = require("__flib__.gui")
local trains = require("__flib__.train")
local time_filter = require("scripts/filter-time")
local summary_gui = require("gui/summary")
local gui_handlers = require("gui/handlers")

-- Make a button for this item and quantity
local function sprite_button_type_name_amount(item_type, name, amount, color, gui_id)
  local prototype = nil
  if item_type == "item" then
    prototype = prototypes.item[name]
  elseif item_type == "virtual-signal" then
    prototype = prototypes.virtual_signal[name]
  end
  local sprite = (prototype and (item_type .. "/" .. name)) or nil
  local tooltip = {"rocket-log.summary-item-tooltip", (prototype and prototype.localised_name) or (item_type .. "/" .. name), tostring(amount)}
  return {
    type = "sprite-button",
    style = color and "flib_slot_button_" .. color or "flib_slot_button_default",
    sprite = sprite,
    number = amount,
    handler = gui_handlers.set_filter_item,
    tags = {filter = item_type, value = name, gui_id = gui_id},
    tooltip = tooltip
  }
end

-- Makes one row per rocket launch
local function events_row(rocket_data, children, gui_id, relative_time_start)
  -- Launch time display (if relative, then current tick is provided)
  local launch_time = rocket_data.launch_time
  if relative_time_start then
    launch_time = relative_time_start - launch_time
  end

  local timestamp = {
    type = "label",
    caption = format.time(launch_time, true)
  }

  local origin_children = {}
  if rocket_data.launchpad and rocket_data.launchpad.valid then
    -- Launchpad icon button
    table.insert(origin_children, 
      {
        type = "sprite-button",
        sprite = "rocket-log-launchpad-gps",
        tooltip = {"rocket-log.launchpad-tooltip", rocket_data.origin_zone_name, tostring(rocket_data.launchpad_id), {"control-keys.mouse-button-2-alt-1"}},
        handler = gui_handlers.view_position,
        tags = {action = "container-gui", zone_name = rocket_data.origin_zone_name, position = rocket_data.origin_position}
      }
    )
  else
    -- Launchpad missing icon button
    table.insert(origin_children, 
      {
        type = "sprite-button",
        sprite = "rocket-log-launchpad-missing",
        tooltip = {"rocket-log.missing-launchpad", tostring(rocket_data.launchpad_id)},
        handler = gui_handlers.view_position,
        tags = {action = "remote-view", zone_name = rocket_data.origin_zone_name, position = rocket_data.origin_position}
      }
    )
  end
  -- Launch event origin zone
  table.insert(origin_children,
    {
      type = "button",
      caption = {"rocket-log.origin-label", rocket_data.origin_zone_name, rocket_data.origin_zone_icon},
      --tooltip = {"rocket-log.origin-tooltip", rocket_data.origin_zone_name},
      style = "frame_button",
      style_mods = {font_color = { 1,1,1 }, height=34, minimal_width=50, horizontal_align="left", vertical_align="center", top_margin=4, right_padding=3, left_padding=1},
      handler = gui_handlers.set_filter_origin,
      tags = {origin=rocket_data.origin_zone_name, gui_id=gui_id}
    }
  )
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
      handler = gui_handlers.set_filter_target,
      tags = {target=rocket_data.target_zone_name, gui_id=gui_id}
    }
  }

  -- Landing pad target
  if rocket_data.landingpad_name then
    if rocket_data.landing_failed then
        table.insert(target_children, 1, {
        type = "sprite-button",
        sprite = "rocket-log-rocket-crashed",
        tooltip = {"rocket-log.rocket-crashed", rocket_data.landingpad_name},
        handler = gui_handlers.view_position,
        tags = {action = "remote-view", zone_name = rocket_data.target_zone_name, position = rocket_data.target_position}
      })
    elseif rocket_data.landingpad and rocket_data.landingpad.valid then
      table.insert(target_children, 1, {
        type = "sprite-button",
        sprite = "rocket-log-landingpad-gps",
        tooltip = {"rocket-log.landingpad-tooltip", rocket_data.landingpad_name, {"control-keys.mouse-button-2-alt-1"}},
        handler = gui_handlers.view_position,
        tags = {action = "container-gui", zone_name = rocket_data.target_zone_name, position = rocket_data.target_position}
      })
    else
      table.insert(target_children, 1, {
        type = "sprite-button",
        sprite = "rocket-log-landingpad-missing",
        tooltip = {"rocket-log.missing-landingpad", rocket_data.landingpad_name},
        handler = gui_handlers.view_position,
        tags = {action = "remote-view", zone_name = rocket_data.target_zone_name, position = rocket_data.target_position}
      })
    end
  else
    table.insert(target_children, 1, {
      type = "sprite-button",
      sprite = "rocket-log-crosshairs-gps-white",
      hovered_sprite = "rocket-log-crosshairs-gps",
      clicked_sprite = "rocket-log-crosshairs-gps",
      tooltip = {"rocket-log.no-landingpad"},
      handler = gui_handlers.view_position,
      tags = {action = "remote-view", zone_name = rocket_data.target_zone_name, position = rocket_data.target_position}
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
    for index = 1,#rocket_data.contents do
      table.insert(contents_children, sprite_button_type_name_amount("item", rocket_data.contents[index].name, rocket_data.contents[index].count, nil, gui_id))
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
local function matches_filter(entry, filters)
  if entry.launch_time < filters.time_period then
    return false
  end

  local check_item = (filters.item ~= nil)
  local check_origin = (filters.origin_index ~= nil)
  local check_target = (filters.target_index ~= nil)
  local matches_item = not check_item
  local matches_origin = not check_origin
  local matches_target = not check_target
  
  if check_origin then
    matches_origin = (entry.origin_zone_id == filters.origin_index)
  end
  
  if check_target then
    matches_target = (entry.target_zone_id == filters.target_index)
  end
  
  -- Don't bother checking inventory if locations don't match
  if matches_origin and matches_target and check_item and entry.contents then
    for k = 1,#entry.contents do
      if entry.contents[k].name == filters.item then
        matches_item = true
        break
      end
    end
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
  -- Check if player has selected relative timestamp mode
  local relative_time_setting = storage.guis[gui_id].player.mod_settings["rocket-log-relative-time"]
  local relative_time_start = nil
  if relative_time_setting.value == true then
    relative_time_start = game.tick
  end
  
  local children = {}
  local summary = summary_gui.create_new_summary()
  local count = 0
  for _, column in pairs(columns) do
    table.insert(children, {
      type = "label",
      caption = { "rocket-log.table-header-" .. column }
    })
  end
  for _, rocket_data in iterate_backwards(histories) do
    if matches_filter(rocket_data, filters) then
      events_row(rocket_data, children, gui_id, relative_time_start)
      summary_gui.add_event(rocket_data, summary)
      count = count + 1
    end
  end
  return children, summary, count
end

local function create_events_table(gui_id)
  -- Loop through all the histories first and then check current, sort by the tick of last entry
  local rocket_log_gui = storage.guis[gui_id]
  local force_index = rocket_log_gui.player.force.index
  local histories = {}
  for _, record in pairs(storage.history) do
    if record.force_index == force_index then
      table.insert(histories, record)
    end
  end

  table.sort(histories, function(a, b) return a.launch_time < b.launch_time end)
  
  local filter_guis = rocket_log_gui.filter_guis
  
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
  local count
  local children_guis, summary, count = create_result_guis(histories, filters, events_columns, gui_id)
  rocket_log_gui.events_contents.clear()
  rocket_log_gui.summary_contents.clear()

  local summary_children = summary_gui.create_gui(summary, gui_id)
  
  flib_gui.add(rocket_log_gui.summary_contents, {
    {
      type = "scroll-pane",
      style = "flib_naked_scroll_pane_no_padding",
      name = "scroll_pane",
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
  
  filter_guis.stats.caption = {"rocket-log.display-stats",count,#storage.history}

  return flib_gui.add(rocket_log_gui.events_contents, {
    {
      type = "scroll-pane",
      style = "flib_naked_scroll_pane_no_padding",
      ref = { "scroll_pane" },
      vertical_scroll_policy = "always",
      style_mods = {width = 1000, height = 600, padding = 6},
      children = {
        {
          type = "table",
          name = "events_table",
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
  create_events_table = create_events_table
}
