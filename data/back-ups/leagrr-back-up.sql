--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2 (Debian 17.2-1.pgdg120+1)
-- Dumped by pg_dump version 17.2

-- Started on 2025-02-14 14:28:45 EST

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
-- TOC entry 7 (class 2615 OID 77146)
-- Name: admin; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA admin;


ALTER SCHEMA admin OWNER TO postgres;

--
-- TOC entry 6 (class 2615 OID 77145)
-- Name: league_management; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA league_management;


ALTER SCHEMA league_management OWNER TO postgres;

--
-- TOC entry 8 (class 2615 OID 77147)
-- Name: stats; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA stats;


ALTER SCHEMA stats OWNER TO postgres;

--
-- TOC entry 273 (class 1255 OID 77603)
-- Name: division_join_code_cleanup(); Type: FUNCTION; Schema: league_management; Owner: postgres
--

CREATE FUNCTION league_management.division_join_code_cleanup() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    base_join_code TEXT;
    temp_join_code TEXT;
    final_join_code TEXT;
    join_code_rank INT;
    exact_match INT;
BEGIN
	IF NEW.join_code <> OLD.join_code THEN
	    -- Clean up original join_code
	    base_join_code := lower(
	                      regexp_replace(
	                          regexp_replace(
	                              regexp_replace(NEW.join_code, '\s+', '-', 'g'),
	                              '[^a-zA-Z0-9\-]', '', 'g'
	                          ),
	                      '-+', '-', 'g')
	                  );
	
	    -- Check if this join_code already exists and if so, append a number to ensure uniqueness
	
		-- this SELECT checks if there are other EXACT join_code matches
	    SELECT COUNT(*) INTO exact_match
	    FROM league_management.divisions
	    WHERE join_code = base_join_code;
	
	    IF exact_match = 0 THEN
	        -- No duplicates found, assign base join_code
	        final_join_code := base_join_code;
	    ELSE
			-- this SELECT checks if there are divisions with join_codes starting with the base_join_code
		    SELECT COUNT(*) INTO join_code_rank
		    FROM league_management.divisions
		    WHERE join_code LIKE base_join_code || '%';
			
	        -- Duplicates found, append the count as a suffix
	        temp_join_code := base_join_code || '-' || join_code_rank;
			
			-- check if exact match of temp_join_code found
			SELECT COUNT(*) INTO exact_match
		    FROM league_management.divisions
		    WHERE join_code = temp_join_code;
	
			IF exact_match = 1 THEN
				-- increase join_code_rank by 1 and create final join_code
				final_join_code := base_join_code || '-' || (join_code_rank + 1);
			ELSE
				-- change temp join_code to final join_code
				final_join_code = temp_join_code;
			END IF;
	    END IF;
	
	    -- Assign the final join_code to the new record
	    NEW.join_code := final_join_code;

	END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION league_management.division_join_code_cleanup() OWNER TO postgres;

--
-- TOC entry 278 (class 1255 OID 77297)
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
-- TOC entry 276 (class 1255 OID 77218)
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
-- TOC entry 277 (class 1255 OID 77256)
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
-- TOC entry 274 (class 1255 OID 77180)
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
-- TOC entry 275 (class 1255 OID 77183)
-- Name: join_code_cleanup(); Type: FUNCTION; Schema: league_management; Owner: postgres
--

CREATE FUNCTION league_management.join_code_cleanup() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    base_join_code TEXT;
    temp_join_code TEXT;
    final_join_code TEXT;
    join_code_rank INT;
    exact_match INT;
BEGIN
	IF NEW.join_code <> OLD.join_code THEN
    -- Clean up original join_code
    base_join_code := lower(
                      regexp_replace(
                          regexp_replace(
                              regexp_replace(NEW.join_code, '\s+', '-', 'g'),
                              '[^a-zA-Z0-9\-]', '', 'g'
                          ),
                      '-+', '-', 'g')
                  );

    -- Check if this join_code already exists and if so, append a number to ensure uniqueness

  -- this SELECT checks if there are other EXACT join_code matches
    SELECT COUNT(*) INTO exact_match
    FROM league_management.teams
    WHERE join_code = base_join_code;

    IF exact_match = 0 THEN
        -- No duplicates found, assign base join_code
        final_join_code := base_join_code;
    ELSE
    -- this SELECT checks if there are teams with join_codes starting with the base_join_code
      SELECT COUNT(*) INTO join_code_rank
      FROM league_management.teams
      WHERE join_code LIKE base_join_code || '%';
    
        -- Duplicates found, append the count as a suffix
        temp_join_code := base_join_code || '-' || join_code_rank;
    
    -- check if exact match of temp_join_code found
    SELECT COUNT(*) INTO exact_match
      FROM league_management.teams
      WHERE join_code = temp_join_code;

    IF exact_match = 1 THEN
      -- increase join_code_rank by 1 and create final join_code
      final_join_code := base_join_code || '-' || (join_code_rank + 1);
    ELSE
      -- change temp join_code to final join_code
      final_join_code = temp_join_code;
    END IF;
    END IF;

    -- Assign the final join_code to the new record
    NEW.join_code := final_join_code;

	END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION league_management.join_code_cleanup() OWNER TO postgres;

--
-- TOC entry 279 (class 1255 OID 77429)
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
-- TOC entry 280 (class 1255 OID 77458)
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
-- TOC entry 221 (class 1259 OID 77149)
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
    img character varying(100),
    password_hash character varying(100),
    status character varying(20) DEFAULT 'active'::character varying NOT NULL,
    created_on timestamp without time zone DEFAULT now(),
    CONSTRAINT user_status_enum CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying, 'suspended'::character varying, 'banned'::character varying])::text[])))
);


ALTER TABLE admin.users OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 77148)
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
-- TOC entry 3695 (class 0 OID 0)
-- Dependencies: 220
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: admin; Owner: postgres
--

ALTER SEQUENCE admin.users_user_id_seq OWNED BY admin.users.user_id;


--
-- TOC entry 245 (class 1259 OID 77369)
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
-- TOC entry 244 (class 1259 OID 77368)
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
-- TOC entry 3696 (class 0 OID 0)
-- Dependencies: 244
-- Name: arenas_arena_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.arenas_arena_id_seq OWNED BY league_management.arenas.arena_id;


--
-- TOC entry 239 (class 1259 OID 77319)
-- Name: division_rosters; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.division_rosters (
    division_roster_id integer NOT NULL,
    division_team_id integer,
    team_membership_id integer,
    "position" character varying(50),
    number integer,
    roster_role integer DEFAULT 4 NOT NULL,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.division_rosters OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 77318)
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
-- TOC entry 3697 (class 0 OID 0)
-- Dependencies: 238
-- Name: division_rosters_division_roster_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.division_rosters_division_roster_id_seq OWNED BY league_management.division_rosters.division_roster_id;


--
-- TOC entry 237 (class 1259 OID 77301)
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
-- TOC entry 236 (class 1259 OID 77300)
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
-- TOC entry 3698 (class 0 OID 0)
-- Dependencies: 236
-- Name: division_teams_division_team_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.division_teams_division_team_id_seq OWNED BY league_management.division_teams.division_team_id;


--
-- TOC entry 235 (class 1259 OID 77278)
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
-- TOC entry 234 (class 1259 OID 77277)
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
-- TOC entry 3699 (class 0 OID 0)
-- Dependencies: 234
-- Name: divisions_division_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.divisions_division_id_seq OWNED BY league_management.divisions.division_id;


--
-- TOC entry 249 (class 1259 OID 77402)
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
-- TOC entry 248 (class 1259 OID 77401)
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
-- TOC entry 3700 (class 0 OID 0)
-- Dependencies: 248
-- Name: games_game_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.games_game_id_seq OWNED BY league_management.games.game_id;


--
-- TOC entry 229 (class 1259 OID 77222)
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
-- TOC entry 228 (class 1259 OID 77221)
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
-- TOC entry 3701 (class 0 OID 0)
-- Dependencies: 228
-- Name: league_admins_league_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.league_admins_league_admin_id_seq OWNED BY league_management.league_admins.league_admin_id;


--
-- TOC entry 247 (class 1259 OID 77384)
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
-- TOC entry 246 (class 1259 OID 77383)
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
-- TOC entry 3702 (class 0 OID 0)
-- Dependencies: 246
-- Name: league_venues_league_venue_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.league_venues_league_venue_id_seq OWNED BY league_management.league_venues.league_venue_id;


--
-- TOC entry 227 (class 1259 OID 77205)
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
-- TOC entry 226 (class 1259 OID 77204)
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
-- TOC entry 3703 (class 0 OID 0)
-- Dependencies: 226
-- Name: leagues_league_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.leagues_league_id_seq OWNED BY league_management.leagues.league_id;


--
-- TOC entry 241 (class 1259 OID 77338)
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
-- TOC entry 240 (class 1259 OID 77337)
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
-- TOC entry 3704 (class 0 OID 0)
-- Dependencies: 240
-- Name: playoffs_playoff_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.playoffs_playoff_id_seq OWNED BY league_management.playoffs.playoff_id;


--
-- TOC entry 233 (class 1259 OID 77260)
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
-- TOC entry 232 (class 1259 OID 77259)
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
-- TOC entry 3705 (class 0 OID 0)
-- Dependencies: 232
-- Name: season_admins_season_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.season_admins_season_admin_id_seq OWNED BY league_management.season_admins.season_admin_id;


--
-- TOC entry 231 (class 1259 OID 77240)
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
-- TOC entry 230 (class 1259 OID 77239)
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
-- TOC entry 3706 (class 0 OID 0)
-- Dependencies: 230
-- Name: seasons_season_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.seasons_season_id_seq OWNED BY league_management.seasons.season_id;


--
-- TOC entry 225 (class 1259 OID 77186)
-- Name: team_memberships; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.team_memberships (
    team_membership_id integer NOT NULL,
    user_id integer NOT NULL,
    team_id integer NOT NULL,
    team_role integer DEFAULT 2,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.team_memberships OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 77185)
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
-- TOC entry 3707 (class 0 OID 0)
-- Dependencies: 224
-- Name: team_memberships_team_membership_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.team_memberships_team_membership_id_seq OWNED BY league_management.team_memberships.team_membership_id;


--
-- TOC entry 223 (class 1259 OID 77166)
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
-- TOC entry 222 (class 1259 OID 77165)
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
-- TOC entry 3708 (class 0 OID 0)
-- Dependencies: 222
-- Name: teams_team_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.teams_team_id_seq OWNED BY league_management.teams.team_id;


--
-- TOC entry 243 (class 1259 OID 77357)
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
-- TOC entry 242 (class 1259 OID 77356)
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
-- TOC entry 3709 (class 0 OID 0)
-- Dependencies: 242
-- Name: venues_venue_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.venues_venue_id_seq OWNED BY league_management.venues.venue_id;


--
-- TOC entry 253 (class 1259 OID 77461)
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
-- TOC entry 252 (class 1259 OID 77460)
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
-- TOC entry 3710 (class 0 OID 0)
-- Dependencies: 252
-- Name: assists_assist_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.assists_assist_id_seq OWNED BY stats.assists.assist_id;


--
-- TOC entry 251 (class 1259 OID 77433)
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
-- TOC entry 250 (class 1259 OID 77432)
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
-- TOC entry 3711 (class 0 OID 0)
-- Dependencies: 250
-- Name: goals_goal_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.goals_goal_id_seq OWNED BY stats.goals.goal_id;


--
-- TOC entry 255 (class 1259 OID 77490)
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
-- TOC entry 254 (class 1259 OID 77489)
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
-- TOC entry 3712 (class 0 OID 0)
-- Dependencies: 254
-- Name: penalties_penalty_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.penalties_penalty_id_seq OWNED BY stats.penalties.penalty_id;


--
-- TOC entry 259 (class 1259 OID 77544)
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
-- TOC entry 258 (class 1259 OID 77543)
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
-- TOC entry 3713 (class 0 OID 0)
-- Dependencies: 258
-- Name: saves_save_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.saves_save_id_seq OWNED BY stats.saves.save_id;


--
-- TOC entry 257 (class 1259 OID 77514)
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
-- TOC entry 256 (class 1259 OID 77513)
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
-- TOC entry 3714 (class 0 OID 0)
-- Dependencies: 256
-- Name: shots_shot_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.shots_shot_id_seq OWNED BY stats.shots.shot_id;


--
-- TOC entry 261 (class 1259 OID 77574)
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
-- TOC entry 260 (class 1259 OID 77573)
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
-- TOC entry 3715 (class 0 OID 0)
-- Dependencies: 260
-- Name: shutouts_shutout_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.shutouts_shutout_id_seq OWNED BY stats.shutouts.shutout_id;


--
-- TOC entry 3321 (class 2604 OID 77152)
-- Name: users user_id; Type: DEFAULT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users ALTER COLUMN user_id SET DEFAULT nextval('admin.users_user_id_seq'::regclass);


--
-- TOC entry 3358 (class 2604 OID 77372)
-- Name: arenas arena_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.arenas ALTER COLUMN arena_id SET DEFAULT nextval('league_management.arenas_arena_id_seq'::regclass);


--
-- TOC entry 3349 (class 2604 OID 77322)
-- Name: division_rosters division_roster_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_rosters ALTER COLUMN division_roster_id SET DEFAULT nextval('league_management.division_rosters_division_roster_id_seq'::regclass);


--
-- TOC entry 3347 (class 2604 OID 77304)
-- Name: division_teams division_team_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_teams ALTER COLUMN division_team_id SET DEFAULT nextval('league_management.division_teams_division_team_id_seq'::regclass);


--
-- TOC entry 3342 (class 2604 OID 77281)
-- Name: divisions division_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.divisions ALTER COLUMN division_id SET DEFAULT nextval('league_management.divisions_division_id_seq'::regclass);


--
-- TOC entry 3362 (class 2604 OID 77405)
-- Name: games game_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games ALTER COLUMN game_id SET DEFAULT nextval('league_management.games_game_id_seq'::regclass);


--
-- TOC entry 3335 (class 2604 OID 77225)
-- Name: league_admins league_admin_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins ALTER COLUMN league_admin_id SET DEFAULT nextval('league_management.league_admins_league_admin_id_seq'::regclass);


--
-- TOC entry 3360 (class 2604 OID 77387)
-- Name: league_venues league_venue_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_venues ALTER COLUMN league_venue_id SET DEFAULT nextval('league_management.league_venues_league_venue_id_seq'::regclass);


--
-- TOC entry 3332 (class 2604 OID 77208)
-- Name: leagues league_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.leagues ALTER COLUMN league_id SET DEFAULT nextval('league_management.leagues_league_id_seq'::regclass);


--
-- TOC entry 3352 (class 2604 OID 77341)
-- Name: playoffs playoff_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.playoffs ALTER COLUMN playoff_id SET DEFAULT nextval('league_management.playoffs_playoff_id_seq'::regclass);


--
-- TOC entry 3340 (class 2604 OID 77263)
-- Name: season_admins season_admin_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins ALTER COLUMN season_admin_id SET DEFAULT nextval('league_management.season_admins_season_admin_id_seq'::regclass);


--
-- TOC entry 3337 (class 2604 OID 77243)
-- Name: seasons season_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.seasons ALTER COLUMN season_id SET DEFAULT nextval('league_management.seasons_season_id_seq'::regclass);


--
-- TOC entry 3329 (class 2604 OID 77189)
-- Name: team_memberships team_membership_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships ALTER COLUMN team_membership_id SET DEFAULT nextval('league_management.team_memberships_team_membership_id_seq'::regclass);


--
-- TOC entry 3325 (class 2604 OID 77169)
-- Name: teams team_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.teams ALTER COLUMN team_id SET DEFAULT nextval('league_management.teams_team_id_seq'::regclass);


--
-- TOC entry 3356 (class 2604 OID 77360)
-- Name: venues venue_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.venues ALTER COLUMN venue_id SET DEFAULT nextval('league_management.venues_venue_id_seq'::regclass);


--
-- TOC entry 3373 (class 2604 OID 77464)
-- Name: assists assist_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists ALTER COLUMN assist_id SET DEFAULT nextval('stats.assists_assist_id_seq'::regclass);


--
-- TOC entry 3368 (class 2604 OID 77436)
-- Name: goals goal_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals ALTER COLUMN goal_id SET DEFAULT nextval('stats.goals_goal_id_seq'::regclass);


--
-- TOC entry 3376 (class 2604 OID 77493)
-- Name: penalties penalty_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties ALTER COLUMN penalty_id SET DEFAULT nextval('stats.penalties_penalty_id_seq'::regclass);


--
-- TOC entry 3383 (class 2604 OID 77547)
-- Name: saves save_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves ALTER COLUMN save_id SET DEFAULT nextval('stats.saves_save_id_seq'::regclass);


--
-- TOC entry 3379 (class 2604 OID 77517)
-- Name: shots shot_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots ALTER COLUMN shot_id SET DEFAULT nextval('stats.shots_shot_id_seq'::regclass);


--
-- TOC entry 3387 (class 2604 OID 77577)
-- Name: shutouts shutout_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts ALTER COLUMN shutout_id SET DEFAULT nextval('stats.shutouts_shutout_id_seq'::regclass);


--
-- TOC entry 3649 (class 0 OID 77149)
-- Dependencies: 221
-- Data for Name: users; Type: TABLE DATA; Schema: admin; Owner: postgres
--

INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (2, 'goose', 'hello+1@adamrobillard.ca', 'Hannah', 'Brown', 'Female', 'she/her', 3, NULL, '$2b$10$99E/cmhMolqnQFi3E6CXHOpB7zYYANgDToz1F.WkFrZMOXCFBvxji', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (3, 'caboose', 'hello+3@adamrobillard.ca', 'Aida', 'Robillard', 'Non-binary', 'any/all', 1, NULL, '$2b$10$UM16ckCNhox47R0yOq873uCUX4Pal3GEVlNY8kYszWGGM.Y3kyiZC', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (4, 'caleb', 'caleb@example.com', 'Caleb', 'Smith', 'Male', 'he/him', 2, NULL, 'heyCaleb123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (5, 'kat', 'kat@example.com', 'Kat', 'Ferguson', 'Non-binary', 'they/them', 2, NULL, 'heyKat123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (6, 'trainMale', 'trainMale@example.com', 'Stephen', 'Spence', 'Male', 'he/him', 3, NULL, 'heyStephen123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (7, 'theGoon', 'theGoon@example.com', 'Levi', 'Bradley', 'Non-binary', 'they/them', 3, NULL, 'heyLevi123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (8, 'cheryl', 'cheryl@example.com', 'Cheryl', 'Chaos', NULL, NULL, 3, NULL, 'heyCheryl123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (9, 'mason', 'mason@example.com', 'Mason', 'Nonsense', NULL, NULL, 3, NULL, 'heyMasonl123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (10, 'jayce', 'jayce@example.com', 'Jayce', 'LeClaire', 'Non-binary', 'they/them', 3, NULL, 'heyJaycel123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (11, 'britt', 'britt@example.com', 'Britt', 'Neron', 'Non-binary', 'they/them', 3, NULL, 'heyBrittl123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (12, 'tesolin', 'tesolin@example.com', 'Zachary', 'Tesolin', 'Male', 'he/him', 3, NULL, 'heyZach123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (13, 'robocop', 'robocop@example.com', 'Andrew', 'Robillard', 'Male', 'he/him', 3, NULL, 'heyAndrew123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (14, 'trex', 'trex@example.com', 'Tim', 'Robillard', 'Male', 'he/him', 3, NULL, 'heyTim123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (15, 'lukasbauer', 'lukas.bauer@example.com', 'Lukas', 'Bauer', 'Male', 'he/him', 3, NULL, 'heyLukas123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (16, 'emmaschmidt', 'emma.schmidt@example.com', 'Emma', 'Schmidt', 'Female', 'she/her', 3, NULL, 'heyEmma123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (17, 'liammüller', 'liam.mueller@example.com', 'Liam', 'Müller', 'Male', 'he/him', 3, NULL, 'heyLiam123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (18, 'hannahfischer', 'hannah.fischer@example.com', 'Hannah', 'Fischer', 'Female', 'she/her', 3, NULL, 'heyHanna123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (19, 'oliverkoch', 'oliver.koch@example.com', 'Oliver', 'Koch', 'Male', 'he/him', 3, NULL, 'heyOliver123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (20, 'clararichter', 'clara.richter@example.com', 'Clara', 'Richter', 'Female', 'she/her', 3, NULL, 'heyClara123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (21, 'noahtaylor', 'noah.taylor@example.com', 'Noah', 'Taylor', 'Male', 'he/him', 3, NULL, 'heyNoah123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (22, 'lisahoffmalen', 'lisa.hoffmalen@example.com', 'Lisa', 'Hoffmalen', 'Female', 'she/her', 3, NULL, 'heyLisa123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (23, 'matteorossetti', 'matteo.rossetti@example.com', 'Matteo', 'Rossetti', 'Male', 'he/him', 3, NULL, 'heyMatteo123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (24, 'giuliarossi', 'giulia.rossi@example.com', 'Giulia', 'Rossi', 'Female', 'she/her', 3, NULL, 'heyGiulia123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (25, 'danielebrown', 'daniele.brown@example.com', 'Daniele', 'Brown', 'Non-binary', 'they/them', 3, NULL, 'heyDaniele123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (26, 'sofialopez', 'sofia.lopez@example.com', 'Sofia', 'Lopez', 'Female', 'she/her', 3, NULL, 'heySofia123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (27, 'sebastienmartin', 'sebastien.martin@example.com', 'Sebastien', 'Martin', 'Male', 'he/him', 3, NULL, 'heySebastien123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (28, 'elisavolkova', 'elisa.volkova@example.com', 'Elisa', 'Volkova', 'Female', 'she/her', 3, NULL, 'heyElisa123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (29, 'adriangarcia', 'adrian.garcia@example.com', 'Adrian', 'Garcia', 'Male', 'he/him', 3, NULL, 'heyAdrian123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (30, 'amelialeroux', 'amelia.leroux@example.com', 'Amelia', 'LeRoux', 'Female', 'she/her', 3, NULL, 'heyAmelia123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (31, 'kasperskov', 'kasper.skov@example.com', 'Kasper', 'Skov', 'Male', 'he/him', 3, NULL, 'heyKasper123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (32, 'elinefransen', 'eline.fransen@example.com', 'Eline', 'Fransen', 'Female', 'she/her', 3, NULL, 'heyEline123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (33, 'andreakovacs', 'andrea.kovacs@example.com', 'Andrea', 'Kovacs', 'Non-binary', 'they/them', 3, NULL, 'heyAndrea123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (34, 'petersmith', 'peter.smith@example.com', 'Peter', 'Smith', 'Male', 'he/him', 3, NULL, 'heyPeter123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (35, 'janinanowak', 'janina.nowak@example.com', 'Janina', 'Nowak', 'Female', 'she/her', 3, NULL, 'heyJanina123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (36, 'niklaspetersen', 'niklas.petersen@example.com', 'Niklas', 'Petersen', 'Male', 'he/him', 3, NULL, 'heyNiklas123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (37, 'martakalinski', 'marta.kalinski@example.com', 'Marta', 'Kalinski', 'Female', 'she/her', 3, NULL, 'heyMarta123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (38, 'tomasmarquez', 'tomas.marquez@example.com', 'Tomas', 'Marquez', 'Male', 'he/him', 3, NULL, 'heyTomas123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (39, 'ireneschneider', 'irene.schneider@example.com', 'Irene', 'Schneider', 'Female', 'she/her', 3, NULL, 'heyIrene123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (40, 'maximilianbauer', 'maximilian.bauer@example.com', 'Maximilian', 'Bauer', 'Male', 'he/him', 3, NULL, 'heyMaximilian123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (41, 'annaschaefer', 'anna.schaefer@example.com', 'Anna', 'Schaefer', 'Female', 'she/her', 3, NULL, 'heyAnna123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (42, 'lucasvargas', 'lucas.vargas@example.com', 'Lucas', 'Vargas', 'Male', 'he/him', 3, NULL, 'heyLucas123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (43, 'sofiacosta', 'sofia.costa@example.com', 'Sofia', 'Costa', 'Female', 'she/her', 3, NULL, 'heySofia123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (44, 'alexanderricci', 'alexander.ricci@example.com', 'Alexander', 'Ricci', 'Male', 'he/him', 3, NULL, 'heyAlexander123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (45, 'noemiecaron', 'noemie.caron@example.com', 'Noemie', 'Caron', 'Female', 'she/her', 3, NULL, 'heyNoemie123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (46, 'pietrocapello', 'pietro.capello@example.com', 'Pietro', 'Capello', 'Male', 'he/him', 3, NULL, 'heyPietro123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (47, 'elisabethjensen', 'elisabeth.jensen@example.com', 'Elisabeth', 'Jensen', 'Female', 'she/her', 3, NULL, 'heyElisabeth123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (48, 'dimitripapadopoulos', 'dimitri.papadopoulos@example.com', 'Dimitri', 'Papadopoulos', 'Male', 'he/him', 3, NULL, 'heyDimitri123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (49, 'marielaramos', 'mariela.ramos@example.com', 'Mariela', 'Ramos', 'Female', 'she/her', 3, NULL, 'heyMariela123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (50, 'valeriekeller', 'valerie.keller@example.com', 'Valerie', 'Keller', 'Female', 'she/her', 3, NULL, 'heyValerie123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (51, 'dominikbauer', 'dominik.bauer@example.com', 'Dominik', 'Bauer', 'Male', 'he/him', 3, NULL, 'heyDominik123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (52, 'evaweber', 'eva.weber@example.com', 'Eva', 'Weber', 'Female', 'she/her', 3, NULL, 'heyEva123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (53, 'sebastiancortes', 'sebastian.cortes@example.com', 'Sebastian', 'Cortes', 'Male', 'he/him', 3, NULL, 'heySebastian123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (54, 'maleongarcia', 'maleon.garcia@example.com', 'Maleon', 'Garcia', 'Female', 'she/her', 3, NULL, 'heyMaleon123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (55, 'benjaminflores', 'benjamin.flores@example.com', 'Benjamin', 'Flores', 'Male', 'he/him', 3, NULL, 'heyBenjamin123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (1, 'moose', 'hello+2@adamrobillard.ca', 'Adam', 'Robillard', 'Non-Binary', 'any/all', 1, '/profile.jpg', '$2b$10$pr86AdfgLN.exaQBGQwpVet7lxXVH4EWhAtKwe8nBZzzmN3g7yhLW', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (56, 'saradalgaard', 'sara.dalgaard@example.com', 'Sara', 'Dalgaard', 'Female', 'she/her', 3, NULL, 'heySara123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (57, 'jonasmartinez', 'jonas.martinez@example.com', 'Jonas', 'Martinez', 'Male', 'he/him', 3, NULL, 'heyJonas123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (58, 'alessiadonati', 'alessia.donati@example.com', 'Alessia', 'Donati', 'Female', 'she/her', 3, NULL, 'heyAlessia123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (59, 'lucaskovac', 'lucas.kovac@example.com', 'Lucas', 'Kovac', 'Non-binary', 'they/them', 3, NULL, 'heyLucas123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (60, 'emiliekoch', 'emilie.koch@example.com', 'Emilie', 'Koch', 'Female', 'she/her', 3, NULL, 'heyEmilie123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (61, 'danieljones', 'daniel.jones@example.com', 'Daniel', 'Jones', 'Male', 'he/him', 3, NULL, 'heyDaniel123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (62, 'mathildevogel', 'mathilde.vogel@example.com', 'Mathilde', 'Vogel', 'Female', 'she/her', 3, NULL, 'heyMathilde123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (64, 'angelaperez', 'angela.perez@example.com', 'Angela', 'Perez', 'Female', 'she/her', 3, NULL, 'heyAngela123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (65, 'henrikstrom', 'henrik.strom@example.com', 'Henrik', 'Strom', 'Male', 'he/him', 3, NULL, 'heyHenrik123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (66, 'paulinaklein', 'paulina.klein@example.com', 'Paulina', 'Klein', 'Female', 'she/her', 3, NULL, 'heyPaulina123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (67, 'raphaelgonzalez', 'raphael.gonzalez@example.com', 'Raphael', 'Gonzalez', 'Male', 'he/him', 3, NULL, 'heyRaphael123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (68, 'annaluisachavez', 'anna-luisa.chavez@example.com', 'Anna-Luisa', 'Chavez', 'Female', 'she/her', 3, NULL, 'heyAnna-Luisa123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (69, 'fabiomercier', 'fabio.mercier@example.com', 'Fabio', 'Mercier', 'Male', 'he/him', 3, NULL, 'heyFabio123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (70, 'nataliefischer', 'natalie.fischer@example.com', 'Natalie', 'Fischer', 'Female', 'she/her', 3, NULL, 'heyNatalie123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (71, 'georgmayer', 'georg.mayer@example.com', 'Georg', 'Mayer', 'Male', 'he/him', 3, NULL, 'heyGeorg123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (72, 'julianweiss', 'julian.weiss@example.com', 'Julian', 'Weiss', 'Male', 'he/him', 3, NULL, 'heyJulian123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (73, 'katharinalopez', 'katharina.lopez@example.com', 'Katharina', 'Lopez', 'Female', 'she/her', 3, NULL, 'heyKatharina123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (74, 'simonealvarez', 'simone.alvarez@example.com', 'Simone', 'Alvarez', 'Non-binary', 'they/them', 3, NULL, 'heySimone123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (75, 'frederikschmidt', 'frederik.schmidt@example.com', 'Frederik', 'Schmidt', 'Male', 'he/him', 3, NULL, 'heyFrederik123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (76, 'mariakoval', 'maria.koval@example.com', 'Maria', 'Koval', 'Female', 'she/her', 3, NULL, 'heyMaria123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (77, 'lukemccarthy', 'luke.mccarthy@example.com', 'Luke', 'McCarthy', 'Male', 'he/him', 3, NULL, 'heyLuke123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (78, 'larissahansen', 'larissa.hansen@example.com', 'Larissa', 'Hansen', 'Female', 'she/her', 3, NULL, 'heyLarissa123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (79, 'adamwalker', 'adam.walker@example.com', 'Adam', 'Walker', 'Male', 'he/him', 3, NULL, 'heyAdam123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (80, 'paolamendes', 'paola.mendes@example.com', 'Paola', 'Mendes', 'Female', 'she/her', 3, NULL, 'heyPaola123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (81, 'ethanwilliams', 'ethan.williams@example.com', 'Ethan', 'Williams', 'Male', 'he/him', 3, NULL, 'heyEthan123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (82, 'evastark', 'eva.stark@example.com', 'Eva', 'Stark', 'Female', 'she/her', 3, NULL, 'heyEva123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (83, 'juliankovacic', 'julian.kovacic@example.com', 'Julian', 'Kovacic', 'Male', 'he/him', 3, NULL, 'heyJulian123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (84, 'ameliekrause', 'amelie.krause@example.com', 'Amelie', 'Krause', 'Female', 'she/her', 3, NULL, 'heyAmelie123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (85, 'ryanschneider', 'ryan.schneider@example.com', 'Ryan', 'Schneider', 'Male', 'he/him', 3, NULL, 'heyRyan123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (86, 'monikathomsen', 'monika.thomsen@example.com', 'Monika', 'Thomsen', 'Female', 'she/her', 3, NULL, 'heyMonika123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (87, 'daniellefoster', 'danielle.foster@example.com', 'Danielle', 'Foster', '4', 'she/her', 3, NULL, 'heyDanielle123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (88, 'harrykhan', 'harry.khan@example.com', 'Harry', 'Khan', 'Male', 'he/him', 3, NULL, 'heyHarry123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (89, 'sophielindgren', 'sophie.lindgren@example.com', 'Sophie', 'Lindgren', 'Female', 'she/her', 3, NULL, 'heySophie123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (90, 'oskarpetrov', 'oskar.petrov@example.com', 'Oskar', 'Petrov', 'Male', 'he/him', 3, NULL, 'heyOskar123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (91, 'lindavon', 'linda.von@example.com', 'Linda', 'Von', 'Female', 'she/her', 3, NULL, 'heyLinda123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (92, 'andreaspeicher', 'andreas.peicher@example.com', 'Andreas', 'Peicher', 'Male', 'he/him', 3, NULL, 'heyAndreas123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (94, 'marianapaz', 'mariana.paz@example.com', 'Mariana', 'Paz', 'Female', 'she/her', 3, NULL, 'heyMariana123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (95, 'fionaberg', 'fiona.berg@example.com', 'Fiona', 'Berg', 'Female', 'she/her', 3, NULL, 'heyFiona123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (96, 'joachimkraus', 'joachim.kraus@example.com', 'Joachim', 'Kraus', 'Male', 'he/him', 3, NULL, 'heyJoachim123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (97, 'michellebauer', 'michelle.bauer@example.com', 'Michelle', 'Bauer', 'Female', 'she/her', 3, NULL, 'heyMichelle123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (98, 'mariomatteo', 'mario.matteo@example.com', 'Mario', 'Matteo', 'Male', 'he/him', 3, NULL, 'heyMario123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (99, 'elizabethsmith', 'elizabeth.smith@example.com', 'Elizabeth', 'Smith', 'Female', 'she/her', 3, NULL, 'heyElizabeth123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (100, 'ianlennox', 'ian.lennox@example.com', 'Ian', 'Lennox', 'Male', 'he/him', 3, NULL, 'heyIan123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (101, 'evabradley', 'eva.bradley@example.com', 'Eva', 'Bradley', 'Female', 'she/her', 3, NULL, 'heyEva123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (102, 'francescoantoni', 'francesco.antoni@example.com', 'Francesco', 'Antoni', 'Male', 'he/him', 3, NULL, 'heyFrancesco123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (103, 'celinebrown', 'celine.brown@example.com', 'Celine', 'Brown', 'Female', 'she/her', 3, NULL, 'heyCeline123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (104, 'georgiamills', 'georgia.mills@example.com', 'Georgia', 'Mills', 'Female', 'she/her', 3, NULL, 'heyGeorgia123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (105, 'antoineclark', 'antoine.clark@example.com', 'Antoine', 'Clark', 'Male', 'he/him', 3, NULL, 'heyAntoine123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (106, 'valentinwebb', 'valentin.webb@example.com', 'Valentin', 'Webb', 'Male', 'he/him', 3, NULL, 'heyValentin123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (107, 'oliviamorales', 'olivia.morales@example.com', 'Olivia', 'Morales', 'Female', 'she/her', 3, NULL, 'heyOlivia123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (108, 'mathieuhebert', 'mathieu.hebert@example.com', 'Mathieu', 'Hebert', 'Male', 'he/him', 3, NULL, 'heyMathieu123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (109, 'rosepatel', 'rose.patel@example.com', 'Rose', 'Patel', 'Female', 'she/her', 3, NULL, 'heyRose123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (110, 'travisrichards', 'travis.richards@example.com', 'Travis', 'Richards', 'Male', 'he/him', 3, NULL, 'heyTravis123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (111, 'josefinklein', 'josefinklein@example.com', 'Josefin', 'Klein', 'Female', 'she/her', 3, NULL, 'heyJosefin123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (63, 'thomasleroux', 'thomas.leroux@example.com', 'Tom', 'LeRoux', 'Male', 'he/him', 3, NULL, 'heyThomas123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (112, 'finnandersen', 'finn.andersen@example.com', 'Finn', 'Andersen', 'Male', 'he/him', 3, NULL, 'heyFinn123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (113, 'sofiaparker', 'sofia.parker@example.com', 'Sofia', 'Parker', 'Female', 'she/her', 3, NULL, 'heySofia123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (114, 'theogibson', 'theo.gibson@example.com', 'Theo', 'Gibson', 'Male', 'he/him', 3, NULL, 'heyTheo123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (115, 'floose', 'floose@example.com', 'Floose', 'McGoose', '3', 'any/all', 1, NULL, '$2b$10$7pjrECYElk1ithndcAhtcuPytB2Hc8DiDi3e8gAEXYcfIjOVZdEfS', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (93, 'jjmcray', 'josephine.jung@example.com', 'Josephine', 'Jung', 'NB', 'they/theme', 3, NULL, 'heyJosephine123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (116, 'loose', 'loose@example.com', 'Loose', 'Caboose', 'NB', 'any/all', 3, NULL, '$2b$10$b5ZNgNVD19DbZ2cfneJHbeMOD//r.Eg23ovq2Odoofek8bOO5m1V2', 'active', '2025-02-11 15:44:13.703754');
INSERT INTO admin.users (user_id, username, email, first_name, last_name, gender, pronouns, user_role, img, password_hash, status, created_on) VALUES (117, 'spoose', 'spoose@example.com', 'Spoose', 'Fence', NULL, NULL, 3, NULL, '$2b$10$SEZYh44vnRhKW8vKUIgcv..0B3WRQs9xcnDPZWpA5RvoP2SYEev5a', 'active', '2025-02-12 02:14:07.46819');


--
-- TOC entry 3673 (class 0 OID 77369)
-- Dependencies: 245
-- Data for Name: arenas; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (1, 'arena', 'Arena', NULL, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (2, '1', '1', NULL, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (3, '2', '2', NULL, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (4, '3', '3', NULL, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (5, '4', '4', NULL, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (6, 'arena', 'Arena', NULL, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (7, 'a', 'A', NULL, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (8, 'b', 'B', NULL, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (9, 'a', 'A', NULL, 5, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (10, 'b', 'B', NULL, 5, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (11, 'arena', 'Arena', NULL, 6, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (12, 'a', 'A', NULL, 7, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (13, 'b', 'B', NULL, 7, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (14, 'arena', 'Arena', NULL, 8, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (15, 'a', 'A', NULL, 9, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (16, 'b', 'B', NULL, 9, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas (arena_id, slug, name, description, venue_id, created_on) VALUES (17, 'arena', 'Arena', NULL, 10, '2025-02-10 22:27:41.682766');


--
-- TOC entry 3667 (class 0 OID 77319)
-- Dependencies: 239
-- Data for Name: division_rosters; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (1, 1, 1, 'Center', 30, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (2, 1, 2, 'Defense', 25, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (3, 2, 3, 'Defense', 18, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (4, 2, 4, 'Defense', 47, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (5, 3, 5, 'Center', 12, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (6, 3, 6, 'Left Wing', 9, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (7, 4, 7, 'Right Wing', 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (8, 4, 8, 'Defense', 10, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (9, 5, 57, 'Defense', 93, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (10, 6, 58, 'Defense', 13, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (11, 7, 59, 'Defense', 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (12, 8, 60, 'Defense', 19, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (13, 9, 61, 'Left Wing', 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (14, 1, 9, 'Center', 8, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (15, 1, 10, 'Center', 9, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (16, 1, 11, 'Left Wing', 10, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (17, 1, 12, 'Left Wing', 11, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (18, 1, 13, 'Right Wing', 12, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (19, 1, 14, 'Right Wing', 13, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (20, 1, 15, 'Center', 14, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (21, 1, 16, 'Defense', 15, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (22, 1, 19, 'Defense', 18, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (23, 1, 20, 'Goalie', 33, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (24, 2, 21, 'Center', 20, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (25, 2, 22, 'Center', 21, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (26, 2, 25, 'Left Wing', 24, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (27, 2, 26, 'Right Wing', 25, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (28, 2, 27, 'Right Wing', 26, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (29, 2, 28, 'Left Wing', 27, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (30, 2, 29, 'Right Wing', 28, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (31, 2, 30, 'Defense', 29, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (32, 2, 31, 'Defense', 30, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (33, 2, 32, 'Goalie', 31, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (34, 3, 33, 'Center', 40, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (35, 3, 34, 'Center', 41, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (36, 3, 35, 'Left Wing', 42, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (37, 3, 36, 'Left Wing', 43, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (38, 3, 37, 'Right Wing', 44, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (39, 3, 39, 'Center', 46, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (40, 3, 40, 'Defense', 47, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (41, 3, 41, 'Defense', 48, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (42, 3, 42, 'Defense', 49, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (43, 3, 44, 'Goalie', 51, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (44, 4, 45, 'Center', 26, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (45, 4, 47, 'Left Wing', 28, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (46, 4, 49, 'Right Wing', 30, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (47, 4, 50, 'Right Wing', 31, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (48, 4, 51, 'Center', 32, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (49, 4, 52, 'Defense', 33, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (50, 4, 53, 'Defense', 34, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (51, 4, 54, 'Defense', 35, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (52, 4, 55, 'Defense', 36, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (53, 4, 56, 'Goalie', 3, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (54, 5, 63, NULL, 61, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (55, 5, 65, NULL, 63, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (56, 5, 66, NULL, 64, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (57, 5, 67, NULL, 65, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (58, 5, 68, NULL, 66, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (59, 5, 69, NULL, 67, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (60, 5, 70, NULL, 68, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (61, 5, 71, 'Goalie', 69, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (62, 6, 72, NULL, 70, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (63, 6, 73, NULL, 71, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (64, 6, 75, NULL, 73, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (65, 6, 76, NULL, 74, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (66, 6, 77, NULL, 75, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (67, 6, 78, NULL, 76, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (68, 6, 80, NULL, 78, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (69, 6, 81, 'Goalie', 79, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (70, 7, 82, NULL, 80, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (71, 7, 83, NULL, 81, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (72, 7, 85, NULL, 83, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (73, 7, 86, NULL, 84, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (74, 7, 88, NULL, 86, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (75, 7, 89, NULL, 87, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (76, 7, 90, NULL, 88, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (77, 7, 91, 'Goalie', 89, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (78, 8, 93, NULL, 91, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (79, 8, 94, NULL, 92, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (80, 8, 95, NULL, 93, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (81, 8, 96, NULL, 94, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (82, 8, 97, NULL, 95, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (83, 8, 98, NULL, 96, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (84, 8, 99, NULL, 97, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (85, 8, 101, 'Goalie', 1, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (86, 9, 103, NULL, 21, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (87, 9, 104, NULL, 22, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (88, 9, 105, NULL, 23, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (89, 9, 107, NULL, 25, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (90, 9, 108, NULL, 26, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (91, 9, 109, NULL, 27, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (92, 9, 110, NULL, 28, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (93, 9, 111, 'Goalie', 29, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (94, 15, 3, 'Defense', 18, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (95, 15, 4, 'Center', 47, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (96, 15, 21, 'Goalie', 20, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (97, 15, 22, 'Right Wing', 21, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (98, 15, 23, 'Center', 22, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (99, 15, 24, 'Left Wing', 23, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (100, 15, 27, 'Defense', 26, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (101, 15, 28, 'Left Wing', 27, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (102, 15, 29, 'Right Wing', 28, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (103, 15, 30, 'Defense', 29, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (104, 15, 31, 'Left Wing', 30, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (106, 37, 112, 'Center', 20, 2, '2025-02-11 21:02:16.12983');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (107, 37, 113, 'Defense', 69, 4, '2025-02-11 21:02:37.731746');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (108, 16, 115, 'Center', 13, 4, '2025-02-12 02:14:24.728494');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (109, 38, 112, 'Center', 93, 2, '2025-02-12 02:27:34.151101');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (110, 38, 113, 'Defense', 18, 4, '2025-02-12 02:27:48.986371');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (111, 13, 116, 'Center', 1, 4, '2025-02-12 02:28:30.898243');
INSERT INTO league_management.division_rosters (division_roster_id, division_team_id, team_membership_id, "position", number, roster_role, created_on) VALUES (112, 18, 114, 'Center', 1, 2, '2025-02-13 22:14:45.507515');


--
-- TOC entry 3665 (class 0 OID 77301)
-- Dependencies: 237
-- Data for Name: division_teams; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (1, 1, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (2, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (3, 1, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (4, 1, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (5, 4, 5, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (6, 4, 6, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (7, 4, 7, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (8, 4, 8, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (9, 4, 9, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (10, 11, 10, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (11, 11, 11, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (12, 11, 12, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (13, 11, 13, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (14, 11, 14, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (15, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (16, 5, 15, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (17, 5, 16, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (18, 5, 17, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (19, 5, 18, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (20, 5, 19, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (21, 5, 20, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (22, 6, 21, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (23, 6, 22, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (24, 6, 23, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (25, 6, 24, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (26, 6, 25, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (27, 6, 26, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (28, 7, 27, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (29, 7, 28, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (30, 7, 29, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (31, 7, 30, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (32, 8, 31, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (33, 8, 32, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (34, 8, 33, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (35, 8, 34, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (37, 5, 35, '2025-02-11 21:01:54.633882');
INSERT INTO league_management.division_teams (division_team_id, division_id, team_id, created_on) VALUES (38, 11, 35, '2025-02-12 02:27:11.045775');


--
-- TOC entry 3663 (class 0 OID 77278)
-- Dependencies: 235
-- Data for Name: divisions; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (1, 'div-inc', 'Div Inc', NULL, 1, 'all', 1, 'bbf07e3b-6053-49b2-86c8-fe1d7802480a', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (2, 'div-1', 'Div 1', NULL, 1, 'all', 3, 'a6b6e1b9-2655-4b00-9d3c-f3dad9b7d155', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (3, 'div-2', 'Div 2', NULL, 1, 'all', 3, 'b112efae-15c5-425b-882d-881250b8a810', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (4, 'div-1', 'Div 1', NULL, 1, 'all', 4, '6712c68b-c6ce-4d8d-addd-c9528bfa7265', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (5, 'div-2', 'Div 2', NULL, 2, 'all', 4, '07792bf2-fad1-4238-b829-2cdc2c63fafd', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (6, 'div-3', 'Div 3', NULL, 3, 'all', 4, '9c579f89-b602-4840-8431-f4a6df50f251', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (7, 'div-4', 'Div 4', NULL, 4, 'all', 4, '05e5b429-044d-4c88-afe1-2e18780b9ac9', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (8, 'div-5', 'Div 5', NULL, 5, 'all', 4, '6b838963-645a-4105-9652-20c41dad8fc1', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (9, 'men-35', 'Men 35+', NULL, 6, 'men', 4, '2da2e898-5758-4c95-b1dc-6f28c16c419c', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (10, 'women-35', 'Women 35+', NULL, 6, 'women', 4, '9b65036d-6b67-4801-afae-0a578bb93a50', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (11, 'div-1', 'Div 1', NULL, 1, 'all', 5, 'c778816a-2c26-44e6-af7a-fa68417803c7', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (12, 'div-2', 'Div 2', NULL, 2, 'all', 5, '274a3d14-57a5-4bfe-bb50-2d2439ba7752', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (13, 'div-3', 'Div 3', NULL, 3, 'all', 5, '568bb835-df39-4f77-a578-11c3a05d5347', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (14, 'div-4', 'Div 4', NULL, 4, 'all', 5, 'b87a2ac2-d13f-4af4-bd2d-9bed9601fcaa', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (15, 'div-5', 'Div 5', NULL, 5, 'all', 5, '5ebf829e-9936-4a10-9221-29322d98565e', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (16, 'div-6', 'Div 6', NULL, 6, 'all', 5, '64e2eedc-91b1-409b-9e74-617303a4947b', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (17, 'men-1', 'Men 1', NULL, 1, 'men', 5, '427ffcf6-6eaa-4c57-b191-76a1cd3921e6', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (18, 'men-2', 'Men 2', NULL, 2, 'men', 5, '11720906-0165-482a-a1bf-b5f26fb90ef2', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (19, 'men-3', 'Men 3', NULL, 3, 'men', 5, '71276567-9ef1-4e47-9fb5-55028a0eac83', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (20, 'women-1', 'Women 1', NULL, 1, 'women', 5, 'a239f17a-d4e1-4675-bb46-78ba307accee', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (21, 'women-2', 'Women 2', NULL, 2, 'women', 5, '24d85b55-317f-41e0-89dc-0cfd7d2d3243', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (22, 'women-3', 'Women 3', NULL, 3, 'women', 5, 'c187e88d-7712-4b11-9761-5f48c494d5fd', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (23, 'div-1', 'Div 1', 'For those elites!', 1, 'all', 6, 'uottawa-division-1-coed', 'draft', '2025-02-11 17:18:32.615245');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (24, 'div-2', 'Div 2', 'For those almost elites!', 2, 'all', 6, 'uottawa-division-2-coed', 'draft', '2025-02-11 17:25:08.275158');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (26, 'div-4', 'Div 4', 'Not really elites any more', 4, 'all', 6, 'uottawa-division-4-coed', 'draft', '2025-02-11 17:40:57.819025');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (25, 'div-3', 'Div 3', 'For those approaching elite!', 3, 'all', 6, 'uottawa-division-4-coed-1', 'draft', '2025-02-11 17:26:23.17534');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (27, 'div-5', 'Div 5', 'Definitely not elite', 5, 'all', 6, '', 'draft', '2025-02-11 17:42:32.669863');
INSERT INTO league_management.divisions (division_id, slug, name, description, tier, gender, season_id, join_code, status, created_on) VALUES (28, 'div-6', 'Div 6', 'Starting to get a bit sad', 6, 'all', 6, '', 'draft', '2025-02-11 17:42:58.597412');


--
-- TOC entry 3677 (class 0 OID 77402)
-- Dependencies: 249
-- Data for Name: games; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (1, 1, 3, 4, 0, 1, NULL, '2024-09-08 17:45:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (2, 2, 3, 3, 4, 1, NULL, '2024-09-08 18:45:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (3, 3, 0, 1, 2, 1, NULL, '2024-09-16 22:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (4, 4, 1, 2, 4, 1, NULL, '2024-09-16 23:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (5, 1, 4, 2, 1, 1, NULL, '2024-09-25 21:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (6, 3, 3, 4, 4, 1, NULL, '2024-09-25 22:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (7, 1, 2, 4, 2, 1, NULL, '2024-10-03 19:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (8, 2, 2, 3, 1, 1, NULL, '2024-10-03 20:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (9, 3, 3, 1, 4, 1, NULL, '2024-10-14 19:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (10, 4, 2, 2, 3, 1, NULL, '2024-10-14 20:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (11, 1, 1, 4, 2, 1, NULL, '2024-10-19 20:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (12, 2, 2, 3, 0, 1, NULL, '2024-10-19 21:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (13, 1, 2, 2, 2, 1, NULL, '2024-10-30 21:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (14, 3, 2, 4, 4, 1, NULL, '2024-10-30 22:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (15, 1, 0, 4, 2, 1, NULL, '2024-11-08 20:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (16, 2, 4, 3, 0, 1, NULL, '2024-11-08 21:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (17, 3, 3, 1, 5, 1, NULL, '2024-11-18 20:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (18, 4, 2, 2, 5, 1, NULL, '2024-11-18 21:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (19, 1, 2, 2, 3, 1, NULL, '2024-11-27 18:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (20, 3, 1, 4, 2, 1, NULL, '2024-11-27 19:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (21, 1, 1, 4, 3, 1, NULL, '2024-12-05 20:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (22, 2, 2, 3, 1, 1, NULL, '2024-12-05 21:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (23, 3, 2, 1, 0, 1, NULL, '2024-12-14 18:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (24, 4, 0, 2, 4, 1, NULL, '2024-12-14 19:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (25, 1, 1, 2, 4, 1, NULL, '2024-12-23 19:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (26, 3, 5, 4, 6, 1, NULL, '2024-12-23 20:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (27, 1, 5, 4, 3, 1, NULL, '2025-01-02 20:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (29, 4, 0, 1, 0, 1, NULL, '2025-01-11 19:45:00', 10, 'cancelled', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (30, 2, 0, 3, 0, 1, NULL, '2025-01-11 20:45:00', 10, 'cancelled', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (32, 3, 4, 4, 1, 1, NULL, '2025-01-23 20:00:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (37, 3, 0, 1, 0, 1, NULL, '2025-02-14 22:00:00', 9, 'public', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (38, 4, 0, 2, 0, 1, NULL, '2025-02-14 23:00:00', 9, 'public', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (39, 1, 0, 2, 0, 1, NULL, '2025-02-23 19:00:00', 9, 'public', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (40, 3, 0, 4, 0, 1, NULL, '2025-02-23 20:00:00', 9, 'public', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (31, 1, 1, 2, 4, 1, NULL, '2025-01-23 19:00:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (35, 1, 4, 4, 0, 1, NULL, '2025-02-05 22:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (33, 3, 0, 1, 4, 1, NULL, '2025-01-26 21:45:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (36, 2, 1, 3, 1, 1, NULL, '2025-02-05 23:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (41, 1, 0, 4, 0, 1, NULL, '2025-03-03 18:30:00', 10, 'public', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (42, 2, 0, 3, 0, 1, NULL, '2025-03-03 19:30:00', 10, 'public', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (50, 6, 1, 2, 3, 4, NULL, '2025-02-07 20:30:00', 12, 'completed', true, '2025-01-31 16:15:00.936068');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (28, 2, 7, 3, 2, 1, NULL, '2025-01-02 21:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (46, 7, 1, 8, 4, 4, NULL, '2025-01-29 21:00:00', 13, 'completed', true, '2025-01-31 12:47:08.939324');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (47, 9, 1, 5, 3, 4, NULL, '2025-01-30 20:45:00', 11, 'completed', true, '2025-01-31 13:38:51.595059');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (43, 5, 3, 6, 4, 4, NULL, '2025-01-28 21:30:00', 17, 'completed', true, '2025-01-29 18:20:39.803043');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (48, 6, 3, 8, 1, 4, NULL, '2025-01-31 22:00:00', 17, 'completed', true, '2025-01-31 14:22:31.627166');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (34, 4, 3, 2, 1, 1, NULL, '2025-01-26 22:45:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (49, 5, 1, 2, 2, 4, NULL, '2025-01-20 21:30:00', 17, 'completed', false, '2025-01-31 16:12:44.553138');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (53, 5, 0, 9, 0, 4, NULL, '2025-02-11 22:30:00', 17, 'draft', false, '2025-02-11 21:36:40.58145');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (54, 35, 3, 13, 0, 11, NULL, '2025-02-26 21:30:00', 17, 'completed', true, '2025-02-12 02:29:21.131088');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (51, 15, 4, 35, 3, 5, NULL, '2025-02-12 20:30:00', 17, 'completed', true, '2025-02-11 21:35:36.789921');
INSERT INTO league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, playoff_id, date_time, arena_id, status, has_been_published, created_on) VALUES (52, 5, 0, 6, 0, 4, NULL, '2025-02-13 20:45:00', 12, 'public', false, '2025-02-11 21:36:18.23309');


--
-- TOC entry 3657 (class 0 OID 77222)
-- Dependencies: 229
-- Data for Name: league_admins; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.league_admins (league_admin_id, league_role, league_id, user_id, created_on) VALUES (1, 1, 1, 5, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_admins (league_admin_id, league_role, league_id, user_id, created_on) VALUES (2, 1, 1, 10, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_admins (league_admin_id, league_role, league_id, user_id, created_on) VALUES (3, 1, 1, 11, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_admins (league_admin_id, league_role, league_id, user_id, created_on) VALUES (4, 1, 2, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_admins (league_admin_id, league_role, league_id, user_id, created_on) VALUES (5, 1, 3, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_admins (league_admin_id, league_role, league_id, user_id, created_on) VALUES (6, 2, 1, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_admins (league_admin_id, league_role, league_id, user_id, created_on) VALUES (7, 1, 4, 1, '2025-02-11 17:17:44.056244');


--
-- TOC entry 3675 (class 0 OID 77384)
-- Dependencies: 247
-- Data for Name: league_venues; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.league_venues (league_venue_id, venue_id, league_id, created_on) VALUES (1, 5, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_venues (league_venue_id, venue_id, league_id, created_on) VALUES (2, 7, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_venues (league_venue_id, venue_id, league_id, created_on) VALUES (3, 6, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_venues (league_venue_id, venue_id, league_id, created_on) VALUES (4, 10, 3, '2025-02-10 22:27:41.682766');


--
-- TOC entry 3655 (class 0 OID 77205)
-- Dependencies: 227
-- Data for Name: leagues; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.leagues (league_id, slug, name, description, sport, status, created_on) VALUES (1, 'ottawa-pride-hockey', 'Ottawa Pride Hockey', NULL, 'hockey', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.leagues (league_id, slug, name, description, sport, status, created_on) VALUES (2, 'fia-hockey', 'FIA Hockey', NULL, 'hockey', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.leagues (league_id, slug, name, description, sport, status, created_on) VALUES (3, 'hometown-hockey', 'Hometown Hockey', NULL, 'hockey', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.leagues (league_id, slug, name, description, sport, status, created_on) VALUES (4, 'uottawa-hockey', 'uOttawa Hockey', '', 'hockey', 'draft', '2025-02-11 17:17:44.049954');


--
-- TOC entry 3669 (class 0 OID 77338)
-- Dependencies: 241
-- Data for Name: playoffs; Type: TABLE DATA; Schema: league_management; Owner: postgres
--



--
-- TOC entry 3661 (class 0 OID 77260)
-- Dependencies: 233
-- Data for Name: season_admins; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.season_admins (season_admin_id, season_role, season_id, user_id, created_on) VALUES (1, 1, 3, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.season_admins (season_admin_id, season_role, season_id, user_id, created_on) VALUES (2, 1, 4, 3, '2025-02-10 22:27:41.682766');


--
-- TOC entry 3659 (class 0 OID 77240)
-- Dependencies: 231
-- Data for Name: seasons; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.seasons (season_id, slug, name, description, league_id, start_date, end_date, status, created_on) VALUES (1, 'winter-20242025', 'Winter 2024/2025', NULL, 1, '2024-09-01', '2025-03-31', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.seasons (season_id, slug, name, description, league_id, start_date, end_date, status, created_on) VALUES (2, '2023-2024-season', '2023-2024 Season', NULL, 2, '2023-09-01', '2024-03-31', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.seasons (season_id, slug, name, description, league_id, start_date, end_date, status, created_on) VALUES (3, '2024-2025-season', '2024-2025 Season', NULL, 2, '2024-09-01', '2025-03-31', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.seasons (season_id, slug, name, description, league_id, start_date, end_date, status, created_on) VALUES (4, '2024-2025-season', '2024-2025 Season', NULL, 3, '2024-09-01', '2025-03-31', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.seasons (season_id, slug, name, description, league_id, start_date, end_date, status, created_on) VALUES (5, '2025-spring', '2025 Spring', NULL, 3, '2025-04-01', '2025-06-30', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.seasons (season_id, slug, name, description, league_id, start_date, end_date, status, created_on) VALUES (6, '2025-spring', '2025 Spring', 'Get your Spring skate on!', 4, '2025-04-01', '2025-06-30', 'draft', '2025-02-11 17:18:23.454463');


--
-- TOC entry 3653 (class 0 OID 77186)
-- Dependencies: 225
-- Data for Name: team_memberships; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (1, 6, 1, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (2, 7, 1, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (3, 10, 2, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (4, 3, 2, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (5, 8, 3, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (6, 11, 3, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (7, 9, 4, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (8, 5, 4, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (9, 15, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (10, 16, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (11, 17, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (12, 18, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (13, 19, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (14, 20, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (15, 21, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (16, 22, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (17, 23, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (18, 24, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (19, 25, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (20, 26, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (21, 27, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (22, 28, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (23, 29, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (24, 30, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (25, 31, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (26, 32, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (27, 33, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (28, 34, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (29, 35, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (30, 36, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (31, 37, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (32, 38, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (33, 39, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (34, 40, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (35, 41, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (36, 42, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (37, 43, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (38, 44, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (39, 45, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (40, 46, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (41, 47, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (42, 48, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (43, 49, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (44, 50, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (45, 51, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (46, 52, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (47, 53, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (48, 54, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (49, 55, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (50, 56, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (51, 57, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (52, 58, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (53, 59, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (54, 60, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (55, 61, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (56, 62, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (57, 1, 5, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (58, 12, 6, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (59, 13, 7, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (60, 4, 8, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (61, 14, 9, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (62, 60, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (63, 61, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (64, 62, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (65, 63, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (66, 64, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (67, 65, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (68, 66, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (69, 67, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (70, 68, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (71, 69, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (72, 70, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (73, 71, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (74, 72, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (75, 73, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (76, 74, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (77, 75, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (78, 76, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (79, 77, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (80, 78, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (81, 79, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (82, 80, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (83, 81, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (84, 82, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (85, 83, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (86, 84, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (87, 85, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (88, 86, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (89, 87, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (90, 88, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (91, 89, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (92, 90, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (93, 91, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (94, 92, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (95, 93, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (96, 94, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (97, 95, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (98, 96, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (99, 97, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (100, 98, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (101, 99, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (102, 100, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (103, 101, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (104, 102, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (105, 103, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (106, 104, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (107, 105, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (108, 106, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (109, 107, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (110, 108, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (111, 109, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (112, 1, 35, 1, '2025-02-11 17:14:31.681891');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (113, 116, 35, 2, '2025-02-11 21:02:37.728242');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (115, 117, 15, 1, '2025-02-12 02:14:24.724896');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (116, 117, 13, 2, '2025-02-12 02:28:30.89557');
INSERT INTO league_management.team_memberships (team_membership_id, user_id, team_id, team_role, created_on) VALUES (114, 1, 17, 1, '2025-02-11 21:30:45.188603');


--
-- TOC entry 3651 (class 0 OID 77166)
-- Dependencies: 223
-- Data for Name: teams; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (1, 'significant-otters', 'Significant Otters', NULL, '#942f2f', '42773d4b-a0db-45a5-b6e7-4ed0352a3a32', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (2, 'otterwa-senators', 'Otterwa Senators', NULL, '#8d45a3', '3a84f69c-abf2-4a93-85ee-94687ad0c1f3', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (3, 'otter-chaos', 'Otter Chaos', NULL, '#2f945b', '6e1bec03-dc19-45cc-949d-9510b0132208', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (4, 'otter-nonsense', 'Otter Nonsense', NULL, '#2f3794', '55020d20-4bb8-4b07-a0f5-314431e1013f', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (5, 'frostbiters', 'Frostbiters', 'An icy team known for their chilling defense.', 'green', '40b541f0-6692-4c33-be1e-91fd2d0cd6d1', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (6, 'blazing-blizzards', 'Blazing Blizzards', 'A team that combines fiery offense with frosty precision.', 'purple', 'bfb64227-22c0-4a8f-9a40-7351dad6c63a', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (7, 'polar-puckers', 'Polar Puckers', 'Masters of the north, specializing in swift plays.', '#285fa2', '4a8f8471-9d19-4c48-bc56-022f9f0594f1', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (8, 'arctic-avengers', 'Arctic Avengers', 'A cold-blooded team with a knack for thrilling comebacks.', 'yellow', '72b0b271-3e6c-476b-8de4-7980577f9d72', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (9, 'glacial-guardians', 'Glacial Guardians', 'Defensive titans who freeze their opponents in their tracks.', 'pink', 'ab1c8fb0-8fe6-4c1b-ad44-6a0294e2068d', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (10, 'tundra-titans', 'Tundra Titans', 'A powerhouse team dominating the ice with strength and speed.', 'orange', '10a02058-bc90-4f5e-a8bb-58935074119d', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (11, 'permafrost-predators', 'Permafrost Predators', 'Known for their unrelenting pressure and icy precision.', '#bc83d4', 'a35d0e62-6e45-4cbf-9131-6b8bef866a65', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (12, 'snowstorm-scorchers', 'Snowstorm Scorchers', 'A team with a fiery spirit and unstoppable energy.', 'rebeccapurple', '2711261e-bf6f-4743-883f-583df10a8633', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (13, 'frozen-flames', 'Frozen Flames', 'Bringing the heat to the ice with blazing fast attacks.', 'cyan', 'ce6ee21f-dd90-4496-b0cf-5ad2feb01008', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (14, 'chill-crushers', 'Chill Crushers', 'Breaking the ice with powerful plays and intense rivalries.', 'lime', 'd980236e-931e-41db-a7e6-2303fc03c2b0', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (15, 'shadow-panthers', 'Shadow Panthers', 'A fierce team known for their unpredictable playstyle.', '#222222', 'b6c202f3-bd0a-4412-8f36-2ba04a0b09a5', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (16, 'crimson-vipers', 'Crimson Vipers', 'Fast and aggressive with deadly precision.', '#B22222', '59611bcf-40a1-47b3-a2b0-3abaa0642c14', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (18, 'thunder-hawks', 'Thunder Hawks', 'A high-energy team that dominates the rink.', '#8B0000', 'ed487c64-f246-483e-bdd3-37a45c7daff1', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (19, 'emerald-guardians', 'Emerald Guardians', 'A defensive powerhouse with an unbreakable strategy.', '#228B22', '45c16776-2b6f-4799-9118-6443fd091ef6', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (20, 'steel-titans', 'Steel Titans', 'Strong, resilient, and impossible to shake.', '#708090', 'd6bf0119-8553-4174-b919-1f2f5963021f', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (21, 'phoenix-fire', 'Phoenix Fire', 'Rises to the occasion in clutch moments.', '#FF4500', '520e9bfb-0dc4-437e-9d18-ba0c8362bab6', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (22, 'iron-wolves', 'Iron Wolves', 'A relentless team that never backs down.', '#2F4F4F', '33a6c42e-a819-4196-bdf9-1dbf05973f1f', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (23, 'midnight-reapers', 'Midnight Reapers', 'Lethal in the final minutes of every game.', '#4B0082', '147ac64b-e0b6-489f-9cc3-44f8a2177ebe', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (24, 'neon-strikers', 'Neon Strikers', 'A high-scoring team with flashy plays.', '#00FF7F', '21634835-c743-4df8-8be8-7cc7df8cf5fe', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (25, 'scarlet-blades', 'Scarlet Blades', 'Masters of precision passing and quick attacks.', '#DC143C', '2598f426-f3a9-491c-b897-3b9ae351404a', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (26, 'cobalt-chargers', 'Cobalt Chargers', 'Unstoppable speed and offensive firepower.', '#4169E1', '55b2026a-b69d-4dda-a508-d0fcc54c3ba2', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (27, 'onyx-predators', 'Onyx Predators', 'A physically dominant team that wears down opponents.', '#000000', '1b943fc9-f5fc-4c66-a5df-7547edb073f9', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (28, 'amber-raptors', 'Amber Raptors', 'Fast and unpredictable, known for creative plays.', '#FF8C00', 'b1cdaad7-b17a-4a07-9adf-5cbf3ea58292', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (29, 'silver-foxes', 'Silver Foxes', 'A veteran team with discipline and experience.', '#C0C0C0', 'cb65e419-d79a-4dbf-b89a-eb45b3db0e95', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (30, 'voltage-kings', 'Voltage Kings', 'Electrifying speed and a lightning-fast transition game.', '#FFFF00', '0ecb2e43-bf74-4fb1-b1f2-0aba58a83e33', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (31, 'obsidian-warriors', 'Obsidian Warriors', 'A tough and resilient team that grinds out wins.', '#1C1C1C', 'fa9df39d-3912-4d77-9672-af586571c4f5', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (32, 'titanium-blizzards', 'Titanium Blizzards', 'A well-balanced team with elite skill.', '#D3D3D3', '1ea4d2de-9727-4a0d-bb29-66c5047ed5ce', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (33, 'ruby-thunder', 'Ruby Thunder', 'A powerhouse with a thunderous offensive presence.', '#8B0000', 'a3cbfc64-6dee-49d0-a524-30df8303e540', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (34, 'sapphire-storm', 'Sapphire Storm', 'A dynamic team known for their speed and agility.', '#0000FF', '20e8872f-ed17-4429-ab07-1eaff7b99946', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (35, 'metcalfe-jets', 'Metcalfe Jets', 'A small town team.', '#3bb55f', '68004b56-9db1-475b-8e4a-2234daad0d71', 'active', '2025-02-11 17:14:31.669097');
INSERT INTO league_management.teams (team_id, slug, name, description, color, join_code, status, created_on) VALUES (17, 'golden-stingers', 'Golden Stingers', 'Masters of quick strikes and counterattacks.', '#FFD700', '532c12c8-74dd-4305-a597-2f6b0a670478', 'active', '2025-02-10 22:27:41.682766');


--
-- TOC entry 3671 (class 0 OID 77357)
-- Dependencies: 243
-- Data for Name: venues; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.venues (venue_id, slug, name, description, address, created_on) VALUES (1, 'canadian-tire-centre', 'Canadian Tire Centre', 'Home of the NHL''s Ottawa Senators, this state-of-the-art entertainment facility seats 19,153 spectators.', '1000 Palladium Dr, Ottawa, ON K2V 1A5', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues (venue_id, slug, name, description, address, created_on) VALUES (2, 'bell-sensplex', 'Bell Sensplex', 'A multi-purpose sports facility featuring four NHL-sized ice rinks, including an Olympic-sized rink, operated by Capital Sports Management.', '1565 Maple Grove Rd, Ottawa, ON K2V 1A3', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues (venue_id, slug, name, description, address, created_on) VALUES (3, 'td-place-arena', 'TD Place Arena', 'An indoor arena located at Lansdowne Park, hosting the Ottawa 67''s (OHL) and Ottawa Blackjacks (CEBL), with a seating capacity of up to 8,585.', '1015 Bank St, Ottawa, ON K1S 3W7', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues (venue_id, slug, name, description, address, created_on) VALUES (4, 'minto-sports-complex-arena', 'Minto Sports Complex Arena', 'Part of the University of Ottawa, this complex contains two ice rinks, one with seating for 840 spectators, and the Draft Pub overlooking the ice.', '801 King Edward Ave, Ottawa, ON K1N 6N5', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues (venue_id, slug, name, description, address, created_on) VALUES (5, 'carleton-university-ice-house', 'Carleton University Ice House', 'A leading indoor skating facility featuring two NHL-sized ice surfaces, home to the Carleton Ravens hockey teams.', '1125 Colonel By Dr, Ottawa, ON K1S 5B6', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues (venue_id, slug, name, description, address, created_on) VALUES (6, 'howard-darwin-centennial-arena', 'Howard Darwin Centennial Arena', 'A community arena offering ice rentals and public skating programs, maleaged by the City of Ottawa.', '1765 Merivale Rd, Ottawa, ON K2G 1E1', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues (venue_id, slug, name, description, address, created_on) VALUES (7, 'fred-barrett-arena', 'Fred Barrett Arena', 'A municipal arena providing ice rentals and public skating, located in the southern part of Ottawa.', '3280 Leitrim Rd, Ottawa, ON K1T 3Z4', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues (venue_id, slug, name, description, address, created_on) VALUES (8, 'blackburn-arena', 'Blackburn Arena', 'A community arena offering skating programs and ice rentals, serving the Blackburn Hamlet area.', '200 Glen Park Dr, Gloucester, ON K1B 5A3', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues (venue_id, slug, name, description, address, created_on) VALUES (9, 'bob-macquarrie-recreation-complex-orlans-arena', 'Bob MacQuarrie Recreation Complex – Orléans Arena', 'A recreation complex featuring an arena, pool, and fitness facilities, serving the Orléans community.', '1490 Youville Dr, Orléans, ON K1C 2X8', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues (venue_id, slug, name, description, address, created_on) VALUES (10, 'brewer-arena', 'Brewer Arena', 'A municipal arena adjacent to Brewer Park, offering public skating and ice rentals.', '200 Hopewell Ave, Ottawa, ON K1S 2Z5', '2025-02-10 22:27:41.682766');


--
-- TOC entry 3681 (class 0 OID 77461)
-- Dependencies: 253
-- Data for Name: assists; Type: TABLE DATA; Schema: stats; Owner: postgres
--

INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (1, 1, 31, 33, 2, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (2, 1, 31, 32, 2, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (3, 2, 31, 3, 2, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (4, 3, 31, 16, 1, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (5, 4, 31, 32, 2, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (28, 31, 33, 7, 1, true, '2025-01-28 22:12:20.844298');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (29, 32, 33, 22, 1, true, '2025-01-28 22:22:01.452293');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (30, 34, 33, 6, 1, true, '2025-01-28 22:26:59.666412');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (33, 37, 33, 25, 1, true, '2025-01-28 22:28:27.851364');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (46, 55, 43, 61, 5, true, '2025-01-29 18:21:40.518237');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (49, 57, 28, 10, 2, true, '2025-01-29 21:14:24.144683');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (50, 59, 28, 43, 3, true, '2025-01-29 21:15:04.368026');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (51, 60, 28, 35, 2, true, '2025-01-29 21:15:30.875789');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (52, 61, 28, 3, 2, true, '2025-01-29 21:15:51.821809');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (53, 62, 28, 43, 3, true, '2025-01-29 21:16:33.021139');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (54, 63, 28, 37, 2, true, '2025-01-29 21:16:54.814861');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (55, 64, 28, 34, 2, true, '2025-01-29 21:17:20.730325');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (56, 65, 28, 34, 2, true, '2025-01-29 21:18:11.706933');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (57, 66, 34, 3, 2, true, '2025-01-30 19:29:25.064095');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (59, 70, 46, 93, 8, true, '2025-01-31 12:48:22.160339');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (60, 70, 46, 92, 8, false, '2025-01-31 12:48:22.163271');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (61, 71, 46, 89, 7, true, '2025-01-31 12:48:49.323484');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (62, 71, 46, 86, 7, false, '2025-01-31 12:48:49.325205');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (63, 72, 46, 95, 8, true, '2025-01-31 12:49:13.948142');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (64, 72, 46, 99, 8, false, '2025-01-31 12:49:13.950133');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (65, 73, 46, 4, 8, true, '2025-01-31 12:49:39.543621');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (66, 74, 46, 96, 8, true, '2025-01-31 12:49:58.808175');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (67, 74, 46, 92, 8, false, '2025-01-31 12:49:58.810277');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (68, 75, 47, 67, 5, true, '2025-01-31 13:49:17.011754');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (69, 75, 47, 63, 5, false, '2025-01-31 13:49:17.014353');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (70, 76, 47, 69, 5, true, '2025-01-31 13:50:09.753327');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (71, 76, 47, 64, 5, false, '2025-01-31 13:50:09.754901');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (72, 77, 47, 103, 9, true, '2025-01-31 14:04:31.832027');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (73, 78, 47, 1, 5, true, '2025-01-31 14:04:53.658749');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (74, 79, 43, 70, 6, true, '2025-01-31 14:06:18.158741');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (75, 80, 43, 78, 6, true, '2025-01-31 14:09:45.231942');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (76, 80, 43, 79, 6, false, '2025-01-31 14:09:45.234272');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (78, 82, 43, 65, 5, true, '2025-01-31 14:11:04.929727');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (79, 83, 43, 12, 6, true, '2025-01-31 14:14:42.809173');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (80, 84, 48, 93, 8, true, '2025-01-31 14:22:50.338125');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (81, 85, 48, 75, 6, true, '2025-01-31 14:23:05.01828');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (82, 86, 48, 78, 6, true, '2025-01-31 14:23:28.611552');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (83, 87, 48, 70, 6, true, '2025-01-31 14:24:19.144736');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (84, 87, 48, 71, 6, false, '2025-01-31 14:24:19.146655');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (85, 88, 34, 5, 4, true, '2025-01-31 14:51:01.646627');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (86, 89, 34, 57, 4, true, '2025-01-31 14:51:58.871587');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (87, 92, 49, 37, 2, true, '2025-01-31 16:13:08.180217');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (88, 94, 49, 37, 2, true, '2025-01-31 16:14:16.682627');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (89, 95, 50, 37, 2, true, '2025-02-11 16:18:42.893918');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (90, 98, 36, 45, 3, true, '2025-02-11 17:16:39.326494');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (91, 101, 51, 1, 35, true, '2025-02-12 02:15:18.804293');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (92, 103, 54, 1, 35, true, '2025-02-12 02:33:55.52354');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (94, 111, 50, 33, 2, true, '2025-02-14 18:05:10.928176');
INSERT INTO stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) VALUES (95, 111, 50, 30, 2, false, '2025-02-14 18:05:10.929672');


--
-- TOC entry 3679 (class 0 OID 77433)
-- Dependencies: 251
-- Data for Name: goals; Type: TABLE DATA; Schema: stats; Owner: postgres
--

INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (1, 31, 3, 2, 1, '00:11:20', false, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (2, 31, 10, 2, 1, '00:15:37', false, true, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (3, 31, 6, 1, 2, '00:05:40', false, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (4, 31, 3, 2, 2, '00:18:10', false, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (5, 31, 28, 2, 3, '00:18:20', false, false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (31, 33, 6, 1, 2, '00:03:32', false, false, false, '2025-01-28 22:12:20.836554');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (32, 33, 7, 1, 2, '00:06:55', false, true, false, '2025-01-28 22:22:01.446369');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (34, 33, 20, 1, 3, '00:16:51', false, false, false, '2025-01-28 22:26:59.659856');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (37, 33, 6, 1, 3, '00:19:28', false, false, true, '2025-01-28 22:28:27.845173');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (53, 43, 1, 5, 1, '00:02:14', false, false, false, '2025-01-29 18:21:12.871841');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (54, 43, 73, 6, 1, '00:04:15', false, false, false, '2025-01-29 18:21:28.21693');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (55, 43, 1, 5, 2, '00:04:16', false, false, false, '2025-01-29 18:21:40.511549');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (57, 28, 3, 2, 1, '00:02:00', false, false, false, '2025-01-29 21:14:24.138571');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (58, 28, 27, 2, 1, '00:06:07', false, false, false, '2025-01-29 21:14:43.596312');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (59, 28, 50, 3, 1, '00:10:19', false, false, false, '2025-01-29 21:15:04.362646');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (60, 28, 3, 2, 1, '00:16:24', false, false, false, '2025-01-29 21:15:30.869789');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (61, 28, 10, 2, 2, '00:06:10', false, false, false, '2025-01-29 21:15:51.815019');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (62, 28, 11, 3, 2, '00:10:23', false, true, false, '2025-01-29 21:16:33.015637');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (63, 28, 3, 2, 3, '00:05:24', false, false, false, '2025-01-29 21:16:54.809394');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (64, 28, 32, 2, 3, '00:12:56', false, false, false, '2025-01-29 21:17:20.723557');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (65, 28, 10, 2, 3, '00:17:17', false, false, false, '2025-01-29 21:18:11.700948');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (66, 34, 10, 2, 3, '00:19:50', false, false, false, '2025-01-30 19:29:25.056506');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (70, 46, 94, 8, 1, '00:03:12', false, false, false, '2025-01-31 12:48:22.153813');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (71, 46, 13, 7, 1, '00:03:13', false, false, false, '2025-01-31 12:48:49.317687');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (72, 46, 4, 8, 1, '00:07:19', false, false, false, '2025-01-31 12:49:13.94251');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (73, 46, 93, 8, 2, '00:11:20', false, false, false, '2025-01-31 12:49:39.53854');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (74, 46, 4, 8, 3, '00:16:21', false, false, false, '2025-01-31 12:49:58.803182');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (75, 47, 1, 5, 1, '00:09:00', false, false, false, '2025-01-31 13:49:17.005933');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (76, 47, 1, 5, 1, '00:13:17', false, true, false, '2025-01-31 13:50:09.7489');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (77, 47, 14, 9, 2, '00:08:13', false, false, false, '2025-01-31 14:04:31.827789');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (78, 47, 68, 5, 3, '00:18:56', false, false, true, '2025-01-31 14:04:53.654327');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (79, 43, 12, 6, 2, '00:10:24', false, false, false, '2025-01-31 14:06:18.15422');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (80, 43, 12, 6, 3, '00:14:25', false, false, false, '2025-01-31 14:09:45.226699');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (82, 43, 63, 5, 3, '00:19:23', false, false, false, '2025-01-31 14:11:04.925064');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (83, 43, 74, 6, 3, '00:19:44', false, false, false, '2025-01-31 14:14:42.804546');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (84, 48, 4, 8, 1, '00:10:00', false, false, false, '2025-01-31 14:22:50.332613');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (85, 48, 12, 6, 1, '00:15:00', false, false, false, '2025-01-31 14:23:05.013364');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (86, 48, 12, 6, 2, '00:07:00', false, false, false, '2025-01-31 14:23:28.606041');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (87, 48, 12, 6, 3, '00:13:06', false, false, false, '2025-01-31 14:24:19.139733');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (88, 34, 9, 4, 1, '00:19:51', false, false, false, '2025-01-31 14:51:01.641769');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (89, 34, 5, 4, 2, '00:06:38', false, true, false, '2025-01-31 14:51:58.867463');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (90, 34, 5, 4, 3, '00:07:37', false, false, false, '2025-01-31 14:52:32.568702');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (92, 49, 10, 2, 1, '00:15:00', false, false, false, '2025-01-31 16:13:08.17596');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (93, 49, 63, 5, 2, '00:07:18', false, false, false, '2025-01-31 16:13:22.432711');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (94, 49, 3, 2, 3, '00:08:21', false, false, false, '2025-01-31 16:14:16.677822');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (95, 50, 30, 2, 1, '00:10:00', false, false, false, '2025-02-11 16:18:42.886551');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (96, 50, 29, 2, 1, '00:14:00', false, true, false, '2025-02-11 16:19:12.338693');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (97, 50, 12, 6, 3, '00:16:00', false, false, false, '2025-02-11 16:19:41.199947');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (98, 36, 47, 3, 1, '00:04:07', false, false, false, '2025-02-11 17:16:39.320918');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (99, 36, 36, 2, 1, '00:07:08', false, false, false, '2025-02-11 17:16:50.020966');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (100, 51, 1, 35, 1, '00:04:01', false, false, false, '2025-02-12 02:15:08.255402');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (101, 51, 116, 35, 3, '00:07:02', false, false, false, '2025-02-12 02:15:18.800357');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (102, 51, 1, 35, 3, '00:12:04', false, false, false, '2025-02-12 02:15:47.557999');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (103, 54, 116, 35, 1, '00:04:00', false, false, false, '2025-02-12 02:33:55.5194');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (104, 54, 1, 35, 1, '00:09:00', false, false, false, '2025-02-12 02:35:28.7082');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (105, 54, 116, 35, 3, '00:14:00', false, false, false, '2025-02-12 02:35:49.655329');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (106, 51, 117, 15, 3, '00:06:05', false, false, false, '2025-02-13 14:10:31.699027');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (107, 51, 117, 15, 2, '00:11:05', false, false, false, '2025-02-13 14:10:48.515808');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (108, 51, 117, 15, 1, '00:15:05', false, false, false, '2025-02-13 14:11:04.032675');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (109, 51, 117, 15, 3, '00:16:05', false, false, false, '2025-02-13 14:11:21.474113');
INSERT INTO stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) VALUES (111, 50, 37, 2, 3, '00:07:00', false, false, false, '2025-02-14 18:05:10.923627');


--
-- TOC entry 3683 (class 0 OID 77490)
-- Dependencies: 255
-- Data for Name: penalties; Type: TABLE DATA; Schema: stats; Owner: postgres
--

INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (1, 31, 7, 1, 1, '00:15:02', 'Tripping', 2, '2025-01-28 15:35:00.023976');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (2, 31, 32, 2, 2, '00:08:22', 'Hooking', 2, '2025-01-28 15:35:00.023976');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (3, 31, 32, 2, 3, '00:11:31', 'Interference', 2, '2025-01-28 15:35:00.023976');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (7, 33, 15, 1, 1, '00:12:25', 'Tripping', 2, '2025-01-28 22:11:31.236037');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (8, 33, 47, 3, 2, '00:05:48', 'Too Maley Players', 2, '2025-01-28 22:21:39.139248');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (9, 33, 19, 1, 3, '00:12:42', 'Hooking', 2, '2025-01-28 22:22:38.701351');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (11, 34, 10, 2, 2, '00:05:50', 'Holding', 2, '2025-01-29 17:32:25.075633');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (12, 34, 32, 2, 3, '00:06:55', 'Hitting from behind', 5, '2025-01-29 19:37:54.835293');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (13, 28, 27, 2, 2, '00:09:18', 'Roughing', 2, '2025-01-29 21:16:15.507966');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (14, 50, 12, 6, 1, '00:13:00', 'Tripping', 2, '2025-02-11 16:18:59.776395');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (15, 36, 8, 3, 1, '00:09:12', 'Hooking', 2, '2025-02-11 17:17:07.882261');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (16, 51, 1, 35, 2, '00:12:05', 'Hooking', 2, '2025-02-12 02:16:00.63894');


--
-- TOC entry 3687 (class 0 OID 77544)
-- Dependencies: 259
-- Data for Name: saves; Type: TABLE DATA; Schema: stats; Owner: postgres
--

INSERT INTO stats.saves (save_id, game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound, created_on) VALUES (1, 31, 26, 1, 1, 1, '00:05:15', false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves (save_id, game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound, created_on) VALUES (2, 31, 38, 2, 2, 1, '00:07:35', false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves (save_id, game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound, created_on) VALUES (3, 31, 26, 1, 3, 1, '00:09:05', false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves (save_id, game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound, created_on) VALUES (4, 31, 38, 2, 4, 1, '00:10:03', false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves (save_id, game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound, created_on) VALUES (5, 31, 26, 1, 7, 1, '00:17:43', false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves (save_id, game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound, created_on) VALUES (6, 31, 26, 1, 8, 2, '00:01:11', false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves (save_id, game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound, created_on) VALUES (7, 31, 38, 2, 10, 2, '00:07:15', false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves (save_id, game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound, created_on) VALUES (8, 31, 26, 1, 11, 2, '00:11:15', false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves (save_id, game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound, created_on) VALUES (9, 31, 26, 1, 13, 3, '00:07:12', false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves (save_id, game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound, created_on) VALUES (10, 31, 38, 2, 14, 3, '00:11:56', true, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves (save_id, game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound, created_on) VALUES (11, 31, 26, 1, 15, 3, '00:15:15', false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.saves (save_id, game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound, created_on) VALUES (28, 33, 50, 3, 60, 1, '00:07:02', false, false, '2025-01-28 22:10:08.823041');
INSERT INTO stats.saves (save_id, game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound, created_on) VALUES (29, 33, 26, 1, 63, 2, '00:05:47', false, false, '2025-01-28 22:21:11.455121');
INSERT INTO stats.saves (save_id, game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound, created_on) VALUES (34, 34, 38, 2, 81, 1, '00:15:18', false, false, '2025-01-29 17:30:20.974172');
INSERT INTO stats.saves (save_id, game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound, created_on) VALUES (39, 49, 38, 2, 138, 2, '00:15:20', false, false, '2025-01-31 16:13:46.285032');
INSERT INTO stats.saves (save_id, game_id, user_id, team_id, shot_id, period, period_time, penalty_kill, rebound, created_on) VALUES (40, 50, 79, 6, 140, 1, '00:05:00', false, false, '2025-02-11 16:18:29.395591');


--
-- TOC entry 3685 (class 0 OID 77514)
-- Dependencies: 257
-- Data for Name: shots; Type: TABLE DATA; Schema: stats; Owner: postgres
--

INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (1, 31, 3, 2, 1, '00:05:15', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (2, 31, 6, 1, 1, '00:07:35', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (3, 31, 31, 2, 1, '00:09:05', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (4, 31, 18, 1, 1, '00:10:03', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (5, 31, 3, 2, 1, '00:11:20', 1, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (6, 31, 10, 2, 1, '00:15:37', 2, false, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (7, 31, 3, 2, 1, '00:17:43', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (8, 31, 10, 2, 2, '00:01:11', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (9, 31, 6, 1, 2, '00:05:40', 3, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (10, 31, 21, 1, 2, '00:07:15', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (11, 31, 34, 2, 2, '00:11:15', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (12, 31, 3, 2, 2, '00:18:10', 4, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (13, 31, 27, 2, 3, '00:07:12', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (14, 31, 22, 1, 3, '00:11:56', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (15, 31, 36, 2, 3, '00:15:15', NULL, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (16, 31, 28, 2, 3, '00:18:20', 5, false, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (60, 33, 26, 1, 1, '00:07:02', NULL, false, false, '2025-01-28 22:10:08.819217');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (62, 33, 6, 1, 2, '00:03:32', 31, false, false, '2025-01-28 22:12:20.846527');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (63, 33, 8, 3, 2, '00:05:47', NULL, false, false, '2025-01-28 22:21:11.452163');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (64, 33, 7, 1, 2, '00:06:55', 32, false, true, '2025-01-28 22:22:01.455122');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (66, 33, 20, 1, 3, '00:16:51', 34, false, false, '2025-01-28 22:26:59.668639');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (69, 33, 6, 1, 3, '00:19:28', 37, false, false, '2025-01-28 22:28:27.853387');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (81, 34, 51, 4, 1, '00:15:18', NULL, false, false, '2025-01-29 17:30:20.970281');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (91, 43, 1, 5, 1, '00:02:14', 53, false, false, '2025-01-29 18:21:12.878535');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (92, 43, 73, 6, 1, '00:04:15', 54, false, false, '2025-01-29 18:21:28.221923');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (93, 43, 1, 5, 2, '00:04:16', 55, false, false, '2025-01-29 18:21:40.520499');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (95, 28, 3, 2, 1, '00:02:00', 57, false, false, '2025-01-29 21:14:24.146839');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (96, 28, 27, 2, 1, '00:06:07', 58, false, false, '2025-01-29 21:14:43.602289');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (97, 28, 50, 3, 1, '00:10:19', 59, false, false, '2025-01-29 21:15:04.370381');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (98, 28, 3, 2, 1, '00:16:24', 60, false, false, '2025-01-29 21:15:30.877857');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (99, 28, 10, 2, 2, '00:06:10', 61, false, false, '2025-01-29 21:15:51.825065');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (100, 28, 11, 3, 2, '00:10:23', 62, false, true, '2025-01-29 21:16:33.02304');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (101, 28, 3, 2, 3, '00:05:24', 63, false, false, '2025-01-29 21:16:54.817298');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (102, 28, 30, 2, 3, '00:12:56', 64, false, false, '2025-01-29 21:17:20.732602');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (103, 28, 10, 2, 3, '00:17:17', 65, false, false, '2025-01-29 21:18:11.70895');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (104, 34, 10, 2, 3, '00:19:50', 66, false, false, '2025-01-30 19:29:25.066441');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (109, 46, 94, 8, 1, '00:03:12', 70, false, false, '2025-01-31 12:48:22.164783');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (110, 46, 13, 7, 1, '00:03:13', 71, false, false, '2025-01-31 12:48:49.32671');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (111, 46, 4, 8, 1, '00:07:19', 72, false, false, '2025-01-31 12:49:13.951748');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (112, 46, 93, 8, 2, '00:11:20', 73, false, false, '2025-01-31 12:49:39.545655');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (113, 46, 4, 8, 3, '00:16:21', 74, false, false, '2025-01-31 12:49:58.812247');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (114, 47, 1, 5, 1, '00:09:00', 75, false, false, '2025-01-31 13:49:17.016808');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (115, 47, 1, 5, 1, '00:13:17', 76, false, true, '2025-01-31 13:50:09.756151');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (117, 47, 14, 9, 2, '00:03:11', NULL, false, false, '2025-01-31 13:51:29.431308');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (118, 47, 66, 5, 2, '00:05:12', NULL, false, false, '2025-01-31 14:03:58.495521');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (119, 47, 14, 9, 2, '00:08:13', 77, false, false, '2025-01-31 14:04:31.83424');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (120, 47, 68, 5, 3, '00:18:56', 78, false, false, '2025-01-31 14:04:53.660301');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (121, 43, 12, 6, 2, '00:10:24', 79, false, false, '2025-01-31 14:06:18.160428');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (122, 43, 12, 6, 3, '00:14:25', 80, false, false, '2025-01-31 14:09:45.235912');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (124, 43, 63, 5, 3, '00:19:23', 82, false, false, '2025-01-31 14:11:04.931927');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (125, 43, 74, 6, 3, '00:19:44', 83, false, false, '2025-01-31 14:14:42.811083');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (126, 48, 4, 8, 1, '00:10:00', 84, false, false, '2025-01-31 14:22:50.340325');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (127, 48, 12, 6, 1, '00:15:00', 85, false, false, '2025-01-31 14:23:05.020307');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (128, 48, 12, 6, 2, '00:07:00', 86, false, false, '2025-01-31 14:23:28.613506');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (130, 48, 12, 6, 3, '00:13:06', 87, false, false, '2025-01-31 14:24:19.14811');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (131, 34, 9, 4, 1, '00:19:51', 88, false, false, '2025-01-31 14:51:01.648853');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (132, 34, 5, 4, 2, '00:06:38', 89, false, true, '2025-01-31 14:51:58.873246');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (133, 34, 5, 4, 3, '00:07:37', 90, false, false, '2025-01-31 14:52:32.574245');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (135, 49, 10, 2, 1, '00:15:00', 92, false, false, '2025-01-31 16:13:08.181947');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (136, 49, 63, 5, 2, '00:07:18', 93, false, false, '2025-01-31 16:13:22.437177');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (137, 49, 3, 2, 2, '00:11:19', NULL, false, false, '2025-01-31 16:13:31.262792');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (138, 49, 1, 5, 2, '00:15:20', NULL, false, false, '2025-01-31 16:13:46.281404');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (139, 49, 3, 2, 3, '00:08:21', 94, false, false, '2025-01-31 16:14:16.68463');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (140, 50, 3, 2, 1, '00:05:00', NULL, false, false, '2025-02-11 16:18:29.391681');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (141, 50, 30, 2, 1, '00:10:00', 95, false, false, '2025-02-11 16:18:42.896329');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (142, 50, 29, 2, 1, '00:14:00', 96, false, true, '2025-02-11 16:19:12.343197');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (143, 50, 12, 6, 3, '00:16:00', 97, false, false, '2025-02-11 16:19:41.204413');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (144, 36, 47, 3, 1, '00:04:07', 98, false, false, '2025-02-11 17:16:39.328626');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (145, 36, 36, 2, 1, '00:07:08', 99, false, false, '2025-02-11 17:16:50.025299');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (146, 51, 1, 35, 1, '00:04:01', 100, false, false, '2025-02-12 02:15:08.26085');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (147, 51, 116, 35, 3, '00:07:02', 101, false, false, '2025-02-12 02:15:18.805778');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (148, 51, 1, 35, 3, '00:10:03', NULL, false, false, '2025-02-12 02:15:34.454305');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (149, 51, 1, 35, 3, '00:12:04', 102, false, false, '2025-02-12 02:15:47.561952');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (150, 54, 116, 35, 1, '00:04:00', 103, false, false, '2025-02-12 02:33:55.525163');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (151, 54, 1, 35, 1, '00:09:00', 104, false, false, '2025-02-12 02:35:28.714908');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (152, 54, 116, 35, 3, '00:14:00', 105, false, false, '2025-02-12 02:35:49.65978');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (153, 51, 117, 15, 3, '00:06:05', 106, false, false, '2025-02-13 14:10:31.712666');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (154, 51, 117, 15, 2, '00:11:05', 107, false, false, '2025-02-13 14:10:48.519702');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (155, 51, 117, 15, 1, '00:15:05', 108, false, false, '2025-02-13 14:11:04.037873');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (156, 51, 117, 15, 3, '00:16:05', 109, false, false, '2025-02-13 14:11:21.477969');
INSERT INTO stats.shots (shot_id, game_id, user_id, team_id, period, period_time, goal_id, shorthanded, power_play, created_on) VALUES (158, 50, 37, 2, 3, '00:07:00', 111, false, false, '2025-02-14 18:05:10.930747');


--
-- TOC entry 3689 (class 0 OID 77574)
-- Dependencies: 261
-- Data for Name: shutouts; Type: TABLE DATA; Schema: stats; Owner: postgres
--



--
-- TOC entry 3716 (class 0 OID 0)
-- Dependencies: 220
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: admin; Owner: postgres
--

SELECT pg_catalog.setval('admin.users_user_id_seq', 117, true);


--
-- TOC entry 3717 (class 0 OID 0)
-- Dependencies: 244
-- Name: arenas_arena_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.arenas_arena_id_seq', 17, true);


--
-- TOC entry 3718 (class 0 OID 0)
-- Dependencies: 238
-- Name: division_rosters_division_roster_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.division_rosters_division_roster_id_seq', 112, true);


--
-- TOC entry 3719 (class 0 OID 0)
-- Dependencies: 236
-- Name: division_teams_division_team_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.division_teams_division_team_id_seq', 38, true);


--
-- TOC entry 3720 (class 0 OID 0)
-- Dependencies: 234
-- Name: divisions_division_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.divisions_division_id_seq', 28, true);


--
-- TOC entry 3721 (class 0 OID 0)
-- Dependencies: 248
-- Name: games_game_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.games_game_id_seq', 54, true);


--
-- TOC entry 3722 (class 0 OID 0)
-- Dependencies: 228
-- Name: league_admins_league_admin_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.league_admins_league_admin_id_seq', 7, true);


--
-- TOC entry 3723 (class 0 OID 0)
-- Dependencies: 246
-- Name: league_venues_league_venue_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.league_venues_league_venue_id_seq', 4, true);


--
-- TOC entry 3724 (class 0 OID 0)
-- Dependencies: 226
-- Name: leagues_league_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.leagues_league_id_seq', 4, true);


--
-- TOC entry 3725 (class 0 OID 0)
-- Dependencies: 240
-- Name: playoffs_playoff_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.playoffs_playoff_id_seq', 1, false);


--
-- TOC entry 3726 (class 0 OID 0)
-- Dependencies: 232
-- Name: season_admins_season_admin_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.season_admins_season_admin_id_seq', 2, true);


--
-- TOC entry 3727 (class 0 OID 0)
-- Dependencies: 230
-- Name: seasons_season_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.seasons_season_id_seq', 6, true);


--
-- TOC entry 3728 (class 0 OID 0)
-- Dependencies: 224
-- Name: team_memberships_team_membership_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.team_memberships_team_membership_id_seq', 116, true);


--
-- TOC entry 3729 (class 0 OID 0)
-- Dependencies: 222
-- Name: teams_team_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.teams_team_id_seq', 35, true);


--
-- TOC entry 3730 (class 0 OID 0)
-- Dependencies: 242
-- Name: venues_venue_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.venues_venue_id_seq', 10, true);


--
-- TOC entry 3731 (class 0 OID 0)
-- Dependencies: 252
-- Name: assists_assist_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.assists_assist_id_seq', 95, true);


--
-- TOC entry 3732 (class 0 OID 0)
-- Dependencies: 250
-- Name: goals_goal_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.goals_goal_id_seq', 111, true);


--
-- TOC entry 3733 (class 0 OID 0)
-- Dependencies: 254
-- Name: penalties_penalty_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.penalties_penalty_id_seq', 16, true);


--
-- TOC entry 3734 (class 0 OID 0)
-- Dependencies: 258
-- Name: saves_save_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.saves_save_id_seq', 40, true);


--
-- TOC entry 3735 (class 0 OID 0)
-- Dependencies: 256
-- Name: shots_shot_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.shots_shot_id_seq', 158, true);


--
-- TOC entry 3736 (class 0 OID 0)
-- Dependencies: 260
-- Name: shutouts_shutout_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.shutouts_shutout_id_seq', 1, false);


--
-- TOC entry 3399 (class 2606 OID 77163)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3401 (class 2606 OID 77159)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 3403 (class 2606 OID 77161)
-- Name: users users_username_key; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 3433 (class 2606 OID 77377)
-- Name: arenas arenas_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.arenas
    ADD CONSTRAINT arenas_pkey PRIMARY KEY (arena_id);


--
-- TOC entry 3425 (class 2606 OID 77326)
-- Name: division_rosters division_rosters_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_rosters
    ADD CONSTRAINT division_rosters_pkey PRIMARY KEY (division_roster_id);


--
-- TOC entry 3423 (class 2606 OID 77307)
-- Name: division_teams division_teams_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_teams
    ADD CONSTRAINT division_teams_pkey PRIMARY KEY (division_team_id);


--
-- TOC entry 3421 (class 2606 OID 77289)
-- Name: divisions divisions_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.divisions
    ADD CONSTRAINT divisions_pkey PRIMARY KEY (division_id);


--
-- TOC entry 3437 (class 2606 OID 77412)
-- Name: games games_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games
    ADD CONSTRAINT games_pkey PRIMARY KEY (game_id);


--
-- TOC entry 3415 (class 2606 OID 77228)
-- Name: league_admins league_admins_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins
    ADD CONSTRAINT league_admins_pkey PRIMARY KEY (league_admin_id);


--
-- TOC entry 3435 (class 2606 OID 77390)
-- Name: league_venues league_venues_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_venues
    ADD CONSTRAINT league_venues_pkey PRIMARY KEY (league_venue_id);


--
-- TOC entry 3411 (class 2606 OID 77214)
-- Name: leagues leagues_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.leagues
    ADD CONSTRAINT leagues_pkey PRIMARY KEY (league_id);


--
-- TOC entry 3413 (class 2606 OID 77216)
-- Name: leagues leagues_slug_key; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.leagues
    ADD CONSTRAINT leagues_slug_key UNIQUE (slug);


--
-- TOC entry 3427 (class 2606 OID 77348)
-- Name: playoffs playoffs_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.playoffs
    ADD CONSTRAINT playoffs_pkey PRIMARY KEY (playoff_id);


--
-- TOC entry 3419 (class 2606 OID 77266)
-- Name: season_admins season_admins_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins
    ADD CONSTRAINT season_admins_pkey PRIMARY KEY (season_admin_id);


--
-- TOC entry 3417 (class 2606 OID 77249)
-- Name: seasons seasons_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.seasons
    ADD CONSTRAINT seasons_pkey PRIMARY KEY (season_id);


--
-- TOC entry 3409 (class 2606 OID 77193)
-- Name: team_memberships team_memberships_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships
    ADD CONSTRAINT team_memberships_pkey PRIMARY KEY (team_membership_id);


--
-- TOC entry 3405 (class 2606 OID 77176)
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (team_id);


--
-- TOC entry 3407 (class 2606 OID 77178)
-- Name: teams teams_slug_key; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.teams
    ADD CONSTRAINT teams_slug_key UNIQUE (slug);


--
-- TOC entry 3429 (class 2606 OID 77365)
-- Name: venues venues_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.venues
    ADD CONSTRAINT venues_pkey PRIMARY KEY (venue_id);


--
-- TOC entry 3431 (class 2606 OID 77367)
-- Name: venues venues_slug_key; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.venues
    ADD CONSTRAINT venues_slug_key UNIQUE (slug);


--
-- TOC entry 3441 (class 2606 OID 77468)
-- Name: assists assists_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT assists_pkey PRIMARY KEY (assist_id);


--
-- TOC entry 3439 (class 2606 OID 77442)
-- Name: goals goals_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals
    ADD CONSTRAINT goals_pkey PRIMARY KEY (goal_id);


--
-- TOC entry 3443 (class 2606 OID 77497)
-- Name: penalties penalties_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties
    ADD CONSTRAINT penalties_pkey PRIMARY KEY (penalty_id);


--
-- TOC entry 3447 (class 2606 OID 77552)
-- Name: saves saves_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT saves_pkey PRIMARY KEY (save_id);


--
-- TOC entry 3445 (class 2606 OID 77522)
-- Name: shots shots_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT shots_pkey PRIMARY KEY (shot_id);


--
-- TOC entry 3449 (class 2606 OID 77580)
-- Name: shutouts shutouts_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts
    ADD CONSTRAINT shutouts_pkey PRIMARY KEY (shutout_id);


--
-- TOC entry 3500 (class 2620 OID 77430)
-- Name: games insert_game_status_check; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER insert_game_status_check BEFORE INSERT ON league_management.games FOR EACH ROW EXECUTE FUNCTION league_management.mark_game_as_published();


--
-- TOC entry 3497 (class 2620 OID 77298)
-- Name: divisions set_divisions_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER set_divisions_slug BEFORE INSERT ON league_management.divisions FOR EACH ROW EXECUTE FUNCTION league_management.generate_division_slug();


--
-- TOC entry 3493 (class 2620 OID 77219)
-- Name: leagues set_leagues_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER set_leagues_slug BEFORE INSERT ON league_management.leagues FOR EACH ROW EXECUTE FUNCTION league_management.generate_league_slug();


--
-- TOC entry 3495 (class 2620 OID 77257)
-- Name: seasons set_seasons_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER set_seasons_slug BEFORE INSERT ON league_management.seasons FOR EACH ROW EXECUTE FUNCTION league_management.generate_season_slug();


--
-- TOC entry 3490 (class 2620 OID 77181)
-- Name: teams set_teams_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER set_teams_slug BEFORE INSERT ON league_management.teams FOR EACH ROW EXECUTE FUNCTION league_management.generate_team_slug();


--
-- TOC entry 3498 (class 2620 OID 77604)
-- Name: divisions update_divisions_join_code; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_divisions_join_code BEFORE UPDATE OF join_code ON league_management.divisions FOR EACH ROW EXECUTE FUNCTION league_management.division_join_code_cleanup();


--
-- TOC entry 3499 (class 2620 OID 77299)
-- Name: divisions update_divisions_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_divisions_slug BEFORE UPDATE OF name ON league_management.divisions FOR EACH ROW EXECUTE FUNCTION league_management.generate_division_slug();


--
-- TOC entry 3501 (class 2620 OID 77431)
-- Name: games update_game_status_check; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_game_status_check BEFORE UPDATE OF status ON league_management.games FOR EACH ROW EXECUTE FUNCTION league_management.mark_game_as_published();


--
-- TOC entry 3494 (class 2620 OID 77220)
-- Name: leagues update_leagues_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_leagues_slug BEFORE UPDATE OF name ON league_management.leagues FOR EACH ROW EXECUTE FUNCTION league_management.generate_league_slug();


--
-- TOC entry 3496 (class 2620 OID 77258)
-- Name: seasons update_seasons_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_seasons_slug BEFORE UPDATE OF name ON league_management.seasons FOR EACH ROW EXECUTE FUNCTION league_management.generate_season_slug();


--
-- TOC entry 3491 (class 2620 OID 77184)
-- Name: teams update_teams_join_code; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_teams_join_code BEFORE UPDATE OF join_code ON league_management.teams FOR EACH ROW EXECUTE FUNCTION league_management.join_code_cleanup();


--
-- TOC entry 3492 (class 2620 OID 77182)
-- Name: teams update_teams_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_teams_slug BEFORE UPDATE OF name ON league_management.teams FOR EACH ROW EXECUTE FUNCTION league_management.generate_team_slug();


--
-- TOC entry 3502 (class 2620 OID 77459)
-- Name: goals goal_update_game_score; Type: TRIGGER; Schema: stats; Owner: postgres
--

CREATE TRIGGER goal_update_game_score AFTER INSERT OR DELETE ON stats.goals FOR EACH ROW EXECUTE FUNCTION league_management.update_game_score();


--
-- TOC entry 3463 (class 2606 OID 77378)
-- Name: arenas fk_arena_venue_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.arenas
    ADD CONSTRAINT fk_arena_venue_id FOREIGN KEY (venue_id) REFERENCES league_management.venues(venue_id) ON DELETE CASCADE;


--
-- TOC entry 3460 (class 2606 OID 77327)
-- Name: division_rosters fk_division_rosters_division_team_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_rosters
    ADD CONSTRAINT fk_division_rosters_division_team_id FOREIGN KEY (division_team_id) REFERENCES league_management.division_teams(division_team_id) ON DELETE CASCADE;


--
-- TOC entry 3461 (class 2606 OID 77332)
-- Name: division_rosters fk_division_rosters_team_membership_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_rosters
    ADD CONSTRAINT fk_division_rosters_team_membership_id FOREIGN KEY (team_membership_id) REFERENCES league_management.team_memberships(team_membership_id) ON DELETE CASCADE;


--
-- TOC entry 3458 (class 2606 OID 77308)
-- Name: division_teams fk_division_teams_division_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_teams
    ADD CONSTRAINT fk_division_teams_division_id FOREIGN KEY (division_id) REFERENCES league_management.divisions(division_id) ON DELETE CASCADE;


--
-- TOC entry 3459 (class 2606 OID 77313)
-- Name: division_teams fk_division_teams_team_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_teams
    ADD CONSTRAINT fk_division_teams_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3457 (class 2606 OID 77290)
-- Name: divisions fk_divisions_season_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.divisions
    ADD CONSTRAINT fk_divisions_season_id FOREIGN KEY (season_id) REFERENCES league_management.seasons(season_id) ON DELETE CASCADE;


--
-- TOC entry 3466 (class 2606 OID 77423)
-- Name: games fk_game_arena_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games
    ADD CONSTRAINT fk_game_arena_id FOREIGN KEY (arena_id) REFERENCES league_management.arenas(arena_id);


--
-- TOC entry 3467 (class 2606 OID 77413)
-- Name: games fk_game_division_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games
    ADD CONSTRAINT fk_game_division_id FOREIGN KEY (division_id) REFERENCES league_management.divisions(division_id) ON DELETE CASCADE;


--
-- TOC entry 3468 (class 2606 OID 77418)
-- Name: games fk_game_playoff_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games
    ADD CONSTRAINT fk_game_playoff_id FOREIGN KEY (playoff_id) REFERENCES league_management.playoffs(playoff_id) ON DELETE CASCADE;


--
-- TOC entry 3452 (class 2606 OID 77229)
-- Name: league_admins fk_league_admins_league_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins
    ADD CONSTRAINT fk_league_admins_league_id FOREIGN KEY (league_id) REFERENCES league_management.leagues(league_id) ON DELETE CASCADE;


--
-- TOC entry 3453 (class 2606 OID 77234)
-- Name: league_admins fk_league_admins_user_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins
    ADD CONSTRAINT fk_league_admins_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3464 (class 2606 OID 77396)
-- Name: league_venues fk_league_venue_league_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_venues
    ADD CONSTRAINT fk_league_venue_league_id FOREIGN KEY (league_id) REFERENCES league_management.leagues(league_id) ON DELETE CASCADE;


--
-- TOC entry 3465 (class 2606 OID 77391)
-- Name: league_venues fk_league_venue_venue_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_venues
    ADD CONSTRAINT fk_league_venue_venue_id FOREIGN KEY (venue_id) REFERENCES league_management.venues(venue_id) ON DELETE CASCADE;


--
-- TOC entry 3462 (class 2606 OID 77349)
-- Name: playoffs fk_playoffs_season_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.playoffs
    ADD CONSTRAINT fk_playoffs_season_id FOREIGN KEY (season_id) REFERENCES league_management.seasons(season_id) ON DELETE CASCADE;


--
-- TOC entry 3455 (class 2606 OID 77267)
-- Name: season_admins fk_season_admins_season_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins
    ADD CONSTRAINT fk_season_admins_season_id FOREIGN KEY (season_id) REFERENCES league_management.seasons(season_id) ON DELETE CASCADE;


--
-- TOC entry 3456 (class 2606 OID 77272)
-- Name: season_admins fk_season_admins_user_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins
    ADD CONSTRAINT fk_season_admins_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3454 (class 2606 OID 77250)
-- Name: seasons fk_seasons_league_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.seasons
    ADD CONSTRAINT fk_seasons_league_id FOREIGN KEY (league_id) REFERENCES league_management.leagues(league_id) ON DELETE CASCADE;


--
-- TOC entry 3450 (class 2606 OID 77199)
-- Name: team_memberships fk_team_memberships_team_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships
    ADD CONSTRAINT fk_team_memberships_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3451 (class 2606 OID 77194)
-- Name: team_memberships fk_team_memberships_user_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships
    ADD CONSTRAINT fk_team_memberships_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3472 (class 2606 OID 77474)
-- Name: assists fk_assists_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT fk_assists_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3473 (class 2606 OID 77469)
-- Name: assists fk_assists_goal_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT fk_assists_goal_id FOREIGN KEY (goal_id) REFERENCES stats.goals(goal_id) ON DELETE CASCADE;


--
-- TOC entry 3474 (class 2606 OID 77484)
-- Name: assists fk_assists_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT fk_assists_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3475 (class 2606 OID 77479)
-- Name: assists fk_assists_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT fk_assists_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3469 (class 2606 OID 77443)
-- Name: goals fk_goals_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals
    ADD CONSTRAINT fk_goals_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3470 (class 2606 OID 77453)
-- Name: goals fk_goals_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals
    ADD CONSTRAINT fk_goals_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3471 (class 2606 OID 77448)
-- Name: goals fk_goals_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals
    ADD CONSTRAINT fk_goals_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3476 (class 2606 OID 77498)
-- Name: penalties fk_penalties_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties
    ADD CONSTRAINT fk_penalties_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3477 (class 2606 OID 77508)
-- Name: penalties fk_penalties_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties
    ADD CONSTRAINT fk_penalties_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3478 (class 2606 OID 77503)
-- Name: penalties fk_penalties_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties
    ADD CONSTRAINT fk_penalties_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3483 (class 2606 OID 77553)
-- Name: saves fk_saves_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT fk_saves_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3484 (class 2606 OID 77568)
-- Name: saves fk_saves_shot_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT fk_saves_shot_id FOREIGN KEY (shot_id) REFERENCES stats.shots(shot_id) ON DELETE CASCADE;


--
-- TOC entry 3485 (class 2606 OID 77563)
-- Name: saves fk_saves_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT fk_saves_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3486 (class 2606 OID 77558)
-- Name: saves fk_saves_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT fk_saves_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3479 (class 2606 OID 77523)
-- Name: shots fk_shots_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT fk_shots_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3480 (class 2606 OID 77538)
-- Name: shots fk_shots_goal_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT fk_shots_goal_id FOREIGN KEY (goal_id) REFERENCES stats.goals(goal_id) ON DELETE CASCADE;


--
-- TOC entry 3481 (class 2606 OID 77533)
-- Name: shots fk_shots_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT fk_shots_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3482 (class 2606 OID 77528)
-- Name: shots fk_shots_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT fk_shots_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3487 (class 2606 OID 77581)
-- Name: shutouts fk_shutouts_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts
    ADD CONSTRAINT fk_shutouts_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3488 (class 2606 OID 77591)
-- Name: shutouts fk_shutouts_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts
    ADD CONSTRAINT fk_shutouts_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3489 (class 2606 OID 77586)
-- Name: shutouts fk_shutouts_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts
    ADD CONSTRAINT fk_shutouts_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


-- Completed on 2025-02-14 14:28:45 EST

--
-- PostgreSQL database dump complete
--

