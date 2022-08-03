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
  if not summary.origins[event.origin_zone_name].launchpads[event.launchpad_id] then
    local launchpad_summary = {
        name = event.origin_zone_name,
        launchpad_id = event.launchpad_id,
        zone_name = event.origin_zone_name,
        position = event.origin_position,
        count = 0
      }
    if event.launchpad.valid then
      launchpad_summary.entity = event.launchpad
      launchpad_summary.icon = "rocket-log-launchpad-gps"
      launchpad_summary.tooltip = {"rocket-log.summary-launchpad-tooltip",
                                    event.origin_zone_name, tostring(event.launchpad_id), "0", {"control-keys.mouse-button-2-alt-1"} }
      launchpad_summary.action = "container-gui"
    else
      launchpad_summary.entity = nil
      launchpad_summary.icon = "rocket-log-launchpad-missing"
      launchpad_summary.tooltip = {"rocket-log.summary-launchpad-missing-tooltip", event.origin_zone_name, tostring(event.launchpad_id), "0" }
      launchpad_summary.action = "remote-view"
    end
    summary.origins[event.origin_zone_name].launchpads[event.launchpad_id] = launchpad_summary
  end
  summary.origins[event.origin_zone_name].launchpads[event.launchpad_id].count =
      summary.origins[event.origin_zone_name].launchpads[event.launchpad_id].count + 1


  -- Total per target surface
  summary.targets[event.target_zone_name] = summary.targets[event.target_zone_name] or
      {
        zone_index = event.target_zone_id,
        zone_name = event.target_zone_name,
        count = 0,
        icon = event.target_zone_icon,
        landingpads = {}
      }
  summary.targets[event.target_zone_name].count = summary.targets[event.target_zone_name].count + 1
  summary.targets[event.target_zone_name].position = event.target_position

  -- Total per landingpad or area
  if event.landingpad_name then
    if event.landing_failed then
      -- Keep count of crashed rockets for this destination surface
      if not summary.targets[event.target_zone_name].landingpads["__crashed__"] then
        summary.targets[event.target_zone_name].landingpads["__crashed__"] = {
            name = {"rocket-log.rocket-crashed"},
            zone_name = event.target_zone_name,
            position = event.target_position,
            count = 0,
            tooltip = {"rocket-log.summary-crashed-tooltip", "0"},
            action = "remote-view",
            icon = "rocket-log-rocket-crashed"
          }
      end
      summary.targets[event.target_zone_name].landingpads["__crashed__"].count =
          summary.targets[event.target_zone_name].landingpads["__crashed__"].count + 1
    else
      -- Most recent event is saved first, don't position/entity information with subsequent (earlier) events
      if not summary.targets[event.target_zone_name].landingpads[event.landingpad_name] then
        local landingpad_summary = {
            name = event.landingpad_name,
            zone_name = event.target_zone_name,
            position = event.target_position,
            count = 0
          }
        if event.landingpad.valid then
          landingpad_summary.entity = event.landingpad
          landingpad_summary.icon = "rocket-log-landingpad-gps"
          landingpad_summary.tooltip = {"rocket-log.summary-landingpad-tooltip",
                                        event.landingpad_name, "0", {"control-keys.mouse-button-2-alt-1"} }
          landingpad_summary.action = "container-gui"
        else
          landingpad_summary.entity = nil
          landingpad_summary.icon = "rocket-log-landingpad-missing"
          landingpad_summary.tooltip = {"rocket-log.summary-landingpad-missing-tooltip", event.landingpad_name, "0"}
          landingpad_summary.action = "remote-view"
        end
        summary.targets[event.target_zone_name].landingpads[event.landingpad_name] = landingpad_summary
      end

      summary.targets[event.target_zone_name].landingpads[event.landingpad_name].count  =
          summary.targets[event.target_zone_name].landingpads[event.landingpad_name].count  + 1
    end
  else
    if not summary.targets[event.target_zone_name].landingpads["__area__"] then
      summary.targets[event.target_zone_name].landingpads["__area__"] = {
          name = {"rocket-log.no-landingpad"},
          zone_name = event.target_zone_name,
          position = event.target_position,
          count = 0,
          tooltip = {"rocket-log.summary-area-tooltip", "0"},
          action = "remote-view",
          icon = "rocket-log-crosshairs-gps-white",
          hovered_icon = "rocket-log-crosshairs-gps"
        }
    end
    summary.targets[event.target_zone_name].landingpads["__area__"].count =
        summary.targets[event.target_zone_name].landingpads["__area__"].count + 1
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
      launchpad.tooltip[4] = tostring(launchpad.count)
      table.insert(launchpad_children,
        {
          type = "sprite-button",
          sprite = launchpad.icon,
          tooltip = launchpad.tooltip,
          actions = {
            on_click = { type = "table", action = launchpad.action,
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
    local total_count = 0
    local failed_count = 0
    for _, landingpad in pairs(target.landingpads) do
      if landingpad.tooltip[1] == "rocket-log.summary-area-tooltip" then
        landingpad.tooltip[2] = tostring(landingpad.count)
      elseif landingpad.tooltip[1] == "rocket-log.summary-crashed-tooltip" then
        landingpad.tooltip[2] = tostring(landingpad.count)
        total_count = total_count + landingpad.count
        failed_count = failed_count + landingpad.count
      else
        landingpad.tooltip[3] = tostring(landingpad.count)
        total_count = total_count + landingpad.count
      end
      table.insert(landingpad_children,
        {
          type = "sprite-button",
          sprite = landingpad.icon,
          hovered_sprite = landingpad.hovered_icon,
          clicked_sprite = landingpad.hovered_icon,
          tooltip = landingpad.tooltip,
          actions = {
            on_click = { type = "table", action = landingpad.action,
              zone_name = landingpad.zone_name,
              position = landingpad.position
            }
          }
        })
    end
    
    local count_caption
    if failed_count > 0 and total_count > 0 then
      local failure_rate = math.floor(failed_count / total_count * 100)
      count_caption = {"rocket-log.summary-target-stats", target.count, failure_rate}
    else
      count_caption = {"rocket-log.summary-target-stats-simple", target.count}
    end

    return {
      count = {
        type = "label",
        caption = count_caption
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
  local _, items_top = tables.for_n_of(items, nil, 60, function(item)
    local prototype = game.item_prototypes[item.name]
    local sprite = prototype and ("item/" .. item.name) or nil
    local tooltip = {"rocket-log.summary-item-tooltip", (prototype and prototype.localised_name) or ("item/" .. item.name), util.format_number(item.count,true)}
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
