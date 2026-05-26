-- Singular test: assert_channel_conversion_rate_is_valid
--
-- Business rule: conversion_rate must always be between 0 and 100
-- because it is a percentage (conversions / total_sessions * 100)
--
-- HOW THIS TEST WORKS:
-- This query finds VIOLATIONS of the rule — rows where the rate is impossible
-- If this query returns ZERO rows → test passes (no violations found)
-- If this query returns ANY rows  → test fails (here are the broken records)

select
    source,
    device_type,
    conversion_rate
from {{ ref('mart_channel_performance') }}
where conversion_rate < 0      -- impossible: can't have negative conversion rate
   or conversion_rate > 100    -- impossible: can't convert more than 100% of sessions