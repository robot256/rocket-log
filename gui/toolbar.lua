local events_table = require("gui/events_table")
local time_filter = require("scripts/filter-time")
local rocket_log = require("scripts/rocket_log")
local gui_handlers = require("gui/handlers")

-- Navigate recursively to find the star system this zone is in
--local get_star_name(zone)
--  local star_name = nil
--  for i=1,8 do
--    if not zone then
--      break
--    end
--    if zone.type == "star" then
--      star_name = zone.name
--      break
--    end
--    zone = zone.parent
--  end
--  return star_name
--end


local function update_filters(gui_id)
  -- Update the dropdown list options
  local rocket_log_gui = storage.guis[gui_id]
  local filter_guis = rocket_log_gui.filter_guis
  local force_index = rocket_log_gui.player.force.index
  
  -- Make list of surfaces to allow in selection boxes
  local origins = {{name={"rocket-log.filter-zone-select-none"}, index=-1}}
  local targets = {{name={"rocket-log.filter-zone-select-none"}, index=-1}}
  local origin_list = {}
  local target_list = {}
  --local origin_system_list = {}
  --local target_system_list = {}
  for _, record in pairs(storage.history) do
    if record.force_index == force_index then
      if not origin_list[record.origin_zone_id] then
        origin_list[record.origin_zone_id] = true
        table.insert(origins, {name="[img="..record.origin_zone_icon.."] "..record.origin_zone_name, index=record.origin_zone_id})
        --local parent = remote.call("space-exploration", "get_zone_from_zone_index", {zone_index = record.origin_zone_id}).parent
        --if parent then
        --  if parent.parent then
        --    origin_system_list[parent.parent.index] = true
        --  else
        --    origin_system_list[parent.index] = true
        --  end
        --end
      end
      if not target_list[record.target_zone_id] then
        target_list[record.target_zone_id] = true
        table.insert(targets, {name="[img="..record.target_zone_icon.."] "..record.target_zone_name, index=record.target_zone_id})
        --local zone = remote.call("space-exploration", "get_zone_from_zone_index", {zone_index = record.target_zone_id})
        --local system = get_star_name(zone)
        --if parent then
        --  if parent.parent then
        --    target_system_list[parent.parent.index] = parent.parent.name
        --  else
        --    target_system_list[parent.index] = parent.name
        --  end
        --end
      end
    end
  end
  
  --for i,p in pairs(target_system_list) do
  --  table.insert(origins, {name="[img=se-map-gui-system] "..p.." System", index=i-0.5})
  --end
  --for i,p in pairs(origin_system_list) do
  --  table.insert(targets, {name="[img=se-map-gui-system] "..p.." System", index=i-0.5})
  --end
  
  table.sort(origins, function(a, b) return a.index < b.index end)
  table.sort(targets, function(a, b) return a.index < b.index end)
    
  local old_origin = filter_guis.origin_list.get_item(filter_guis.origin_list.selected_index)
  local old_target = filter_guis.target_list.get_item(filter_guis.target_list.selected_index)
  
  local new_origin_index = 1
  local new_target_index = 1
  local new_origin_items = {}
  local new_target_items = {}
  for i,x in pairs(origins) do
    if old_origin == x.name then
      new_origin_index = i
    end
    table.insert(new_origin_items, x.name)
  end
  for i,x in pairs(targets) do
    if old_target == x.name then
      new_target_index = i
    end
    table.insert(new_target_items, x.name)
  end
  
  filter_guis.origin_list.items=new_origin_items
  filter_guis.target_list.items=new_target_items
  filter_guis.origin_list.selected_index=new_origin_index
  filter_guis.target_list.selected_index=new_target_index
end

-- Assign the origin filter to target, and target filter to origin, if possible
local function swap_filters(gui_id)
  local rocket_log_gui = storage.guis[gui_id]
  local filter_guis = rocket_log_gui.filter_guis
  
  local old_origin = filter_guis.origin_list.get_item(filter_guis.origin_list.selected_index)
  local old_target = filter_guis.target_list.get_item(filter_guis.target_list.selected_index)
  
  -- Check if old origin is in the target list, assign it to the new target
  local new_target_index = 1  -- Default to empty filter
  for list_index,list_entry in pairs(filter_guis.target_list.items) do
    if list_entry == old_origin then
      new_target_index = list_index
      break
    end
  end
  
  -- Check if old target is in the origin list, assign it to the new origin
  local new_origin_index = 1
  for list_index,list_entry in pairs(filter_guis.origin_list.items) do
    if list_entry == old_target then
      new_origin_index = list_index
      break
    end
  end
  
  filter_guis.origin_list.selected_index=new_origin_index
  filter_guis.target_list.selected_index=new_target_index
end

local function refresh(gui_id)
  --log(serpent.line(storage.guis[gui_id].gui.children_names))
  local filter_guis = storage.guis[gui_id].filter_guis
  filter_guis.item.tooltip = (filter_guis.item.elem_value and prototypes.item[filter_guis.item.elem_value] and 
                                                    prototypes.item[filter_guis.item.elem_value].localised_name) or ""
  update_filters(gui_id)
  events_table.create_events_table(gui_id)
end

function gui_handlers.refresh(event)
  refresh(event.element.tags.gui_id)
end

function gui_handlers.swap_filters(event)
  local gui_id = event.element.tags.gui_id
  swap_filters(gui_id)
  refresh(gui_id)
end

function gui_handlers.clear_filters(event)
  local gui_id = event.element.tags.gui_id
  local filter_guis = storage.guis[gui_id].filter_guis
  filter_guis.origin_list.selected_index = 1
  filter_guis.target_list.selected_index = 1
  filter_guis.item.elem_value = nil
  refresh(gui_id)
end

function gui_handlers.set_filter_item(event)
  local gui_id = event.element.tags.gui_id
  local filter_guis = storage.guis[gui_id].filter_guis
  filter_guis.item.elem_value = event.element.tags.value
  refresh(gui_id)
end

function gui_handlers.set_filter_origin(event)
  local gui_id = event.element.tags.gui_id
  local filter_guis = storage.guis[gui_id].filter_guis
  local origin = event.element.tags.origin
  for i,x in pairs(filter_guis.origin_list.items) do
    if i > 1 then  -- skip the "none" entry
      if origin == string.gsub(x, "^(%[.*%] )", "") then
        filter_guis.origin_list.selected_index = i
        break
      end
    end
  end
  refresh(gui_id)
end

function gui_handlers.set_filter_target(event)
  local gui_id = event.element.tags.gui_id
  local filter_guis = storage.guis[gui_id].filter_guis
  local target = event.element.tags.target
  for i,x in pairs(filter_guis.target_list.items) do
    if i > 1 then  -- skip the "none" entry
      if target == string.gsub(x, "^(%[.*%] )", "") then
        filter_guis.target_list.selected_index = i
        break
      end
    end
  end
  refresh(gui_id)
end

local function create_toolbar(gui_id)
  return {
    type = "flow",
    direction = "vertical",
    name = "toolbar",
    children = {
      {
        type = "flow",
        direction = "horizontal",
        name = "row1",
        children = {
          {
            type = "sprite",
            sprite = "rocket-log-clock-white",
          },
          {
            type = "drop-down",
            name = "filter_time_period",
            items = time_filter.time_period_items,
            selected_index = time_filter.default_index,
            tooltip = { "rocket-log.filter-time-period-label" },
            handler = gui_handlers.refresh,
            tags = {gui_id = gui_id}
          },
          {
            type = "sprite-button",
            sprite = "utility/refresh",
            style = "item_and_count_select_confirm",
            tooltip = { "rocket-log.refresh" },
            handler = gui_handlers.refresh,
            tags = {gui_id = gui_id}
          },
          {
            type = "label",
            name = "filter_stats",
            caption = "test"
          }
        }
      },
      {
        type = "flow",
        direction = "horizontal",
        name = "row2",
        children = {
          {
            type = "sprite",
            sprite = "entity/se-rocket-launch-pad",
            tooltip = { "rocket-log.filter-origin-label" },
          },
          {
            type = "drop-down",
            name = "filter_origin_list",
            items = {{"rocket-log.filter-zone-select-none"}},
            selected_index = 1,
            handler = gui_handlers.refresh,
            tags = {gui_id = gui_id}
          },
          {
            type = "sprite-button",
            sprite = "rocket-log-swap",
            style = "item_and_count_select_confirm",
            tooltip = { "rocket-log.swap-filters" },
            handler = gui_handlers.swap_filters,
            tags = {gui_id = gui_id}
          },
          {
            type = "sprite",
            sprite = "entity/cargo-landing-pad",
            tooltip = { "rocket-log.filter-target-label" },
          },
          {
            type = "drop-down",
            name = "filter_target_list",
            items = {{"rocket-log.filter-zone-select-none"}},
            selected_index = 1,
            handler = gui_handlers.refresh,
            tags = {gui_id = gui_id}
          },
          {
            type = "sprite",
            sprite = "entity/se-cargo-rocket-cargo-pod",
            tooltip = { "rocket-log.filter-item-label" },
          },
          {
            type = "choose-elem-button",
            elem_type = "item",
            name = "filter_item",
            handler = gui_handlers.refresh,
            tags = {gui_id = gui_id}
          },
          {
            type = "sprite-button",
            sprite = "se-search-close-white",
            hovered_sprite = "se-search-close-black",
            clicked_sprite="se-search-close-black",
            tooltip = { "rocket-log.filter-clear" },
            handler = gui_handlers.clear_filters,
            tags = {gui_id = gui_id}
          },
        }
      }
    }
  }
end

return {
  create_toolbar = create_toolbar,
  refresh = refresh
}
