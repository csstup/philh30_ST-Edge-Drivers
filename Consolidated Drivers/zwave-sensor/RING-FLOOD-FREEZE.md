# Ring Flood and Freeze Sensor

Model 4SF1S80EN0, US fingerprint `0346/0501/0101`, uses the
`ring-flood-freeze` profile. Standard SmartThings Z-Wave capability handlers
process water, freeze, tamper, and battery reports. This model reports a freeze
alarm rather than a continuous temperature measurement.

The existing driver configuration establishes association group 1 (lifeline).
Settings use the driver's existing deferred preference handling for sleeping
devices. Close the cover to wake the sensor and apply pending settings.

| Preference | Parameter | Bytes | Range | Default |
| --- | --- | --- | --- | --- |
| Heartbeat interval (seconds) | 1 | 2 | 255–4200 | 4200 |

Parameter 2 is a self-resetting one-shot wake-up timer and is intentionally
not a persistent preference. Parameters 3–5 (application retries, retry delay,
and supervision response wait) are intentionally left at the device's existing
values and are not exposed as preferences. Wake-up uses the normal interval selector with
choices from 1 to 24 hours. The driver defaults to 12 hours; a factory default
was not documented in the sources below. Battery requests use the existing
battery update interval preference, in addition to automatic heartbeat reports.

Sources:
- [Ring technical manuals](https://ring.com/support/articles/3aeym/Ring-Alarm-Z-Wave-Technical-Information)
- [Ring technical PDF](https://d1kusojqr3t85q.cloudfront.net/jrz4hnnvdyct/185ugXCSMgrspin6ZryIBU/0c60548e787b7b9f52aac978cbfc962d/Ring_Flood_Freeze_Sensor_Zwave_NA.pdf): parameters 1–3.
- [Certification-derived manual, ZC10-19016344](https://manual.zwave.eu/backend/make.php?cert=ZC10-19016344&lang=en&sku=4SF1S80EN0&type=mini): fingerprint, wake-up limits, and parameters 1–5.

After installing the updated driver, pair the sensor or switch it to this driver.
If an existing device retains the generic profile, re-pair it to select the new
fingerprint/profile. Verify wet/dry, freeze/clear, cover tamper, and battery
reporting on actual hardware before relying on automations.
