local function create_sprite_icon(name, size, scale, path)
  return {
    type = "sprite",
    name = "rocket_log_" .. name,
    filename = path or "__rocket-log__/graphics/icons/material-design/" .. name .. ".png",
    priority = "medium",
    width = size or 24,
    height = size or 24,
    scale = scale or 1
  }
end

data:extend {
  create_sprite_icon("crosshairs-gps", nil, 1.5),
  create_sprite_icon("timer-outline"),
  create_sprite_icon("rocket-button", 64, 0.5625, "__space-exploration-graphics__/graphics/icons/cargo-rocket.png")
}

data:extend {
  {
      type = 'custom-input',
      name = 'rocket-log-open',
      key_sequence = 'CONTROL + Y',
      enabled_while_spectating = true,
  },
}
