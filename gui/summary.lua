local tables = require("__flib__.table")

local function flat_map(tbl, mapper)
  local output = {}
  for k, v in pairs(tbl) do
    local result = mapper(v, k)
    for _, item in pairs(result) do
      table.insert(output, item)
    end
  end
  return output
end

local function create_new_summary()
  return {
    origins = {},
    targets = {},
    items = {},
  }
end

local function add_event(event, summary)
  if event.contents then
    for name, count in pairs(event.contents) do
      summary.items[name] = summary.items[name] or { count = 0, name = name }
      local data = summary.items[name]
      data.count = data.count + count
    end
  end
  
  -- Total per origin surface
  summary.origins[event.origin_zone_name] = summary.origins[event.origin_zone_name] or
      {zone_index=event.origin_zone_id, zone_name=event.origin_zone_name, icon=event.origin_zone_icon, count=0, launchpads={}}
  summary.origins[event.origin_zone_name].count = summary.origins[event.origin_zone_name].count + 1
  summary.origins[event.origin_zone_name].position = event.origin_position
  
  -- Total per launchpad
  local launchpad_summary = summary.origins[event.origin_zone_name].launchpads[event.launchpad_id] or
      {name=event.origin_zone_name, launchpad_id=event.launchpad_id, icon="rocket-log-launchpad-gps", zone_name=event.origin_zone_name, count=0}
  launchpad_summary.count = launchpad_summary.count + 1
  launchpad_summary.position = event.origin_position
  summary.origins[event.origin_zone_name].launchpads[event.launchpad_id] = launchpad_summary
  
  
  -- Total per target surface
  summary.targets[event.target_zone_name] = summary.targets[event.target_zone_name] or {zone_index=event.target_zone_id, zone_name=event.target_zone_name, count=0, icon=event.target_zone_icon, landingpads={}, area_count=0}
  summary.targets[event.target_zone_name].count = summary.targets[event.target_zone_name].count + 1
  summary.targets[event.target_zone_name].position = event.target_position
  
  -- Total per landingpad or area
  if event.landingpad_name then
    local landingpad_summary = summary.targets[event.target_zone_name].landingpads[event.landingpad_name] or 
        {name=event.landingpad_name, icon="rocket-log-landingpad-gps", zone_name=event.target_zone_name, count=0}
    landingpad_summary.count = landingpad_summary.count + 1
    landingpad_summary.position = event.target_position
    summary.targets[event.target_zone_name].landingpads[event.landingpad_name] = landingpad_summary
  else
    local landingpad_summary = summary.targets[event.target_zone_name].landingpads["__area__"] or 
        {name={"rocket-log.no-landingpad"}, zone_name=event.target_zone_name, count=0}
    landingpad_summary.count = landingpad_summary.count + 1
    landingpad_summary.position = event.target_position
    summary.targets[event.target_zone_name].landingpads["__area__"] = landingpad_summary
  end

end

local function create_gui(summary, gui_id)
  local origins = tables.filter(summary.origins, function() return true end, true)
  local targets = tables.filter(summary.targets, function() return true end, true)
  local items = tables.filter(summary.items, function() return true end, true)

  table.sort(origins, function(a, b) return a.count > b.count end)
  table.sort(targets, function(a, b) return a.count > b.count end)
  table.sort(items, function(a, b) return a.count > b.count end)
  for _, origin in pairs(origins) do
    local launchpad_list = {}
    for _, launchpad in pairs(origin.launchpads) do
      table.insert(launchpad_list, launchpad)
    end
    table.sort(launchpad_list, function(a, b) return a.count > b.count end)
    origin.launchpads = launchpad_list
  end
  for _, target in pairs(targets) do
    local landingpad_list = {}
    for _, landingpad in pairs(target.landingpads) do
      table.insert(landingpad_list, landingpad)
    end
    table.sort(landingpad_list, function(a, b) return a.count > b.count end)
    target.landingpads = landingpad_list
  end
  
  -- Makes one line for the top ten surfaces origin surface
  -- Line starts with surface count, icon, and name
  -- Then list of top ten launchpads
  local origins_top
  local _, origins_top = tables.for_n_of(origins, nil, 10, function(origin)
    local launchpad_children = {}
    for id, launchpad in pairs(origin.launchpads) do
      table.insert(launchpad_children,
        {
          type = "sprite-button",
          sprite = launchpad.icon,
          tooltip = {"rocket-log.summary-launchpad-tooltip", launchpad.name, tostring(launchpad.launchpad_id), tostring(launchpad.count), {"control-keys.mouse-button-2-alt-1"}},
          actions = {
            on_click = { type = "table", action = "container-gui", 
              zone_name = launchpad.zone_name,
              position = launchpad.position
            }
          }
        })
    end
      
    return {
      count = {
        type = "label",
        caption = tostring(origin.count)
      },
      surface = {
        type = "button",
        caption = {"rocket-log.origin-label", origin.zone_name, origin.icon},
        style = "frame_button",
        style_mods = {font_color = { 1,1,1 }, height=34, minimal_width=50, horizontal_align="left", vertical_align="center", top_margin=4, right_padding=3, left_padding=1},
        actions = {
          on_click = { type = "toolbar", action = "filter", filter = "origin", value = origin.zone_name, gui_id = gui_id }
        }
      },
      launchpads = {
        type = "flow",
        direction = "horizontal",
        children = launchpad_children
      }
    }
  end)

  local targets_top
  local _, targets_top = tables.for_n_of(targets, nil, 10, function(target)
    local landingpad_children = {}
    for _, landingpad in pairs(target.landingpads) do
      local pad_tooltip
      if landingpad.icon then
        pad_tooltip = {"rocket-log.summary-landingpad-tooltip", landingpad.name, tostring(landingpad.count), {"control-keys.mouse-button-2-alt-1"}}
      else
        pad_tooltip = {"rocket-log.summary-area-tooltip", tostring(landingpad.count)}
      end
      table.insert(landingpad_children, 
        {
          type = "sprite-button",
          sprite = landingpad.icon or "rocket-log-crosshairs-gps-white",
          hovered_sprite = ((landingpad.icon == nil) and "rocket-log-crosshairs-gps") or nil,
          clicked_sprite = ((landingpad.icon == nil) and "rocket-log-crosshairs-gps") or nil,
          tooltip = pad_tooltip,
          actions = {
            on_click = { type = "table", action = "container-gui", 
              zone_name = landingpad.zone_name,
              position = landingpad.position
            }
          }
        })
    end
    
    return {
      count = {
        type = "label",
        caption = tostring(target.count)
      },
      surface = {
        type = "button",
        caption = {"rocket-log.target-label", target.zone_name, target.icon},
        style = "frame_button",
        style_mods = {font_color = { 1,1,1 }, height=34, minimal_width=50, horizontal_align="left", vertical_align="center", top_margin=4, right_padding=3, left_padding=1},
        actions = {
          on_click = { type = "toolbar", action = "filter", filter = "target", value = target.zone_name, gui_id = gui_id }
        }
      },
      landingpads = {
        type = "flow",
        direction = "horizontal",
        children = landingpad_children
      }
    }
  end)

  local items_top
  local _, items_top = tables.for_n_of(items, nil, 30, function(item)
    local prototype = game.item_prototypes[item.name]
    local sprite = prototype and ("item/" .. item.name) or nil
    local tooltip = {"rocket-log.summary-item-tooltip", (prototype and prototype.localised_name) or ("item/" .. item.name), tostring(item.count)}
    return {
      type = "sprite-button",
      sprite = sprite,
      number = item.loaded,
      actions = {
        on_click = {
          type = "toolbar", action = "filter",
          filter = "item", value = item.name, gui_id = gui_id
        }
      },
      tooltip = tooltip
    }
  end)

  local summary_gui_elements = {
    {
      type = "label",
      caption = { "rocket-log.summary-top-origins" }
    },
    {
      type = "table",
      column_count = 3,
      children = flat_map(origins_top, function(v)
          return { v.count, v.surface, v.launchpads }
      end)
    },
    {
      type = "label",
      caption = { "rocket-log.summary-top-targets" }
    },
    {
      type = "table",
      column_count = 3,
      children = flat_map(targets_top, function(v)
          return { v.count, v.surface, v.landingpads}
      end)
    },
    {
      type = "label",
      caption = { "rocket-log.summary-top-items" }
    },
    {
      type = "table",
      column_count = 10,
      children = items_top
    },
  }
  return summary_gui_elements
end

return {
  add_event = add_event,
  create_new_summary = create_new_summary,
  create_gui = create_gui
}
