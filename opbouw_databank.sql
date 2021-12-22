-- opbouw databank
-- leegmaken en verwijderen tabellen
drop trigger if exists check_uur_trigger on trip_halte;
drop trigger if exists check_capaciteit_trigger on trip_halte;
drop trigger if exists aankomstVolgendeDagTrue_trigger on trip_halte;
drop table if exists trip_halte;
drop table if exists trip_data;
drop table if exists trip;
drop table if exists treinsoort;
drop table if exists traject;
drop table if exists binnenlands_volledigeVertaling;
drop table if exists BINNENLANDS;
drop table if exists buitenlands;
drop table if exists station;
drop function if exists checkCapaciteit();
drop function if exists checkuur();
drop function if exists aankomstVolgendeDagTrue();

--functies
create function checkCapaciteit()
returns trigger 
language plpgsql 
as $BODY$
declare
trip_maxcapaciteit int;
begin
		select max_capaciteit into trip_maxcapaciteit from trip where code =NEW.code;

	if (new.verwachteBezetting>trip_maxcapaciteit) then
	raise exception 'verwachte_bezetting kan niet groter zijn dan max capaciteit: tripcode %', new.code;
	end if;
	return new;
	end;
	$BODY$;

	
create function checkuur()
returns trigger 
language plpgsql 
as $BODY$
DECLARE
halte_vertrekVolgendeDag boolean;
halte_aankomstVolgendeDag boolean;
begin
	select vertrekVolgendeDag into halte_vertrekVolgendeDag from trip_halte where code =NEW.code and nummer=new.nummer;
	select aankomstVolgendeDag into halte_aankomstVolgendeDag from trip_halte where code=new.code and nummer=new.nummer;
	if (new.nummer = 1)then 
		if(new.vertrekuur is null)THEN
			raise exception 'trein kan niet vertrekken zonder eerst aan te komen: tripcode %, station %, haltenummer %', new.code,new.naam,new.nummer;
		end IF;
	elsif (new.nummer=(select max(nummer) from trip_halte where code=new.code))THEN
		if(new.aankomstuur is null)THEN
			raise exception 'trein kan niet vertrekken zonder eerst aan te komen: tripcode %, station %, haltenummer %', new.code,new.naam,new.nummer;
		END IF;
	elsif (halte_vertrekVolgendeDag=halte_aankomstVolgendeDag)THEN
		if (new.vertrekuur<new.aankomstuur) then
		raise exception 'trein kan niet vertrekken zonder eerst aan te komen: tripcode %, station %, haltenummer %', new.code,new.naam,new.nummer;
		END IF;
	end if;
	return new;
	end;
	$BODY$;
	
create function aankomstVolgendeDagTrue()
returns trigger 
language plpgsql 
as $BODY$
declare
halte_vertrekVolgendeDag boolean;
halte_aankomstVolgendeDag boolean;
begin
		select vertrekVolgendeDag into halte_vertrekVolgendeDag from trip_halte where code =NEW.code and nummer=new.nummer;
		select aankomstVolgendeDag into halte_aankomstVolgendeDag from trip_halte where code=new.code and nummer=new.nummer;
if (halte_aankomstVolgendeDag and not halte_vertrekVolgendeDag) then
	raise exception 'trein kan niet de volgende dag aankomen en de eerste dag vertrekken: tripcode %, station %, haltenummer %', new.code,new.naam,new.nummer;
	end if;
	return new;
	end;
	$BODY$;
	

-- aanmaak tabellen
CREATE TABLE STATION(
	NAAM varchar PRIMARY KEY,
	LENGTEGRAAD varchar NOT NULL,
	BREEDTEGRAAD varchar NOT NULL,
	constraint UC_station unique (lengtegraad,breedtegraad)

);


CREATE TABLE BUITENLANDS(
	NAAM varchar primary key,
	LANDCODE CHAR(2) NOT NULL,
	constraint buitenlands_fkey FOREIGN KEY (naam) REFERENCES STATION (NAAM) ON UPDATE CASCADE ON DELETE CASCADE
	
);


CREATE table BINNENLANDS(
	naam varchar primary key,
	constraint binnenlands_fkey foreign key (naam) references station (naam) ON UPDATE CASCADE ON DELETE CASCADE
	
);

create table binnenlands_volledigeVertaling(
	naam varchar,
	landcode char(2),
	vertaling varchar not null,
	constraint binnenlands_volledigeVertaling_pkey primary key (naam,landcode),
	constraint binnenlands_volledigeVertaling_fkey foreign key (naam) references binnenlands (naam) ON UPDATE CASCADE ON DELETE CASCADE
);

create table traject(
	naam varchar primary key
);

create table treinsoort(
	soortnaam varchar primary key,
	verbindingscategorie varchar not null
);

create table trip(
	code varchar  primary key,
	max_capaciteit int not null,
	soortnaam varchar,
	naam varchar,
	constraint trip_fkey foreign key (naam) references traject(naam) ON UPDATE CASCADE ON DELETE CASCADE,
	constraint trip_fkey2 foreign key (soortnaam) references treinsoort (soortnaam) ON UPDATE CASCADE ON DELETE CASCADE,
	constraint trip_maxcap check (max_capaciteit>0)
	
);

create table trip_data(
	code varchar,
	datum date,
	constraint trip_data_pkey primary key (code,datum),
	constraint trip_data_fkey foreign key (code) references trip (code) ON UPDATE CASCADE ON DELETE CASCADE
);

create table trip_halte(
	verwachteBezetting int,
	nummer INT,
	code varchar,
	vertrekuur time,
	vertrekVolgendeDag boolean,
	aankomstuur time,
	aankomstVolgendeDag boolean,
	naam varchar not null,
	constraint trip_halte_pkey primary key(code,nummer),
	constraint trip_halte_fkey2 foreign key (naam) references station(naam) ON UPDATE CASCADE ON DELETE CASCADE,
	constraint trip_halte_fkey foreign key (code) references trip(code) ON UPDATE CASCADE ON DELETE CASCADE,
	constraint check_bezetting  check verwachteBezetting>0,
	constraint check_nummer check nummer>0
);


create trigger check_uur_trigger before insert on public.trip_halte for each row execute function public.checkuur();
create trigger check_capaciteit_trigger before insert on public.trip_halte for each row execute function public.checkCapaciteit();
create trigger aankomstVolgendeDagTrue_trigger before insert on public.trip_halte for each row execute function public.aankomstVolgendeDagTrue();
