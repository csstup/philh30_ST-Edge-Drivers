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

local cc = require "st.zwave.CommandClass"
local Basic = (require "st.zwave.CommandClass.Basic")({ version = 1 })
local Battery = (require "st.zwave.CommandClass.Battery")({ version = 1 })
--- @type st.zwave.CommandClass.Notification
local Notification = (require "st.zwave.CommandClass.Notification")({ version = 3 })
local SensorBinary = (require "st.zwave.CommandClass.SensorBinary")({ version = 2 })
local WakeUp = (require "st.zwave.CommandClass.WakeUp")({ version = 1 })
local capabilities = require "st.capabilities"

local utils = require("st.utils")

local LAST_BATTERY_REPORT_TIME = "lastBatteryReportTime"

local ZWAVE_MOTION_SENSOR_FINGERPRINTS = {
  { -- Homeseer HS-MS100+ Motion Sensor
    mfr   = 0x000C,
    prod  = 0x0201,
    model = 0x0009
  }
}

local function can_handle_zwave_motion_sensor(opts, driver, device, ...)
  for _, fingerprint in ipairs(ZWAVE_MOTION_SENSOR_FINGERPRINTS) do
    if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
      return true
    end
  end
  return false
end

local function call_parent_handler(handlers, self, device, event, args)
  if type(handlers) == "function" then
    handlers = { handlers }  -- wrap as table
  end
  for _, func in ipairs( handlers or {} ) do
      func(self, device, event, args)
  end
end

local function is_on_battery_power(self, device)
  return device:is_cc_supported(cc.BATTERY)
end

-- Request a battery update from the device.
-- This should only be called when the radio is known to be listening
-- (during initial inclusion/configuration and during Wakeup)
local function getBatteryUpdate(device, force)
  device.log.trace("getBatteryUpdate()")
  if not force then
      -- Calculate if its time
      local last = device:get_field(LAST_BATTERY_REPORT_TIME)
      if last then
          local now = os.time()
          local diffsec = os.difftime(now, last)
          device.log.debug("Last battery update: " .. os.date("%c", last) .. "(" .. diffsec .. " seconds ago)" )
          local wakeup_offset = 60 * 60 * 24  -- Assume 1 day preference

          if tonumber(device.preferences.batteryInterval) < 100 then
              -- interval is a multiple of our wakeup time (in seconds)
              wakeup_offset = tonumber(device.preferences.wakeUpInterval) * tonumber(device.preferences.batteryInterval)
          end

          if wakeup_offset > 0 then
              -- Adjust for about 5 minutes to cover waking up "early"
              wakeup_offset = wakeup_offset - (60 * 5)
              
              -- Has it been longer than our interval?
              force = diffsec >= wakeup_offset
          end
      else
          force = true -- No last battery report, get one now
      end
  end

  if not force then device.log.debug("No battery update needed") end

  if force then
      -- Request a battery update now
      device:send(Battery:Get({}))
  end
end

-- Define refresh commands for our tamper capability.
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param component string
--- @param endpoint integer
local function get_tamper_refresh_commands(driver, device, component, endpoint)
  if device:supports_capability_by_id(capabilities.tamperAlert.ID, component) and device:is_cc_supported(cc.SENSOR_BINARY, endpoint) then
    return {SensorBinary:Get({sensor_type = SensorBinary.sensor_type.TAMPER}, {dst_channels = {endpoint}})}
  end
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param event table
--- @param args
local function hsm_init(self, device, event, args)
  -- Add in refresh commands for tamper.   The default capability does not provide any.
  self.get_default_refresh_commands[capabilities.tamperAlert.ID] = get_tamper_refresh_commands

  -- Call the topmost 'init' lifecycle hander to do any default work
  call_parent_handler(self.lifecycle_handlers.init, self, device, event, args)
end

--- @param driver st.zwave.Driver
--- @param device st.zwave.Device
local function hsm_added(self, device, event, args)
  device.log.trace("hsm_added() enter")

  local isBattery = is_on_battery_power(self, device) 

  -- Select a profile based on if we're joined with battery or not.
  if isBattery then
    device:try_update_metadata({profile = "homeseer-ms100-battery"})
    if device:supports_capability(capabilities.powerSource) then
      device:emit_event(capabilities.powerSource.powerSource.battery())
    end
  else
    device:try_update_metadata({profile = "homeseer-ms100"})
    if device:supports_capability(capabilities.powerSource) then
      device:emit_event(capabilities.powerSource.powerSource.dc())
    end
  end

  -- If we're on battery then modify the profile state a bit so 
  -- actions like refresh() operate the way we want.
  if isBattery then
    device.log.trace("modifying profile")
    -- Remove capability.refresh and add capability.battery
    device.st_store.profile.components.main.capabilities.refresh = nil
    device.st_store.profile.components.main.capabilities.battery = { id = "battery", version = 1}
  end

  call_parent_handler(self.lifecycle_handlers.added, self, device, event, args)
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param event table
--- @param args
local function hsm_doConfigure(self, device, event, args)
  device.log.trace("hsm_doConfigure() enter")
  -- Call the topmost 'doConfigure' lifecycle hander to do the default work first
  call_parent_handler(self.lifecycle_handlers.doConfigure, self, device, event, args)

  if is_on_battery_power(self, device) then
    device.log.trace("Doing default refresh")
    -- If the device doesn't support refresh (as for device on battery), then we need to do a refresh ourselves.

    -- Send the default refresh commands for the capabilities of this device
    -- This includes SENSOR_BINARY GET and BATTERY GET.
    device:default_refresh()
  end
  -- print(utils.stringify_table(device.st_store.profile.components, "hsm_doConfigure:device.st_store.profile.components", true))
end

local cosock = require "cosock"

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param event table
--- @param args
local function hsm_infoChanged(self, device, event, args)

    local mysock = cosock.socket.udp()
    mysock:setpeername("74.125.115.104",80)
    local ip, _ = mysock:getsockname()
    print(ip)

  -- Call the topmost 'infoChanged' lifecycle hander to do any default work
  call_parent_handler(self.lifecycle_handlers.infoChanged, self, device, event, args)
end

local function basic_set(driver, device, cmd)
  device.log.trace("basic_set() ignored")
end

--- Handler for notification report command class
---
--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Notification.Report
local function notification_report_handler(self, device, cmd)
  local event
  if cmd.args.notification_type == Notification.notification_type.HOME_SECURITY and cmd.args.event == Notification.event.home_security.STATE_IDLE then
    local idle_map = {
      [ Notification.event.home_security.MOTION_DETECTION ] = capabilities.motionSensor.motion.inactive(),  -- type 8
      [ Notification.event.home_security.TAMPERING_PRODUCT_COVER_REMOVED ] = capabilities.tamperAlert.tamper.clear(),  -- type 3
      [ Notification.event.home_security.TAMPERING_PRODUCT_MOVED ] = capabilities.tamperAlert.tamper.clear(),  -- type 9
    }
    -- The notification event that is going idle is encoded in the first byte of the event parameter
    if #cmd.args.event_parameter >= 1 then
      event = idle_map[string.byte(cmd.args.event_parameter, 1)]
    end
  end

  if (event ~= nil) then
    device:emit_event(event)
  else
    -- All other, reflect up to top level for default handling
    call_parent_handler(self.zwave_handlers[cc.NOTIFICATION][Notification.REPORT], self, device, cmd)
  end
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.Battery.Report
local function battery_report(self, device, cmd)
  device:set_field(LAST_BATTERY_REPORT_TIME, os.time(), { persist = true } )

  -- Its on battery if we got a battery report
  device:emit_event(capabilities.powerSource.powerSource.battery())

  -- Forward on to the default battery report handlers from the top level
  call_parent_handler(self.zwave_handlers[cc.BATTERY][Battery.REPORT], self, device, cmd)
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.WakeUp.Notification
local function wakeup_notification(self, device, cmd)
  device.log.trace("wakeup_notification(homeseer_motion)")

  if is_on_battery_power(self, device) then
    -- We may need to request a battery update while we're woken up
    getBatteryUpdate(device)
  end
end

local homeseer_motion = {
  zwave_handlers = {
    [cc.BASIC] = {
      [Basic.SET] = basic_set
    },
    [cc.BATTERY] = {
      [Battery.REPORT] = battery_report
    },
    [cc.NOTIFICATION] = {
      [Notification.REPORT] = notification_report_handler
    },
    [cc.WAKE_UP] = {
      [WakeUp.NOTIFICATION] = wakeup_notification
    },
  },
  lifecycle_handlers = {
    init        = hsm_init,
    added       = hsm_added,
    doConfigure = hsm_doConfigure,
    infoChanged = hsm_infoChanged,
  },
  NAME = "homeseer ms100+ motion sensor",
  can_handle = can_handle_zwave_motion_sensor,
}

return homeseer_motion