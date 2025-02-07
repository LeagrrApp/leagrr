--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2 (Debian 17.2-1.pgdg120+1)
-- Dumped by pg_dump version 17.2

-- Started on 2025-02-03 13:42:42 EST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 7 (class 2615 OID 60383)
-- Name: admin; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA admin;


ALTER SCHEMA admin OWNER TO postgres;

--
-- TOC entry 6 (class 2615 OID 60382)
-- Name: league_management; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA league_management;


ALTER SCHEMA league_management OWNER TO postgres;

--
-- TOC entry 8 (class 2615 OID 60384)
-- Name: stats; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA stats;


ALTER SCHEMA stats OWNER TO postgres;

--
-- TOC entry 277 (class 1255 OID 60529)
-- Name: generate_division_slug(); Type: FUNCTION; Schema: league_management; Owner: postgres
--

CREATE FUNCTION league_management.generate_division_slug() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    base_slug TEXT;
    temp_slug TEXT;
    final_slug TEXT;
    slug_rank INT;
    exact_match INT;
BEGIN

	IF NEW.name <> OLD.name OR tg_op = 'INSERT' THEN
	
	    -- Generate the initial slug by processing the name
	    base_slug := lower(
	                      regexp_replace(
	                          regexp_replace(
	                              regexp_replace(NEW.name, '\s+', '-', 'g'),
	                              '[^a-zA-Z0-9\-]', '', 'g'
	                          ),
	                      '-+', '-', 'g')
	                  );
	
	    -- Check if this slug already exists and if so, append a number to ensure uniqueness
	
		-- this SELECT checks if there are other EXACT slug matches
	    SELECT COUNT(*) INTO exact_match
	    FROM league_management.divisions
	    WHERE slug = base_slug AND season_id = NEW.season_id;
	
	    IF exact_match = 0 THEN
	        -- No duplicates found, assign base slug
	        final_slug := base_slug;
	    ELSE
			-- this SELECT checks if there are divisions with slugs starting with the base_slug
		    SELECT COUNT(*) INTO slug_rank
		    FROM league_management.divisions
		    WHERE slug LIKE base_slug || '%' AND season_id = NEW.season_id;
			
	        -- Duplicates found, append the count as a suffix
	        temp_slug := base_slug || '-' || slug_rank;
			
			-- check if exact match of temp_slug found
			SELECT COUNT(*) INTO exact_match
		    FROM league_management.divisions
		    WHERE slug = temp_slug AND season_id = NEW.season_id;
	
			IF exact_match = 1 THEN
				-- increase slug_rank by 1 and create final slug
				final_slug := base_slug || '-' || (slug_rank + 1);
			ELSE
				-- change temp slug to final slug
				final_slug = temp_slug;
			END IF;
	    END IF;
	
	    -- Assign the final slug to the new record
	    NEW.slug := final_slug;
	
	END IF;
	
	RETURN NEW;
END;
$$;


ALTER FUNCTION league_management.generate_division_slug() OWNER TO postgres;

--
-- TOC entry 275 (class 1255 OID 60450)
-- Name: generate_league_slug(); Type: FUNCTION; Schema: league_management; Owner: postgres
--

CREATE FUNCTION league_management.generate_league_slug() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    base_slug TEXT;
    temp_slug TEXT;
    final_slug TEXT;
    slug_rank INT;
    exact_match INT;
BEGIN
	IF NEW.name <> OLD.name OR tg_op = 'INSERT' THEN
	    -- Generate the initial slug by processing the name
	    base_slug := lower(
	                      regexp_replace(
	                          regexp_replace(
	                              regexp_replace(NEW.name, '\s+', '-', 'g'),
	                              '[^a-zA-Z0-9\-]', '', 'g'
	                          ),
	                      '-+', '-', 'g')
	                  );
	
	    -- Check if this slug already exists and if so, append a number to ensure uniqueness
	
		-- this SELECT checks if there are other EXACT slug matches
	    SELECT COUNT(*) INTO exact_match
	    FROM league_management.leagues
	    WHERE slug = base_slug;
	
	    IF exact_match = 0 THEN
	        -- No duplicates found, assign base slug
	        final_slug := base_slug;
	    ELSE
			-- this SELECT checks if there are leagues with slugs starting with the base_slug
		    SELECT COUNT(*) INTO slug_rank
		    FROM league_management.leagues
		    WHERE slug LIKE base_slug || '%';
			
	        -- Duplicates found, append the count as a suffix
	        temp_slug := base_slug || '-' || slug_rank;
			
			-- check if exact match of temp_slug found
			SELECT COUNT(*) INTO exact_match
		    FROM league_management.leagues
		    WHERE slug = temp_slug;
	
			IF exact_match = 1 THEN
				-- increase slug_rank by 1 and create final slug
				final_slug := base_slug || '-' || (slug_rank + 1);
			ELSE
				-- change temp slug to final slug
				final_slug = temp_slug;
			END IF;
	    END IF;
	
	    -- Assign the final slug to the new record
	    NEW.slug := final_slug;

	END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION league_management.generate_league_slug() OWNER TO postgres;

--
-- TOC entry 276 (class 1255 OID 60488)
-- Name: generate_season_slug(); Type: FUNCTION; Schema: league_management; Owner: postgres
--

CREATE FUNCTION league_management.generate_season_slug() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    base_slug TEXT;
    temp_slug TEXT;
    final_slug TEXT;
    slug_rank INT;
    exact_match INT;
BEGIN

	IF NEW.name <> OLD.name OR tg_op = 'INSERT' THEN
	
	    -- Generate the initial slug by processing the name
	    base_slug := lower(
	                      regexp_replace(
	                          regexp_replace(
	                              regexp_replace(NEW.name, '\s+', '-', 'g'),
	                              '[^a-zA-Z0-9\-]', '', 'g'
	                          ),
	                      '-+', '-', 'g')
	                  );
	
	    -- Check if this slug already exists and if so, append a number to ensure uniqueness
	
		-- this SELECT checks if there are other EXACT slug matches
	    SELECT COUNT(*) INTO exact_match
	    FROM league_management.seasons
	    WHERE slug = base_slug AND league_id = NEW.league_id;
	
	    IF exact_match = 0 THEN
	        -- No duplicates found, assign base slug
	        final_slug := base_slug;
	    ELSE
			-- this SELECT checks if there are seasons with slugs starting with the base_slug
		    SELECT COUNT(*) INTO slug_rank
		    FROM league_management.seasons
		    WHERE slug LIKE base_slug || '%' AND league_id = NEW.league_id;
			
	        -- Duplicates found, append the count as a suffix
	        temp_slug := base_slug || '-' || slug_rank;
			
			-- check if exact match of temp_slug found
			SELECT COUNT(*) INTO exact_match
		    FROM league_management.seasons
		    WHERE slug = temp_slug AND league_id = NEW.league_id;
	
			IF exact_match = 1 THEN
				-- increase slug_rank by 1 and create final slug
				final_slug := base_slug || '-' || (slug_rank + 1);
			ELSE
				-- change temp slug to final slug
				final_slug = temp_slug;
			END IF;
	    END IF;
	
	    -- Assign the final slug to the new record
	    NEW.slug := final_slug;
	
	END IF;
	
	RETURN NEW;
END;
$$;


ALTER FUNCTION league_management.generate_season_slug() OWNER TO postgres;

--
-- TOC entry 278 (class 1255 OID 60550)
-- Name: generate_team_slug(); Type: FUNCTION; Schema: league_management; Owner: postgres
--

CREATE FUNCTION league_management.generate_team_slug() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    base_slug TEXT;
    temp_slug TEXT;
    final_slug TEXT;
    slug_rank INT;
    exact_match INT;
BEGIN
	IF NEW.name <> OLD.name OR tg_op = 'INSERT' THEN
	    -- Generate the initial slug by processing the name
	    base_slug := lower(
	                      regexp_replace(
	                          regexp_replace(
	                              regexp_replace(NEW.name, '\s+', '-', 'g'),
	                              '[^a-zA-Z0-9\-]', '', 'g'
	                          ),
	                      '-+', '-', 'g')
	                  );
	
	    -- Check if this slug already exists and if so, append a number to ensure uniqueness
	
		-- this SELECT checks if there are other EXACT slug matches
	    SELECT COUNT(*) INTO exact_match
	    FROM league_management.teams
	    WHERE slug = base_slug;
	
	    IF exact_match = 0 THEN
	        -- No duplicates found, assign base slug
	        final_slug := base_slug;
	    ELSE
			-- this SELECT checks if there are teams with slugs starting with the base_slug
		    SELECT COUNT(*) INTO slug_rank
		    FROM league_management.teams
		    WHERE slug LIKE base_slug || '%';
			
	        -- Duplicates found, append the count as a suffix
	        temp_slug := base_slug || '-' || slug_rank;
			
			-- check if exact match of temp_slug found
			SELECT COUNT(*) INTO exact_match
		    FROM league_management.teams
		    WHERE slug = temp_slug;
	
			IF exact_match = 1 THEN
				-- increase slug_rank by 1 and create final slug
				final_slug := base_slug || '-' || (slug_rank + 1);
			ELSE
				-- change temp slug to final slug
				final_slug = temp_slug;
			END IF;
	    END IF;
	
	    -- Assign the final slug to the new record
	    NEW.slug := final_slug;

	END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION league_management.generate_team_slug() OWNER TO postgres;

--
-- TOC entry 273 (class 1255 OID 60663)
-- Name: mark_game_as_published(); Type: FUNCTION; Schema: league_management; Owner: postgres
--

CREATE FUNCTION league_management.mark_game_as_published() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF NEW.status <> OLD.status AND NEW.status != 'draft' THEN
		NEW.has_been_published = true;
	END IF;
	
	RETURN NEW;
END;
$$;


ALTER FUNCTION league_management.mark_game_as_published() OWNER TO postgres;

--
-- TOC entry 274 (class 1255 OID 60692)
-- Name: update_game_score(); Type: FUNCTION; Schema: league_management; Owner: postgres
--

CREATE FUNCTION league_management.update_game_score() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	UPDATE league_management.games AS g
	SET
		home_team_score = (SELECT COUNT(*) FROM stats.goals AS goals WHERE goals.team_id = g.home_team_id AND goals.game_id IN (NEW.game_id, OLD.game_id)),
		away_team_score = (SELECT COUNT(*) FROM stats.goals AS goals WHERE goals.team_id = g.away_team_id AND goals.game_id IN (NEW.game_id, OLD.game_id))
	WHERE
		g.game_id IN (NEW.game_id, OLD.game_id);
	
	RETURN NEW;
END;
$$;


ALTER FUNCTION league_management.update_game_score() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 221 (class 1259 OID 60386)
-- Name: users; Type: TABLE; Schema: admin; Owner: postgres
--

CREATE TABLE admin.users (
    user_id integer NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(50) NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    gender character varying(50),
    pronouns character varying(50),
    user_role integer DEFAULT 3 NOT NULL,
    password_hash character varying(100),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now(),
    CONSTRAINT user_status_enum CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying, 'suspended'::character varying, 'banned'::character varying])::text[])))
);


ALTER TABLE admin.users OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 60385)
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: admin; Owner: postgres
--

CREATE SEQUENCE admin.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE admin.users_user_id_seq OWNER TO postgres;

--
-- TOC entry 3692 (class 0 OID 0)
-- Dependencies: 220
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: admin; Owner: postgres
--

ALTER SEQUENCE admin.users_user_id_seq OWNED BY admin.users.user_id;


--
-- TOC entry 245 (class 1259 OID 60603)
-- Name: arenas; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.arenas (
    arena_id integer NOT NULL,
    slug character varying(50) NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    venue_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.arenas OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 60602)
-- Name: arenas_arena_id_seq; Type: SEQUENCE; Schema: league_management; Owner: postgres
--

CREATE SEQUENCE league_management.arenas_arena_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE league_management.arenas_arena_id_seq OWNER TO postgres;

--
-- TOC entry 3693 (class 0 OID 0)
-- Dependencies: 244
-- Name: arenas_arena_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.arenas_arena_id_seq OWNED BY league_management.arenas.arena_id;


--
-- TOC entry 239 (class 1259 OID 60554)
-- Name: division_rosters; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.division_rosters (
    division_roster_id integer NOT NULL,
    division_team_id integer,
    user_id integer,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.division_rosters OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 60553)
-- Name: division_rosters_division_roster_id_seq; Type: SEQUENCE; Schema: league_management; Owner: postgres
--

CREATE SEQUENCE league_management.division_rosters_division_roster_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE league_management.division_rosters_division_roster_id_seq OWNER TO postgres;

--
-- TOC entry 3694 (class 0 OID 0)
-- Dependencies: 238
-- Name: division_rosters_division_roster_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.division_rosters_division_roster_id_seq OWNED BY league_management.division_rosters.division_roster_id;


--
-- TOC entry 237 (class 1259 OID 60533)
-- Name: division_teams; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.division_teams (
    division_team_id integer NOT NULL,
    division_id integer,
    team_id integer,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.division_teams OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 60532)
-- Name: division_teams_division_team_id_seq; Type: SEQUENCE; Schema: league_management; Owner: postgres
--

CREATE SEQUENCE league_management.division_teams_division_team_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE league_management.division_teams_division_team_id_seq OWNER TO postgres;

--
-- TOC entry 3695 (class 0 OID 0)
-- Dependencies: 236
-- Name: division_teams_division_team_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.division_teams_division_team_id_seq OWNED BY league_management.division_teams.division_team_id;


--
-- TOC entry 235 (class 1259 OID 60510)
-- Name: divisions; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.divisions (
    division_id integer NOT NULL,
    slug character varying(50) NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    tier integer,
    gender character varying(10) DEFAULT 'All'::character varying NOT NULL,
    season_id integer,
    join_code character varying(50) DEFAULT gen_random_uuid() NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now(),
    CONSTRAINT division_gender_enum CHECK (((gender)::text = ANY ((ARRAY['all'::character varying, 'men'::character varying, 'women'::character varying])::text[]))),
    CONSTRAINT division_status_enum CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'public'::character varying, 'archived'::character varying])::text[])))
);


ALTER TABLE league_management.divisions OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 60509)
-- Name: divisions_division_id_seq; Type: SEQUENCE; Schema: league_management; Owner: postgres
--

CREATE SEQUENCE league_management.divisions_division_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE league_management.divisions_division_id_seq OWNER TO postgres;

--
-- TOC entry 3696 (class 0 OID 0)
-- Dependencies: 234
-- Name: divisions_division_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.divisions_division_id_seq OWNED BY league_management.divisions.division_id;


--
-- TOC entry 249 (class 1259 OID 60636)
-- Name: games; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.games (
    game_id integer NOT NULL,
    home_team_id integer,
    home_team_score integer DEFAULT 0,
    away_team_id integer,
    away_team_score integer DEFAULT 0,
    division_id integer,
    playoff_id integer,
    date_time timestamp without time zone,
    arena_id integer,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    has_been_published boolean DEFAULT false,
    created_on timestamp without time zone DEFAULT now(),
    CONSTRAINT game_status_enum CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'public'::character varying, 'completed'::character varying, 'cancelled'::character varying, 'postponed'::character varying, 'archived'::character varying])::text[])))
);


ALTER TABLE league_management.games OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 60635)
-- Name: games_game_id_seq; Type: SEQUENCE; Schema: league_management; Owner: postgres
--

CREATE SEQUENCE league_management.games_game_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE league_management.games_game_id_seq OWNER TO postgres;

--
-- TOC entry 3697 (class 0 OID 0)
-- Dependencies: 248
-- Name: games_game_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.games_game_id_seq OWNED BY league_management.games.game_id;


--
-- TOC entry 229 (class 1259 OID 60454)
-- Name: league_admins; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.league_admins (
    league_admin_id integer NOT NULL,
    league_role integer,
    league_id integer,
    user_id integer,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.league_admins OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 60453)
-- Name: league_admins_league_admin_id_seq; Type: SEQUENCE; Schema: league_management; Owner: postgres
--

CREATE SEQUENCE league_management.league_admins_league_admin_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE league_management.league_admins_league_admin_id_seq OWNER TO postgres;

--
-- TOC entry 3698 (class 0 OID 0)
-- Dependencies: 228
-- Name: league_admins_league_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.league_admins_league_admin_id_seq OWNED BY league_management.league_admins.league_admin_id;


--
-- TOC entry 247 (class 1259 OID 60618)
-- Name: league_venues; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.league_venues (
    league_venue_id integer NOT NULL,
    venue_id integer,
    league_id integer,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.league_venues OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 60617)
-- Name: league_venues_league_venue_id_seq; Type: SEQUENCE; Schema: league_management; Owner: postgres
--

CREATE SEQUENCE league_management.league_venues_league_venue_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE league_management.league_venues_league_venue_id_seq OWNER TO postgres;

--
-- TOC entry 3699 (class 0 OID 0)
-- Dependencies: 246
-- Name: league_venues_league_venue_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.league_venues_league_venue_id_seq OWNED BY league_management.league_venues.league_venue_id;


--
-- TOC entry 227 (class 1259 OID 60437)
-- Name: leagues; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.leagues (
    league_id integer NOT NULL,
    slug character varying(50) NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    sport character varying(50),
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now(),
    CONSTRAINT league_status_enum CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'public'::character varying, 'archived'::character varying])::text[])))
);


ALTER TABLE league_management.leagues OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 60436)
-- Name: leagues_league_id_seq; Type: SEQUENCE; Schema: league_management; Owner: postgres
--

CREATE SEQUENCE league_management.leagues_league_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE league_management.leagues_league_id_seq OWNER TO postgres;

--
-- TOC entry 3700 (class 0 OID 0)
-- Dependencies: 226
-- Name: leagues_league_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.leagues_league_id_seq OWNED BY league_management.leagues.league_id;


--
-- TOC entry 241 (class 1259 OID 60572)
-- Name: playoffs; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.playoffs (
    playoff_id integer NOT NULL,
    slug character varying(50) NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    playoff_structure character varying(20) DEFAULT 'bracket'::character varying NOT NULL,
    season_id integer,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now(),
    CONSTRAINT playoffs_status_enum CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'public'::character varying, 'archived'::character varying])::text[]))),
    CONSTRAINT playoffs_structure_enum CHECK (((playoff_structure)::text = ANY ((ARRAY['bracket'::character varying, 'round-robin'::character varying])::text[])))
);


ALTER TABLE league_management.playoffs OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 60571)
-- Name: playoffs_playoff_id_seq; Type: SEQUENCE; Schema: league_management; Owner: postgres
--

CREATE SEQUENCE league_management.playoffs_playoff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE league_management.playoffs_playoff_id_seq OWNER TO postgres;

--
-- TOC entry 3701 (class 0 OID 0)
-- Dependencies: 240
-- Name: playoffs_playoff_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.playoffs_playoff_id_seq OWNED BY league_management.playoffs.playoff_id;


--
-- TOC entry 233 (class 1259 OID 60492)
-- Name: season_admins; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.season_admins (
    season_admin_id integer NOT NULL,
    season_role integer,
    season_id integer,
    user_id integer,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.season_admins OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 60491)
-- Name: season_admins_season_admin_id_seq; Type: SEQUENCE; Schema: league_management; Owner: postgres
--

CREATE SEQUENCE league_management.season_admins_season_admin_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE league_management.season_admins_season_admin_id_seq OWNER TO postgres;

--
-- TOC entry 3702 (class 0 OID 0)
-- Dependencies: 232
-- Name: season_admins_season_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.season_admins_season_admin_id_seq OWNED BY league_management.season_admins.season_admin_id;


--
-- TOC entry 231 (class 1259 OID 60472)
-- Name: seasons; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.seasons (
    season_id integer NOT NULL,
    slug character varying(50) NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    league_id integer,
    start_date date,
    end_date date,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now(),
    CONSTRAINT season_status_enum CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'public'::character varying, 'archived'::character varying])::text[])))
);


ALTER TABLE league_management.seasons OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 60471)
-- Name: seasons_season_id_seq; Type: SEQUENCE; Schema: league_management; Owner: postgres
--

CREATE SEQUENCE league_management.seasons_season_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE league_management.seasons_season_id_seq OWNER TO postgres;

--
-- TOC entry 3703 (class 0 OID 0)
-- Dependencies: 230
-- Name: seasons_season_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.seasons_season_id_seq OWNED BY league_management.seasons.season_id;


--
-- TOC entry 225 (class 1259 OID 60418)
-- Name: team_memberships; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.team_memberships (
    team_membership_id integer NOT NULL,
    user_id integer NOT NULL,
    team_id integer NOT NULL,
    team_role integer DEFAULT 5,
    "position" character varying(50),
    number integer,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.team_memberships OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 60417)
-- Name: team_memberships_team_membership_id_seq; Type: SEQUENCE; Schema: league_management; Owner: postgres
--

CREATE SEQUENCE league_management.team_memberships_team_membership_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE league_management.team_memberships_team_membership_id_seq OWNER TO postgres;

--
-- TOC entry 3704 (class 0 OID 0)
-- Dependencies: 224
-- Name: team_memberships_team_membership_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.team_memberships_team_membership_id_seq OWNED BY league_management.team_memberships.team_membership_id;


--
-- TOC entry 223 (class 1259 OID 60401)
-- Name: teams; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.teams (
    team_id integer NOT NULL,
    slug character varying(50) NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    color character varying(50),
    join_code character varying(50) DEFAULT gen_random_uuid() NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now(),
    CONSTRAINT team_status_enum CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying, 'suspended'::character varying, 'banned'::character varying])::text[])))
);


ALTER TABLE league_management.teams OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 60400)
-- Name: teams_team_id_seq; Type: SEQUENCE; Schema: league_management; Owner: postgres
--

CREATE SEQUENCE league_management.teams_team_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE league_management.teams_team_id_seq OWNER TO postgres;

--
-- TOC entry 3705 (class 0 OID 0)
-- Dependencies: 222
-- Name: teams_team_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.teams_team_id_seq OWNED BY league_management.teams.team_id;


--
-- TOC entry 243 (class 1259 OID 60591)
-- Name: venues; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.venues (
    venue_id integer NOT NULL,
    slug character varying(50) NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    address text,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.venues OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 60590)
-- Name: venues_venue_id_seq; Type: SEQUENCE; Schema: league_management; Owner: postgres
--

CREATE SEQUENCE league_management.venues_venue_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE league_management.venues_venue_id_seq OWNER TO postgres;

--
-- TOC entry 3706 (class 0 OID 0)
-- Dependencies: 242
-- Name: venues_venue_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.venues_venue_id_seq OWNED BY league_management.venues.venue_id;


--
-- TOC entry 253 (class 1259 OID 60695)
-- Name: assists; Type: TABLE; Schema: stats; Owner: postgres
--

CREATE TABLE stats.assists (
    assist_id integer NOT NULL,
    goal_id integer NOT NULL,
    game_id integer NOT NULL,
    user_id integer NOT NULL,
    team_id integer NOT NULL,
    primary_assist boolean DEFAULT true,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE stats.assists OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 60694)
-- Name: assists_assist_id_seq; Type: SEQUENCE; Schema: stats; Owner: postgres
--

CREATE SEQUENCE stats.assists_assist_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE stats.assists_assist_id_seq OWNER TO postgres;

--
-- TOC entry 3707 (class 0 OID 0)
-- Dependencies: 252
-- Name: assists_assist_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.assists_assist_id_seq OWNED BY stats.assists.assist_id;


--
-- TOC entry 251 (class 1259 OID 60667)
-- Name: goals; Type: TABLE; Schema: stats; Owner: postgres
--

CREATE TABLE stats.goals (
    goal_id integer NOT NULL,
    game_id integer NOT NULL,
    user_id integer NOT NULL,
    team_id integer NOT NULL,
    period integer,
    period_time interval,
    shorthanded boolean DEFAULT false,
    power_play boolean DEFAULT false,
    empty_net boolean DEFAULT false,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE stats.goals OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 60666)
-- Name: goals_goal_id_seq; Type: SEQUENCE; Schema: stats; Owner: postgres
--

CREATE SEQUENCE stats.goals_goal_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE stats.goals_goal_id_seq OWNER TO postgres;

--
-- TOC entry 3708 (class 0 OID 0)
-- Dependencies: 250
-- Name: goals_goal_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.goals_goal_id_seq OWNED BY stats.goals.goal_id;


--
-- TOC entry 255 (class 1259 OID 60724)
-- Name: penalties; Type: TABLE; Schema: stats; Owner: postgres
--

CREATE TABLE stats.penalties (
    penalty_id integer NOT NULL,
    game_id integer NOT NULL,
    user_id integer NOT NULL,
    team_id integer NOT NULL,
    period integer,
    period_time interval,
    infraction character varying(50) NOT NULL,
    minutes integer DEFAULT 2 NOT NULL,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE stats.penalties OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 60723)
-- Name: penalties_penalty_id_seq; Type: SEQUENCE; Schema: stats; Owner: postgres
--

CREATE SEQUENCE stats.penalties_penalty_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE stats.penalties_penalty_id_seq OWNER TO postgres;

--
-- TOC entry 3709 (class 0 OID 0)
-- Dependencies: 254
-- Name: penalties_penalty_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.penalties_penalty_id_seq OWNED BY stats.penalties.penalty_id;


--
-- TOC entry 259 (class 1259 OID 60778)
-- Name: saves; Type: TABLE; Schema: stats; Owner: postgres
--

CREATE TABLE stats.saves (
    save_id integer NOT NULL,
    game_id integer NOT NULL,
    user_id integer NOT NULL,
    team_id integer NOT NULL,
    shot_id integer NOT NULL,
    period integer,
    period_time interval,
    penalty_kill boolean DEFAULT false,
    rebound boolean DEFAULT false,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE stats.saves OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 60777)
-- Name: saves_save_id_seq; Type: SEQUENCE; Schema: stats; Owner: postgres
--

CREATE SEQUENCE stats.saves_save_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE stats.saves_save_id_seq OWNER TO postgres;

--
-- TOC entry 3710 (class 0 OID 0)
-- Dependencies: 258
-- Name: saves_save_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.saves_save_id_seq OWNED BY stats.saves.save_id;


--
-- TOC entry 257 (class 1259 OID 60748)
-- Name: shots; Type: TABLE; Schema: stats; Owner: postgres
--

CREATE TABLE stats.shots (
    shot_id integer NOT NULL,
    game_id integer NOT NULL,
    user_id integer NOT NULL,
    team_id integer NOT NULL,
    period integer,
    period_time interval,
    goal_id integer,
    shorthanded boolean DEFAULT false,
    power_play boolean DEFAULT false,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE stats.shots OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 60747)
-- Name: shots_shot_id_seq; Type: SEQUENCE; Schema: stats; Owner: postgres
--

CREATE SEQUENCE stats.shots_shot_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE stats.shots_shot_id_seq OWNER TO postgres;

--
-- TOC entry 3711 (class 0 OID 0)
-- Dependencies: 256
-- Name: shots_shot_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.shots_shot_id_seq OWNED BY stats.shots.shot_id;


--
-- TOC entry 261 (class 1259 OID 60808)
-- Name: shutouts; Type: TABLE; Schema: stats; Owner: postgres
--

CREATE TABLE stats.shutouts (
    shutout_id integer NOT NULL,
    game_id integer NOT NULL,
    user_id integer NOT NULL,
    team_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE stats.shutouts OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 60807)
-- Name: shutouts_shutout_id_seq; Type: SEQUENCE; Schema: stats; Owner: postgres
--

CREATE SEQUENCE stats.shutouts_shutout_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE stats.shutouts_shutout_id_seq OWNER TO postgres;

--
-- TOC entry 3712 (class 0 OID 0)
-- Dependencies: 260
-- Name: shutouts_shutout_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.shutouts_shutout_id_seq OWNED BY stats.shutouts.shutout_id;


--
-- TOC entry 3319 (class 2604 OID 60389)
-- Name: users user_id; Type: DEFAULT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users ALTER COLUMN user_id SET DEFAULT nextval('admin.users_user_id_seq'::regclass);


--
-- TOC entry 3355 (class 2604 OID 60606)
-- Name: arenas arena_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.arenas ALTER COLUMN arena_id SET DEFAULT nextval('league_management.arenas_arena_id_seq'::regclass);


--
-- TOC entry 3347 (class 2604 OID 60557)
-- Name: division_rosters division_roster_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_rosters ALTER COLUMN division_roster_id SET DEFAULT nextval('league_management.division_rosters_division_roster_id_seq'::regclass);


--
-- TOC entry 3345 (class 2604 OID 60536)
-- Name: division_teams division_team_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_teams ALTER COLUMN division_team_id SET DEFAULT nextval('league_management.division_teams_division_team_id_seq'::regclass);


--
-- TOC entry 3340 (class 2604 OID 60513)
-- Name: divisions division_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.divisions ALTER COLUMN division_id SET DEFAULT nextval('league_management.divisions_division_id_seq'::regclass);


--
-- TOC entry 3359 (class 2604 OID 60639)
-- Name: games game_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games ALTER COLUMN game_id SET DEFAULT nextval('league_management.games_game_id_seq'::regclass);


--
-- TOC entry 3333 (class 2604 OID 60457)
-- Name: league_admins league_admin_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins ALTER COLUMN league_admin_id SET DEFAULT nextval('league_management.league_admins_league_admin_id_seq'::regclass);


--
-- TOC entry 3357 (class 2604 OID 60621)
-- Name: league_venues league_venue_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_venues ALTER COLUMN league_venue_id SET DEFAULT nextval('league_management.league_venues_league_venue_id_seq'::regclass);


--
-- TOC entry 3330 (class 2604 OID 60440)
-- Name: leagues league_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.leagues ALTER COLUMN league_id SET DEFAULT nextval('league_management.leagues_league_id_seq'::regclass);


--
-- TOC entry 3349 (class 2604 OID 60575)
-- Name: playoffs playoff_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.playoffs ALTER COLUMN playoff_id SET DEFAULT nextval('league_management.playoffs_playoff_id_seq'::regclass);


--
-- TOC entry 3338 (class 2604 OID 60495)
-- Name: season_admins season_admin_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins ALTER COLUMN season_admin_id SET DEFAULT nextval('league_management.season_admins_season_admin_id_seq'::regclass);


--
-- TOC entry 3335 (class 2604 OID 60475)
-- Name: seasons season_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.seasons ALTER COLUMN season_id SET DEFAULT nextval('league_management.seasons_season_id_seq'::regclass);


--
-- TOC entry 3327 (class 2604 OID 60421)
-- Name: team_memberships team_membership_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships ALTER COLUMN team_membership_id SET DEFAULT nextval('league_management.team_memberships_team_membership_id_seq'::regclass);


--
-- TOC entry 3323 (class 2604 OID 60404)
-- Name: teams team_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.teams ALTER COLUMN team_id SET DEFAULT nextval('league_management.teams_team_id_seq'::regclass);


--
-- TOC entry 3353 (class 2604 OID 60594)
-- Name: venues venue_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.venues ALTER COLUMN venue_id SET DEFAULT nextval('league_management.venues_venue_id_seq'::regclass);


--
-- TOC entry 3370 (class 2604 OID 60698)
-- Name: assists assist_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists ALTER COLUMN assist_id SET DEFAULT nextval('stats.assists_assist_id_seq'::regclass);


--
-- TOC entry 3365 (class 2604 OID 60670)
-- Name: goals goal_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals ALTER COLUMN goal_id SET DEFAULT nextval('stats.goals_goal_id_seq'::regclass);


--
-- TOC entry 3373 (class 2604 OID 60727)
-- Name: penalties penalty_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties ALTER COLUMN penalty_id SET DEFAULT nextval('stats.penalties_penalty_id_seq'::regclass);


--
-- TOC entry 3380 (class 2604 OID 60781)
-- Name: saves save_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves ALTER COLUMN save_id SET DEFAULT nextval('stats.saves_save_id_seq'::regclass);


--
-- TOC entry 3376 (class 2604 OID 60751)
-- Name: shots shot_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots ALTER COLUMN shot_id SET DEFAULT nextval('stats.shots_shot_id_seq'::regclass);


--
-- TOC entry 3384 (class 2604 OID 60811)
-- Name: shutouts shutout_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts ALTER COLUMN shutout_id SET DEFAULT nextval('stats.shutouts_shutout_id_seq'::regclass);


--
-- TOC entry 3646 (class 0 OID 60386)
-- Dependencies: 221
-- Data for Name: users; Type: TABLE DATA; Schema: admin; Owner: postgres
--

INSERT INTO admin.users VALUES (1, 'moose', 'hello+2@adamrobillard.ca', 'Adam', 'Robillard', 'Non-binary/Non-conforming', 'any/all', 1, '$2b$10$7pjrECYElk1ithndcAhtcuPytB2Hc8DiDi3e8gAEXYcfIjOVZdEfS', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (2, 'goose', 'hello+1@adamrobillard.ca', 'Hannah', 'Brown', 'Woman', 'she/her', 3, '$2b$10$99E/cmhMolqnQFi3E6CXHOpB7zYYANgDToz1F.WkFrZMOXCFBvxji', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (3, 'caboose', 'hello+3@adamrobillard.ca', 'Aida', 'Robillard', 'Non-binary/Non-conforming', 'any/all', 1, '$2b$10$UM16ckCNhox47R0yOq873uCUX4Pal3GEVlNY8kYszWGGM.Y3kyiZC', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (4, 'caleb', 'caleb@example.com', 'Caleb', 'Smith', 'Man', 'he/him', 2, 'heyCaleb123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (5, 'kat', 'kat@example.com', 'Kat', 'Ferguson', 'Non-binary/Non-conforming', 'they/them', 2, 'heyKat123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (6, 'trainMan', 'trainMan@example.com', 'Stephen', 'Spence', 'Man', 'he/him', 3, 'heyStephen123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (7, 'theGoon', 'theGoon@example.com', 'Levi', 'Bradley', 'Non-binary/Non-conforming', 'they/them', 3, 'heyLevi123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (8, 'cheryl', 'cheryl@example.com', 'Cheryl', 'Chaos', NULL, NULL, 3, 'heyCheryl123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (9, 'mason', 'mason@example.com', 'Mason', 'Nonsense', NULL, NULL, 3, 'heyMasonl123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (10, 'jayce', 'jayce@example.com', 'Jayce', 'LeClaire', 'Non-binary/Non-conforming', 'they/them', 3, 'heyJaycel123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (11, 'britt', 'britt@example.com', 'Britt', 'Neron', 'Non-binary/Non-conforming', 'they/them', 3, 'heyBrittl123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (12, 'tesolin', 'tesolin@example.com', 'Zachary', 'Tesolin', 'Man', 'he/him', 3, 'heyZach123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (13, 'robocop', 'robocop@example.com', 'Andrew', 'Robillard', 'Man', 'he/him', 3, 'heyAndrew123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (14, 'trex', 'trex@example.com', 'Tim', 'Robillard', 'Man', 'he/him', 3, 'heyTim123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (15, 'lukasbauer', 'lukas.bauer@example.com', 'Lukas', 'Bauer', 'Man', 'he/him', 3, 'heyLukas123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (16, 'emmaschmidt', 'emma.schmidt@example.com', 'Emma', 'Schmidt', 'Woman', 'she/her', 3, 'heyEmma123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (17, 'liammüller', 'liam.mueller@example.com', 'Liam', 'Müller', 'Man', 'he/him', 3, 'heyLiam123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (18, 'hannahfischer', 'hannah.fischer@example.com', 'Hannah', 'Fischer', 'Woman', 'she/her', 3, 'heyHanna123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (19, 'oliverkoch', 'oliver.koch@example.com', 'Oliver', 'Koch', 'Man', 'he/him', 3, 'heyOliver123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (20, 'clararichter', 'clara.richter@example.com', 'Clara', 'Richter', 'Woman', 'she/her', 3, 'heyClara123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (21, 'noahtaylor', 'noah.taylor@example.com', 'Noah', 'Taylor', 'Man', 'he/him', 3, 'heyNoah123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (22, 'lisahoffmann', 'lisa.hoffmann@example.com', 'Lisa', 'Hoffmann', 'Woman', 'she/her', 3, 'heyLisa123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (23, 'matteorossetti', 'matteo.rossetti@example.com', 'Matteo', 'Rossetti', 'Man', 'he/him', 3, 'heyMatteo123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (24, 'giuliarossi', 'giulia.rossi@example.com', 'Giulia', 'Rossi', 'Woman', 'she/her', 3, 'heyGiulia123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (25, 'danielebrown', 'daniele.brown@example.com', 'Daniele', 'Brown', 'Non-binary/Non-conforming', 'they/them', 3, 'heyDaniele123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (26, 'sofialopez', 'sofia.lopez@example.com', 'Sofia', 'Lopez', 'Woman', 'she/her', 3, 'heySofia123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (27, 'sebastienmartin', 'sebastien.martin@example.com', 'Sebastien', 'Martin', 'Man', 'he/him', 3, 'heySebastien123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (28, 'elisavolkova', 'elisa.volkova@example.com', 'Elisa', 'Volkova', 'Woman', 'she/her', 3, 'heyElisa123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (29, 'adriangarcia', 'adrian.garcia@example.com', 'Adrian', 'Garcia', 'Man', 'he/him', 3, 'heyAdrian123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (30, 'amelialeroux', 'amelia.leroux@example.com', 'Amelia', 'LeRoux', 'Woman', 'she/her', 3, 'heyAmelia123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (31, 'kasperskov', 'kasper.skov@example.com', 'Kasper', 'Skov', 'Man', 'he/him', 3, 'heyKasper123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (32, 'elinefransen', 'eline.fransen@example.com', 'Eline', 'Fransen', 'Woman', 'she/her', 3, 'heyEline123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (33, 'andreakovacs', 'andrea.kovacs@example.com', 'Andrea', 'Kovacs', 'Non-binary/Non-conforming', 'they/them', 3, 'heyAndrea123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (34, 'petersmith', 'peter.smith@example.com', 'Peter', 'Smith', 'Man', 'he/him', 3, 'heyPeter123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (35, 'janinanowak', 'janina.nowak@example.com', 'Janina', 'Nowak', 'Woman', 'she/her', 3, 'heyJanina123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (36, 'niklaspetersen', 'niklas.petersen@example.com', 'Niklas', 'Petersen', 'Man', 'he/him', 3, 'heyNiklas123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (37, 'martakalinski', 'marta.kalinski@example.com', 'Marta', 'Kalinski', 'Woman', 'she/her', 3, 'heyMarta123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (38, 'tomasmarquez', 'tomas.marquez@example.com', 'Tomas', 'Marquez', 'Man', 'he/him', 3, 'heyTomas123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (39, 'ireneschneider', 'irene.schneider@example.com', 'Irene', 'Schneider', 'Woman', 'she/her', 3, 'heyIrene123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (40, 'maximilianbauer', 'maximilian.bauer@example.com', 'Maximilian', 'Bauer', 'Man', 'he/him', 3, 'heyMaximilian123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (41, 'annaschaefer', 'anna.schaefer@example.com', 'Anna', 'Schaefer', 'Woman', 'she/her', 3, 'heyAnna123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (42, 'lucasvargas', 'lucas.vargas@example.com', 'Lucas', 'Vargas', 'Man', 'he/him', 3, 'heyLucas123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (43, 'sofiacosta', 'sofia.costa@example.com', 'Sofia', 'Costa', 'Woman', 'she/her', 3, 'heySofia123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (44, 'alexanderricci', 'alexander.ricci@example.com', 'Alexander', 'Ricci', 'Man', 'he/him', 3, 'heyAlexander123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (45, 'noemiecaron', 'noemie.caron@example.com', 'Noemie', 'Caron', 'Woman', 'she/her', 3, 'heyNoemie123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (46, 'pietrocapello', 'pietro.capello@example.com', 'Pietro', 'Capello', 'Man', 'he/him', 3, 'heyPietro123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (47, 'elisabethjensen', 'elisabeth.jensen@example.com', 'Elisabeth', 'Jensen', 'Woman', 'she/her', 3, 'heyElisabeth123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (48, 'dimitripapadopoulos', 'dimitri.papadopoulos@example.com', 'Dimitri', 'Papadopoulos', 'Man', 'he/him', 3, 'heyDimitri123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (49, 'marielaramos', 'mariela.ramos@example.com', 'Mariela', 'Ramos', 'Woman', 'she/her', 3, 'heyMariela123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (50, 'valeriekeller', 'valerie.keller@example.com', 'Valerie', 'Keller', 'Woman', 'she/her', 3, 'heyValerie123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (51, 'dominikbauer', 'dominik.bauer@example.com', 'Dominik', 'Bauer', 'Man', 'he/him', 3, 'heyDominik123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (52, 'evaweber', 'eva.weber@example.com', 'Eva', 'Weber', 'Woman', 'she/her', 3, 'heyEva123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (53, 'sebastiancortes', 'sebastian.cortes@example.com', 'Sebastian', 'Cortes', 'Man', 'he/him', 3, 'heySebastian123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (54, 'manongarcia', 'manon.garcia@example.com', 'Manon', 'Garcia', 'Woman', 'she/her', 3, 'heyManon123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (55, 'benjaminflores', 'benjamin.flores@example.com', 'Benjamin', 'Flores', 'Man', 'he/him', 3, 'heyBenjamin123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (56, 'saradalgaard', 'sara.dalgaard@example.com', 'Sara', 'Dalgaard', 'Woman', 'she/her', 3, 'heySara123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (57, 'jonasmartinez', 'jonas.martinez@example.com', 'Jonas', 'Martinez', 'Man', 'he/him', 3, 'heyJonas123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (58, 'alessiadonati', 'alessia.donati@example.com', 'Alessia', 'Donati', 'Woman', 'she/her', 3, 'heyAlessia123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (59, 'lucaskovac', 'lucas.kovac@example.com', 'Lucas', 'Kovac', 'Non-binary/Non-conforming', 'they/them', 3, 'heyLucas123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (60, 'emiliekoch', 'emilie.koch@example.com', 'Emilie', 'Koch', 'Woman', 'she/her', 3, 'heyEmilie123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (61, 'danieljones', 'daniel.jones@example.com', 'Daniel', 'Jones', 'Man', 'he/him', 3, 'heyDaniel123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (62, 'mathildevogel', 'mathilde.vogel@example.com', 'Mathilde', 'Vogel', 'Woman', 'she/her', 3, 'heyMathilde123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (63, 'thomasleroux', 'thomas.leroux@example.com', 'Thomas', 'LeRoux', 'Man', 'he/him', 3, 'heyThomas123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (64, 'angelaperez', 'angela.perez@example.com', 'Angela', 'Perez', 'Woman', 'she/her', 3, 'heyAngela123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (65, 'henrikstrom', 'henrik.strom@example.com', 'Henrik', 'Strom', 'Man', 'he/him', 3, 'heyHenrik123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (66, 'paulinaklein', 'paulina.klein@example.com', 'Paulina', 'Klein', 'Woman', 'she/her', 3, 'heyPaulina123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (67, 'raphaelgonzalez', 'raphael.gonzalez@example.com', 'Raphael', 'Gonzalez', 'Man', 'he/him', 3, 'heyRaphael123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (68, 'annaluisachavez', 'anna-luisa.chavez@example.com', 'Anna-Luisa', 'Chavez', 'Woman', 'she/her', 3, 'heyAnna-Luisa123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (69, 'fabiomercier', 'fabio.mercier@example.com', 'Fabio', 'Mercier', 'Man', 'he/him', 3, 'heyFabio123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (70, 'nataliefischer', 'natalie.fischer@example.com', 'Natalie', 'Fischer', 'Woman', 'she/her', 3, 'heyNatalie123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (71, 'georgmayer', 'georg.mayer@example.com', 'Georg', 'Mayer', 'Man', 'he/him', 3, 'heyGeorg123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (72, 'julianweiss', 'julian.weiss@example.com', 'Julian', 'Weiss', 'Man', 'he/him', 3, 'heyJulian123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (73, 'katharinalopez', 'katharina.lopez@example.com', 'Katharina', 'Lopez', 'Woman', 'she/her', 3, 'heyKatharina123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (74, 'simonealvarez', 'simone.alvarez@example.com', 'Simone', 'Alvarez', 'Non-binary/Non-conforming', 'they/them', 3, 'heySimone123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (75, 'frederikschmidt', 'frederik.schmidt@example.com', 'Frederik', 'Schmidt', 'Man', 'he/him', 3, 'heyFrederik123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (76, 'mariakoval', 'maria.koval@example.com', 'Maria', 'Koval', 'Woman', 'she/her', 3, 'heyMaria123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (77, 'lukemccarthy', 'luke.mccarthy@example.com', 'Luke', 'McCarthy', 'Man', 'he/him', 3, 'heyLuke123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (78, 'larissahansen', 'larissa.hansen@example.com', 'Larissa', 'Hansen', 'Woman', 'she/her', 3, 'heyLarissa123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (79, 'adamwalker', 'adam.walker@example.com', 'Adam', 'Walker', 'Man', 'he/him', 3, 'heyAdam123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (80, 'paolamendes', 'paola.mendes@example.com', 'Paola', 'Mendes', 'Woman', 'she/her', 3, 'heyPaola123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (81, 'ethanwilliams', 'ethan.williams@example.com', 'Ethan', 'Williams', 'Man', 'he/him', 3, 'heyEthan123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (82, 'evastark', 'eva.stark@example.com', 'Eva', 'Stark', 'Woman', 'she/her', 3, 'heyEva123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (83, 'juliankovacic', 'julian.kovacic@example.com', 'Julian', 'Kovacic', 'Man', 'he/him', 3, 'heyJulian123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (84, 'ameliekrause', 'amelie.krause@example.com', 'Amelie', 'Krause', 'Woman', 'she/her', 3, 'heyAmelie123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (85, 'ryanschneider', 'ryan.schneider@example.com', 'Ryan', 'Schneider', 'Man', 'he/him', 3, 'heyRyan123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (86, 'monikathomsen', 'monika.thomsen@example.com', 'Monika', 'Thomsen', 'Woman', 'she/her', 3, 'heyMonika123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (87, 'daniellefoster', 'danielle.foster@example.com', 'Danielle', 'Foster', '4', 'she/her', 3, 'heyDanielle123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (88, 'harrykhan', 'harry.khan@example.com', 'Harry', 'Khan', 'Man', 'he/him', 3, 'heyHarry123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (89, 'sophielindgren', 'sophie.lindgren@example.com', 'Sophie', 'Lindgren', 'Woman', 'she/her', 3, 'heySophie123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (90, 'oskarpetrov', 'oskar.petrov@example.com', 'Oskar', 'Petrov', 'Man', 'he/him', 3, 'heyOskar123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (91, 'lindavon', 'linda.von@example.com', 'Linda', 'Von', 'Woman', 'she/her', 3, 'heyLinda123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (92, 'andreaspeicher', 'andreas.peicher@example.com', 'Andreas', 'Peicher', 'Man', 'he/him', 3, 'heyAndreas123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (93, 'josephinejung', 'josephine.jung@example.com', 'Josephine', 'Jung', 'Woman', 'she/her', 3, 'heyJosephine123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (94, 'marianapaz', 'mariana.paz@example.com', 'Mariana', 'Paz', 'Woman', 'she/her', 3, 'heyMariana123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (95, 'fionaberg', 'fiona.berg@example.com', 'Fiona', 'Berg', 'Woman', 'she/her', 3, 'heyFiona123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (96, 'joachimkraus', 'joachim.kraus@example.com', 'Joachim', 'Kraus', 'Man', 'he/him', 3, 'heyJoachim123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (97, 'michellebauer', 'michelle.bauer@example.com', 'Michelle', 'Bauer', 'Woman', 'she/her', 3, 'heyMichelle123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (98, 'mariomatteo', 'mario.matteo@example.com', 'Mario', 'Matteo', 'Man', 'he/him', 3, 'heyMario123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (99, 'elizabethsmith', 'elizabeth.smith@example.com', 'Elizabeth', 'Smith', 'Woman', 'she/her', 3, 'heyElizabeth123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (100, 'ianlennox', 'ian.lennox@example.com', 'Ian', 'Lennox', 'Man', 'he/him', 3, 'heyIan123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (101, 'evabradley', 'eva.bradley@example.com', 'Eva', 'Bradley', 'Woman', 'she/her', 3, 'heyEva123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (102, 'francescoantoni', 'francesco.antoni@example.com', 'Francesco', 'Antoni', 'Man', 'he/him', 3, 'heyFrancesco123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (103, 'celinebrown', 'celine.brown@example.com', 'Celine', 'Brown', 'Woman', 'she/her', 3, 'heyCeline123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (104, 'georgiamills', 'georgia.mills@example.com', 'Georgia', 'Mills', 'Woman', 'she/her', 3, 'heyGeorgia123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (105, 'antoineclark', 'antoine.clark@example.com', 'Antoine', 'Clark', 'Man', 'he/him', 3, 'heyAntoine123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (106, 'valentinwebb', 'valentin.webb@example.com', 'Valentin', 'Webb', 'Man', 'he/him', 3, 'heyValentin123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (107, 'oliviamorales', 'olivia.morales@example.com', 'Olivia', 'Morales', 'Woman', 'she/her', 3, 'heyOlivia123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (108, 'mathieuhebert', 'mathieu.hebert@example.com', 'Mathieu', 'Hebert', 'Man', 'he/him', 3, 'heyMathieu123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (109, 'rosepatel', 'rose.patel@example.com', 'Rose', 'Patel', 'Woman', 'she/her', 3, 'heyRose123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (110, 'travisrichards', 'travis.richards@example.com', 'Travis', 'Richards', 'Man', 'he/him', 3, 'heyTravis123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (111, 'josefinklein', 'josefinklein@example.com', 'Josefin', 'Klein', 'Woman', 'she/her', 3, 'heyJosefin123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (112, 'finnandersen', 'finn.andersen@example.com', 'Finn', 'Andersen', 'Man', 'he/him', 3, 'heyFinn123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (113, 'sofiaparker', 'sofia.parker@example.com', 'Sofia', 'Parker', 'Woman', 'she/her', 3, 'heySofia123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (114, 'theogibson', 'theo.gibson@example.com', 'Theo', 'Gibson', 'Man', 'he/him', 3, 'heyTheo123', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO admin.users VALUES (115, 'floose', 'floose@example.com', 'Floose', 'McGoose', '3', 'any/all', 3, '$2b$10$7pjrECYElk1ithndcAhtcuPytB2Hc8DiDi3e8gAEXYcfIjOVZdEfS', 'active', '2025-01-30 16:59:31.768605');


--
-- TOC entry 3670 (class 0 OID 60603)
-- Dependencies: 245
-- Data for Name: arenas; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.arenas VALUES (1, 'arena', 'Arena', NULL, 1, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.arenas VALUES (2, '1', '1', NULL, 2, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.arenas VALUES (3, '2', '2', NULL, 2, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.arenas VALUES (4, '3', '3', NULL, 2, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.arenas VALUES (5, '4', '4', NULL, 2, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.arenas VALUES (6, 'arena', 'Arena', NULL, 3, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.arenas VALUES (7, 'a', 'A', NULL, 4, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.arenas VALUES (8, 'b', 'B', NULL, 4, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.arenas VALUES (9, 'a', 'A', NULL, 5, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.arenas VALUES (10, 'b', 'B', NULL, 5, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.arenas VALUES (11, 'arena', 'Arena', NULL, 6, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.arenas VALUES (12, 'a', 'A', NULL, 7, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.arenas VALUES (13, 'b', 'B', NULL, 7, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.arenas VALUES (14, 'arena', 'Arena', NULL, 8, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.arenas VALUES (15, 'a', 'A', NULL, 9, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.arenas VALUES (16, 'b', 'B', NULL, 9, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.arenas VALUES (17, 'arena', 'Arena', NULL, 10, '2025-01-30 16:59:31.768605');


--
-- TOC entry 3664 (class 0 OID 60554)
-- Dependencies: 239
-- Data for Name: division_rosters; Type: TABLE DATA; Schema: league_management; Owner: postgres
--



--
-- TOC entry 3662 (class 0 OID 60533)
-- Dependencies: 237
-- Data for Name: division_teams; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.division_teams VALUES (1, 1, 1, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.division_teams VALUES (2, 1, 2, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.division_teams VALUES (3, 1, 3, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.division_teams VALUES (4, 1, 4, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.division_teams VALUES (5, 4, 5, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.division_teams VALUES (6, 4, 6, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.division_teams VALUES (7, 4, 7, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.division_teams VALUES (8, 4, 8, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.division_teams VALUES (9, 4, 9, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.division_teams VALUES (10, 11, 10, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.division_teams VALUES (11, 11, 11, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.division_teams VALUES (12, 11, 12, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.division_teams VALUES (13, 11, 13, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.division_teams VALUES (14, 11, 14, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.division_teams VALUES (15, 4, 2, '2025-01-31 16:11:53.42355');


--
-- TOC entry 3660 (class 0 OID 60510)
-- Dependencies: 235
-- Data for Name: divisions; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.divisions VALUES (2, 'div-1', 'Div 1', NULL, 1, 'all', 3, 'db851f23-36c8-437c-b6b3-c84dbe9db1b3', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (3, 'div-2', 'Div 2', NULL, 1, 'all', 3, '0c9fb01e-3e4f-49e1-9b98-ad605200fcf8', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (5, 'div-2', 'Div 2', NULL, 2, 'all', 4, '4ab607d2-b705-4576-a52c-1b9bcb44520c', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (6, 'div-3', 'Div 3', NULL, 3, 'all', 4, '614df04b-bf5e-4423-b78d-e85b3e149efc', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (8, 'div-5', 'Div 5', NULL, 5, 'all', 4, '3d94046c-8575-4319-bcea-8097f83225eb', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (9, 'men-35', 'Men 35+', NULL, 6, 'men', 4, '9e2a98a7-d86b-4db3-a053-75257d9620fd', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (10, 'women-35', 'Women 35+', NULL, 6, 'women', 4, 'cd8262e4-400c-4bac-9ce9-ed255e93d6a8', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (11, 'div-1', 'Div 1', NULL, 1, 'all', 5, 'f3ea1a86-2e90-4ba7-a1a7-31dc3e93a689', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (12, 'div-2', 'Div 2', NULL, 2, 'all', 5, '37efe214-5418-4e8d-9c42-2cc399cf6978', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (13, 'div-3', 'Div 3', NULL, 3, 'all', 5, '550b7d8a-b1a4-490d-a323-033472464e41', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (14, 'div-4', 'Div 4', NULL, 4, 'all', 5, '8b662c75-bcb7-486b-a641-7d9fe3076c9c', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (15, 'div-5', 'Div 5', NULL, 5, 'all', 5, '8b294258-2e9b-4ca0-920c-f7e5d515ee6a', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (16, 'div-6', 'Div 6', NULL, 6, 'all', 5, '85bbfcae-eaca-44bf-b9ed-9ac1e0bc159e', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (17, 'men-1', 'Men 1', NULL, 1, 'men', 5, '34759952-a416-4176-a2d4-302ce3979454', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (18, 'men-2', 'Men 2', NULL, 2, 'men', 5, '14b5eb62-4c80-4f01-a55f-b0f38004fb38', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (19, 'men-3', 'Men 3', NULL, 3, 'men', 5, 'f6791f2b-c8be-4869-9005-5bae0ca9da3c', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (20, 'women-1', 'Women 1', NULL, 1, 'women', 5, '9ae2f6f6-1ad0-42b4-a71b-c290b2ab9cee', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (21, 'women-2', 'Women 2', NULL, 2, 'women', 5, '7b88f682-1561-4002-9ef3-a1ec88695c43', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (22, 'women-3', 'Women 3', NULL, 3, 'women', 5, 'f163c1a4-faba-4b57-be22-5f8ec6ea0981', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (23, 'div-6', 'Div 6', 'For those elites!', 6, 'all', 4, '', 'draft', '2025-01-30 17:10:14.403961');
INSERT INTO league_management.divisions VALUES (4, 'div-1', 'Div 1', '', 1, 'all', 4, 'aab8a4b1-e321-43b9-babc-03c74f26b50d', 'public', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (1, 'div-inc', 'Div Inc', '', 1, 'all', 1, 'b15a9130-ad19-41c2-be33-93f1fb36c1e7', 'public', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.divisions VALUES (7, 'div-4', 'Div 4', '', 4, 'all', 4, 'cool-shoes-for-days', 'draft', '2025-01-30 16:59:31.768605');


--
-- TOC entry 3674 (class 0 OID 60636)
-- Dependencies: 249
-- Data for Name: games; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.games VALUES (1, 1, 3, 4, 0, 1, NULL, '2024-09-08 17:45:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (2, 2, 3, 3, 4, 1, NULL, '2024-09-08 18:45:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (3, 3, 0, 1, 2, 1, NULL, '2024-09-16 22:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (4, 4, 1, 2, 4, 1, NULL, '2024-09-16 23:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (5, 1, 4, 2, 1, 1, NULL, '2024-09-25 21:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (6, 3, 3, 4, 4, 1, NULL, '2024-09-25 22:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (7, 1, 2, 4, 2, 1, NULL, '2024-10-03 19:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (8, 2, 2, 3, 1, 1, NULL, '2024-10-03 20:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (9, 3, 3, 1, 4, 1, NULL, '2024-10-14 19:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (10, 4, 2, 2, 3, 1, NULL, '2024-10-14 20:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (11, 1, 1, 4, 2, 1, NULL, '2024-10-19 20:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (12, 2, 2, 3, 0, 1, NULL, '2024-10-19 21:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (13, 1, 2, 2, 2, 1, NULL, '2024-10-30 21:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (14, 3, 2, 4, 4, 1, NULL, '2024-10-30 22:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (15, 1, 0, 4, 2, 1, NULL, '2024-11-08 20:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (16, 2, 4, 3, 0, 1, NULL, '2024-11-08 21:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (17, 3, 3, 1, 5, 1, NULL, '2024-11-18 20:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (18, 4, 2, 2, 5, 1, NULL, '2024-11-18 21:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (19, 1, 2, 2, 3, 1, NULL, '2024-11-27 18:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (20, 3, 1, 4, 2, 1, NULL, '2024-11-27 19:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (21, 1, 1, 4, 3, 1, NULL, '2024-12-05 20:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (22, 2, 2, 3, 1, 1, NULL, '2024-12-05 21:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (23, 3, 2, 1, 0, 1, NULL, '2024-12-14 18:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (24, 4, 0, 2, 4, 1, NULL, '2024-12-14 19:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (25, 1, 1, 2, 4, 1, NULL, '2024-12-23 19:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (26, 3, 5, 4, 6, 1, NULL, '2024-12-23 20:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (27, 1, 5, 4, 3, 1, NULL, '2025-01-02 20:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (29, 4, 0, 1, 0, 1, NULL, '2025-01-11 19:45:00', 10, 'cancelled', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (30, 2, 0, 3, 0, 1, NULL, '2025-01-11 20:45:00', 10, 'cancelled', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (32, 3, 4, 4, 1, 1, NULL, '2025-01-23 20:00:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (36, 2, 0, 3, 0, 1, NULL, '2025-02-05 23:00:00', 9, 'public', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (37, 3, 0, 1, 0, 1, NULL, '2025-02-14 22:00:00', 9, 'public', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (38, 4, 0, 2, 0, 1, NULL, '2025-02-14 23:00:00', 9, 'public', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (39, 1, 0, 2, 0, 1, NULL, '2025-02-23 19:00:00', 9, 'public', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (40, 3, 0, 4, 0, 1, NULL, '2025-02-23 20:00:00', 9, 'public', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (41, 1, 0, 4, 0, 1, NULL, '2025-03-03 18:30:00', 10, 'draft', false, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (42, 2, 0, 3, 0, 1, NULL, '2025-03-03 19:30:00', 10, 'draft', false, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (35, 1, 0, 4, 0, 1, NULL, '2025-02-05 22:00:00', 9, 'public', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (33, 3, 0, 1, 4, 1, NULL, '2025-01-26 21:45:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (31, 1, 1, 2, 4, 1, NULL, '2025-01-23 19:00:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (46, 7, 1, 8, 4, 4, NULL, '2025-01-29 21:00:00', 13, 'completed', true, '2025-01-31 12:47:08.939324');
INSERT INTO league_management.games VALUES (34, 4, 3, 2, 1, 1, NULL, '2025-01-26 22:45:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (49, 5, 1, 2, 2, 4, NULL, '2025-01-20 21:30:00', 17, 'completed', false, '2025-01-31 16:12:44.553138');
INSERT INTO league_management.games VALUES (47, 9, 1, 5, 3, 4, NULL, '2025-01-30 20:45:00', 11, 'completed', true, '2025-01-31 13:38:51.595059');
INSERT INTO league_management.games VALUES (50, 6, 0, 2, 0, 4, NULL, '2025-02-07 20:30:00', 12, 'public', true, '2025-01-31 16:15:00.936068');
INSERT INTO league_management.games VALUES (28, 2, 7, 3, 2, 1, NULL, '2025-01-02 21:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (43, 5, 3, 6, 4, 4, NULL, '2025-01-28 21:30:00', 17, 'completed', true, '2025-01-29 18:20:39.803043');
INSERT INTO league_management.games VALUES (48, 6, 3, 8, 1, 4, NULL, '2025-01-31 22:00:00', 17, 'completed', true, '2025-01-31 14:22:31.627166');


--
-- TOC entry 3654 (class 0 OID 60454)
-- Dependencies: 229
-- Data for Name: league_admins; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.league_admins VALUES (1, 1, 1, 5, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.league_admins VALUES (2, 1, 1, 10, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.league_admins VALUES (3, 1, 1, 11, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.league_admins VALUES (4, 1, 2, 4, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.league_admins VALUES (5, 1, 3, 1, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.league_admins VALUES (6, 2, 1, 1, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.league_admins VALUES (10, 1, 7, 115, '2025-02-03 17:04:43.584006');


--
-- TOC entry 3672 (class 0 OID 60618)
-- Dependencies: 247
-- Data for Name: league_venues; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.league_venues VALUES (1, 5, 1, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.league_venues VALUES (2, 7, 3, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.league_venues VALUES (3, 6, 3, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.league_venues VALUES (4, 10, 3, '2025-01-30 16:59:31.768605');


--
-- TOC entry 3652 (class 0 OID 60437)
-- Dependencies: 227
-- Data for Name: leagues; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.leagues VALUES (2, 'fia-hockey', 'FIA Hockey', NULL, 'hockey', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.leagues VALUES (3, 'hometown-hockey', 'Hometown Hockey', '', 'hockey', 'public', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.leagues VALUES (1, 'ottawa-pride-hockey', 'Ottawa Pride Hockey', '', 'hockey', 'public', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.leagues VALUES (7, 'sick-league', 'Sick League', '', 'hockey', 'draft', '2025-02-03 17:04:43.578451');


--
-- TOC entry 3666 (class 0 OID 60572)
-- Dependencies: 241
-- Data for Name: playoffs; Type: TABLE DATA; Schema: league_management; Owner: postgres
--



--
-- TOC entry 3658 (class 0 OID 60492)
-- Dependencies: 233
-- Data for Name: season_admins; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.season_admins VALUES (1, 1, 3, 1, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.season_admins VALUES (2, 1, 4, 3, '2025-01-30 16:59:31.768605');


--
-- TOC entry 3656 (class 0 OID 60472)
-- Dependencies: 231
-- Data for Name: seasons; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.seasons VALUES (2, '2023-2024-season', '2023-2024 Season', NULL, 2, '2023-09-01', '2024-03-31', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.seasons VALUES (3, '2024-2025-season', '2024-2025 Season', NULL, 2, '2024-09-01', '2025-03-31', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.seasons VALUES (5, '2025-spring', '2025 Spring', NULL, 3, '2025-04-01', '2025-06-30', 'draft', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.seasons VALUES (4, '2024-2025-season', '2024-2025 Season', '', 3, '2024-09-01', '2025-03-31', 'public', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.seasons VALUES (1, 'winter-20242025', 'Winter 2024/2025', '', 1, '2024-09-01', '2025-03-31', 'public', '2025-01-30 16:59:31.768605');


--
-- TOC entry 3650 (class 0 OID 60418)
-- Dependencies: 225
-- Data for Name: team_memberships; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.team_memberships VALUES (1, 6, 1, 3, 'Center', 30, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (2, 7, 1, 4, 'Defense', 25, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (3, 10, 2, 3, 'Defense', 18, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (4, 3, 2, 4, 'Defense', 47, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (5, 8, 3, 3, 'Center', 12, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (6, 11, 3, 4, 'Left Wing', 9, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (7, 9, 4, 3, 'Right Wing', 8, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (8, 5, 4, 4, 'Defense', 10, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (9, 15, 1, 5, 'Center', 8, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (10, 16, 1, 5, 'Center', 9, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (11, 17, 1, 5, 'Left Wing', 10, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (12, 18, 1, 5, 'Left Wing', 11, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (13, 19, 1, 5, 'Right Wing', 12, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (14, 20, 1, 5, 'Right Wing', 13, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (15, 21, 1, 5, 'Center', 14, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (16, 22, 1, 5, 'Defense', 15, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (17, 23, 1, 5, 'Defense', 16, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (18, 24, 1, 5, 'Defense', 17, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (19, 25, 1, 5, 'Defense', 18, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (20, 26, 1, 5, 'Goalie', 33, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (21, 27, 2, 5, 'Center', 20, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (22, 28, 2, 5, 'Center', 21, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (23, 29, 2, 5, 'Center', 22, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (24, 30, 2, 5, 'Left Wing', 23, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (25, 31, 2, 5, 'Left Wing', 24, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (26, 32, 2, 5, 'Right Wing', 25, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (27, 33, 2, 5, 'Right Wing', 26, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (28, 34, 2, 5, 'Left Wing', 27, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (29, 35, 2, 5, 'Right Wing', 28, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (30, 36, 2, 5, 'Defense', 29, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (31, 37, 2, 5, 'Defense', 30, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (32, 38, 2, 5, 'Goalie', 31, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (33, 39, 3, 5, 'Center', 40, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (34, 40, 3, 5, 'Center', 41, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (35, 41, 3, 5, 'Left Wing', 42, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (36, 42, 3, 5, 'Left Wing', 43, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (37, 43, 3, 5, 'Right Wing', 44, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (38, 44, 3, 5, 'Right Wing', 45, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (39, 45, 3, 5, 'Center', 46, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (40, 46, 3, 5, 'Defense', 47, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (41, 47, 3, 5, 'Defense', 48, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (42, 48, 3, 5, 'Defense', 49, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (43, 49, 3, 5, 'Defense', 50, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (44, 50, 3, 5, 'Goalie', 51, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (45, 51, 4, 5, 'Center', 26, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (46, 52, 4, 5, 'Center', 27, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (47, 53, 4, 5, 'Left Wing', 28, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (48, 54, 4, 5, 'Left Wing', 29, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (49, 55, 4, 5, 'Right Wing', 30, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (50, 56, 4, 5, 'Right Wing', 31, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (51, 57, 4, 5, 'Center', 32, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (52, 58, 4, 5, 'Defense', 33, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (53, 59, 4, 5, 'Defense', 34, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (54, 60, 4, 5, 'Defense', 35, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (55, 61, 4, 5, 'Defense', 36, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (56, 62, 4, 5, 'Goalie', 37, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (57, 1, 5, 3, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (58, 12, 6, 3, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (59, 13, 7, 3, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (60, 4, 8, 3, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (61, 14, 9, 3, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (62, 60, 5, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (63, 61, 5, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (64, 62, 5, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (65, 63, 5, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (66, 64, 5, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (67, 65, 5, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (68, 66, 5, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (69, 67, 5, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (70, 68, 5, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (71, 69, 5, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (72, 70, 6, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (73, 71, 6, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (74, 72, 6, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (75, 73, 6, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (76, 74, 6, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (77, 75, 6, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (78, 76, 6, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (79, 77, 6, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (80, 78, 6, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (81, 79, 6, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (82, 80, 7, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (83, 81, 7, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (84, 82, 7, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (85, 83, 7, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (86, 84, 7, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (87, 85, 7, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (88, 86, 7, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (89, 87, 7, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (90, 88, 7, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (91, 89, 7, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (92, 90, 8, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (93, 91, 8, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (94, 92, 8, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (95, 93, 8, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (96, 94, 8, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (97, 95, 8, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (98, 96, 8, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (99, 97, 8, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (100, 98, 8, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (101, 99, 8, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (102, 100, 9, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (103, 101, 9, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (104, 102, 9, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (105, 103, 9, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (106, 104, 9, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (107, 105, 9, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (108, 106, 9, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (109, 107, 9, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (110, 108, 9, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (111, 109, 9, 5, NULL, NULL, '2025-01-30 16:59:31.768605');
INSERT INTO league_management.team_memberships VALUES (112, 1, 15, 1, NULL, NULL, '2025-01-30 17:04:37.067367');


--
-- TOC entry 3648 (class 0 OID 60401)
-- Dependencies: 223
-- Data for Name: teams; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.teams VALUES (1, 'significant-otters', 'Significant Otters', NULL, '#942f2f', '4b068647-453c-4527-9591-5f83529fe2a9', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.teams VALUES (2, 'otterwa-senators', 'Otterwa Senators', NULL, '#8d45a3', '991ab72d-1e5c-4c65-8cbb-197b2a741b49', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.teams VALUES (3, 'otter-chaos', 'Otter Chaos', NULL, '#2f945b', '73d6942c-a39b-4ed1-8463-75138581dd58', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.teams VALUES (4, 'otter-nonsense', 'Otter Nonsense', NULL, '#2f3794', '607e00e3-b355-4f31-b034-62ef8516b19e', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.teams VALUES (6, 'blazing-blizzards', 'Blazing Blizzards', 'A team that combines fiery offense with frosty precision.', 'purple', 'a677f142-5bcb-4095-b3dd-12bd0ddbcd2f', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.teams VALUES (7, 'polar-puckers', 'Polar Puckers', 'Masters of the north, specializing in swift plays.', '#285fa2', '20eacf03-6bf9-4ad1-9a01-41fc4056e073', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.teams VALUES (8, 'arctic-avengers', 'Arctic Avengers', 'A cold-blooded team with a knack for thrilling comebacks.', 'yellow', 'c867eff9-3dfa-4805-89e0-4655d7081acf', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.teams VALUES (9, 'glacial-guardians', 'Glacial Guardians', 'Defensive titans who freeze their opponents in their tracks.', 'pink', '48c3e18c-eee1-4b26-823b-ec6c76037b66', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.teams VALUES (10, 'tundra-titans', 'Tundra Titans', 'A powerhouse team dominating the ice with strength and speed.', 'orange', '5d973900-8c14-4b00-a026-e5ce593a2dae', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.teams VALUES (11, 'permafrost-predators', 'Permafrost Predators', 'Known for their unrelenting pressure and icy precision.', '#bc83d4', '05cedee6-126d-4082-97fb-12ac4c7e340c', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.teams VALUES (12, 'snowstorm-scorchers', 'Snowstorm Scorchers', 'A team with a fiery spirit and unstoppable energy.', 'rebeccapurple', 'af735ee5-13b7-4060-bc80-44dbe0d405d2', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.teams VALUES (13, 'frozen-flames', 'Frozen Flames', 'Bringing the heat to the ice with blazing fast attacks.', 'cyan', '4ab488ce-7bee-4683-af1e-d6f11842af2a', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.teams VALUES (14, 'chill-crushers', 'Chill Crushers', 'Breaking the ice with powerful plays and intense rivalries.', 'lime', 'e0e73553-6320-49ef-9022-c366c6f2ac62', 'active', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.teams VALUES (15, 'metcalfe-jets', 'Metcalfe Jets', 'A small town team', '', '', 'active', '2025-01-30 17:04:37.061945');
INSERT INTO league_management.teams VALUES (5, 'frostbiters', 'Frostbiters', 'An icy team known for their chilling defense.', 'cyan', '3c26683e-7c02-4f77-b342-c3bc7aef47b0', 'active', '2025-01-30 16:59:31.768605');


--
-- TOC entry 3668 (class 0 OID 60591)
-- Dependencies: 243
-- Data for Name: venues; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.venues VALUES (1, 'canadian-tire-centre', 'Canadian Tire Centre', 'Home of the NHL''s Ottawa Senators, this state-of-the-art entertainment facility seats 19,153 spectators.', '1000 Palladium Dr, Ottawa, ON K2V 1A5', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.venues VALUES (2, 'bell-sensplex', 'Bell Sensplex', 'A multi-purpose sports facility featuring four NHL-sized ice rinks, including an Olympic-sized rink, operated by Capital Sports Management.', '1565 Maple Grove Rd, Ottawa, ON K2V 1A3', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.venues VALUES (3, 'td-place-arena', 'TD Place Arena', 'An indoor arena located at Lansdowne Park, hosting the Ottawa 67''s (OHL) and Ottawa Blackjacks (CEBL), with a seating capacity of up to 8,585.', '1015 Bank St, Ottawa, ON K1S 3W7', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.venues VALUES (4, 'minto-sports-complex-arena', 'Minto Sports Complex Arena', 'Part of the University of Ottawa, this complex contains two ice rinks, one with seating for 840 spectators, and the Draft Pub overlooking the ice.', '801 King Edward Ave, Ottawa, ON K1N 6N5', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.venues VALUES (5, 'carleton-university-ice-house', 'Carleton University Ice House', 'A leading indoor skating facility featuring two NHL-sized ice surfaces, home to the Carleton Ravens hockey teams.', '1125 Colonel By Dr, Ottawa, ON K1S 5B6', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.venues VALUES (6, 'howard-darwin-centennial-arena', 'Howard Darwin Centennial Arena', 'A community arena offering ice rentals and public skating programs, managed by the City of Ottawa.', '1765 Merivale Rd, Ottawa, ON K2G 1E1', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.venues VALUES (7, 'fred-barrett-arena', 'Fred Barrett Arena', 'A municipal arena providing ice rentals and public skating, located in the southern part of Ottawa.', '3280 Leitrim Rd, Ottawa, ON K1T 3Z4', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.venues VALUES (8, 'blackburn-arena', 'Blackburn Arena', 'A community arena offering skating programs and ice rentals, serving the Blackburn Hamlet area.', '200 Glen Park Dr, Gloucester, ON K1B 5A3', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.venues VALUES (9, 'bob-macquarrie-recreation-complex-orlans-arena', 'Bob MacQuarrie Recreation Complex – Orléans Arena', 'A recreation complex featuring an arena, pool, and fitness facilities, serving the Orléans community.', '1490 Youville Dr, Orléans, ON K1C 2X8', '2025-01-30 16:59:31.768605');
INSERT INTO league_management.venues VALUES (10, 'brewer-arena', 'Brewer Arena', 'A municipal arena adjacent to Brewer Park, offering public skating and ice rentals.', '200 Hopewell Ave, Ottawa, ON K1S 2Z5', '2025-01-30 16:59:31.768605');


--
-- TOC entry 3678 (class 0 OID 60695)
-- Dependencies: 253
-- Data for Name: assists; Type: TABLE DATA; Schema: stats; Owner: postgres
--

INSERT INTO stats.assists VALUES (1, 1, 31, 33, 2, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.assists VALUES (2, 1, 31, 30, 2, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.assists VALUES (3, 2, 31, 3, 2, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.assists VALUES (4, 3, 31, 16, 1, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.assists VALUES (5, 4, 31, 30, 2, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.assists VALUES (28, 31, 33, 7, 1, true, '2025-01-28 22:12:20.844298');
INSERT INTO stats.assists VALUES (29, 32, 33, 22, 1, true, '2025-01-28 22:22:01.452293');
INSERT INTO stats.assists VALUES (30, 34, 33, 6, 1, true, '2025-01-28 22:26:59.666412');
INSERT INTO stats.assists VALUES (33, 37, 33, 25, 1, true, '2025-01-28 22:28:27.851364');
INSERT INTO stats.assists VALUES (46, 55, 43, 61, 5, true, '2025-01-29 18:21:40.518237');
INSERT INTO stats.assists VALUES (49, 57, 28, 10, 2, true, '2025-01-29 21:14:24.144683');
INSERT INTO stats.assists VALUES (50, 59, 28, 43, 3, true, '2025-01-29 21:15:04.368026');
INSERT INTO stats.assists VALUES (51, 60, 28, 35, 2, true, '2025-01-29 21:15:30.875789');
INSERT INTO stats.assists VALUES (52, 61, 28, 3, 2, true, '2025-01-29 21:15:51.821809');
INSERT INTO stats.assists VALUES (53, 62, 28, 43, 3, true, '2025-01-29 21:16:33.021139');
INSERT INTO stats.assists VALUES (54, 63, 28, 37, 2, true, '2025-01-29 21:16:54.814861');
INSERT INTO stats.assists VALUES (55, 64, 28, 34, 2, true, '2025-01-29 21:17:20.730325');
INSERT INTO stats.assists VALUES (56, 65, 28, 34, 2, true, '2025-01-29 21:18:11.706933');
INSERT INTO stats.assists VALUES (57, 66, 34, 3, 2, true, '2025-01-30 19:29:25.064095');
INSERT INTO stats.assists VALUES (59, 70, 46, 93, 8, true, '2025-01-31 12:48:22.160339');
INSERT INTO stats.assists VALUES (60, 70, 46, 92, 8, false, '2025-01-31 12:48:22.163271');
INSERT INTO stats.assists VALUES (61, 71, 46, 89, 7, true, '2025-01-31 12:48:49.323484');
INSERT INTO stats.assists VALUES (62, 71, 46, 86, 7, false, '2025-01-31 12:48:49.325205');
INSERT INTO stats.assists VALUES (63, 72, 46, 95, 8, true, '2025-01-31 12:49:13.948142');
INSERT INTO stats.assists VALUES (64, 72, 46, 99, 8, false, '2025-01-31 12:49:13.950133');
INSERT INTO stats.assists VALUES (65, 73, 46, 4, 8, true, '2025-01-31 12:49:39.543621');
INSERT INTO stats.assists VALUES (66, 74, 46, 96, 8, true, '2025-01-31 12:49:58.808175');
INSERT INTO stats.assists VALUES (67, 74, 46, 92, 8, false, '2025-01-31 12:49:58.810277');
INSERT INTO stats.assists VALUES (68, 75, 47, 67, 5, true, '2025-01-31 13:49:17.011754');
INSERT INTO stats.assists VALUES (69, 75, 47, 63, 5, false, '2025-01-31 13:49:17.014353');
INSERT INTO stats.assists VALUES (70, 76, 47, 69, 5, true, '2025-01-31 13:50:09.753327');
INSERT INTO stats.assists VALUES (71, 76, 47, 64, 5, false, '2025-01-31 13:50:09.754901');
INSERT INTO stats.assists VALUES (72, 77, 47, 103, 9, true, '2025-01-31 14:04:31.832027');
INSERT INTO stats.assists VALUES (73, 78, 47, 1, 5, true, '2025-01-31 14:04:53.658749');
INSERT INTO stats.assists VALUES (74, 79, 43, 70, 6, true, '2025-01-31 14:06:18.158741');
INSERT INTO stats.assists VALUES (75, 80, 43, 78, 6, true, '2025-01-31 14:09:45.231942');
INSERT INTO stats.assists VALUES (76, 80, 43, 79, 6, false, '2025-01-31 14:09:45.234272');
INSERT INTO stats.assists VALUES (78, 82, 43, 65, 5, true, '2025-01-31 14:11:04.929727');
INSERT INTO stats.assists VALUES (79, 83, 43, 12, 6, true, '2025-01-31 14:14:42.809173');
INSERT INTO stats.assists VALUES (80, 84, 48, 93, 8, true, '2025-01-31 14:22:50.338125');
INSERT INTO stats.assists VALUES (81, 85, 48, 75, 6, true, '2025-01-31 14:23:05.01828');
INSERT INTO stats.assists VALUES (82, 86, 48, 78, 6, true, '2025-01-31 14:23:28.611552');
INSERT INTO stats.assists VALUES (83, 87, 48, 70, 6, true, '2025-01-31 14:24:19.144736');
INSERT INTO stats.assists VALUES (84, 87, 48, 71, 6, false, '2025-01-31 14:24:19.146655');
INSERT INTO stats.assists VALUES (85, 88, 34, 5, 4, true, '2025-01-31 14:51:01.646627');
INSERT INTO stats.assists VALUES (86, 89, 34, 57, 4, true, '2025-01-31 14:51:58.871587');
INSERT INTO stats.assists VALUES (87, 92, 49, 37, 2, true, '2025-01-31 16:13:08.180217');
INSERT INTO stats.assists VALUES (88, 94, 49, 37, 2, true, '2025-01-31 16:14:16.682627');


--
-- TOC entry 3676 (class 0 OID 60667)
-- Dependencies: 251
-- Data for Name: goals; Type: TABLE DATA; Schema: stats; Owner: postgres
--

INSERT INTO stats.goals VALUES (1, 31, 3, 2, 1, '00:11:20', false, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.goals VALUES (2, 31, 10, 2, 1, '00:15:37', false, true, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.goals VALUES (3, 31, 6, 1, 2, '00:05:40', false, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.goals VALUES (4, 31, 3, 2, 2, '00:18:10', false, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.goals VALUES (5, 31, 28, 2, 3, '00:18:20', false, false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.goals VALUES (31, 33, 6, 1, 2, '00:03:32', false, false, false, '2025-01-28 22:12:20.836554');
INSERT INTO stats.goals VALUES (32, 33, 7, 1, 2, '00:06:55', false, true, false, '2025-01-28 22:22:01.446369');
INSERT INTO stats.goals VALUES (34, 33, 20, 1, 3, '00:16:51', false, false, false, '2025-01-28 22:26:59.659856');
INSERT INTO stats.goals VALUES (37, 33, 6, 1, 3, '00:19:28', false, false, true, '2025-01-28 22:28:27.845173');
INSERT INTO stats.goals VALUES (53, 43, 1, 5, 1, '00:02:14', false, false, false, '2025-01-29 18:21:12.871841');
INSERT INTO stats.goals VALUES (54, 43, 73, 6, 1, '00:04:15', false, false, false, '2025-01-29 18:21:28.21693');
INSERT INTO stats.goals VALUES (55, 43, 1, 5, 2, '00:04:16', false, false, false, '2025-01-29 18:21:40.511549');
INSERT INTO stats.goals VALUES (57, 28, 3, 2, 1, '00:02:00', false, false, false, '2025-01-29 21:14:24.138571');
INSERT INTO stats.goals VALUES (58, 28, 27, 2, 1, '00:06:07', false, false, false, '2025-01-29 21:14:43.596312');
INSERT INTO stats.goals VALUES (59, 28, 50, 3, 1, '00:10:19', false, false, false, '2025-01-29 21:15:04.362646');
INSERT INTO stats.goals VALUES (60, 28, 3, 2, 1, '00:16:24', false, false, false, '2025-01-29 21:15:30.869789');
INSERT INTO stats.goals VALUES (61, 28, 10, 2, 2, '00:06:10', false, false, false, '2025-01-29 21:15:51.815019');
INSERT INTO stats.goals VALUES (62, 28, 11, 3, 2, '00:10:23', false, true, false, '2025-01-29 21:16:33.015637');
INSERT INTO stats.goals VALUES (63, 28, 3, 2, 3, '00:05:24', false, false, false, '2025-01-29 21:16:54.809394');
INSERT INTO stats.goals VALUES (64, 28, 30, 2, 3, '00:12:56', false, false, false, '2025-01-29 21:17:20.723557');
INSERT INTO stats.goals VALUES (65, 28, 10, 2, 3, '00:17:17', false, false, false, '2025-01-29 21:18:11.700948');
INSERT INTO stats.goals VALUES (66, 34, 10, 2, 3, '00:19:50', false, false, false, '2025-01-30 19:29:25.056506');
INSERT INTO stats.goals VALUES (70, 46, 94, 8, 1, '00:03:12', false, false, false, '2025-01-31 12:48:22.153813');
INSERT INTO stats.goals VALUES (71, 46, 13, 7, 1, '00:03:13', false, false, false, '2025-01-31 12:48:49.317687');
INSERT INTO stats.goals VALUES (72, 46, 4, 8, 1, '00:07:19', false, false, false, '2025-01-31 12:49:13.94251');
INSERT INTO stats.goals VALUES (73, 46, 93, 8, 2, '00:11:20', false, false, false, '2025-01-31 12:49:39.53854');
INSERT INTO stats.goals VALUES (74, 46, 4, 8, 3, '00:16:21', false, false, false, '2025-01-31 12:49:58.803182');
INSERT INTO stats.goals VALUES (75, 47, 1, 5, 1, '00:09:00', false, false, false, '2025-01-31 13:49:17.005933');
INSERT INTO stats.goals VALUES (76, 47, 1, 5, 1, '00:13:17', false, true, false, '2025-01-31 13:50:09.7489');
INSERT INTO stats.goals VALUES (77, 47, 14, 9, 2, '00:08:13', false, false, false, '2025-01-31 14:04:31.827789');
INSERT INTO stats.goals VALUES (78, 47, 68, 5, 3, '00:18:56', false, false, true, '2025-01-31 14:04:53.654327');
INSERT INTO stats.goals VALUES (79, 43, 12, 6, 2, '00:10:24', false, false, false, '2025-01-31 14:06:18.15422');
INSERT INTO stats.goals VALUES (80, 43, 12, 6, 3, '00:14:25', false, false, false, '2025-01-31 14:09:45.226699');
INSERT INTO stats.goals VALUES (82, 43, 63, 5, 3, '00:19:23', false, false, false, '2025-01-31 14:11:04.925064');
INSERT INTO stats.goals VALUES (83, 43, 74, 6, 3, '00:19:44', false, false, false, '2025-01-31 14:14:42.804546');
INSERT INTO stats.goals VALUES (84, 48, 4, 8, 1, '00:10:00', false, false, false, '2025-01-31 14:22:50.332613');
INSERT INTO stats.goals VALUES (85, 48, 12, 6, 1, '00:15:00', false, false, false, '2025-01-31 14:23:05.013364');
INSERT INTO stats.goals VALUES (86, 48, 12, 6, 2, '00:07:00', false, false, false, '2025-01-31 14:23:28.606041');
INSERT INTO stats.goals VALUES (87, 48, 12, 6, 3, '00:13:06', false, false, false, '2025-01-31 14:24:19.139733');
INSERT INTO stats.goals VALUES (88, 34, 9, 4, 1, '00:19:51', false, false, false, '2025-01-31 14:51:01.641769');
INSERT INTO stats.goals VALUES (89, 34, 5, 4, 2, '00:06:38', false, true, false, '2025-01-31 14:51:58.867463');
INSERT INTO stats.goals VALUES (90, 34, 5, 4, 3, '00:07:37', false, false, false, '2025-01-31 14:52:32.568702');
INSERT INTO stats.goals VALUES (92, 49, 10, 2, 1, '00:15:00', false, false, false, '2025-01-31 16:13:08.17596');
INSERT INTO stats.goals VALUES (93, 49, 63, 5, 2, '00:07:18', false, false, false, '2025-01-31 16:13:22.432711');
INSERT INTO stats.goals VALUES (94, 49, 3, 2, 3, '00:08:21', false, false, false, '2025-01-31 16:14:16.677822');


--
-- TOC entry 3680 (class 0 OID 60724)
-- Dependencies: 255
-- Data for Name: penalties; Type: TABLE DATA; Schema: stats; Owner: postgres
--

INSERT INTO stats.penalties VALUES (1, 31, 7, 1, 1, '00:15:02', 'Tripping', 2, '2025-01-28 15:35:00.023976');
INSERT INTO stats.penalties VALUES (2, 31, 32, 2, 2, '00:08:22', 'Hooking', 2, '2025-01-28 15:35:00.023976');
INSERT INTO stats.penalties VALUES (3, 31, 32, 2, 3, '00:11:31', 'Interference', 2, '2025-01-28 15:35:00.023976');
INSERT INTO stats.penalties VALUES (7, 33, 15, 1, 1, '00:12:25', 'Tripping', 2, '2025-01-28 22:11:31.236037');
INSERT INTO stats.penalties VALUES (8, 33, 47, 3, 2, '00:05:48', 'Too Many Players', 2, '2025-01-28 22:21:39.139248');
INSERT INTO stats.penalties VALUES (9, 33, 19, 1, 3, '00:12:42', 'Hooking', 2, '2025-01-28 22:22:38.701351');
INSERT INTO stats.penalties VALUES (11, 34, 10, 2, 2, '00:05:50', 'Holding', 2, '2025-01-29 17:32:25.075633');
INSERT INTO stats.penalties VALUES (12, 34, 32, 2, 3, '00:06:55', 'Hitting from behind', 5, '2025-01-29 19:37:54.835293');
INSERT INTO stats.penalties VALUES (13, 28, 27, 2, 2, '00:09:18', 'Roughing', 2, '2025-01-29 21:16:15.507966');
INSERT INTO stats.penalties VALUES (14, 47, 14, 9, 1, '00:12:11', 'Hooking', 2, '2025-01-31 13:49:42.571771');


--
-- TOC entry 3684 (class 0 OID 60778)
-- Dependencies: 259
-- Data for Name: saves; Type: TABLE DATA; Schema: stats; Owner: postgres
--

INSERT INTO stats.saves VALUES (1, 31, 26, 1, 1, 1, '00:05:15', false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves VALUES (2, 31, 38, 2, 2, 1, '00:07:35', false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves VALUES (3, 31, 26, 1, 3, 1, '00:09:05', false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves VALUES (4, 31, 38, 2, 4, 1, '00:10:03', false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves VALUES (5, 31, 26, 1, 7, 1, '00:17:43', false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves VALUES (6, 31, 26, 1, 8, 2, '00:01:11', false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves VALUES (7, 31, 38, 2, 10, 2, '00:07:15', false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves VALUES (8, 31, 26, 1, 11, 2, '00:11:15', false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves VALUES (9, 31, 26, 1, 13, 3, '00:07:12', false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves VALUES (10, 31, 38, 2, 14, 3, '00:11:56', true, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves VALUES (11, 31, 26, 1, 15, 3, '00:15:15', false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves VALUES (28, 33, 50, 3, 60, 1, '00:07:02', false, false, '2025-01-28 22:10:08.823041');
INSERT INTO stats.saves VALUES (29, 33, 26, 1, 63, 2, '00:05:47', false, false, '2025-01-28 22:21:11.455121');
INSERT INTO stats.saves VALUES (34, 34, 38, 2, 81, 1, '00:15:18', false, false, '2025-01-29 17:30:20.974172');
INSERT INTO stats.saves VALUES (39, 49, 38, 2, 138, 2, '00:15:20', false, false, '2025-01-31 16:13:46.285032');


--
-- TOC entry 3682 (class 0 OID 60748)
-- Dependencies: 257
-- Data for Name: shots; Type: TABLE DATA; Schema: stats; Owner: postgres
--

INSERT INTO stats.shots VALUES (1, 31, 3, 2, 1, '00:05:15', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots VALUES (2, 31, 6, 1, 1, '00:07:35', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots VALUES (3, 31, 31, 2, 1, '00:09:05', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots VALUES (4, 31, 18, 1, 1, '00:10:03', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots VALUES (5, 31, 3, 2, 1, '00:11:20', 1, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots VALUES (6, 31, 10, 2, 1, '00:15:37', 2, false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots VALUES (7, 31, 3, 2, 1, '00:17:43', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots VALUES (8, 31, 10, 2, 2, '00:01:11', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots VALUES (9, 31, 6, 1, 2, '00:05:40', 3, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots VALUES (10, 31, 21, 1, 2, '00:07:15', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots VALUES (11, 31, 34, 2, 2, '00:11:15', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots VALUES (12, 31, 3, 2, 2, '00:18:10', 4, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots VALUES (13, 31, 27, 2, 3, '00:07:12', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots VALUES (14, 31, 22, 1, 3, '00:11:56', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots VALUES (15, 31, 36, 2, 3, '00:15:15', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots VALUES (16, 31, 28, 2, 3, '00:18:20', 5, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots VALUES (60, 33, 26, 1, 1, '00:07:02', NULL, false, false, '2025-01-28 22:10:08.819217');
INSERT INTO stats.shots VALUES (62, 33, 6, 1, 2, '00:03:32', 31, false, false, '2025-01-28 22:12:20.846527');
INSERT INTO stats.shots VALUES (63, 33, 8, 3, 2, '00:05:47', NULL, false, false, '2025-01-28 22:21:11.452163');
INSERT INTO stats.shots VALUES (64, 33, 7, 1, 2, '00:06:55', 32, false, true, '2025-01-28 22:22:01.455122');
INSERT INTO stats.shots VALUES (66, 33, 20, 1, 3, '00:16:51', 34, false, false, '2025-01-28 22:26:59.668639');
INSERT INTO stats.shots VALUES (69, 33, 6, 1, 3, '00:19:28', 37, false, false, '2025-01-28 22:28:27.853387');
INSERT INTO stats.shots VALUES (81, 34, 51, 4, 1, '00:15:18', NULL, false, false, '2025-01-29 17:30:20.970281');
INSERT INTO stats.shots VALUES (91, 43, 1, 5, 1, '00:02:14', 53, false, false, '2025-01-29 18:21:12.878535');
INSERT INTO stats.shots VALUES (92, 43, 73, 6, 1, '00:04:15', 54, false, false, '2025-01-29 18:21:28.221923');
INSERT INTO stats.shots VALUES (93, 43, 1, 5, 2, '00:04:16', 55, false, false, '2025-01-29 18:21:40.520499');
INSERT INTO stats.shots VALUES (95, 28, 3, 2, 1, '00:02:00', 57, false, false, '2025-01-29 21:14:24.146839');
INSERT INTO stats.shots VALUES (96, 28, 27, 2, 1, '00:06:07', 58, false, false, '2025-01-29 21:14:43.602289');
INSERT INTO stats.shots VALUES (97, 28, 50, 3, 1, '00:10:19', 59, false, false, '2025-01-29 21:15:04.370381');
INSERT INTO stats.shots VALUES (98, 28, 3, 2, 1, '00:16:24', 60, false, false, '2025-01-29 21:15:30.877857');
INSERT INTO stats.shots VALUES (99, 28, 10, 2, 2, '00:06:10', 61, false, false, '2025-01-29 21:15:51.825065');
INSERT INTO stats.shots VALUES (100, 28, 11, 3, 2, '00:10:23', 62, false, true, '2025-01-29 21:16:33.02304');
INSERT INTO stats.shots VALUES (101, 28, 3, 2, 3, '00:05:24', 63, false, false, '2025-01-29 21:16:54.817298');
INSERT INTO stats.shots VALUES (102, 28, 30, 2, 3, '00:12:56', 64, false, false, '2025-01-29 21:17:20.732602');
INSERT INTO stats.shots VALUES (103, 28, 10, 2, 3, '00:17:17', 65, false, false, '2025-01-29 21:18:11.70895');
INSERT INTO stats.shots VALUES (104, 34, 10, 2, 3, '00:19:50', 66, false, false, '2025-01-30 19:29:25.066441');
INSERT INTO stats.shots VALUES (109, 46, 94, 8, 1, '00:03:12', 70, false, false, '2025-01-31 12:48:22.164783');
INSERT INTO stats.shots VALUES (110, 46, 13, 7, 1, '00:03:13', 71, false, false, '2025-01-31 12:48:49.32671');
INSERT INTO stats.shots VALUES (111, 46, 4, 8, 1, '00:07:19', 72, false, false, '2025-01-31 12:49:13.951748');
INSERT INTO stats.shots VALUES (112, 46, 93, 8, 2, '00:11:20', 73, false, false, '2025-01-31 12:49:39.545655');
INSERT INTO stats.shots VALUES (113, 46, 4, 8, 3, '00:16:21', 74, false, false, '2025-01-31 12:49:58.812247');
INSERT INTO stats.shots VALUES (114, 47, 1, 5, 1, '00:09:00', 75, false, false, '2025-01-31 13:49:17.016808');
INSERT INTO stats.shots VALUES (115, 47, 1, 5, 1, '00:13:17', 76, false, true, '2025-01-31 13:50:09.756151');
INSERT INTO stats.shots VALUES (117, 47, 14, 9, 2, '00:03:11', NULL, false, false, '2025-01-31 13:51:29.431308');
INSERT INTO stats.shots VALUES (118, 47, 66, 5, 2, '00:05:12', NULL, false, false, '2025-01-31 14:03:58.495521');
INSERT INTO stats.shots VALUES (119, 47, 14, 9, 2, '00:08:13', 77, false, false, '2025-01-31 14:04:31.83424');
INSERT INTO stats.shots VALUES (120, 47, 68, 5, 3, '00:18:56', 78, false, false, '2025-01-31 14:04:53.660301');
INSERT INTO stats.shots VALUES (121, 43, 12, 6, 2, '00:10:24', 79, false, false, '2025-01-31 14:06:18.160428');
INSERT INTO stats.shots VALUES (122, 43, 12, 6, 3, '00:14:25', 80, false, false, '2025-01-31 14:09:45.235912');
INSERT INTO stats.shots VALUES (124, 43, 63, 5, 3, '00:19:23', 82, false, false, '2025-01-31 14:11:04.931927');
INSERT INTO stats.shots VALUES (125, 43, 74, 6, 3, '00:19:44', 83, false, false, '2025-01-31 14:14:42.811083');
INSERT INTO stats.shots VALUES (126, 48, 4, 8, 1, '00:10:00', 84, false, false, '2025-01-31 14:22:50.340325');
INSERT INTO stats.shots VALUES (127, 48, 12, 6, 1, '00:15:00', 85, false, false, '2025-01-31 14:23:05.020307');
INSERT INTO stats.shots VALUES (128, 48, 12, 6, 2, '00:07:00', 86, false, false, '2025-01-31 14:23:28.613506');
INSERT INTO stats.shots VALUES (130, 48, 12, 6, 3, '00:13:06', 87, false, false, '2025-01-31 14:24:19.14811');
INSERT INTO stats.shots VALUES (131, 34, 9, 4, 1, '00:19:51', 88, false, false, '2025-01-31 14:51:01.648853');
INSERT INTO stats.shots VALUES (132, 34, 5, 4, 2, '00:06:38', 89, false, true, '2025-01-31 14:51:58.873246');
INSERT INTO stats.shots VALUES (133, 34, 5, 4, 3, '00:07:37', 90, false, false, '2025-01-31 14:52:32.574245');
INSERT INTO stats.shots VALUES (135, 49, 10, 2, 1, '00:15:00', 92, false, false, '2025-01-31 16:13:08.181947');
INSERT INTO stats.shots VALUES (136, 49, 63, 5, 2, '00:07:18', 93, false, false, '2025-01-31 16:13:22.437177');
INSERT INTO stats.shots VALUES (137, 49, 3, 2, 2, '00:11:19', NULL, false, false, '2025-01-31 16:13:31.262792');
INSERT INTO stats.shots VALUES (138, 49, 1, 5, 2, '00:15:20', NULL, false, false, '2025-01-31 16:13:46.281404');
INSERT INTO stats.shots VALUES (139, 49, 3, 2, 3, '00:08:21', 94, false, false, '2025-01-31 16:14:16.68463');


--
-- TOC entry 3686 (class 0 OID 60808)
-- Dependencies: 261
-- Data for Name: shutouts; Type: TABLE DATA; Schema: stats; Owner: postgres
--



--
-- TOC entry 3713 (class 0 OID 0)
-- Dependencies: 220
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: admin; Owner: postgres
--

SELECT pg_catalog.setval('admin.users_user_id_seq', 117, true);


--
-- TOC entry 3714 (class 0 OID 0)
-- Dependencies: 244
-- Name: arenas_arena_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.arenas_arena_id_seq', 17, true);


--
-- TOC entry 3715 (class 0 OID 0)
-- Dependencies: 238
-- Name: division_rosters_division_roster_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.division_rosters_division_roster_id_seq', 1, false);


--
-- TOC entry 3716 (class 0 OID 0)
-- Dependencies: 236
-- Name: division_teams_division_team_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.division_teams_division_team_id_seq', 15, true);


--
-- TOC entry 3717 (class 0 OID 0)
-- Dependencies: 234
-- Name: divisions_division_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.divisions_division_id_seq', 23, true);


--
-- TOC entry 3718 (class 0 OID 0)
-- Dependencies: 248
-- Name: games_game_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.games_game_id_seq', 50, true);


--
-- TOC entry 3719 (class 0 OID 0)
-- Dependencies: 228
-- Name: league_admins_league_admin_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.league_admins_league_admin_id_seq', 10, true);


--
-- TOC entry 3720 (class 0 OID 0)
-- Dependencies: 246
-- Name: league_venues_league_venue_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.league_venues_league_venue_id_seq', 4, true);


--
-- TOC entry 3721 (class 0 OID 0)
-- Dependencies: 226
-- Name: leagues_league_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.leagues_league_id_seq', 7, true);


--
-- TOC entry 3722 (class 0 OID 0)
-- Dependencies: 240
-- Name: playoffs_playoff_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.playoffs_playoff_id_seq', 1, false);


--
-- TOC entry 3723 (class 0 OID 0)
-- Dependencies: 232
-- Name: season_admins_season_admin_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.season_admins_season_admin_id_seq', 2, true);


--
-- TOC entry 3724 (class 0 OID 0)
-- Dependencies: 230
-- Name: seasons_season_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.seasons_season_id_seq', 5, true);


--
-- TOC entry 3725 (class 0 OID 0)
-- Dependencies: 224
-- Name: team_memberships_team_membership_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.team_memberships_team_membership_id_seq', 112, true);


--
-- TOC entry 3726 (class 0 OID 0)
-- Dependencies: 222
-- Name: teams_team_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.teams_team_id_seq', 16, true);


--
-- TOC entry 3727 (class 0 OID 0)
-- Dependencies: 242
-- Name: venues_venue_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.venues_venue_id_seq', 10, true);


--
-- TOC entry 3728 (class 0 OID 0)
-- Dependencies: 252
-- Name: assists_assist_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.assists_assist_id_seq', 88, true);


--
-- TOC entry 3729 (class 0 OID 0)
-- Dependencies: 250
-- Name: goals_goal_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.goals_goal_id_seq', 94, true);


--
-- TOC entry 3730 (class 0 OID 0)
-- Dependencies: 254
-- Name: penalties_penalty_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.penalties_penalty_id_seq', 14, true);


--
-- TOC entry 3731 (class 0 OID 0)
-- Dependencies: 258
-- Name: saves_save_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.saves_save_id_seq', 39, true);


--
-- TOC entry 3732 (class 0 OID 0)
-- Dependencies: 256
-- Name: shots_shot_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.shots_shot_id_seq', 139, true);


--
-- TOC entry 3733 (class 0 OID 0)
-- Dependencies: 260
-- Name: shutouts_shutout_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.shutouts_shutout_id_seq', 1, false);


--
-- TOC entry 3396 (class 2606 OID 60398)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3398 (class 2606 OID 60394)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 3400 (class 2606 OID 60396)
-- Name: users users_username_key; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 3432 (class 2606 OID 60611)
-- Name: arenas arenas_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.arenas
    ADD CONSTRAINT arenas_pkey PRIMARY KEY (arena_id);


--
-- TOC entry 3424 (class 2606 OID 60560)
-- Name: division_rosters division_rosters_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_rosters
    ADD CONSTRAINT division_rosters_pkey PRIMARY KEY (division_roster_id);


--
-- TOC entry 3422 (class 2606 OID 60539)
-- Name: division_teams division_teams_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_teams
    ADD CONSTRAINT division_teams_pkey PRIMARY KEY (division_team_id);


--
-- TOC entry 3420 (class 2606 OID 60521)
-- Name: divisions divisions_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.divisions
    ADD CONSTRAINT divisions_pkey PRIMARY KEY (division_id);


--
-- TOC entry 3436 (class 2606 OID 60646)
-- Name: games games_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games
    ADD CONSTRAINT games_pkey PRIMARY KEY (game_id);


--
-- TOC entry 3414 (class 2606 OID 60460)
-- Name: league_admins league_admins_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins
    ADD CONSTRAINT league_admins_pkey PRIMARY KEY (league_admin_id);


--
-- TOC entry 3434 (class 2606 OID 60624)
-- Name: league_venues league_venues_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_venues
    ADD CONSTRAINT league_venues_pkey PRIMARY KEY (league_venue_id);


--
-- TOC entry 3410 (class 2606 OID 60446)
-- Name: leagues leagues_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.leagues
    ADD CONSTRAINT leagues_pkey PRIMARY KEY (league_id);


--
-- TOC entry 3412 (class 2606 OID 60448)
-- Name: leagues leagues_slug_key; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.leagues
    ADD CONSTRAINT leagues_slug_key UNIQUE (slug);


--
-- TOC entry 3426 (class 2606 OID 60582)
-- Name: playoffs playoffs_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.playoffs
    ADD CONSTRAINT playoffs_pkey PRIMARY KEY (playoff_id);


--
-- TOC entry 3418 (class 2606 OID 60498)
-- Name: season_admins season_admins_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins
    ADD CONSTRAINT season_admins_pkey PRIMARY KEY (season_admin_id);


--
-- TOC entry 3416 (class 2606 OID 60481)
-- Name: seasons seasons_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.seasons
    ADD CONSTRAINT seasons_pkey PRIMARY KEY (season_id);


--
-- TOC entry 3408 (class 2606 OID 60425)
-- Name: team_memberships team_memberships_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships
    ADD CONSTRAINT team_memberships_pkey PRIMARY KEY (team_membership_id);


--
-- TOC entry 3402 (class 2606 OID 60415)
-- Name: teams teams_join_code_key; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.teams
    ADD CONSTRAINT teams_join_code_key UNIQUE (join_code);


--
-- TOC entry 3404 (class 2606 OID 60411)
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (team_id);


--
-- TOC entry 3406 (class 2606 OID 60413)
-- Name: teams teams_slug_key; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.teams
    ADD CONSTRAINT teams_slug_key UNIQUE (slug);


--
-- TOC entry 3428 (class 2606 OID 60599)
-- Name: venues venues_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.venues
    ADD CONSTRAINT venues_pkey PRIMARY KEY (venue_id);


--
-- TOC entry 3430 (class 2606 OID 60601)
-- Name: venues venues_slug_key; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.venues
    ADD CONSTRAINT venues_slug_key UNIQUE (slug);


--
-- TOC entry 3440 (class 2606 OID 60702)
-- Name: assists assists_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT assists_pkey PRIMARY KEY (assist_id);


--
-- TOC entry 3438 (class 2606 OID 60676)
-- Name: goals goals_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals
    ADD CONSTRAINT goals_pkey PRIMARY KEY (goal_id);


--
-- TOC entry 3442 (class 2606 OID 60731)
-- Name: penalties penalties_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties
    ADD CONSTRAINT penalties_pkey PRIMARY KEY (penalty_id);


--
-- TOC entry 3446 (class 2606 OID 60786)
-- Name: saves saves_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT saves_pkey PRIMARY KEY (save_id);


--
-- TOC entry 3444 (class 2606 OID 60756)
-- Name: shots shots_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT shots_pkey PRIMARY KEY (shot_id);


--
-- TOC entry 3448 (class 2606 OID 60814)
-- Name: shutouts shutouts_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts
    ADD CONSTRAINT shutouts_pkey PRIMARY KEY (shutout_id);


--
-- TOC entry 3497 (class 2620 OID 60664)
-- Name: games insert_game_status_check; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER insert_game_status_check BEFORE INSERT ON league_management.games FOR EACH ROW EXECUTE FUNCTION league_management.mark_game_as_published();


--
-- TOC entry 3495 (class 2620 OID 60530)
-- Name: divisions set_divisions_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER set_divisions_slug BEFORE INSERT ON league_management.divisions FOR EACH ROW EXECUTE FUNCTION league_management.generate_division_slug();


--
-- TOC entry 3491 (class 2620 OID 60451)
-- Name: leagues set_leagues_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER set_leagues_slug BEFORE INSERT ON league_management.leagues FOR EACH ROW EXECUTE FUNCTION league_management.generate_league_slug();


--
-- TOC entry 3493 (class 2620 OID 60489)
-- Name: seasons set_seasons_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER set_seasons_slug BEFORE INSERT ON league_management.seasons FOR EACH ROW EXECUTE FUNCTION league_management.generate_season_slug();


--
-- TOC entry 3489 (class 2620 OID 60551)
-- Name: teams set_teams_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER set_teams_slug BEFORE INSERT ON league_management.teams FOR EACH ROW EXECUTE FUNCTION league_management.generate_team_slug();


--
-- TOC entry 3496 (class 2620 OID 60531)
-- Name: divisions update_divisions_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_divisions_slug BEFORE UPDATE OF name ON league_management.divisions FOR EACH ROW EXECUTE FUNCTION league_management.generate_division_slug();


--
-- TOC entry 3498 (class 2620 OID 60665)
-- Name: games update_game_status_check; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_game_status_check BEFORE UPDATE OF status ON league_management.games FOR EACH ROW EXECUTE FUNCTION league_management.mark_game_as_published();


--
-- TOC entry 3492 (class 2620 OID 60452)
-- Name: leagues update_leagues_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_leagues_slug BEFORE UPDATE OF name ON league_management.leagues FOR EACH ROW EXECUTE FUNCTION league_management.generate_league_slug();


--
-- TOC entry 3494 (class 2620 OID 60490)
-- Name: seasons update_seasons_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_seasons_slug BEFORE UPDATE OF name ON league_management.seasons FOR EACH ROW EXECUTE FUNCTION league_management.generate_season_slug();


--
-- TOC entry 3490 (class 2620 OID 60552)
-- Name: teams update_teams_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_teams_slug BEFORE UPDATE OF name ON league_management.teams FOR EACH ROW EXECUTE FUNCTION league_management.generate_team_slug();


--
-- TOC entry 3499 (class 2620 OID 60693)
-- Name: goals goal_update_game_score; Type: TRIGGER; Schema: stats; Owner: postgres
--

CREATE TRIGGER goal_update_game_score AFTER INSERT OR DELETE ON stats.goals FOR EACH ROW EXECUTE FUNCTION league_management.update_game_score();


--
-- TOC entry 3462 (class 2606 OID 60612)
-- Name: arenas fk_arena_venue_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.arenas
    ADD CONSTRAINT fk_arena_venue_id FOREIGN KEY (venue_id) REFERENCES league_management.venues(venue_id) ON DELETE CASCADE;


--
-- TOC entry 3459 (class 2606 OID 60561)
-- Name: division_rosters fk_division_rosters_division_team_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_rosters
    ADD CONSTRAINT fk_division_rosters_division_team_id FOREIGN KEY (division_team_id) REFERENCES league_management.division_teams(division_team_id) ON DELETE CASCADE;


--
-- TOC entry 3460 (class 2606 OID 60566)
-- Name: division_rosters fk_division_rosters_user_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_rosters
    ADD CONSTRAINT fk_division_rosters_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3457 (class 2606 OID 60540)
-- Name: division_teams fk_division_teams_division_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_teams
    ADD CONSTRAINT fk_division_teams_division_id FOREIGN KEY (division_id) REFERENCES league_management.divisions(division_id) ON DELETE CASCADE;


--
-- TOC entry 3458 (class 2606 OID 60545)
-- Name: division_teams fk_division_teams_team_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_teams
    ADD CONSTRAINT fk_division_teams_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3456 (class 2606 OID 60522)
-- Name: divisions fk_divisions_season_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.divisions
    ADD CONSTRAINT fk_divisions_season_id FOREIGN KEY (season_id) REFERENCES league_management.seasons(season_id) ON DELETE CASCADE;


--
-- TOC entry 3465 (class 2606 OID 60657)
-- Name: games fk_game_arena_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games
    ADD CONSTRAINT fk_game_arena_id FOREIGN KEY (arena_id) REFERENCES league_management.arenas(arena_id);


--
-- TOC entry 3466 (class 2606 OID 60647)
-- Name: games fk_game_division_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games
    ADD CONSTRAINT fk_game_division_id FOREIGN KEY (division_id) REFERENCES league_management.divisions(division_id) ON DELETE CASCADE;


--
-- TOC entry 3467 (class 2606 OID 60652)
-- Name: games fk_game_playoff_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games
    ADD CONSTRAINT fk_game_playoff_id FOREIGN KEY (playoff_id) REFERENCES league_management.playoffs(playoff_id) ON DELETE CASCADE;


--
-- TOC entry 3451 (class 2606 OID 60461)
-- Name: league_admins fk_league_admins_league_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins
    ADD CONSTRAINT fk_league_admins_league_id FOREIGN KEY (league_id) REFERENCES league_management.leagues(league_id) ON DELETE CASCADE;


--
-- TOC entry 3452 (class 2606 OID 60466)
-- Name: league_admins fk_league_admins_user_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins
    ADD CONSTRAINT fk_league_admins_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3463 (class 2606 OID 60630)
-- Name: league_venues fk_league_venue_league_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_venues
    ADD CONSTRAINT fk_league_venue_league_id FOREIGN KEY (league_id) REFERENCES league_management.leagues(league_id) ON DELETE CASCADE;


--
-- TOC entry 3464 (class 2606 OID 60625)
-- Name: league_venues fk_league_venue_venue_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_venues
    ADD CONSTRAINT fk_league_venue_venue_id FOREIGN KEY (venue_id) REFERENCES league_management.venues(venue_id) ON DELETE CASCADE;


--
-- TOC entry 3461 (class 2606 OID 60583)
-- Name: playoffs fk_playoffs_season_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.playoffs
    ADD CONSTRAINT fk_playoffs_season_id FOREIGN KEY (season_id) REFERENCES league_management.seasons(season_id) ON DELETE CASCADE;


--
-- TOC entry 3454 (class 2606 OID 60499)
-- Name: season_admins fk_season_admins_season_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins
    ADD CONSTRAINT fk_season_admins_season_id FOREIGN KEY (season_id) REFERENCES league_management.seasons(season_id) ON DELETE CASCADE;


--
-- TOC entry 3455 (class 2606 OID 60504)
-- Name: season_admins fk_season_admins_user_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins
    ADD CONSTRAINT fk_season_admins_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3453 (class 2606 OID 60482)
-- Name: seasons fk_seasons_league_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.seasons
    ADD CONSTRAINT fk_seasons_league_id FOREIGN KEY (league_id) REFERENCES league_management.leagues(league_id) ON DELETE CASCADE;


--
-- TOC entry 3449 (class 2606 OID 60431)
-- Name: team_memberships fk_team_memberships_team_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships
    ADD CONSTRAINT fk_team_memberships_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3450 (class 2606 OID 60426)
-- Name: team_memberships fk_team_memberships_user_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships
    ADD CONSTRAINT fk_team_memberships_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3471 (class 2606 OID 60708)
-- Name: assists fk_assists_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT fk_assists_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3472 (class 2606 OID 60703)
-- Name: assists fk_assists_goal_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT fk_assists_goal_id FOREIGN KEY (goal_id) REFERENCES stats.goals(goal_id) ON DELETE CASCADE;


--
-- TOC entry 3473 (class 2606 OID 60718)
-- Name: assists fk_assists_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT fk_assists_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3474 (class 2606 OID 60713)
-- Name: assists fk_assists_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT fk_assists_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3468 (class 2606 OID 60677)
-- Name: goals fk_goals_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals
    ADD CONSTRAINT fk_goals_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3469 (class 2606 OID 60687)
-- Name: goals fk_goals_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals
    ADD CONSTRAINT fk_goals_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3470 (class 2606 OID 60682)
-- Name: goals fk_goals_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals
    ADD CONSTRAINT fk_goals_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3475 (class 2606 OID 60732)
-- Name: penalties fk_penalties_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties
    ADD CONSTRAINT fk_penalties_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3476 (class 2606 OID 60742)
-- Name: penalties fk_penalties_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties
    ADD CONSTRAINT fk_penalties_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3477 (class 2606 OID 60737)
-- Name: penalties fk_penalties_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties
    ADD CONSTRAINT fk_penalties_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3482 (class 2606 OID 60787)
-- Name: saves fk_saves_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT fk_saves_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3483 (class 2606 OID 60802)
-- Name: saves fk_saves_shot_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT fk_saves_shot_id FOREIGN KEY (shot_id) REFERENCES stats.shots(shot_id) ON DELETE CASCADE;


--
-- TOC entry 3484 (class 2606 OID 60797)
-- Name: saves fk_saves_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT fk_saves_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3485 (class 2606 OID 60792)
-- Name: saves fk_saves_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT fk_saves_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3478 (class 2606 OID 60757)
-- Name: shots fk_shots_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT fk_shots_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3479 (class 2606 OID 60772)
-- Name: shots fk_shots_goal_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT fk_shots_goal_id FOREIGN KEY (goal_id) REFERENCES stats.goals(goal_id) ON DELETE CASCADE;


--
-- TOC entry 3480 (class 2606 OID 60767)
-- Name: shots fk_shots_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT fk_shots_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3481 (class 2606 OID 60762)
-- Name: shots fk_shots_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT fk_shots_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3486 (class 2606 OID 60815)
-- Name: shutouts fk_shutouts_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts
    ADD CONSTRAINT fk_shutouts_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3487 (class 2606 OID 60825)
-- Name: shutouts fk_shutouts_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts
    ADD CONSTRAINT fk_shutouts_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3488 (class 2606 OID 60820)
-- Name: shutouts fk_shutouts_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts
    ADD CONSTRAINT fk_shutouts_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


-- Completed on 2025-02-03 13:42:42 EST

--
-- PostgreSQL database dump complete
--

