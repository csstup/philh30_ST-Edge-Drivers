-- Copyright 2026 csstup
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

--
-- Ring Alarm Range Extender Gen 1 / Gen 2 support.
-- Handles AC mains / battery power-source reporting, Gen 1 charging
-- notifications, and Ring Gen 2 Battery Command Class v3 status reporting.
--

local capabilities = require "st.capabilities"
--- @type st.zwave.CommandClass
local cc = require "st.zwave.CommandClass"
--- @type st.zwave.CommandClass.Battery
local Battery = (require "st.zwave.CommandClass.Battery")({ version = 3 })
--- @type st.zwave.CommandClass.Notification
local Notification = (require "st.zwave.CommandClass.Notification")({ version = 3 })
local call_parent_handler = require "call_parent"

local POWER_EVENT_STATE_IDLE = 0x00
local POWER_EVENT_AC_MAINS_DISCONNECTED = 0x02
local POWER_EVENT_AC_MAINS_RE_CONNECTED = 0x03
local POWER_EVENT_BATTERY_CHARGING = 0x0C

-- Battery CC Replace/Recharge values used by the Ring.
-- Observed on Gen 2 during testing:
--   0 = no warning
--   1 = warning (first observed at 10%)
--   3 = critical (observed from the low single digits through 0%)
-- Value 2 is also treated as critical defensively.
local REPLACE_RECHARGE_SOON = 0x01
local REPLACE_RECHARGE_NOW = 0x02
local REPLACE_RECHARGE_CRITICAL = 0x03

-- Percentage fallback / hysteresis thresholds.  Ring's percentage is strongly
-- voltage-derived and can move up or down a few points while discharging.
local BATTERY_WARNING_ENTER_PERCENT = 20
local BATTERY_WARNING_CLEAR_PERCENT = 25
local BATTERY_CRITICAL_ENTER_PERCENT = 5
local BATTERY_CRITICAL_CLEAR_PERCENT = 10
local BATTERY_LEVEL_LOW_WARNING = 0xFF

local RING_EXTENDER_FINGERPRINTS = {
  { manufacturerId = 0x0346, productType = 0x0401, productId = 0x0101 }, -- Ring Range Extender Gen 1 (early US revision)
  { manufacturerId = 0x0346, productType = 0x0401, productId = 0x0201 }, -- Ring Range Extender Gen 1 US
  { manufacturerId = 0x0346, productType = 0x0401, productId = 0x0202 }, -- Ring Range Extender Gen 1 UK
  { manufacturerId = 0x0346, productType = 0x0401, productId = 0x0301 }, -- Ring Range Extender Gen 2 US
}

local function can_handle_ring_extender(opts, driver, device, ...)
  for _, fingerprint in ipairs(RING_EXTENDER_FINGERPRINTS) do
    if device:id_match(fingerprint.manufacturerId, fingerprint.productType, fingerprint.productId) then
      return true
    end
  end
  return false
end

local function emit_power_source(device, source)
  if source == "battery" then
    device:emit_event(capabilities.powerSource.powerSource.battery())
  elseif source == "mains" then
    device:emit_event(capabilities.powerSource.powerSource.mains())
  end
end

--- Power-source Notification Reports do not include a Battery Report.
--- Re-query Battery CC shortly after the reported power state so chargingState
--- and batteryLevel are kept in sync for both unsolicited transitions and refresh.
local function refresh_battery_after_power_state(device)
  if not device:is_cc_supported(cc.BATTERY) then
    return
  end

  device.thread:call_with_delay(1, function()
    device.log.info("Power source reported; refreshing Ring Range Extender battery status")
    device:send(Battery:Get({}))
  end)
end

--- Handle Ring Power Management Notification Reports.
--- 0x02 = AC mains disconnected -> running from battery
--- 0x03 = AC mains re-connected -> running from mains
--- 0x0C = battery is charging (Gen 1 reports charging via Notification CC)
--- For a targeted GET of event 0x02, STATE_IDLE with event_parameter=0x02
--- means AC_MAINS_DISCONNECTED is not active, so the extender is on mains.
local function notification_report_handler(self, device, cmd)
  if cmd.args.notification_type ~= Notification.notification_type.POWER_MANAGEMENT then
    return
  end

  local source = nil

  if cmd.args.event == POWER_EVENT_AC_MAINS_DISCONNECTED then
    device.log.info("AC mains disconnected; Ring extender is running from battery")
    source = "battery"

    -- Gen 1 Battery CC v1 has no charging_status field, so derive the
    -- unambiguous discharging state from its Power Management notification.
    device:emit_event(capabilities.chargingState.chargingState.discharging())
  elseif cmd.args.event == POWER_EVENT_AC_MAINS_RE_CONNECTED then
    device.log.info("AC mains re-connected; Ring extender is running from mains")
    source = "mains"
  elseif cmd.args.event == POWER_EVENT_BATTERY_CHARGING then
    device.log.info("Ring extender battery is charging")
    source = "mains"
    device:emit_event(capabilities.chargingState.chargingState.charging())
  elseif cmd.args.event == POWER_EVENT_STATE_IDLE then
    local event_parameter = cmd.args.event_parameter
    local queried_event = nil

    if type(event_parameter) == "string" and #event_parameter > 0 then
      queried_event = string.byte(event_parameter, 1)
    end

    if queried_event == POWER_EVENT_AC_MAINS_DISCONNECTED then
      device.log.info("AC mains disconnected state is idle; Ring extender is running from mains")
      source = "mains"
    else
      device.log.debug("Power Management Notification returned STATE_IDLE; preserving current powerSource")
    end
  else
    device.log.debug("Unhandled Ring extender Power Management event: " .. tostring(cmd.args.event))
  end

  if source ~= nil then
    emit_power_source(device, source)
    refresh_battery_after_power_state(device)
  end
end

--- Ask for current power source. Ring does not return useful state for
--- Notification:Get(event=0). Querying AC_MAINS_DISCONNECTED (0x02) is enough:
---   event 0x02                 -> running from battery
---   STATE_IDLE, parameter 0x02 -> running from mains
--- The resulting power-source report schedules one Battery:Get.
local function refresh_handler(self, device, command)
  device.log.info("Refreshing Ring Range Extender power source and battery")

  device:send(Notification:Get({
    v1_alarm_type = 0,
    notification_type = Notification.notification_type.POWER_MANAGEMENT,
    event = POWER_EVENT_AC_MAINS_DISCONNECTED,
  }))
end

local function charging_state_event(device, cmd)
  local charging_status = cmd.args.charging_status

  if cmd.args.disconnected == true then
    return capabilities.chargingState.chargingState.error()
  elseif charging_status == Battery.charging_status.DISCHARGING or charging_status == "DISCHARGING" then
    return capabilities.chargingState.chargingState.discharging()
  elseif charging_status == Battery.charging_status.CHARGING or charging_status == "CHARGING" then
    return capabilities.chargingState.chargingState.charging()
  elseif charging_status == Battery.charging_status.MAINTAINING or charging_status == "MAINTAINING" then
    return capabilities.chargingState.chargingState.fullyCharged()
  elseif charging_status ~= nil then
    device.log.warn("Unknown Ring battery charging status: " .. tostring(charging_status))
    return capabilities.chargingState.chargingState.other()
  end

  return nil
end

--- Derive SmartThings batteryLevel from the Ring Battery CC v3 report.
---
--- Device-provided critical conditions win.  Otherwise, qualitative state is
--- latched with hysteresis so voltage-derived percentage / replace_recharge
--- rebounds cannot chatter SmartThings History:
---   warning:  enter <= 20%, clear >= 25%
---   critical: enter <=  5% (or replace 2/3), clear to warning >= 10%
local function battery_level_event(device, cmd)
  local battery_level = cmd.args.battery_level
  local replace_recharge = cmd.args.replace_recharge
  local current_battery_level = device:get_latest_state(
    "main", capabilities.batteryLevel.ID, "battery", nil)

  -- Explicit device-provided critical conditions always win.
  if cmd.args.disconnected == true or
      replace_recharge == REPLACE_RECHARGE_NOW or
      replace_recharge == REPLACE_RECHARGE_CRITICAL or
      battery_level == BATTERY_LEVEL_LOW_WARNING then
    return capabilities.batteryLevel.battery.critical()
  end

  -- Once critical, stay critical through low-end voltage/gauge rebounds.
  -- Testing showed replace_recharge can rebound from 3 to 1 along with the
  -- reported percentage. Do not downgrade until the percentage reaches 10%.
  if current_battery_level == "critical" and
      type(battery_level) == "number" and
      battery_level < BATTERY_CRITICAL_CLEAR_PERCENT then
    return capabilities.batteryLevel.battery.critical()
  end

  if replace_recharge == REPLACE_RECHARGE_SOON then
    return capabilities.batteryLevel.battery.warning()
  end

  if type(battery_level) ~= "number" then
    return nil
  end

  if battery_level <= BATTERY_CRITICAL_ENTER_PERCENT then
    return capabilities.batteryLevel.battery.critical()
  elseif battery_level <= BATTERY_WARNING_ENTER_PERCENT then
    return capabilities.batteryLevel.battery.warning()
  elseif (current_battery_level == "warning" or current_battery_level == "critical") and
      battery_level < BATTERY_WARNING_CLEAR_PERCENT then
    return capabilities.batteryLevel.battery.warning()
  end

  return capabilities.batteryLevel.battery.normal()
end

--- Handle Battery CC v3 status fields that are specific/useful to the Ring extender.
--- The generic battery-device subdriver still receives this same report and handles
--- battery percentage / timestamp normally.
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Battery.Report
local function battery_report_handler(self, device, cmd)
  local charging_event = charging_state_event(device, cmd)
  if charging_event ~= nil then
    device:emit_event(charging_event)
  end

  local level_event = battery_level_event(device, cmd)
  if level_event ~= nil then
    device:emit_event(level_event)
  end
end

local function device_added(self, device, event, args)
  -- Don't guess the initial power source. The targeted refresh below should
  -- resolve mains vs battery immediately.

  -- Preserve common handling from the parent driver (network ID, firmware, etc.).
  call_parent_handler(self.lifecycle_handlers.added, self, device, event, args)

  device.thread:call_with_delay(1, function()
    refresh_handler(self, device)
  end)
end

local function device_init(self, device)
  -- Preserve common init handling from the parent driver.
  call_parent_handler(self.lifecycle_handlers.init, self, device)

  -- Re-query after driver/hub startup. This covers the case where the hub
  -- missed the mains-restored notification while it was offline.
  device.thread:call_with_delay(2, function()
    refresh_handler(self, device)
  end)
end

local ring_range_extender = {
  NAME = "Ring Range Extender",
  zwave_handlers = {
    [cc.NOTIFICATION] = {
      [Notification.REPORT] = notification_report_handler,
    },
    [cc.BATTERY] = {
      [Battery.REPORT] = battery_report_handler,
    },
  },
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = refresh_handler,
    },
  },
  lifecycle_handlers = {
    added = device_added,
    init = device_init,
  },
  can_handle = can_handle_ring_extender,
}

return ring_range_extender
