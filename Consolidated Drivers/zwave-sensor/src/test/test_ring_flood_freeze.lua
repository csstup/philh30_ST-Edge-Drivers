local test = require "integration_test"
local capabilities = require "st.capabilities"
local zw = require "st.zwave"
local zw_test_utils = require "integration_test.zwave_test_utils"
local t_utils = require "integration_test.utils"
local Notification = (require "st.zwave.CommandClass.Notification")({ version = 5 })

local sensor = test.mock_device.build_test_zwave_device({
  profile = t_utils.get_profile_definition("ring-flood-freeze.yml"),
  zwave_endpoints = {{command_classes = {
    {value = zw.BATTERY}, {value = zw.NOTIFICATION},
    {value = zw.WAKE_UP}, {value = zw.CONFIGURATION}, {value = zw.ASSOCIATION},
  }}},
  zwave_manufacturer_id = 0x0346,
  zwave_product_type = 0x0501,
  zwave_product_id = 0x0101,
})

test.set_test_init_function(function()
  test.mock_device.add_test_device(sensor)
end)

-- Ring uses standard Notification reports; these exercise the registered
-- capability defaults, including targeted idle reports that clear an alarm.
local cases = {
  {"Leak detected", 0x05, 0x02, nil, capabilities.waterSensor.water.wet()},
  {"Leak cleared", 0x05, 0x00, '\x02', capabilities.waterSensor.water.dry()},
  {"Freeze detected", 0x04, 0x06, nil, capabilities.temperatureAlarm.temperatureAlarm.freeze()},
  {"Freeze cleared", 0x04, 0x00, '\x06', capabilities.temperatureAlarm.temperatureAlarm.cleared()},
  {"Cover removed", 0x07, 0x03, nil, capabilities.tamperAlert.tamper.detected()},
  {"Cover closed", 0x07, 0x00, '\x03', capabilities.tamperAlert.tamper.clear()},
}

for _, case in ipairs(cases) do
  test.register_message_test(case[1], {
    {
      channel = "zwave", direction = "receive",
      message = {sensor.id, zw_test_utils.zwave_test_build_receive_command(Notification:Report({
        notification_type = case[2], event = case[3], event_parameter = case[4],
      }))},
    },
    {
      channel = "capability", direction = "send",
      message = sensor:generate_test_message("main", case[5]),
    },
  })
end

test.run_registered_tests()
