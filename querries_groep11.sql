
select count(distinct soortnaam) from treinsoort where verbindingscategorie ilike 'lokaal';

select count(distinct naam) from trip where soortnaam ilike 'IC';

select count(distinct naam) from buitenlands where landcode ilike 'fr';

select count(distinct vertaling) from binnenlands_volledigeVertaling where landcode ILIKE 'en';

select count(distinct code) from trip where max_capaciteit>=300;

select count(distinct code) from trip_data where to_char(datum,'DD/MM/YYYY') ilike '19/09/2021';

select max(nummer) from trip_halte;