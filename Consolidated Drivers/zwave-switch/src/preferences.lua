-- Copyright 2021 SmartThings
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

local GE_BASIC = {
  PARAMETERS = {
    ledIndicator    = {type = 'config', parameter_number = 3, size = 1},
    invertSwitch    = {type = 'config', parameter_number = 4, size = 1},
    dimStepsZwave   = {type = 'config', parameter_number = 7, size = 1},
    dimTimeZwave    = {type = 'config', parameter_number = 8, size = 2},
    dimStepsManual  = {type = 'config', parameter_number = 9, size = 1},
    dimTimeManual   = {type = 'config', parameter_number = 10, size = 2},
    dimStepsAll     = {type = 'config', parameter_number = 11, size = 1},
    dimTimeAll      = {type = 'config', parameter_number = 12, size = 2},
    switchMode      = {type = 'config', parameter_number = 16, size = 1},       -- fw 5.26+
    excludeProtect  = {type = 'config', parameter_number = 19, size = 1},
    minDim          = {type = 'config', parameter_number = 20, size = 1},       -- fw 5.26+
    assocGroup2     = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
    assocGroup3     = {type = 'assoc', group = 3, maxnodes = 4, addhub = true},
  },
  BUTTONS = {
    count = 1,
    values = {'up_2x','down_2x','pushed_2x'},
  },
}

local GE_SCENE = {
  PARAMETERS = {
    powerReset      = {type = 'config', parameter_number = 1, size = 1},
    energyMode      = {type = 'config', parameter_number = 2, size = 1},
    energyFrequency = {type = 'config', parameter_number = 3, size = 1},
    ledIndicator    = {type = 'config', parameter_number = 3, size = 1},
    invertSwitch    = {type = 'config', parameter_number = 4, size = 1},
    dimRate         = {type = 'config', parameter_number = 6, size = 1},
    switchMode      = {type = 'config', parameter_number = 16, size = 1},
    excludeProtect  = {type = 'config', parameter_number = 19, size = 1},
    minDim          = {type = 'config', parameter_number = 30, size = 1},
    maxBright       = {type = 'config', parameter_number = 31, size = 1},
    defaultBright   = {type = 'config', parameter_number = 32, size = 1},
    assocGroup2     = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
    assocGroup3     = {type = 'assoc', group = 3, maxnodes = 5, addhub = false},
  },
  BUTTONS = {
    count = 1,
    values = {'up','down','pushed','up_hold','down_hold','held','up_2x','down_2x','pushed_2x','up_3x','down_3x','pushed_3x'},
  },
}
local GE_MOTION = {
  PARAMETERS = {
    timeoutDuration   = {type = 'config', parameter_number = 1, size = 1},
    --assocBright       = {type = 'config', parameter_number = 2, size = 2},
    operationMode     = {type = 'config', parameter_number = 3, size = 1},
    --associationMode   = {type = 'config', parameter_number = 4, size = 1},
    invertSwitch      = {type = 'config', parameter_number = 5, size = 1},
    enableMotion      = {type = 'config', parameter_number = 6, size = 1},
    dimStepsZwave     = {type = 'config', parameter_number = 7, size = 1},
    dimTimeZwave      = {type = 'config', parameter_number = 8, size = 2},
    dimStepsManual    = {type = 'config', parameter_number = 9, size = 1},
    dimTimeManual     = {type = 'config', parameter_number = 10, size = 2},
    dimStepsAll       = {type = 'config', parameter_number = 11, size = 1},
    dimTimeAll        = {type = 'config', parameter_number = 12, size = 2},
    motionSensitivity = {type = 'config', parameter_number = 13, size = 1},
    lightSensing      = {type = 'config', parameter_number = 14, size = 1},
    resetCycle        = {type = 'config', parameter_number = 15, size = 2},
    switchMode        = {type = 'config', parameter_number = 16, size = 1},
    switchLevel       = {type = 'config', parameter_number = 17, size = 1},
    dimRate           = {type = 'config', parameter_number = 18, size = 1},
    excludeProtect    = {type = 'config', parameter_number = 19, size = 1},
    assocGroup2       = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
    assocGroup3       = {type = 'assoc', group = 3, maxnodes = 5, addhub = false},
  },
  BUTTONS = {}
}

local devices = {
  GE_SWITCH_BASIC = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4952, 0x5257},
      product_ids = {0x3032, 0x3033, 0x3034, 0x3036, 0x3037, 0x3038, 0x3130, 0x3533},
    },
    PARAMETERS = GE_BASIC.PARAMETERS,
    BUTTONS = GE_BASIC.BUTTONS,
  },
  GE_DIMMER_BASIC = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4450, 0x4944},
      product_ids = {0x3030, 0x3031, 0x3032, 0x3033, 0x3035, 0x3036, 0x3037, 0x3038, 0x3039, 0x3130, 0x3135, 0x3136, 0x3233},
    },
    PARAMETERS = GE_BASIC.PARAMETERS,
    BUTTONS = GE_BASIC.BUTTONS,
  },
  GE_FAN_BASIC = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4944},
      product_ids = {0x3034, 0x3131, 0x3138},
    },
    PARAMETERS = GE_BASIC.PARAMETERS,
    BUTTONS = GE_BASIC.BUTTONS,
  },
  GE_OUTLET_BASIC = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4952, 0x5252},
      product_ids = {0x3031, 0x3035, 0x3133, 0x3134, 0x3530},
    },
    PARAMETERS = GE_BASIC.PARAMETERS,
    BUTTONS = GE_BASIC.BUTTONS,
  },
  GE_PLUGIN_BASIC = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4F50, 0x5052, 0x5250, 0x6363},
      product_ids = {0x3030, 0x3031, 0x3032, 0x3033, 0x3038, 0x3039, 0x3130, 0x3132},
    },
    PARAMETERS = GE_BASIC.PARAMETERS,
    BUTTONS = GE_BASIC.BUTTONS,
  },
  GE_PLUGDIM_BASIC = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x5044},
      product_ids = {0x3031, 0x3033, 0x3037, 0x3038, 0x3130, 0x3132},
    },
    PARAMETERS = GE_BASIC.PARAMETERS,
    BUTTONS = GE_BASIC.BUTTONS,
  },
  GE_HEAVYSWITCH_BASIC = {
    MATCHING_MATRIX = {
      mfrs = {0x0063},
      product_types = {0x4F44},
      product_ids = {0x3031},
    },
    PARAMETERS = GE_BASIC.PARAMETERS,
    BUTTONS = {},
  },
  GE_SWITCH_SCENE = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4952},
      product_ids = {0x3135, 0x3136, 0x3137, 0x3139, 0x3231, 0x3237, 0x3238},
    },
    PARAMETERS = GE_SCENE.PARAMETERS,
    BUTTONS = GE_SCENE.BUTTONS,
  },
  GE_DIMMER_SCENE = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4944},
      product_ids = {0x3132, 0x3235, 0x3237, 0x3333, 0x3334, 0x3339, 0x3431},
    },
    PARAMETERS = GE_SCENE.PARAMETERS,
    BUTTONS = GE_SCENE.BUTTONS,
  },
  GE_FAN_SCENE = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4944},
      product_ids = {0x3337},
    },
    PARAMETERS = GE_SCENE.PARAMETERS,
    BUTTONS = GE_SCENE.BUTTONS,
  },
  GE_OUTLET_SCENE = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4952},
      product_ids = {0x3233,0x3234,0x3235},
    },
    PARAMETERS = GE_SCENE.PARAMETERS,
    BUTTONS = GE_SCENE.BUTTONS,
  },
  GE_PLUGIN_SCENE = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4F50},
      product_ids = {0x3034},
    },
    PARAMETERS = GE_SCENE.PARAMETERS,
    BUTTONS = GE_SCENE.BUTTONS,
  },
  GE_MOTIONSWITCH_ASSOC = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x494D},
      product_ids = {0x3031,0x3032},
    },
    PARAMETERS = GE_MOTION.PARAMETERS,
    BUTTONS = GE_MOTION.BUTTONS,
  },
  GE_MOTIONDIMMER_ASSOC = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x494D},
      product_ids = {0x3033,0x3034},
    },
    PARAMETERS = GE_MOTION.PARAMETERS,
    BUTTONS = GE_MOTION.BUTTONS,
  },
  GE_HEAVYSWITCH_SCENE = {
    MATCHING_MATRIX = {
      mfrs = {0x0039, 0x0063},
      product_types = {0x4F44},
      product_ids = {0x3032},
    },
    PARAMETERS = GE_SCENE.PARAMETERS,
    BUTTONS = GE_SCENE.BUTTONS,
  },
  ZOOZ_ZEN32 = {
    MATCHING_MATRIX = {
      mfrs = 0x027A,
      product_types = 0x7000,
      product_ids = 0xA008
    },
    PARAMETERS = {
      relayAutoTurnOff        = {type = 'config', parameter_number = 16, size = 4},
      relayAutoTurnOn         = {type = 'config', parameter_number = 17, size = 4},
      stateAfterPowerFailure  = {type = 'config', parameter_number = 18, size = 1},
      relayControl            = {type = 'config', parameter_number = 19, size = 1},
      disabledRelayReporting  = {type = 'config', parameter_number = 20, size = 1},
      threeWaySwitchType      = {type = 'config', parameter_number = 21, size = 1},
      assocGroup2             = {type = 'assoc', group = 2, maxnodes = 10, addhub = false},
      assocGroup3             = {type = 'assoc', group = 3, maxnodes = 10, addhub = false},
      assocGroup4             = {type = 'assoc', group = 4, maxnodes = 10, addhub = false},
      assocGroup5             = {type = 'assoc', group = 5, maxnodes = 10, addhub = false},
      assocGroup6             = {type = 'assoc', group = 6, maxnodes = 10, addhub = false},
      assocGroup7             = {type = 'assoc', group = 7, maxnodes = 10, addhub = false},
      assocGroup8             = {type = 'assoc', group = 8, maxnodes = 10, addhub = false},
      assocGroup9             = {type = 'assoc', group = 9, maxnodes = 10, addhub = false},
      assocGroup10            = {type = 'assoc', group = 10, maxnodes = 10, addhub = false},
      assocGroup11            = {type = 'assoc', group = 11, maxnodes = 10, addhub = false},
    }
  },
  ZEN51 = {
    MATCHING_MATRIX = {
      mfrs = 0x027A,
      product_types = 0x0104,
      product_ids = 0x0201
    },
    PARAMETERS = {
      ledIndicator            = {type = 'config', parameter_number = 1, size = 1},
      autoTurnOff             = {type = 'config', parameter_number = 2, size = 2},
      autoTurnOn              = {type = 'config', parameter_number = 3, size = 2},
      powerFailure            = {type = 'config', parameter_number = 4, size = 1},
      sceneControl            = {type = 'config', parameter_number = 5, size = 1},
      smartBulbMode           = {type = 'config', parameter_number = 6, size = 1},
      externalSwitchType      = {type = 'config', parameter_number = 7, size = 1},
      associationReports      = {type = 'config', parameter_number = 8, size = 1},
      relayTypeBehavior       = {type = 'config', parameter_number = 9, size = 1},
      timerUnit               = {type = 'config', parameter_number = 10, size = 1},
      impulseDuration         = {type = 'config', parameter_number = 11, size = 1},
      assocGroup2             = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
    }
  },
  LZW36 = {
    MATCHING_MATRIX = {
      mfrs = 0x031E,
      product_types = 0x000E,
      product_ids = 0x0001
    },
    PARAMETERS = {
      dimmingSpeed            = {type = 'config', parameter_number = 1, size = 1},
      dimmingSpeedSwitch      = {type = 'config', parameter_number = 2, size = 1},
      rampRate                = {type = 'config', parameter_number = 3, size = 1},
      rampRateSwitch          = {type = 'config', parameter_number = 4, size = 1},
      lightMinLevel           = {type = 'config', parameter_number = 5, size = 1},
      lightMaxLevel           = {type = 'config', parameter_number = 6, size = 1},
      fanMinLevel             = {type = 'config', parameter_number = 7, size = 1},
      fanMaxLevel             = {type = 'config', parameter_number = 8, size = 1},
      lightAutoOffTimer       = {type = 'config', parameter_number = 10, size = 2},
      fanAutoOffTimer         = {type = 'config', parameter_number = 11, size = 2},
      lightDefaultLocal       = {type = 'config', parameter_number = 12, size = 2},
      lightDefaultZwave       = {type = 'config', parameter_number = 13, size = 1},
      fanDefaultLocal         = {type = 'config', parameter_number = 14, size = 1},
      fanDefaultZwave         = {type = 'config', parameter_number = 15, size = 1},
      lightPowerRestore       = {type = 'config', parameter_number = 16, size = 1},
      fanPowerRestore         = {type = 'config', parameter_number = 17, size = 1},
      lightLEDIntensityOff    = {type = 'config', parameter_number = 22, size = 1},
      fanLEDIntensityOff      = {type = 'config', parameter_number = 23, size = 1},
      lightLEDTimeout         = {type = 'config', parameter_number = 26, size = 1},
      fanLEDTimeout           = {type = 'config', parameter_number = 27, size = 1},
      powerReports            = {type = 'config', parameter_number = 28, size = 1},
      periodicPowerEnergy     = {type = 'config', parameter_number = 29, size = 2},
      energyReports           = {type = 'config', parameter_number = 30, size = 1},
      assocGroup2             = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
      assocGroup3             = {type = 'assoc', group = 3, maxnodes = 5, addhub = false},
      assocGroup4             = {type = 'assoc', group = 4, maxnodes = 5, addhub = false},
      assocGroup5             = {type = 'assoc', group = 5, maxnodes = 5, addhub = false},
      assocGroup6             = {type = 'assoc', group = 6, maxnodes = 5, addhub = false},
      assocGroup7             = {type = 'assoc', group = 7, maxnodes = 5, addhub = false},
    }
  },
  LZW45 = {
    MATCHING_MATRIX = {
      mfrs = 0x031E,
      product_types = 0x000A,
      product_ids = 0x0001
    },
    PARAMETERS = {
      parameter001            = {type = 'config', parameter_number = 1, size = 1},
      parameter002            = {type = 'config', parameter_number = 2, size = 1},
      parameter003            = {type = 'config', parameter_number = 3, size = 1},
      parameter004            = {type = 'config', parameter_number = 4, size = 1},
      parameter005            = {type = 'config', parameter_number = 5, size = 1},
      parameter006            = {type = 'config', parameter_number = 6, size = 2},
      parameter007            = {type = 'config', parameter_number = 7, size = 1},
      parameter008            = {type = 'config', parameter_number = 8, size = 1},
      parameter009            = {type = 'config', parameter_number = 9, size = 4},
      parameter010            = {type = 'config', parameter_number = 10, size = 1},
      parameter017            = {type = 'config', parameter_number = 17, size = 1},
      parameter018            = {type = 'config', parameter_number = 18, size = 2},
      parameter019            = {type = 'config', parameter_number = 19, size = 1},
      parameter051            = {type = 'config', parameter_number = 51, size = 1},
      assocGroup2             = {type = 'assoc', group = 2, maxnodes = 5, addhub = false},
      assocGroup3             = {type = 'assoc', group = 3, maxnodes = 5, addhub = false},
      assocGroup4             = {type = 'assoc', group = 4, maxnodes = 5, addhub = false},
    }
  },
  NZW97 = {
    MATCHING_MATRIX = {
      mfrs = 0x0312,
      product_types = 0x6100,
      product_ids = 0x6100
    },
    PARAMETERS = {
      ledIndicator            = {type = 'config', parameter_number = 1, size = 1 },
      autoOffChannel1         = {type = 'config', parameter_number = 2, size = 2 },
      autoOffChannel2         = {type = 'config', parameter_number = 3, size = 2 },
    }
  },
  REMOTEC_ZFM80 = {
    MATCHING_MATRIX = {
      mfrs = 0x5254,
      product_types = 0x8000,
      product_ids = 0x0002,
    },
    PARAMETERS = {
      externalSwitchType      = {type = 'config', parameter_number = 1, size = 1},
      assocGroup1             = {type = 'assoc', group = 1, maxnodes = 5, addhub = false},
    }
  },
}
local preferences = {}

preferences.get_device_parameters = function(zw_device)
  for _, device in pairs(devices) do
    if zw_device:id_match(
      device.MATCHING_MATRIX.mfrs,
      device.MATCHING_MATRIX.product_types,
      device.MATCHING_MATRIX.product_ids) then
      return device.PARAMETERS
    end
  end
  return nil
end

preferences.get_buttons = function(zw_device)
  for _, device in pairs(devices) do
    if zw_device:id_match(
      device.MATCHING_MATRIX.mfrs,
      device.MATCHING_MATRIX.product_types,
      device.MATCHING_MATRIX.product_ids) then
      return device.BUTTONS
    end
  end
  return nil
end

preferences.to_numeric_value = function(new_value)
  local numeric = tonumber(new_value)
  if numeric == nil then -- in case the value is boolean
    numeric = new_value and 1 or 0
  end
  return numeric
end

return preferences
