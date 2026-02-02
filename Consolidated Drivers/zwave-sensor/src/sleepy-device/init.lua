-- Copyright 2022 philh30
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
-- Support subdriver for zwave sleepy devices.
-- 

local WakeUp = (require "st.zwave.CommandClass.WakeUp")({ version = 1 })
local Battery = (require "st.zwave.CommandClass.Battery")({ version = 1 })
local cc = require "st.zwave.CommandClass"
local call_parent_handler = require "call_parent"
local battery = require "battery"


local function can_handle_sleepy_device(opts, driver, device, ...)
    return device:is_cc_supported(cc.WAKE_UP)
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param force  boolean|nil      Force battery update regardless of timing
local function maybe_getBatteryUpdate(self, device, force)
  local prefs = device.preferences
  if not prefs
     or prefs.batteryInterval == nil
     or prefs.wakeUpInterval == nil then
    device.log.trace("Skipping getBatteryUpdate: batteryInterval/wakeUpInterval not supported in profile")
    return false
  end

  return battery.getBatteryUpdate(self, device, force) == true
end

--- @param self st.zwave.Driver
--- @param device st.zwave.Device
--- @param cmd st.zwave.CommandClass.WakeUp.Notification
local function wakeup_notification(self, device, cmd)
  device.log.trace("wakeup_notification(sleepy-device)")

  -- If we've not yet configured the device, execute it now.  This can be if we switched drivers.
  if device:get_field("device_configured") ~= true then
    device.log.debug("Configuration of device pending, calling doConfigure")
    call_parent_handler(self.lifecycle_handlers.doConfigure, self, device, "doConfigure")
  end

  -- If we support the battery wakeup/update prefs, then we may request a battery update.
  if maybe_getBatteryUpdate(self, device) then
    -- Request a battery update now
    device:send(Battery:Get({}))
  end

  device.log.trace("wakeup_notification(sleepy-device) - calling default handlers")
  -- The default handlers take care of the deferred preferences changes on wakeup.
  call_parent_handler(self.zwave_handlers[cc.WAKE_UP][WakeUp.NOTIFICATION], self, device, cmd)
end

local sleepy_device = {
    NAME = "Sleepy Device",
    zwave_handlers = {
        [cc.WAKE_UP] = {
            [WakeUp.NOTIFICATION] = wakeup_notification,
        },
    },
    can_handle = can_handle_sleepy_device,
}

return sleepy_device