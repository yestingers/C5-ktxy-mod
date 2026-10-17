-- Required DLL event hooks. SP already enables some of these; updates are idempotent.
UPDATE CustomModOptions SET Value = 1 WHERE Name IN (
  'EVENTS_CITY_CAPITAL', 'EVENTS_UNIT_PREKILL', 'EVENTS_NEW_ERA',
  'EVENTS_COMMAND', 'EVENTS_UNIT_UPGRADES', 'EVENTS_MINORS_INTERACTION', 'EVENTS_CITY'
);
