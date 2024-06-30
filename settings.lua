data:extend{
  {
    type = "bool-setting",
    name = "rocket-log-mod-button",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "a"
  },
  {
    type = "bool-setting",
    name = "rocket-log-relative-time",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "b"
  },
  {
    type = "int-setting",
    name = "rocket-log-retention-depth",
    setting_type = "runtime-global",
    default_value = 0,
    minimum_value = 0
  }
}
