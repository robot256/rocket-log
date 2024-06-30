local events_table = require("gui/events_table")
local time_filter = require("scripts/filter-time")
local rocket_log = require("scripts/rocket_log")

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
  local rocket_log_gui = global.guis[gui_id]
  local filter_guis = rocket_log_gui.gui.filter
  local force_index = rocket_log_gui.player.force.index
  
  -- Make list of surfaces to allow in selection boxes
  local origins = {{name={"rocket-log.filter-zone-select-none"}, index=-1}}
  local targets = {{name={"rocket-log.filter-zone-select-none"}, index=-1}}
  local origin_list = {}
  local target_list = {}
  --local origin_system_list = {}
  --local target_system_list = {}
  for _, record in pairs(global.history) do
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
  local rocket_log_gui = global.guis[gui_id]
  local filter_guis = rocket_log_gui.gui.filter
  
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
  local filter_guis = global.guis[gui_id].gui.filter
  filter_guis.item.tooltip = (filter_guis.item.elem_value and game.item_prototypes[filter_guis.item.elem_value] and 
                                                    game.item_prototypes[filter_guis.item.elem_value].localised_name) or ""
  update_filters(gui_id)
  events_table.create_events_table(gui_id)
end

local function handle_action(action, event)
  local gui_id = action.gui_id
  local filter_guis = global.guis[gui_id].gui.filter
  
  if action.action == "filter" then
    if action.filter == "item" and game.item_prototypes[action.value] then
      filter_guis.item.elem_value = action.value
      refresh(gui_id)
    elseif action.filter == "origin" then
      for i,x in pairs(filter_guis.origin_list.items) do
        if i > 1 then  -- skip the "none" entry
          if action.value == string.gsub(x, "^(%[.*%] )", "") then
            filter_guis.origin_list.selected_index = i
            break
          end
        end
      end
      refresh(gui_id)
    elseif action.filter == "target" then
      for i,x in pairs(filter_guis.target_list.items) do
        if i > 1 then  -- skip the "none" entry
          if action.value == string.gsub(x, "^(%[.*%] )", "") then
            filter_guis.target_list.selected_index = i
            break
          end
        end
      end
      refresh(gui_id)
    end
  
  elseif action.action == "swap-filters" then
    swap_filters(gui_id)
    refresh(gui_id)
    
  elseif action.action == "clear-filter" then
    filter_guis.origin_list.selected_index = 1
    filter_guis.target_list.selected_index = 1
    filter_guis.item.elem_value = nil
    refresh(gui_id)
    
  elseif action.action == "refresh" then
    refresh(gui_id)
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
            type = "sprite",
            sprite = "rocket-log-clock-white",
          },
          {
            type = "drop-down",
            items = time_filter.time_period_items,
            selected_index = time_filter.default_index,
            tooltip = { "rocket-log.filter-time-period-label" },
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
            type = "label",
            caption = "test",
            ref = {"filter","stats"}
          }
        }
      },
      {
        type = "flow",
        direction = "horizontal",
        children = {
          {
            type = "sprite",
            sprite = "entity/se-rocket-launch-pad",
            tooltip = { "rocket-log.filter-origin-label" },
          },
          {
            type = "drop-down",
            ref = { "filter", "origin_list" },
            items = {{"rocket-log.filter-zone-select-none"}},
            selected_index = 1,
            actions = {
              on_selection_state_changed = { type = "toolbar", action = "refresh", gui_id = gui_id }
            }
          },
          {
            type = "sprite-button",
            sprite = "rocket-log-swap",
            style = "item_and_count_select_confirm",
            tooltip = { "rocket-log.swap-filters" },
            actions = {
              on_click = { type = "toolbar", action = "swap-filters", gui_id = gui_id }
            }
          },
          {
            type = "sprite",
            sprite = "entity/se-rocket-landing-pad",
            tooltip = { "rocket-log.filter-target-label" },
          },
          {
            type = "drop-down",
            ref = { "filter", "target_list" },
            items = {{"rocket-log.filter-zone-select-none"}},
            selected_index = 1,
            actions = {
              on_selection_state_changed = { type = "toolbar", action = "refresh", gui_id = gui_id }
            }
          },
          {
            type = "sprite",
            sprite = "entity/se-cargo-rocket-cargo-pod",
            tooltip = { "rocket-log.filter-item-label" },
          },
          {
            type = "choose-elem-button",
            elem_type = "item",
            ref = { "filter", "item" },
            actions = {
              on_elem_changed = {
                  type = "toolbar", action = "refresh", gui_id = gui_id
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
          },
        }
      }
    }
  }
end

return {
  handle_action = handle_action,
  create_toolbar = create_toolbar,
  refresh = refresh
}
