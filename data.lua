--------
-- Filter and Swap Arrow icons copied from Recipe Book by Raiguard
local data_util = require("__flib__.data-util")
local tool_icons = "__rocket-log__/graphics/icons/tool-icons.png"

data:extend {
  --data_util.build_sprite("rocket-log-filter", { 0, 288 }, tool_icons, 32),
  data_util.build_sprite("rocket-log-swap", { 0, 320 }, tool_icons, 32),
}
--------

local function create_sprite_icon(name, size, scale, path, tint)
  return {
    type = "sprite",
    name = "rocket-log-" .. name,
    filename = path or "__rocket-log__/graphics/icons/" .. name .. ".png",
    priority = "medium",
    size = size or 24,
    scale = scale or 1,
    tint = tint or nil
  }
end

data:extend {
  create_sprite_icon("crosshairs-gps", nil, 1.5),
  create_sprite_icon("crosshairs-gps-white", nil, 1.5, nil, {0.8, 0.8, 0.8, 1.0}),
  create_sprite_icon("clock-white", nil, 1.25, nil, {0.9, 0.9, 0.9, 1.0}),
  create_sprite_icon("gui-button", (data.raw.item["cargo-landing-pad"].icon_size or 64), 0.5625*64/(data.raw.item["cargo-landing-pad"].icon_size or 64), "__space-exploration-graphics__/graphics/icons/cargo-rocket.png")
}

local function create_sprite_gps_overlay(name, source, tint)
  return   {
    type = "sprite",
    name = name,
    layers = {
      {
        filename = source.icon,
        priority = "medium",
        size = source.icon_size or 64,
        scale = 1,
      },
      {
        filename = "__rocket-log__/graphics/icons/crosshairs-gps-white.png",
        priority = "high",
        size = 22,
        position = {1,1},
        scale = 1.25,
        shift = {4, 4},
        tint = tint,
      }
    }
  }
end

local function create_sprite_destroyed_overlay(name, source)
  return   {
    type = "sprite",
    name = name,
    layers = {
      {
        filename = source.icon,
        priority = "medium",
        size = source.icon_size or 64,
        scale = 1,
      },
      {
        filename = "__core__/graphics/icons/alerts/destroyed-icon.png",
        priority = "high",
        size = 64,
        position = {0,0},
        scale = 0.47,
        shift = {4, 5},
      }
    }
  }
end



data:extend {
  create_sprite_gps_overlay("rocket-log-landingpad-gps", data.raw["cargo-landing-pad"]["cargo-landing-pad"], {0.8, 0.8, 0.8, 1.0}),
  create_sprite_gps_overlay("rocket-log-launchpad-gps", data.raw.container["se-rocket-launch-pad"], {0.8, 0.8, 0.8, 1.0}),
  create_sprite_destroyed_overlay("rocket-log-landingpad-missing", data.raw["cargo-landing-pad"]["cargo-landing-pad"]),
  create_sprite_destroyed_overlay("rocket-log-launchpad-missing", data.raw.container["se-rocket-launch-pad"]),
  create_sprite_destroyed_overlay("rocket-log-rocket-crashed", data.raw["virtual-signal"]["se-cargo-rocket"]),
}

data:extend {
  {
      type = 'custom-input',
      name = 'rocket-log-open',
      key_sequence = '',
      enabled_while_spectating = true,
  },
}
