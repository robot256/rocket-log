
local function create_sprite_icon(name, size, scale, path, tint)
  return {
    type = "sprite",
    name = "rocket-log-" .. name,
    filename = path or "__rocket-log__/graphics/icons/material-design/" .. name .. ".png",
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
  create_sprite_icon("gui-button", data.raw.container["se-rocket-landing-pad"].icon_size, 0.5625*64/data.raw.container["se-rocket-landing-pad"].icon_size, "__space-exploration-graphics__/graphics/icons/cargo-rocket.png")
}

local function create_sprite_gps_overlay(name, source, tint)
  return   {
    type = "sprite",
    name = name,
    layers = {
      {
        filename = source.icon,
        priority = "medium",
        size = source.icon_size,
        scale = 1,
      },
      {
        filename = "__rocket-log__/graphics/icons/material-design/crosshairs-gps-white.png",
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



data:extend {
  create_sprite_gps_overlay("rocket-log-landingpad-gps", data.raw.container["se-rocket-landing-pad"], {0.8, 0.8, 0.8, 1.0}),
  create_sprite_gps_overlay("rocket-log-launchpad-gps", data.raw.container["se-rocket-launch-pad"], {0.8, 0.8, 0.8, 1.0}),
}

data:extend {
  {
      type = 'custom-input',
      name = 'rocket-log-open',
      key_sequence = 'CONTROL + Y',
      enabled_while_spectating = true,
  },
}
