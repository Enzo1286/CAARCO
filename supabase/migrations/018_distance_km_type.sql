-- Migration 018 : élargir distance_km de NUMERIC(6,2) à NUMERIC(8,2)
-- NUMERIC(6,2) max = 9999.99 km — trop limité si l'app s'étend hors du Cameroun.
-- NUMERIC(8,2) max = 999999.99 km — largement suffisant.
ALTER TABLE courses
  ALTER COLUMN distance_km TYPE NUMERIC(8,2);
