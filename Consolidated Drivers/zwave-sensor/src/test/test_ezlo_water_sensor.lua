local test = require "integration_test"
local capabilities = require "st.capabilities"
local zw = require "st.zwave"
local zw_test_utils = require "integration_test.zwave_test_utils"
local Notification = (require "st.zwave.CommandClass.Notification")({ version = 5 })
local t_utils = require "integration_test.utils"

local mock_sensor = test.mock_device.build_test_zwave_device({
  profile = t_utils.get_profile_definition("ezlo-water-sensor.yml"),
  zwave_endpoints = {{ command_classes = {
    { value = zw.BATTERY },
    { value = zw.WAKE_UP },
    { value = zw.NOTIFICATION },
    { value = zw.SENSOR_MULTILEVEL },
  }}},
  zwave_manufacturer_id = 0x025B,
  zwave_product_type = 0x0201,
  zwave_product_id = 0x000F,
})

test.set_test_init_function(function()
  test.mock_device.add_test_device(mock_sensor)
end)

local function notification_test(name, notification_type, event, expected)
  test.register_message_test(name, {
    {
      channel = "zwave",
      direction = "receive",
      message = { mock_sensor.id, zw_test_utils.zwave_test_build_receive_command(Notification:Report({
        notification_type = notification_type,
        event = event,
      })) },
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_sensor:generate_test_message("main", expected),
    },
  })
end

notification_test("Ezlo leak reports wet", Notification.notification_type.WATER,
  Notification.event.water.LEAK_DETECTED, capabilities.waterSensor.water.wet())

test.run_registered_tests()
