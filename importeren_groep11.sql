-- data importeren

-- opvullen station
INSERT INTO station
SELECT DISTINCT station,
				lengtegraad,
				breedtegraad
FROM super_planning;

-- opvullen buitenlands
INSERT INTO buitenlands
SELECT DISTINCT station,
				station_landcode::char(2)
FROM super_planning WHERE station_landcode IS NOT NULL;

-- opvullen binnenlands
INSERT INTO binnenlands
SELECT DISTINCT station
FROM super_vertalingen;

-- opvullen binnenlands_volledigevertaling
INSERT INTO binnenlands_volledigevertaling
SELECT DISTINCT station,
				landcode_vertaling::char(2),
				vertaling
FROM super_vertalingen;

-- opvullen traject
INSERT INTO traject
SELECT DISTINCT traject
FROM super_planning;

-- opvullen treinsoort
INSERT INTO treinsoort
SELECT DISTINCT treinsoort,
				categorie
FROM super_planning;

-- opvullen trip
INSERT INTO trip
SELECT DISTINCT tripcode,
				maximale_capaciteit::INTEGER,
				treinsoort,
				traject
FROM super_planning;

-- opvullen  trip_data
INSERT INTO trip_data
SELECT DISTINCT tripcode,
                to_date(datum, 'YYYY-MM-DD')
FROM super_datums;

-- opvullen trip_halte
INSERT INTO trip_halte
SELECT DISTINCT verwachte_bezetting::INTEGER,
                haltenummer::INTEGER,
                tripcode,
                vertrek::time,
                vertrek_volgende_dag::boolean,
                aankomst::time,
                aankomst_volgende_dag::boolean,
                station
FROM super_planning;