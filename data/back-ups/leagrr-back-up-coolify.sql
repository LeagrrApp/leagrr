--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2 (Debian 17.2-1.pgdg120+1)
-- Dumped by pg_dump version 17.2

-- Started on 2025-04-03 14:51:52 EDT

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 77608)
-- Name: admin; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA admin;


ALTER SCHEMA admin OWNER TO postgres;

--
-- TOC entry 7 (class 2615 OID 77609)
-- Name: league_management; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA league_management;


ALTER SCHEMA league_management OWNER TO postgres;

--
-- TOC entry 8 (class 2615 OID 77610)
-- Name: stats; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA stats;


ALTER SCHEMA stats OWNER TO postgres;

--
-- TOC entry 266 (class 1255 OID 78078)
-- Name: auto_publish_league(); Type: FUNCTION; Schema: league_management; Owner: postgres
--

CREATE FUNCTION league_management.auto_publish_league() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF
		NEW.status <> OLD.status AND NEW.status = 'public'
	THEN

	    UPDATE league_management.leagues
		SET
			status = NEW.status
		WHERE
			league_id = NEW.league_id;
	
	END IF;
	
	RETURN NEW;
END;
$$;


ALTER FUNCTION league_management.auto_publish_league() OWNER TO postgres;

--
-- TOC entry 265 (class 1255 OID 78076)
-- Name: auto_publish_season(); Type: FUNCTION; Schema: league_management; Owner: postgres
--

CREATE FUNCTION league_management.auto_publish_season() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF
		NEW.status <> OLD.status AND NEW.status = 'public'
	THEN

		-- update all seasons with a league_id that matches changed league
	    UPDATE league_management.seasons
		SET
			status = NEW.status
		WHERE
			season_id = NEW.season_id;
	
	END IF;
	
	RETURN NEW;
END;
$$;


ALTER FUNCTION league_management.auto_publish_season() OWNER TO postgres;

--
-- TOC entry 263 (class 1255 OID 78072)
-- Name: auto_update_division_status(); Type: FUNCTION; Schema: league_management; Owner: postgres
--

CREATE FUNCTION league_management.auto_update_division_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF
		NEW.status <> OLD.status AND NEW.status != 'public'
	THEN

		-- update all divisions with a season_id that matches changed season
	    UPDATE league_management.divisions
		SET
			status = NEW.status
		WHERE
			season_id = NEW.season_id;
	
	END IF;
	
	RETURN NEW;
END;
$$;


ALTER FUNCTION league_management.auto_update_division_status() OWNER TO postgres;

--
-- TOC entry 264 (class 1255 OID 78074)
-- Name: auto_update_season_status(); Type: FUNCTION; Schema: league_management; Owner: postgres
--

CREATE FUNCTION league_management.auto_update_season_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF
		NEW.status <> OLD.status AND NEW.status != 'public'
	THEN

		-- update all seasons with a league_id that matches changed league
	    UPDATE league_management.seasons
		SET
			status = NEW.status
		WHERE
			league_id = NEW.league_id;
	
	END IF;
	
	RETURN NEW;
END;
$$;


ALTER FUNCTION league_management.auto_update_season_status() OWNER TO postgres;

--
-- TOC entry 262 (class 1255 OID 77611)
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
-- TOC entry 278 (class 1255 OID 77612)
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
-- TOC entry 279 (class 1255 OID 77613)
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
-- TOC entry 280 (class 1255 OID 77614)
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
-- TOC entry 281 (class 1255 OID 77615)
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
-- TOC entry 285 (class 1255 OID 78062)
-- Name: generate_venue_slug(); Type: FUNCTION; Schema: league_management; Owner: postgres
--

CREATE FUNCTION league_management.generate_venue_slug() RETURNS trigger
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
	    FROM league_management.venues
	    WHERE slug = base_slug;
	
	    IF exact_match = 0 THEN
	        -- No duplicates found, assign base slug
	        final_slug := base_slug;
	    ELSE
	    -- this SELECT checks if there are venues with slugs starting with the base_slug
	      SELECT COUNT(*) INTO slug_rank
	      FROM league_management.venues
	      WHERE slug LIKE base_slug || '%';
	    
	        -- Duplicates found, append the count as a suffix
	        temp_slug := base_slug || '-' || slug_rank;
	    
		    -- check if exact match of temp_slug found
		    SELECT COUNT(*) INTO exact_match
		      FROM league_management.venues
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


ALTER FUNCTION league_management.generate_venue_slug() OWNER TO postgres;

--
-- TOC entry 282 (class 1255 OID 77616)
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
-- TOC entry 283 (class 1255 OID 77617)
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
-- TOC entry 284 (class 1255 OID 77618)
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
-- TOC entry 220 (class 1259 OID 77619)
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
    CONSTRAINT user_status_enum CHECK (((status)::text = ANY (ARRAY[('active'::character varying)::text, ('inactive'::character varying)::text, ('suspended'::character varying)::text, ('banned'::character varying)::text])))
);


ALTER TABLE admin.users OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 77628)
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
-- TOC entry 3706 (class 0 OID 0)
-- Dependencies: 221
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: admin; Owner: postgres
--

ALTER SEQUENCE admin.users_user_id_seq OWNED BY admin.users.user_id;


--
-- TOC entry 222 (class 1259 OID 77629)
-- Name: arenas; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.arenas (
    arena_id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    venue_id integer NOT NULL,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.arenas OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 77635)
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
-- TOC entry 3707 (class 0 OID 0)
-- Dependencies: 223
-- Name: arenas_arena_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.arenas_arena_id_seq OWNED BY league_management.arenas.arena_id;


--
-- TOC entry 224 (class 1259 OID 77636)
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
-- TOC entry 225 (class 1259 OID 77641)
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
-- TOC entry 3708 (class 0 OID 0)
-- Dependencies: 225
-- Name: division_rosters_division_roster_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.division_rosters_division_roster_id_seq OWNED BY league_management.division_rosters.division_roster_id;


--
-- TOC entry 226 (class 1259 OID 77642)
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
-- TOC entry 227 (class 1259 OID 77646)
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
-- TOC entry 3709 (class 0 OID 0)
-- Dependencies: 227
-- Name: division_teams_division_team_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.division_teams_division_team_id_seq OWNED BY league_management.division_teams.division_team_id;


--
-- TOC entry 228 (class 1259 OID 77647)
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
    CONSTRAINT division_gender_enum CHECK (((gender)::text = ANY (ARRAY[('all'::character varying)::text, ('men'::character varying)::text, ('women'::character varying)::text]))),
    CONSTRAINT division_status_enum CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'public'::character varying, 'archived'::character varying, 'locked'::character varying])::text[])))
);


ALTER TABLE league_management.divisions OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 77658)
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
-- TOC entry 3710 (class 0 OID 0)
-- Dependencies: 229
-- Name: divisions_division_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.divisions_division_id_seq OWNED BY league_management.divisions.division_id;


--
-- TOC entry 230 (class 1259 OID 77659)
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
    CONSTRAINT game_status_enum CHECK (((status)::text = ANY (ARRAY[('draft'::character varying)::text, ('public'::character varying)::text, ('completed'::character varying)::text, ('cancelled'::character varying)::text, ('postponed'::character varying)::text, ('archived'::character varying)::text])))
);


ALTER TABLE league_management.games OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 77668)
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
-- TOC entry 3711 (class 0 OID 0)
-- Dependencies: 231
-- Name: games_game_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.games_game_id_seq OWNED BY league_management.games.game_id;


--
-- TOC entry 232 (class 1259 OID 77669)
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
-- TOC entry 233 (class 1259 OID 77673)
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
-- TOC entry 3712 (class 0 OID 0)
-- Dependencies: 233
-- Name: league_admins_league_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.league_admins_league_admin_id_seq OWNED BY league_management.league_admins.league_admin_id;


--
-- TOC entry 234 (class 1259 OID 77674)
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
-- TOC entry 235 (class 1259 OID 77678)
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
-- TOC entry 3713 (class 0 OID 0)
-- Dependencies: 235
-- Name: league_venues_league_venue_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.league_venues_league_venue_id_seq OWNED BY league_management.league_venues.league_venue_id;


--
-- TOC entry 236 (class 1259 OID 77679)
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
    CONSTRAINT league_status_enum CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'public'::character varying, 'archived'::character varying, 'locked'::character varying])::text[])))
);


ALTER TABLE league_management.leagues OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 77687)
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
-- TOC entry 3714 (class 0 OID 0)
-- Dependencies: 237
-- Name: leagues_league_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.leagues_league_id_seq OWNED BY league_management.leagues.league_id;


--
-- TOC entry 238 (class 1259 OID 77688)
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
    CONSTRAINT playoffs_status_enum CHECK (((status)::text = ANY (ARRAY[('draft'::character varying)::text, ('public'::character varying)::text, ('archived'::character varying)::text]))),
    CONSTRAINT playoffs_structure_enum CHECK (((playoff_structure)::text = ANY (ARRAY[('bracket'::character varying)::text, ('round-robin'::character varying)::text])))
);


ALTER TABLE league_management.playoffs OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 77698)
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
-- TOC entry 3715 (class 0 OID 0)
-- Dependencies: 239
-- Name: playoffs_playoff_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.playoffs_playoff_id_seq OWNED BY league_management.playoffs.playoff_id;


--
-- TOC entry 240 (class 1259 OID 77699)
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
-- TOC entry 241 (class 1259 OID 77703)
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
-- TOC entry 3716 (class 0 OID 0)
-- Dependencies: 241
-- Name: season_admins_season_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.season_admins_season_admin_id_seq OWNED BY league_management.season_admins.season_admin_id;


--
-- TOC entry 242 (class 1259 OID 77704)
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
    CONSTRAINT season_status_enum CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'public'::character varying, 'archived'::character varying, 'locked'::character varying])::text[])))
);


ALTER TABLE league_management.seasons OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 77712)
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
-- TOC entry 3717 (class 0 OID 0)
-- Dependencies: 243
-- Name: seasons_season_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.seasons_season_id_seq OWNED BY league_management.seasons.season_id;


--
-- TOC entry 244 (class 1259 OID 77713)
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
-- TOC entry 245 (class 1259 OID 77718)
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
-- TOC entry 3718 (class 0 OID 0)
-- Dependencies: 245
-- Name: team_memberships_team_membership_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.team_memberships_team_membership_id_seq OWNED BY league_management.team_memberships.team_membership_id;


--
-- TOC entry 246 (class 1259 OID 77719)
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
    CONSTRAINT team_status_enum CHECK (((status)::text = ANY (ARRAY[('active'::character varying)::text, ('inactive'::character varying)::text, ('suspended'::character varying)::text, ('banned'::character varying)::text])))
);


ALTER TABLE league_management.teams OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 77728)
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
-- TOC entry 3719 (class 0 OID 0)
-- Dependencies: 247
-- Name: teams_team_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.teams_team_id_seq OWNED BY league_management.teams.team_id;


--
-- TOC entry 248 (class 1259 OID 77729)
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
-- TOC entry 249 (class 1259 OID 77735)
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
-- TOC entry 3720 (class 0 OID 0)
-- Dependencies: 249
-- Name: venues_venue_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.venues_venue_id_seq OWNED BY league_management.venues.venue_id;


--
-- TOC entry 250 (class 1259 OID 77736)
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
-- TOC entry 251 (class 1259 OID 77741)
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
-- TOC entry 3721 (class 0 OID 0)
-- Dependencies: 251
-- Name: assists_assist_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.assists_assist_id_seq OWNED BY stats.assists.assist_id;


--
-- TOC entry 252 (class 1259 OID 77742)
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
    created_on timestamp without time zone DEFAULT now(),
    coordinates character varying
);


ALTER TABLE stats.goals OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 77749)
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
-- TOC entry 3722 (class 0 OID 0)
-- Dependencies: 253
-- Name: goals_goal_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.goals_goal_id_seq OWNED BY stats.goals.goal_id;


--
-- TOC entry 254 (class 1259 OID 77750)
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
    created_on timestamp without time zone DEFAULT now(),
    coordinates character varying
);


ALTER TABLE stats.penalties OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 77755)
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
-- TOC entry 3723 (class 0 OID 0)
-- Dependencies: 255
-- Name: penalties_penalty_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.penalties_penalty_id_seq OWNED BY stats.penalties.penalty_id;


--
-- TOC entry 256 (class 1259 OID 77756)
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
-- TOC entry 257 (class 1259 OID 77762)
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
-- TOC entry 3724 (class 0 OID 0)
-- Dependencies: 257
-- Name: saves_save_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.saves_save_id_seq OWNED BY stats.saves.save_id;


--
-- TOC entry 258 (class 1259 OID 77763)
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
    created_on timestamp without time zone DEFAULT now(),
    coordinates character varying
);


ALTER TABLE stats.shots OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 77769)
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
-- TOC entry 3725 (class 0 OID 0)
-- Dependencies: 259
-- Name: shots_shot_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.shots_shot_id_seq OWNED BY stats.shots.shot_id;


--
-- TOC entry 260 (class 1259 OID 77770)
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
-- TOC entry 261 (class 1259 OID 77774)
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
-- TOC entry 3726 (class 0 OID 0)
-- Dependencies: 261
-- Name: shutouts_shutout_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.shutouts_shutout_id_seq OWNED BY stats.shutouts.shutout_id;


--
-- TOC entry 3326 (class 2604 OID 77775)
-- Name: users user_id; Type: DEFAULT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users ALTER COLUMN user_id SET DEFAULT nextval('admin.users_user_id_seq'::regclass);


--
-- TOC entry 3330 (class 2604 OID 77776)
-- Name: arenas arena_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.arenas ALTER COLUMN arena_id SET DEFAULT nextval('league_management.arenas_arena_id_seq'::regclass);


--
-- TOC entry 3332 (class 2604 OID 77777)
-- Name: division_rosters division_roster_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_rosters ALTER COLUMN division_roster_id SET DEFAULT nextval('league_management.division_rosters_division_roster_id_seq'::regclass);


--
-- TOC entry 3335 (class 2604 OID 77778)
-- Name: division_teams division_team_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_teams ALTER COLUMN division_team_id SET DEFAULT nextval('league_management.division_teams_division_team_id_seq'::regclass);


--
-- TOC entry 3337 (class 2604 OID 77779)
-- Name: divisions division_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.divisions ALTER COLUMN division_id SET DEFAULT nextval('league_management.divisions_division_id_seq'::regclass);


--
-- TOC entry 3342 (class 2604 OID 77780)
-- Name: games game_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games ALTER COLUMN game_id SET DEFAULT nextval('league_management.games_game_id_seq'::regclass);


--
-- TOC entry 3348 (class 2604 OID 77781)
-- Name: league_admins league_admin_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins ALTER COLUMN league_admin_id SET DEFAULT nextval('league_management.league_admins_league_admin_id_seq'::regclass);


--
-- TOC entry 3350 (class 2604 OID 77782)
-- Name: league_venues league_venue_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_venues ALTER COLUMN league_venue_id SET DEFAULT nextval('league_management.league_venues_league_venue_id_seq'::regclass);


--
-- TOC entry 3352 (class 2604 OID 77783)
-- Name: leagues league_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.leagues ALTER COLUMN league_id SET DEFAULT nextval('league_management.leagues_league_id_seq'::regclass);


--
-- TOC entry 3355 (class 2604 OID 77784)
-- Name: playoffs playoff_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.playoffs ALTER COLUMN playoff_id SET DEFAULT nextval('league_management.playoffs_playoff_id_seq'::regclass);


--
-- TOC entry 3359 (class 2604 OID 77785)
-- Name: season_admins season_admin_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins ALTER COLUMN season_admin_id SET DEFAULT nextval('league_management.season_admins_season_admin_id_seq'::regclass);


--
-- TOC entry 3361 (class 2604 OID 77786)
-- Name: seasons season_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.seasons ALTER COLUMN season_id SET DEFAULT nextval('league_management.seasons_season_id_seq'::regclass);


--
-- TOC entry 3364 (class 2604 OID 77787)
-- Name: team_memberships team_membership_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships ALTER COLUMN team_membership_id SET DEFAULT nextval('league_management.team_memberships_team_membership_id_seq'::regclass);


--
-- TOC entry 3367 (class 2604 OID 77788)
-- Name: teams team_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.teams ALTER COLUMN team_id SET DEFAULT nextval('league_management.teams_team_id_seq'::regclass);


--
-- TOC entry 3371 (class 2604 OID 77789)
-- Name: venues venue_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.venues ALTER COLUMN venue_id SET DEFAULT nextval('league_management.venues_venue_id_seq'::regclass);


--
-- TOC entry 3373 (class 2604 OID 77790)
-- Name: assists assist_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists ALTER COLUMN assist_id SET DEFAULT nextval('stats.assists_assist_id_seq'::regclass);


--
-- TOC entry 3376 (class 2604 OID 77791)
-- Name: goals goal_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals ALTER COLUMN goal_id SET DEFAULT nextval('stats.goals_goal_id_seq'::regclass);


--
-- TOC entry 3381 (class 2604 OID 77792)
-- Name: penalties penalty_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties ALTER COLUMN penalty_id SET DEFAULT nextval('stats.penalties_penalty_id_seq'::regclass);


--
-- TOC entry 3384 (class 2604 OID 77793)
-- Name: saves save_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves ALTER COLUMN save_id SET DEFAULT nextval('stats.saves_save_id_seq'::regclass);


--
-- TOC entry 3388 (class 2604 OID 77794)
-- Name: shots shot_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots ALTER COLUMN shot_id SET DEFAULT nextval('stats.shots_shot_id_seq'::regclass);


--
-- TOC entry 3392 (class 2604 OID 77795)
-- Name: shutouts shutout_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts ALTER COLUMN shutout_id SET DEFAULT nextval('stats.shutouts_shutout_id_seq'::regclass);


--
-- TOC entry 3659 (class 0 OID 77619)
-- Dependencies: 220
-- Data for Name: users; Type: TABLE DATA; Schema: admin; Owner: postgres
--

INSERT INTO admin.users VALUES (2, 'goose', 'hello+1@adamrobillard.ca', 'Hannah', 'Brown', 'Female', 'she/her', 3, NULL, '$2b$10$99E/cmhMolqnQFi3E6CXHOpB7zYYANgDToz1F.WkFrZMOXCFBvxji', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (3, 'caboose', 'hello+3@adamrobillard.ca', 'Aida', 'Robillard', 'Non-binary', 'any/all', 1, NULL, '$2b$10$UM16ckCNhox47R0yOq873uCUX4Pal3GEVlNY8kYszWGGM.Y3kyiZC', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (4, 'caleb', 'caleb@example.com', 'Caleb', 'Smith', 'Male', 'he/him', 2, NULL, 'heyCaleb123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (5, 'kat', 'kat@example.com', 'Kat', 'Ferguson', 'Non-binary', 'they/them', 2, NULL, 'heyKat123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (6, 'trainMale', 'trainMale@example.com', 'Stephen', 'Spence', 'Male', 'he/him', 3, NULL, 'heyStephen123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (7, 'theGoon', 'theGoon@example.com', 'Levi', 'Bradley', 'Non-binary', 'they/them', 3, NULL, 'heyLevi123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (8, 'cheryl', 'cheryl@example.com', 'Cheryl', 'Chaos', NULL, NULL, 3, NULL, 'heyCheryl123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (9, 'mason', 'mason@example.com', 'Mason', 'Nonsense', NULL, NULL, 3, NULL, 'heyMasonl123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (10, 'jayce', 'jayce@example.com', 'Jayce', 'LeClaire', 'Non-binary', 'they/them', 3, NULL, 'heyJaycel123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (11, 'britt', 'britt@example.com', 'Britt', 'Neron', 'Non-binary', 'they/them', 3, NULL, 'heyBrittl123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (12, 'tesolin', 'tesolin@example.com', 'Zachary', 'Tesolin', 'Male', 'he/him', 3, NULL, 'heyZach123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (13, 'robocop', 'robocop@example.com', 'Andrew', 'Robillard', 'Male', 'he/him', 3, NULL, 'heyAndrew123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (14, 'trex', 'trex@example.com', 'Tim', 'Robillard', 'Male', 'he/him', 3, NULL, 'heyTim123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (15, 'lukasbauer', 'lukas.bauer@example.com', 'Lukas', 'Bauer', 'Male', 'he/him', 3, NULL, 'heyLukas123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (16, 'emmaschmidt', 'emma.schmidt@example.com', 'Emma', 'Schmidt', 'Female', 'she/her', 3, NULL, 'heyEmma123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (17, 'liammüller', 'liam.mueller@example.com', 'Liam', 'Müller', 'Male', 'he/him', 3, NULL, 'heyLiam123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (18, 'hannahfischer', 'hannah.fischer@example.com', 'Hannah', 'Fischer', 'Female', 'she/her', 3, NULL, 'heyHanna123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (19, 'oliverkoch', 'oliver.koch@example.com', 'Oliver', 'Koch', 'Male', 'he/him', 3, NULL, 'heyOliver123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (20, 'clararichter', 'clara.richter@example.com', 'Clara', 'Richter', 'Female', 'she/her', 3, NULL, 'heyClara123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (21, 'noahtaylor', 'noah.taylor@example.com', 'Noah', 'Taylor', 'Male', 'he/him', 3, NULL, 'heyNoah123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (22, 'lisahoffmalen', 'lisa.hoffmalen@example.com', 'Lisa', 'Hoffmalen', 'Female', 'she/her', 3, NULL, 'heyLisa123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (23, 'matteorossetti', 'matteo.rossetti@example.com', 'Matteo', 'Rossetti', 'Male', 'he/him', 3, NULL, 'heyMatteo123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (24, 'giuliarossi', 'giulia.rossi@example.com', 'Giulia', 'Rossi', 'Female', 'she/her', 3, NULL, 'heyGiulia123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (25, 'danielebrown', 'daniele.brown@example.com', 'Daniele', 'Brown', 'Non-binary', 'they/them', 3, NULL, 'heyDaniele123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (26, 'sofialopez', 'sofia.lopez@example.com', 'Sofia', 'Lopez', 'Female', 'she/her', 3, NULL, 'heySofia123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (27, 'sebastienmartin', 'sebastien.martin@example.com', 'Sebastien', 'Martin', 'Male', 'he/him', 3, NULL, 'heySebastien123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (28, 'elisavolkova', 'elisa.volkova@example.com', 'Elisa', 'Volkova', 'Female', 'she/her', 3, NULL, 'heyElisa123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (29, 'adriangarcia', 'adrian.garcia@example.com', 'Adrian', 'Garcia', 'Male', 'he/him', 3, NULL, 'heyAdrian123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (30, 'amelialeroux', 'amelia.leroux@example.com', 'Amelia', 'LeRoux', 'Female', 'she/her', 3, NULL, 'heyAmelia123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (31, 'kasperskov', 'kasper.skov@example.com', 'Kasper', 'Skov', 'Male', 'he/him', 3, NULL, 'heyKasper123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (32, 'elinefransen', 'eline.fransen@example.com', 'Eline', 'Fransen', 'Female', 'she/her', 3, NULL, 'heyEline123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (33, 'andreakovacs', 'andrea.kovacs@example.com', 'Andrea', 'Kovacs', 'Non-binary', 'they/them', 3, NULL, 'heyAndrea123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (34, 'petersmith', 'peter.smith@example.com', 'Peter', 'Smith', 'Male', 'he/him', 3, NULL, 'heyPeter123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (35, 'janinanowak', 'janina.nowak@example.com', 'Janina', 'Nowak', 'Female', 'she/her', 3, NULL, 'heyJanina123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (36, 'niklaspetersen', 'niklas.petersen@example.com', 'Niklas', 'Petersen', 'Male', 'he/him', 3, NULL, 'heyNiklas123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (37, 'martakalinski', 'marta.kalinski@example.com', 'Marta', 'Kalinski', 'Female', 'she/her', 3, NULL, 'heyMarta123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (38, 'tomasmarquez', 'tomas.marquez@example.com', 'Tomas', 'Marquez', 'Male', 'he/him', 3, NULL, 'heyTomas123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (39, 'ireneschneider', 'irene.schneider@example.com', 'Irene', 'Schneider', 'Female', 'she/her', 3, NULL, 'heyIrene123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (41, 'annaschaefer', 'anna.schaefer@example.com', 'Anna', 'Schaefer', 'Female', 'she/her', 3, NULL, 'heyAnna123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (42, 'lucasvargas', 'lucas.vargas@example.com', 'Lucas', 'Vargas', 'Male', 'he/him', 3, NULL, 'heyLucas123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (43, 'sofiacosta', 'sofia.costa@example.com', 'Sofia', 'Costa', 'Female', 'she/her', 3, NULL, 'heySofia123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (44, 'alexanderricci', 'alexander.ricci@example.com', 'Alexander', 'Ricci', 'Male', 'he/him', 3, NULL, 'heyAlexander123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (45, 'noemiecaron', 'noemie.caron@example.com', 'Noemie', 'Caron', 'Female', 'she/her', 3, NULL, 'heyNoemie123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (46, 'pietrocapello', 'pietro.capello@example.com', 'Pietro', 'Capello', 'Male', 'he/him', 3, NULL, 'heyPietro123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (47, 'elisabethjensen', 'elisabeth.jensen@example.com', 'Elisabeth', 'Jensen', 'Female', 'she/her', 3, NULL, 'heyElisabeth123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (48, 'dimitripapadopoulos', 'dimitri.papadopoulos@example.com', 'Dimitri', 'Papadopoulos', 'Male', 'he/him', 3, NULL, 'heyDimitri123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (49, 'marielaramos', 'mariela.ramos@example.com', 'Mariela', 'Ramos', 'Female', 'she/her', 3, NULL, 'heyMariela123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (50, 'valeriekeller', 'valerie.keller@example.com', 'Valerie', 'Keller', 'Female', 'she/her', 3, NULL, 'heyValerie123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (52, 'evaweber', 'eva.weber@example.com', 'Eva', 'Weber', 'Female', 'she/her', 3, NULL, 'heyEva123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (53, 'sebastiancortes', 'sebastian.cortes@example.com', 'Sebastian', 'Cortes', 'Male', 'he/him', 3, NULL, 'heySebastian123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (54, 'maleongarcia', 'maleon.garcia@example.com', 'Maleon', 'Garcia', 'Female', 'she/her', 3, NULL, 'heyMaleon123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (55, 'benjaminflores', 'benjamin.flores@example.com', 'Benjamin', 'Flores', 'Male', 'he/him', 3, NULL, 'heyBenjamin123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (56, 'saradalgaard', 'sara.dalgaard@example.com', 'Sara', 'Dalgaard', 'Female', 'she/her', 3, NULL, 'heySara123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (57, 'jonasmartinez', 'jonas.martinez@example.com', 'Jonas', 'Martinez', 'Male', 'he/him', 3, NULL, 'heyJonas123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (40, 'maximilianbauer', 'maximilian.bauer@example.com', 'Maximilian', 'Bauer', 'Male', 'he/him', 3, NULL, 'heyMaximilian123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (51, 'dominikbauer', 'dominik.bauer@example.com', 'Dominik', 'Bauer', 'Male', 'he/him', 3, NULL, 'heyDominik123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (58, 'alessiadonati', 'alessia.donati@example.com', 'Alessia', 'Donati', 'Female', 'she/her', 3, NULL, 'heyAlessia123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (59, 'lucaskovac', 'lucas.kovac@example.com', 'Lucas', 'Kovac', 'Non-binary', 'they/them', 3, NULL, 'heyLucas123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (76, 'mariakoval', 'maria.koval@example.com', 'Maria', 'Koval', 'Female', 'she/her', 3, NULL, 'heyMaria123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (77, 'lukemccarthy', 'luke.mccarthy@example.com', 'Luke', 'McCarthy', 'Male', 'he/him', 3, NULL, 'heyLuke123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (78, 'larissahansen', 'larissa.hansen@example.com', 'Larissa', 'Hansen', 'Female', 'she/her', 3, NULL, 'heyLarissa123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (79, 'adamwalker', 'adam.walker@example.com', 'Adam', 'Walker', 'Male', 'he/him', 3, NULL, 'heyAdam123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (91, 'lindavon', 'linda.von@example.com', 'Linda', 'Von', 'Female', 'she/her', 3, NULL, 'heyLinda123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (92, 'andreaspeicher', 'andreas.peicher@example.com', 'Andreas', 'Peicher', 'Male', 'he/him', 3, NULL, 'heyAndreas123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (94, 'marianapaz', 'mariana.paz@example.com', 'Mariana', 'Paz', 'Female', 'she/her', 3, NULL, 'heyMariana123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (95, 'fionaberg', 'fiona.berg@example.com', 'Fiona', 'Berg', 'Female', 'she/her', 3, NULL, 'heyFiona123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (96, 'joachimkraus', 'joachim.kraus@example.com', 'Joachim', 'Kraus', 'Male', 'he/him', 3, NULL, 'heyJoachim123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (98, 'mariomatteo', 'mario.matteo@example.com', 'Mario', 'Matteo', 'Male', 'he/him', 3, NULL, 'heyMario123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (99, 'elizabethsmith', 'elizabeth.smith@example.com', 'Elizabeth', 'Smith', 'Female', 'she/her', 3, NULL, 'heyElizabeth123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (106, 'valentinwebb', 'valentin.webb@example.com', 'Valentin', 'Webb', 'Male', 'he/him', 3, NULL, 'heyValentin123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (107, 'oliviamorales', 'olivia.morales@example.com', 'Olivia', 'Morales', 'Female', 'she/her', 3, NULL, 'heyOlivia123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (108, 'mathieuhebert', 'mathieu.hebert@example.com', 'Mathieu', 'Hebert', 'Male', 'he/him', 3, NULL, 'heyMathieu123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (109, 'rosepatel', 'rose.patel@example.com', 'Rose', 'Patel', 'Female', 'she/her', 3, NULL, 'heyRose123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (110, 'travisrichards', 'travis.richards@example.com', 'Travis', 'Richards', 'Male', 'he/him', 3, NULL, 'heyTravis123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (111, 'josefinklein', 'josefinklein@example.com', 'Josefin', 'Klein', 'Female', 'she/her', 3, NULL, 'heyJosefin123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (113, 'sofiaparker', 'sofia.parker@example.com', 'Sofia', 'Parker', 'Female', 'she/her', 3, NULL, 'heySofia123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (114, 'theogibson', 'theo.gibson@example.com', 'Theo', 'Gibson', 'Male', 'he/him', 3, NULL, 'heyTheo123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (60, 'emiliekoch', 'emilie.koch@example.com', 'Emilie', 'Koch', 'Female', 'she/her', 3, NULL, 'heyEmilie123', 'inactive', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (80, 'paolamendes', 'paola.mendes@example.com', 'Paola', 'Mendes', 'Female', 'she/her', 3, NULL, 'heyPaola123', 'suspended', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (97, 'michellebauer', 'michelle.bauer@example.com', 'Michelle', 'Bauer', 'Female', 'she/her', 3, NULL, 'heyMichelle123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (82, 'evastark', 'eva.stark@example.com', 'Eva', 'Stark', 'Female', 'she/her', 3, NULL, 'heyEva123', 'suspended', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (83, 'juliankovacic', 'julian.kovacic@example.com', 'Julian', 'Kovacic', 'Male', 'he/him', 3, NULL, 'heyJulian123', 'suspended', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (84, 'ameliekrause', 'amelie.krause@example.com', 'Amelie', 'Krause', 'Female', 'she/her', 3, NULL, 'heyAmelie123', 'suspended', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (85, 'ryanschneider', 'ryan.schneider@example.com', 'Ryan', 'Schneider', 'Male', 'he/him', 3, NULL, 'heyRyan123', 'suspended', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (87, 'daniellefoster', 'danielle.foster@example.com', 'Danielle', 'Foster', '4', 'she/her', 3, NULL, 'heyDanielle123', 'suspended', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (88, 'harrykhan', 'harry.khan@example.com', 'Harry', 'Khan', 'Male', 'he/him', 3, NULL, 'heyHarry123', 'suspended', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (89, 'sophielindgren', 'sophie.lindgren@example.com', 'Sophie', 'Lindgren', 'Female', 'she/her', 3, NULL, 'heySophie123', 'suspended', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (90, 'oskarpetrov', 'oskar.petrov@example.com', 'Oskar', 'Petrov', 'Male', 'he/him', 3, NULL, 'heyOskar123', 'suspended', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (100, 'ianlennox', 'ian.lennox@example.com', 'Ian', 'Lennox', 'Male', 'he/him', 3, NULL, 'heyIan123', 'banned', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (103, 'celinebrown', 'celine.brown@example.com', 'Celine', 'Brown', 'Female', 'she/her', 3, NULL, 'heyCeline123', 'banned', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (104, 'georgiamills', 'georgia.mills@example.com', 'Georgia', 'Mills', 'Female', 'she/her', 3, NULL, 'heyGeorgia123', 'banned', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (105, 'antoineclark', 'antoine.clark@example.com', 'Antoine', 'Clark', 'Male', 'he/him', 3, NULL, 'heyAntoine123', 'banned', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (102, 'francescoantoni', 'francesco.antoni@example.com', 'Francesco', 'Antoni', 'Male', 'he/him', 3, NULL, 'heyFrancesco123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (101, 'evabradley', 'eva.bradley@example.com', 'Eva', 'Bradley', 'Female', 'she/her', 3, NULL, 'heyEva123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (81, 'ethanwilliams', 'ethan.williams@example.com', 'Ethan', 'Williams', 'Male', 'he/him', 3, NULL, 'heyEthan123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (86, 'monikathomsen', 'monika.thomsen@example.com', 'Monika', 'Thomsen', 'Female', 'she/her', 3, NULL, 'heyMonika123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (93, 'jjmcray', 'josephine.jung@example.com', 'Josephine', 'Jung', 'NB', 'they/theme', 3, NULL, 'heyJosephine123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (117, 'spoose', 'spoose@example.com', 'Spoose', 'Fence', 'Female', 'she/her', 3, NULL, '$2b$10$SEZYh44vnRhKW8vKUIgcv..0B3WRQs9xcnDPZWpA5RvoP2SYEev5a', 'active', '2025-02-12 02:14:07.46819');
INSERT INTO admin.users VALUES (115, 'floose', 'floose@example.com', 'Floose', 'McGoose', '3', 'any/all', 2, NULL, '$2b$10$7pjrECYElk1ithndcAhtcuPytB2Hc8DiDi3e8gAEXYcfIjOVZdEfS', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (116, 'loose', 'loose@example.com', 'Loose', 'Caboose', 'NB', 'any/all', 2, NULL, '$2b$10$b5ZNgNVD19DbZ2cfneJHbeMOD//r.Eg23ovq2Odoofek8bOO5m1V2', 'active', '2025-02-11 15:44:13.703754');
INSERT INTO admin.users VALUES (119, 'coolio', 'coolio@example.com', 'Coolio', 'Io', NULL, NULL, 3, NULL, '$2b$10$bZs4ZvVVYHxss2qBAzQ9reJT1NYr1791bi4M2cG40z4xcytoRM5pq', 'active', '2025-02-25 22:32:14.479079');
INSERT INTO admin.users VALUES (121, 'grug', 'gru@example.com', 'Greg', 'Grugson', 'Male', 'he/him', 3, NULL, '$2b$10$TUOXapDgSPsIP/w9MV8IV.5gV1qw/PgOAI4xT35vsNf1wvZYBopui', 'active', '2025-02-27 19:51:29.543403');
INSERT INTO admin.users VALUES (120, 'doug', 'doug@example.com', 'Doug', 'Dougerson', 'Male', 'he/him', 3, NULL, '$2b$10$7by/kOGmi2dnpfTDjmQQ.OoCD9Fw2xDG3sikwRDwKqM6lW6asTo9K', 'active', '2025-02-27 19:44:10.552822');
INSERT INTO admin.users VALUES (125, 'kooliokiddio', 'hello+100@adamrobillard.ca', 'Test', 'Testerson', NULL, NULL, 3, NULL, '1234567890', 'active', '2025-02-28 18:24:20.661964');
INSERT INTO admin.users VALUES (126, 'Sup Bitches', 'bitches@example.com', 'Test', 'Testerson', NULL, NULL, 3, NULL, '$2b$10$8erMpj9HFPDn3JsGjr.Reel1t1E8SJhq2HxK0L4WYsQnItqItmTna', 'active', '2025-02-28 18:26:26.414641');
INSERT INTO admin.users VALUES (131, 'heythere', 'sup@example.com', 'Hey', 'There', NULL, NULL, 3, NULL, '$2b$10$PFKlDy935CE/HbWPtsANQuHR1ayy.bJORYn9sXZAQery587DYCXVO', 'active', '2025-02-28 18:39:14.930742');
INSERT INTO admin.users VALUES (132, 'joetester', 'joe@example.com', 'Joe', 'Testers', NULL, NULL, 3, NULL, '$2b$10$/ay2YCdfkRhztDEH/1pubuM56iyKdqtA0kE7AekRj.NeevKD6LRo.', 'active', '2025-03-05 15:36:37.082571');
INSERT INTO admin.users VALUES (61, 'danieljones', 'daniel.jones@example.com', 'Daniel', 'Jones', 'Male', 'he/him', 3, NULL, 'heyDaniel123', 'inactive', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (64, 'angelaperez', 'angela.perez@example.com', 'Angela', 'Perez', 'Female', 'she/her', 3, NULL, 'heyAngela123', 'inactive', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (65, 'henrikstrom', 'henrik.strom@example.com', 'Henrik', 'Strom', 'Male', 'he/him', 3, NULL, 'heyHenrik123', 'inactive', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (66, 'paulinaklein', 'paulina.klein@example.com', 'Paulina', 'Klein', 'Female', 'she/her', 3, NULL, 'heyPaulina123', 'inactive', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (67, 'raphaelgonzalez', 'raphael.gonzalez@example.com', 'Raphael', 'Gonzalez', 'Male', 'he/him', 3, NULL, 'heyRaphael123', 'inactive', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (68, 'annaluisachavez', 'anna-luisa.chavez@example.com', 'Anna-Luisa', 'Chavez', 'Female', 'she/her', 3, NULL, 'heyAnna-Luisa123', 'inactive', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (69, 'fabiomercier', 'fabio.mercier@example.com', 'Fabio', 'Mercier', 'Male', 'he/him', 3, NULL, 'heyFabio123', 'inactive', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (70, 'nataliefischer', 'natalie.fischer@example.com', 'Natalie', 'Fischer', 'Female', 'she/her', 3, NULL, 'heyNatalie123', 'inactive', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (71, 'georgmayer', 'georg.mayer@example.com', 'Georg', 'Mayer', 'Male', 'he/him', 3, NULL, 'heyGeorg123', 'inactive', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (73, 'katharinalopez', 'katharina.lopez@example.com', 'Katharina', 'Lopez', 'Female', 'she/her', 3, NULL, 'heyKatharina123', 'inactive', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (75, 'frederikschmidt', 'frederik.schmidt@example.com', 'Frederik', 'Schmidt', 'Male', 'he/him', 3, NULL, 'heyFrederik123', 'inactive', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (63, 'thomasleroux', 'thomas.leroux@example.com', 'Tom', 'LeRoux', 'Male', 'he/him', 3, NULL, 'heyThomas123', 'inactive', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (74, 'simonealvarez', 'simone.alvarez@example.com', 'Simone', 'Alvarez', 'Non-binary', 'they/them', 3, NULL, 'heySimone123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (112, 'finnandersen', 'finn.andersen@example.com', 'Finn', 'Andersen', 'Male', 'he/him', 3, NULL, 'heyFinn123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (118, 'boose', 'boose@example.com', 'Public', 'Transport', NULL, NULL, 3, NULL, '$2b$10$WJWWTteghY0OBIT1d0t3peCNDl8Vw36S05/.aYDVs8riy8PyeQ2ZW', 'active', '2025-02-18 00:25:31.719469');
INSERT INTO admin.users VALUES (72, 'julianweiss', 'julian.weiss@example.com', 'Julian', 'Weiss', 'Male', 'he/him', 3, NULL, 'heyJulian123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (62, 'mathildevogel', 'mathilde.vogel@example.com', 'Mathilde', 'Vogel', 'Female', 'she/her', 3, NULL, 'heyMathilde123', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO admin.users VALUES (1, 'moose', 'hello+2@adamrobillard.ca', 'Adam', 'Robillard', 'Non-Binary', 'any/all', 1, '/profile.jpg', '$2b$10$2ZZ3US2VAewS22POAX8/DOHQ1dk68lAnyfmDbtdojRmPOpEm.PKQS', 'active', '2025-02-10 22:27:41.682766');


--
-- TOC entry 3661 (class 0 OID 77629)
-- Dependencies: 222
-- Data for Name: arenas; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.arenas VALUES (1, 'Arena', NULL, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (2, '1', NULL, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (3, '2', NULL, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (4, '3', NULL, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (5, '4', NULL, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (6, 'Arena', NULL, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (7, 'A', NULL, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (8, 'B', NULL, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (9, 'A', NULL, 5, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (10, 'B', NULL, 5, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (11, 'Arena', NULL, 6, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (12, 'A', NULL, 7, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (13, 'B', NULL, 7, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (14, 'Arena', NULL, 8, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (15, 'A', NULL, 9, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (16, 'B', NULL, 9, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (17, 'Arena', NULL, 10, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.arenas VALUES (27, 'A', NULL, 17, '2025-02-26 19:38:00.935789');
INSERT INTO league_management.arenas VALUES (28, 'B', NULL, 17, '2025-02-26 19:38:00.937183');
INSERT INTO league_management.arenas VALUES (29, 'International', NULL, 17, '2025-02-26 19:38:00.938284');
INSERT INTO league_management.arenas VALUES (30, 'Arena', NULL, 18, '2025-02-26 19:39:15.103016');
INSERT INTO league_management.arenas VALUES (31, 'Arena', NULL, 21, '2025-02-27 20:11:03.497142');
INSERT INTO league_management.arenas VALUES (32, 'Arena', NULL, 22, '2025-02-27 20:11:34.073511');
INSERT INTO league_management.arenas VALUES (33, '1', NULL, 23, '2025-02-27 20:13:14.353992');
INSERT INTO league_management.arenas VALUES (34, '2', NULL, 23, '2025-02-27 20:13:14.356017');
INSERT INTO league_management.arenas VALUES (35, '3', NULL, 23, '2025-02-27 20:13:14.357227');
INSERT INTO league_management.arenas VALUES (39, 'Arena', NULL, 28, '2025-03-04 15:05:08.438013');
INSERT INTO league_management.arenas VALUES (40, '1', NULL, 29, '2025-03-04 16:29:34.22238');
INSERT INTO league_management.arenas VALUES (41, '2', NULL, 29, '2025-03-04 16:29:34.223966');
INSERT INTO league_management.arenas VALUES (42, 'Arena', NULL, 30, '2025-03-05 16:38:53.550778');


--
-- TOC entry 3663 (class 0 OID 77636)
-- Dependencies: 224
-- Data for Name: division_rosters; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.division_rosters VALUES (1, 1, 1, 'Center', 30, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (2, 1, 2, 'Defense', 25, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (3, 2, 3, 'Defense', 18, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (4, 2, 4, 'Defense', 47, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (5, 3, 5, 'Center', 12, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (6, 3, 6, 'Left Wing', 9, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (7, 4, 7, 'Right Wing', 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (8, 4, 8, 'Defense', 10, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (9, 5, 57, 'Defense', 93, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (10, 6, 58, 'Defense', 13, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (11, 7, 59, 'Defense', 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (12, 8, 60, 'Defense', 19, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (13, 9, 61, 'Left Wing', 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (14, 1, 9, 'Center', 8, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (15, 1, 10, 'Center', 9, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (16, 1, 11, 'Left Wing', 10, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (17, 1, 12, 'Left Wing', 11, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (18, 1, 13, 'Right Wing', 12, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (19, 1, 14, 'Right Wing', 13, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (20, 1, 15, 'Center', 14, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (21, 1, 16, 'Defense', 15, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (22, 1, 19, 'Defense', 18, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (23, 1, 20, 'Goalie', 33, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (24, 2, 21, 'Center', 20, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (25, 2, 22, 'Center', 21, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (26, 2, 25, 'Left Wing', 24, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (27, 2, 26, 'Right Wing', 25, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (28, 2, 27, 'Right Wing', 26, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (29, 2, 28, 'Left Wing', 27, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (30, 2, 29, 'Right Wing', 28, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (31, 2, 30, 'Defense', 29, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (32, 2, 31, 'Defense', 30, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (33, 2, 32, 'Goalie', 31, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (34, 3, 33, 'Center', 40, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (35, 3, 34, 'Center', 41, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (36, 3, 35, 'Left Wing', 42, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (37, 3, 36, 'Left Wing', 43, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (38, 3, 37, 'Right Wing', 44, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (39, 3, 39, 'Center', 46, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (40, 3, 40, 'Defense', 47, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (41, 3, 41, 'Defense', 48, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (42, 3, 42, 'Defense', 49, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (43, 3, 44, 'Goalie', 51, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (44, 4, 45, 'Center', 26, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (45, 4, 47, 'Left Wing', 28, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (46, 4, 49, 'Right Wing', 30, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (47, 4, 50, 'Right Wing', 31, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (48, 4, 51, 'Center', 32, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (49, 4, 52, 'Defense', 33, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (50, 4, 53, 'Defense', 34, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (51, 4, 54, 'Defense', 35, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (52, 4, 55, 'Defense', 36, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (53, 4, 56, 'Goalie', 3, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (54, 5, 63, NULL, 61, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (57, 5, 67, NULL, 65, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (58, 5, 68, NULL, 66, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (59, 5, 69, NULL, 67, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (60, 5, 70, NULL, 68, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (61, 5, 71, 'Goalie', 69, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (62, 6, 72, NULL, 70, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (63, 6, 73, NULL, 71, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (64, 6, 75, NULL, 73, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (65, 6, 76, NULL, 74, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (66, 6, 77, NULL, 75, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (67, 6, 78, NULL, 76, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (68, 6, 80, NULL, 78, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (69, 6, 81, 'Goalie', 79, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (70, 7, 82, NULL, 80, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (71, 7, 83, NULL, 81, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (72, 7, 85, NULL, 83, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (73, 7, 86, NULL, 84, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (74, 7, 88, NULL, 86, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (75, 7, 89, NULL, 87, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (76, 7, 90, NULL, 88, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (77, 7, 91, 'Goalie', 89, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (78, 8, 93, NULL, 91, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (79, 8, 94, NULL, 92, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (80, 8, 95, NULL, 93, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (81, 8, 96, NULL, 94, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (82, 8, 97, NULL, 95, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (83, 8, 98, NULL, 96, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (84, 8, 99, NULL, 97, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (85, 8, 101, 'Goalie', 1, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (86, 9, 103, NULL, 21, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (87, 9, 104, NULL, 22, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (88, 9, 105, NULL, 23, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (89, 9, 107, NULL, 25, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (90, 9, 108, NULL, 26, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (91, 9, 109, NULL, 27, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (92, 9, 110, NULL, 28, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (93, 9, 111, 'Goalie', 29, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (94, 15, 3, 'Defense', 18, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (95, 15, 4, 'Center', 47, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (96, 15, 21, 'Goalie', 20, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (97, 15, 22, 'Right Wing', 21, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (98, 15, 23, 'Center', 22, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (99, 15, 24, 'Left Wing', 23, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (100, 15, 27, 'Defense', 26, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (101, 15, 28, 'Left Wing', 27, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (102, 15, 29, 'Right Wing', 28, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (103, 15, 30, 'Defense', 29, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (104, 15, 31, 'Left Wing', 30, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (106, 37, 112, 'Center', 20, 2, '2025-02-11 21:02:16.12983');
INSERT INTO league_management.division_rosters VALUES (107, 37, 113, 'Defense', 69, 4, '2025-02-11 21:02:37.731746');
INSERT INTO league_management.division_rosters VALUES (108, 16, 115, 'Center', 13, 4, '2025-02-12 02:14:24.728494');
INSERT INTO league_management.division_rosters VALUES (109, 38, 112, 'Center', 93, 2, '2025-02-12 02:27:34.151101');
INSERT INTO league_management.division_rosters VALUES (110, 38, 113, 'Defense', 18, 4, '2025-02-12 02:27:48.986371');
INSERT INTO league_management.division_rosters VALUES (111, 13, 116, 'Center', 1, 4, '2025-02-12 02:28:30.898243');
INSERT INTO league_management.division_rosters VALUES (113, 39, 57, 'Defense', 93, 2, '2025-02-24 20:59:24.480154');
INSERT INTO league_management.division_rosters VALUES (114, 39, 65, 'Center', 32, 4, '2025-02-24 20:59:35.801058');
INSERT INTO league_management.division_rosters VALUES (115, 49, 3, 'Center', 18, 2, '2025-02-24 21:00:32.228505');
INSERT INTO league_management.division_rosters VALUES (116, 49, 4, 'Defense', 47, 3, '2025-02-24 21:00:45.512152');
INSERT INTO league_management.division_rosters VALUES (56, 5, 66, 'Center', 64, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (55, 5, 65, 'Left Wing', 63, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_rosters VALUES (122, 5, 62, 'Center', 1, 3, '2025-02-24 23:56:07.49846');
INSERT INTO league_management.division_rosters VALUES (125, 18, 135, 'Right Wing', 12, 3, '2025-02-27 19:58:23.180086');
INSERT INTO league_management.division_rosters VALUES (126, 18, 142, 'Goalie', 1, 4, '2025-02-27 19:58:34.669903');
INSERT INTO league_management.division_rosters VALUES (127, 18, 139, 'Left Wing', 57, 4, '2025-02-27 19:58:57.083957');
INSERT INTO league_management.division_rosters VALUES (128, 18, 132, 'Defense', 16, 4, '2025-02-27 19:59:07.610507');
INSERT INTO league_management.division_rosters VALUES (129, 18, 143, 'Defense', 14, 3, '2025-02-27 19:59:19.198253');
INSERT INTO league_management.division_rosters VALUES (124, 55, 128, 'Right Wing', 2, 2, '2025-02-27 19:50:27.023973');
INSERT INTO league_management.division_rosters VALUES (123, 53, 128, 'Right Wing', 19, 2, '2025-02-27 19:46:32.349255');
INSERT INTO league_management.division_rosters VALUES (112, 18, 114, 'Center', 93, 2, '2025-02-13 22:14:45.507515');
INSERT INTO league_management.division_rosters VALUES (130, 56, 129, 'Goalie', 69, 2, '2025-02-27 19:59:55.865111');
INSERT INTO league_management.division_rosters VALUES (131, 56, 176, 'Center', 54, 3, '2025-02-27 20:01:29.89506');
INSERT INTO league_management.division_rosters VALUES (132, 56, 170, 'Right Wing', 24, 3, '2025-02-27 20:01:40.343471');
INSERT INTO league_management.division_rosters VALUES (133, 56, 171, 'Right Wing', 4, 4, '2025-02-27 20:02:14.444635');
INSERT INTO league_management.division_rosters VALUES (134, 56, 177, 'Defense', 67, 4, '2025-02-27 20:03:06.567495');
INSERT INTO league_management.division_rosters VALUES (135, 56, 172, 'Defense', 34, 4, '2025-02-27 20:03:16.820317');
INSERT INTO league_management.division_rosters VALUES (136, 55, 164, 'Right Wing', 42, 3, '2025-02-27 20:04:17.238342');
INSERT INTO league_management.division_rosters VALUES (137, 55, 155, 'Center', 7, 4, '2025-02-27 20:04:46.891215');
INSERT INTO league_management.division_rosters VALUES (138, 55, 168, 'Defense', 75, 4, '2025-02-27 20:04:55.180052');
INSERT INTO league_management.division_rosters VALUES (139, 55, 160, 'Goalie', 1, 4, '2025-02-27 20:05:02.012791');
INSERT INTO league_management.division_rosters VALUES (140, 55, 169, 'Defense', 6, 3, '2025-02-27 20:05:19.862702');
INSERT INTO league_management.division_rosters VALUES (141, 54, 127, 'Left Wing', 69, 2, '2025-02-27 20:05:47.170438');
INSERT INTO league_management.division_rosters VALUES (142, 54, 148, 'Right Wing', 4, 3, '2025-02-27 20:05:58.668309');
INSERT INTO league_management.division_rosters VALUES (143, 54, 145, 'Goalie', 33, 4, '2025-02-27 20:06:06.60077');
INSERT INTO league_management.division_rosters VALUES (144, 54, 154, 'Center', 67, 4, '2025-02-27 20:06:14.720618');
INSERT INTO league_management.division_rosters VALUES (145, 54, 146, 'Defense', 83, 4, '2025-02-27 20:06:23.154483');
INSERT INTO league_management.division_rosters VALUES (146, 54, 144, 'Center', 36, 4, '2025-02-27 20:06:28.636181');
INSERT INTO league_management.division_rosters VALUES (147, 51, 114, 'Left Wing', 93, 2, '2025-02-27 20:14:48.750985');
INSERT INTO league_management.division_rosters VALUES (148, 51, 142, 'Right Wing', 25, 4, '2025-02-27 20:15:00.036016');
INSERT INTO league_management.division_rosters VALUES (149, 51, 133, 'Goalie', 1, 4, '2025-02-27 20:15:07.228038');
INSERT INTO league_management.division_rosters VALUES (150, 51, 137, 'Defense', 59, 3, '2025-02-27 20:15:17.830928');
INSERT INTO league_management.division_rosters VALUES (151, 51, 136, 'Center', 85, 4, '2025-02-27 20:15:28.810596');
INSERT INTO league_management.division_rosters VALUES (152, 51, 143, 'Defense', 45, 4, '2025-02-27 20:15:38.256787');
INSERT INTO league_management.division_rosters VALUES (153, 53, 156, 'Right Wing', 45, 3, '2025-02-27 20:18:11.003378');
INSERT INTO league_management.division_rosters VALUES (154, 53, 168, 'Goalie', 33, 4, '2025-02-27 20:18:27.697857');
INSERT INTO league_management.division_rosters VALUES (155, 53, 165, 'Center', 72, 4, '2025-02-27 20:18:38.812485');
INSERT INTO league_management.division_rosters VALUES (156, 53, 166, 'Defense', 87, 4, '2025-02-27 20:18:47.296513');
INSERT INTO league_management.division_rosters VALUES (157, 53, 169, 'Defense', 23, 4, '2025-02-27 20:18:58.409239');


--
-- TOC entry 3665 (class 0 OID 77642)
-- Dependencies: 226
-- Data for Name: division_teams; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.division_teams VALUES (1, 1, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (2, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (3, 1, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (4, 1, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (5, 4, 5, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (6, 4, 6, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (7, 4, 7, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (8, 4, 8, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (9, 4, 9, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (10, 11, 10, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (11, 11, 11, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (12, 11, 12, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (13, 11, 13, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (14, 11, 14, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (15, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (16, 5, 15, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (17, 5, 16, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (18, 5, 17, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (19, 5, 18, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (20, 5, 19, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (21, 5, 20, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (22, 6, 21, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (23, 6, 22, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (24, 6, 23, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (25, 6, 24, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (26, 6, 25, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (27, 6, 26, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (28, 7, 27, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (29, 7, 28, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (30, 7, 29, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (31, 7, 30, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (32, 8, 31, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (33, 8, 32, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (34, 8, 33, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (35, 8, 34, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.division_teams VALUES (37, 5, 35, '2025-02-11 21:01:54.633882');
INSERT INTO league_management.division_teams VALUES (38, 11, 35, '2025-02-12 02:27:11.045775');
INSERT INTO league_management.division_teams VALUES (39, 11, 5, '2025-02-19 21:36:03.137993');
INSERT INTO league_management.division_teams VALUES (40, 11, 19, '2025-02-19 21:36:37.321475');
INSERT INTO league_management.division_teams VALUES (47, 4, 17, '2025-02-20 14:02:20.124252');
INSERT INTO league_management.division_teams VALUES (48, 4, 28, '2025-02-20 14:41:03.281072');
INSERT INTO league_management.division_teams VALUES (49, 11, 2, '2025-02-24 20:50:22.646391');
INSERT INTO league_management.division_teams VALUES (51, 33, 17, '2025-02-27 19:24:34.519071');
INSERT INTO league_management.division_teams VALUES (53, 33, 40, '2025-02-27 19:45:39.167154');
INSERT INTO league_management.division_teams VALUES (54, 33, 39, '2025-02-27 19:47:28.838741');
INSERT INTO league_management.division_teams VALUES (55, 6, 40, '2025-02-27 19:48:20.698147');
INSERT INTO league_management.division_teams VALUES (56, 33, 41, '2025-02-27 19:52:49.34052');
INSERT INTO league_management.division_teams VALUES (57, 37, 16, '2025-03-04 16:45:18.101662');
INSERT INTO league_management.division_teams VALUES (58, 37, 33, '2025-03-04 16:45:26.13602');
INSERT INTO league_management.division_teams VALUES (59, 37, 34, '2025-03-04 16:45:37.697311');
INSERT INTO league_management.division_teams VALUES (60, 37, 21, '2025-03-04 16:45:40.849446');
INSERT INTO league_management.division_teams VALUES (62, 38, 41, '2025-03-05 16:39:41.469373');


--
-- TOC entry 3667 (class 0 OID 77647)
-- Dependencies: 228
-- Data for Name: divisions; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.divisions VALUES (1, 'div-inc', 'Div Inc', NULL, 1, 'all', 1, 'bbf07e3b-6053-49b2-86c8-fe1d7802480a', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (5, 'div-2', 'Div 2', NULL, 2, 'all', 4, '07792bf2-fad1-4238-b829-2cdc2c63fafd', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (6, 'div-3', 'Div 3', NULL, 3, 'all', 4, '9c579f89-b602-4840-8431-f4a6df50f251', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (7, 'div-4', 'Div 4', NULL, 4, 'all', 4, '05e5b429-044d-4c88-afe1-2e18780b9ac9', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (8, 'div-5', 'Div 5', NULL, 5, 'all', 4, '6b838963-645a-4105-9652-20c41dad8fc1', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (9, 'men-35', 'Men 35+', NULL, 6, 'men', 4, '2da2e898-5758-4c95-b1dc-6f28c16c419c', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (10, 'women-35', 'Women 35+', NULL, 6, 'women', 4, '9b65036d-6b67-4801-afae-0a578bb93a50', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (11, 'div-1', 'Div 1', NULL, 1, 'all', 5, 'c778816a-2c26-44e6-af7a-fa68417803c7', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (12, 'div-2', 'Div 2', NULL, 2, 'all', 5, '274a3d14-57a5-4bfe-bb50-2d2439ba7752', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (13, 'div-3', 'Div 3', NULL, 3, 'all', 5, '568bb835-df39-4f77-a578-11c3a05d5347', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (14, 'div-4', 'Div 4', NULL, 4, 'all', 5, 'b87a2ac2-d13f-4af4-bd2d-9bed9601fcaa', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (15, 'div-5', 'Div 5', NULL, 5, 'all', 5, '5ebf829e-9936-4a10-9221-29322d98565e', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (16, 'div-6', 'Div 6', NULL, 6, 'all', 5, '64e2eedc-91b1-409b-9e74-617303a4947b', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (17, 'men-1', 'Men 1', NULL, 1, 'men', 5, '427ffcf6-6eaa-4c57-b191-76a1cd3921e6', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (18, 'men-2', 'Men 2', NULL, 2, 'men', 5, '11720906-0165-482a-a1bf-b5f26fb90ef2', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (19, 'men-3', 'Men 3', NULL, 3, 'men', 5, '71276567-9ef1-4e47-9fb5-55028a0eac83', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (20, 'women-1', 'Women 1', NULL, 1, 'women', 5, 'a239f17a-d4e1-4675-bb46-78ba307accee', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (21, 'women-2', 'Women 2', NULL, 2, 'women', 5, '24d85b55-317f-41e0-89dc-0cfd7d2d3243', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (22, 'women-3', 'Women 3', NULL, 3, 'women', 5, 'c187e88d-7712-4b11-9761-5f48c494d5fd', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (33, 'div-1', 'Div 1', '', 1, 'all', 14, 'full-league-test-div-1', 'public', '2025-02-27 19:18:27.385202');
INSERT INTO league_management.divisions VALUES (37, 'div-1-1', 'Div 1', '', 1, 'women', 4, 'ec809de9-8ac2-4b4c-ac33-93489343c012', 'draft', '2025-03-04 16:43:29.546697');
INSERT INTO league_management.divisions VALUES (38, 'div-2', 'Div 2', '', 2, 'all', 14, '9acd97d9-b6bf-4ab5-8911-bd66788eebb7', 'draft', '2025-03-05 16:30:41.476924');
INSERT INTO league_management.divisions VALUES (2, 'div-1', 'Div 1', NULL, 1, 'all', 3, 'a6b6e1b9-2655-4b00-9d3c-f3dad9b7d155', 'draft', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (3, 'div-2', 'Div 2', NULL, 1, 'all', 3, 'b112efae-15c5-425b-882d-881250b8a810', 'draft', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (46, 'div-1', 'Div 1', '', 1, 'all', 2, '6ca412fc-e599-4756-97ac-1beb63b3a457', 'draft', '2025-03-13 14:09:58.45097');
INSERT INTO league_management.divisions VALUES (43, 'div-2', 'Div 2', '', 2, 'all', 20, '72a54bf1-5ded-4cc2-931a-04fedd8d8ba4', 'archived', '2025-03-07 16:54:39.075851');
INSERT INTO league_management.divisions VALUES (42, 'div-1', 'Div 1', '', 1, 'all', 20, '04a842e9-d15c-451d-87c4-aa40f38171b3', 'archived', '2025-03-07 16:37:01.129257');
INSERT INTO league_management.divisions VALUES (45, 'div-2', 'Div 2', '', 2, 'all', 21, '09010cbc-a1ec-46c3-a22b-0ed043832ae9', 'archived', '2025-03-07 16:55:12.639766');
INSERT INTO league_management.divisions VALUES (44, 'div-1', 'Div 1', '', 1, 'all', 21, 'd7b095cf-1382-4a93-bf6e-fbb9bce34f04', 'archived', '2025-03-07 16:55:01.867378');
INSERT INTO league_management.divisions VALUES (47, 'div-1', 'Div 1', '', 1, 'all', 22, 'f89983eb-418e-4aa5-a370-e84f4b5891d8', 'locked', '2025-03-14 15:14:28.241231');
INSERT INTO league_management.divisions VALUES (4, 'div-1', 'Div 1', 'A great division with a much lengthier description specifically describing who this is for.', 1, 'all', 4, 'join-use-in-div-1', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.divisions VALUES (48, 'div-1', 'Div 1', '', 1, 'all', 23, 'c50b980e-4e64-41b7-9c21-c365cc7a97a0', 'public', '2025-03-21 17:17:57.814953');


--
-- TOC entry 3669 (class 0 OID 77659)
-- Dependencies: 230
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
INSERT INTO league_management.games VALUES (31, 1, 1, 2, 4, 1, NULL, '2025-01-23 19:00:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (35, 1, 4, 4, 0, 1, NULL, '2025-02-05 22:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (33, 3, 0, 1, 4, 1, NULL, '2025-01-26 21:45:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (36, 2, 1, 3, 1, 1, NULL, '2025-02-05 23:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (41, 1, 0, 4, 0, 1, NULL, '2025-03-03 18:30:00', 10, 'public', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (42, 2, 0, 3, 0, 1, NULL, '2025-03-03 19:30:00', 10, 'public', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (50, 6, 1, 2, 3, 4, NULL, '2025-02-07 20:30:00', 12, 'completed', true, '2025-01-31 16:15:00.936068');
INSERT INTO league_management.games VALUES (46, 7, 1, 8, 4, 4, NULL, '2025-01-29 21:00:00', 13, 'completed', true, '2025-01-31 12:47:08.939324');
INSERT INTO league_management.games VALUES (47, 9, 1, 5, 3, 4, NULL, '2025-01-30 20:45:00', 11, 'completed', true, '2025-01-31 13:38:51.595059');
INSERT INTO league_management.games VALUES (43, 5, 3, 6, 4, 4, NULL, '2025-01-28 21:30:00', 17, 'completed', true, '2025-01-29 18:20:39.803043');
INSERT INTO league_management.games VALUES (48, 6, 3, 8, 1, 4, NULL, '2025-01-31 22:00:00', 17, 'completed', true, '2025-01-31 14:22:31.627166');
INSERT INTO league_management.games VALUES (34, 4, 3, 2, 1, 1, NULL, '2025-01-26 22:45:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (49, 5, 1, 2, 2, 4, NULL, '2025-01-20 21:30:00', 17, 'completed', false, '2025-01-31 16:12:44.553138');
INSERT INTO league_management.games VALUES (54, 35, 3, 13, 0, 11, NULL, '2025-02-26 21:30:00', 17, 'completed', true, '2025-02-12 02:29:21.131088');
INSERT INTO league_management.games VALUES (51, 15, 4, 35, 3, 5, NULL, '2025-02-12 20:30:00', 17, 'completed', true, '2025-02-11 21:35:36.789921');
INSERT INTO league_management.games VALUES (63, 17, 0, 41, 0, 33, NULL, '2025-02-28 19:00:00', 33, 'public', false, '2025-02-27 20:13:54.92646');
INSERT INTO league_management.games VALUES (64, 39, 0, 40, 0, 33, NULL, '2025-02-28 20:00:00', 33, 'public', false, '2025-02-27 20:14:17.553713');
INSERT INTO league_management.games VALUES (59, 3, 3, 4, 2, 1, NULL, '2025-02-22 12:00:00', 10, 'archived', true, '2025-02-20 16:18:41.234831');
INSERT INTO league_management.games VALUES (68, 16, 0, 33, 0, 37, NULL, '2025-03-07 21:45:00', 13, 'public', false, '2025-03-04 16:46:15.622146');
INSERT INTO league_management.games VALUES (39, 1, 3, 2, 2, 1, NULL, '2025-02-23 19:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (55, 5, 0, 7, 0, 4, NULL, '2025-02-21 15:00:00', 17, 'cancelled', false, '2025-02-19 19:44:48.640278');
INSERT INTO league_management.games VALUES (52, 5, 3, 6, 2, 4, NULL, '2025-02-13 20:45:00', 12, 'completed', true, '2025-02-11 21:36:18.23309');
INSERT INTO league_management.games VALUES (28, 2, 7, 3, 2, 1, NULL, '2025-01-02 21:30:00', 10, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (38, 4, 0, 2, 5, 1, NULL, '2025-02-14 23:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (66, 41, 3, 40, 0, 33, NULL, '2025-02-21 22:00:00', 31, 'completed', true, '2025-02-27 20:17:19.420527');
INSERT INTO league_management.games VALUES (40, 3, 1, 4, 1, 1, NULL, '2025-02-23 20:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (70, 1, 0, 3, 0, 1, NULL, '2025-03-24 20:00:00', 9, 'public', false, '2025-03-21 17:14:53.881417');
INSERT INTO league_management.games VALUES (37, 3, 3, 1, 1, 1, NULL, '2025-02-14 22:00:00', 9, 'completed', true, '2025-01-28 15:35:00.023976');
INSERT INTO league_management.games VALUES (58, 28, 0, 6, 0, 4, NULL, '2025-02-22 12:15:00', 17, 'draft', false, '2025-02-20 16:14:10.568415');
INSERT INTO league_management.games VALUES (71, 4, 0, 2, 0, 1, NULL, '2025-03-24 19:00:00', 9, 'public', false, '2025-03-21 17:15:32.439078');
INSERT INTO league_management.games VALUES (60, 28, 0, 5, 0, 4, NULL, '2025-02-26 21:30:00', 12, 'public', false, '2025-02-24 18:50:21.292277');
INSERT INTO league_management.games VALUES (62, 2, 0, 5, 1, 11, NULL, '2025-02-24 15:00:00', 17, 'public', true, '2025-02-24 20:50:45.433259');
INSERT INTO league_management.games VALUES (65, 17, 3, 39, 3, 33, NULL, '2025-02-21 21:00:00', 31, 'completed', true, '2025-02-27 20:16:23.950596');
INSERT INTO league_management.games VALUES (67, 28, 0, 8, 0, 4, NULL, '2025-03-07 20:30:00', 41, 'draft', false, '2025-03-04 16:30:13.362662');
INSERT INTO league_management.games VALUES (69, 21, 0, 34, 0, 37, NULL, '2025-03-07 22:45:00', 13, 'public', true, '2025-03-04 16:46:44.520169');


--
-- TOC entry 3671 (class 0 OID 77669)
-- Dependencies: 232
-- Data for Name: league_admins; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.league_admins VALUES (1, 1, 1, 5, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_admins VALUES (2, 1, 1, 10, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_admins VALUES (4, 1, 2, 4, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_admins VALUES (5, 1, 3, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_admins VALUES (6, 2, 1, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_admins VALUES (38, 1, 23, 118, '2025-03-12 14:39:00.776687');
INSERT INTO league_management.league_admins VALUES (41, 1, 26, 1, '2025-03-12 21:26:48.705381');
INSERT INTO league_management.league_admins VALUES (42, 1, 27, 1, '2025-03-21 17:17:06.967239');
INSERT INTO league_management.league_admins VALUES (3, 2, 1, 11, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_admins VALUES (31, 1, 17, 116, '2025-02-27 19:14:12.48337');
INSERT INTO league_management.league_admins VALUES (36, 1, 22, 1, '2025-03-07 16:36:17.221919');
INSERT INTO league_management.league_admins VALUES (37, 2, 22, 118, '2025-03-10 18:34:47.56097');


--
-- TOC entry 3673 (class 0 OID 77674)
-- Dependencies: 234
-- Data for Name: league_venues; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.league_venues VALUES (1, 5, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_venues VALUES (2, 7, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_venues VALUES (3, 6, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_venues VALUES (4, 10, 3, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.league_venues VALUES (8, 19, 17, '2025-02-27 20:10:58.064691');
INSERT INTO league_management.league_venues VALUES (9, 20, 17, '2025-02-27 20:10:59.342421');
INSERT INTO league_management.league_venues VALUES (17, 28, 3, '2025-03-04 15:05:08.440259');
INSERT INTO league_management.league_venues VALUES (18, 29, 3, '2025-03-04 16:29:34.22512');
INSERT INTO league_management.league_venues VALUES (19, 30, 17, '2025-03-05 16:38:53.552218');


--
-- TOC entry 3675 (class 0 OID 77679)
-- Dependencies: 236
-- Data for Name: leagues; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.leagues VALUES (1, 'ottawa-pride-hockey', 'Ottawa Pride Hockey', NULL, 'hockey', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.leagues VALUES (17, 'full-league-test', 'Full League Test', 'A great league that proves it all works hopefully.', 'hockey', 'public', '2025-02-27 19:14:12.470045');
INSERT INTO league_management.leagues VALUES (3, 'hometown-hockey', 'Hometown Hockey', 'Let''s play some hockey!', 'hockey', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.leagues VALUES (2, 'fia-hockey', 'FIA Hockey', '', 'hockey', 'draft', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.leagues VALUES (26, 'soccer-league', 'Soccer League', 'A fun soccer league.', 'soccer', 'draft', '2025-03-12 21:26:48.701595');
INSERT INTO league_management.leagues VALUES (22, 'cool-league', 'Cool League', '', 'hockey', 'archived', '2025-03-07 16:36:17.218225');
INSERT INTO league_management.leagues VALUES (23, 'can-i-league', 'Can I League', '', 'hockey', 'locked', '2025-03-12 14:39:00.758127');
INSERT INTO league_management.leagues VALUES (27, 'phone-made', 'Phone Made', '', 'hockey', 'public', '2025-03-21 17:17:06.956602');


--
-- TOC entry 3677 (class 0 OID 77688)
-- Dependencies: 238
-- Data for Name: playoffs; Type: TABLE DATA; Schema: league_management; Owner: postgres
--



--
-- TOC entry 3679 (class 0 OID 77699)
-- Dependencies: 240
-- Data for Name: season_admins; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.season_admins VALUES (1, 1, 3, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.season_admins VALUES (2, 1, 4, 3, '2025-02-10 22:27:41.682766');


--
-- TOC entry 3681 (class 0 OID 77704)
-- Dependencies: 242
-- Data for Name: seasons; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.seasons VALUES (1, 'winter-20242025', 'Winter 2024/2025', NULL, 1, '2024-09-01', '2025-03-31', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.seasons VALUES (5, '2025-spring', '2025 Spring', NULL, 3, '2025-04-01', '2025-06-30', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.seasons VALUES (4, '2024-2025-season', '2024-2025 Season', 'A great season!', 3, '2024-09-01', '2025-03-31', 'public', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.seasons VALUES (12, 'test', 'Test', 'A great test', 1, '2025-04-01', '2025-08-31', 'draft', '2025-02-19 18:41:37.098992');
INSERT INTO league_management.seasons VALUES (14, 'spring-2025', 'Spring 2025', '', 17, '2025-04-01', '2025-06-30', 'public', '2025-02-27 19:15:17.527095');
INSERT INTO league_management.seasons VALUES (2, '2023-2024-season', '2023-2024 Season', NULL, 2, '2023-09-01', '2024-03-31', 'draft', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.seasons VALUES (3, '2024-2025-season', '2024-2025 Season', NULL, 2, '2024-09-01', '2025-03-31', 'draft', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.seasons VALUES (20, 'spring-2025', 'Spring 2025', '', 22, '2025-04-01', '2025-05-31', 'archived', '2025-03-07 16:36:40.704417');
INSERT INTO league_management.seasons VALUES (21, 'summer-2025', 'Summer 2025', '', 22, '2025-07-01', '2025-09-30', 'archived', '2025-03-07 16:54:13.62301');
INSERT INTO league_management.seasons VALUES (22, 'summer-2025', 'Summer 2025', '', 23, '2025-06-01', '2025-08-31', 'locked', '2025-03-14 15:14:20.518101');
INSERT INTO league_management.seasons VALUES (23, 'spring-2025', 'Spring 2025', '', 27, '2025-04-01', '2025-06-30', 'public', '2025-03-21 17:17:37.770629');


--
-- TOC entry 3683 (class 0 OID 77713)
-- Dependencies: 244
-- Data for Name: team_memberships; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.team_memberships VALUES (1, 6, 1, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (2, 7, 1, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (3, 10, 2, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (4, 3, 2, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (5, 8, 3, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (6, 11, 3, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (7, 9, 4, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (8, 5, 4, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (9, 15, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (10, 16, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (11, 17, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (12, 18, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (13, 19, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (14, 20, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (15, 21, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (16, 22, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (17, 23, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (18, 24, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (19, 25, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (20, 26, 1, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (21, 27, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (22, 28, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (23, 29, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (24, 30, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (25, 31, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (26, 32, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (27, 33, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (28, 34, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (29, 35, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (30, 36, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (31, 37, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (32, 38, 2, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (33, 39, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (34, 40, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (35, 41, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (36, 42, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (37, 43, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (38, 44, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (39, 45, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (40, 46, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (41, 47, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (42, 48, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (43, 49, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (44, 50, 3, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (45, 51, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (46, 52, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (47, 53, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (48, 54, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (49, 55, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (50, 56, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (51, 57, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (52, 58, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (53, 59, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (54, 60, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (55, 61, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (56, 62, 4, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (57, 1, 5, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (58, 12, 6, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (59, 13, 7, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (60, 4, 8, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (61, 14, 9, 1, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (62, 60, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (63, 61, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (64, 62, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (65, 63, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (66, 64, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (67, 65, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (68, 66, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (69, 67, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (70, 68, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (71, 69, 5, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (72, 70, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (73, 71, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (74, 72, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (75, 73, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (76, 74, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (77, 75, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (78, 76, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (79, 77, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (80, 78, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (81, 79, 6, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (82, 80, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (83, 81, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (84, 82, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (85, 83, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (86, 84, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (87, 85, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (88, 86, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (89, 87, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (90, 88, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (91, 89, 7, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (92, 90, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (93, 91, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (94, 92, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (95, 93, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (96, 94, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (97, 95, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (98, 96, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (99, 97, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (100, 98, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (101, 99, 8, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (102, 100, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (103, 101, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (104, 102, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (105, 103, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (106, 104, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (107, 105, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (108, 106, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (109, 107, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (110, 108, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (111, 109, 9, 2, '2025-02-10 22:27:41.682766');
INSERT INTO league_management.team_memberships VALUES (112, 1, 35, 1, '2025-02-11 17:14:31.681891');
INSERT INTO league_management.team_memberships VALUES (115, 117, 15, 1, '2025-02-12 02:14:24.724896');
INSERT INTO league_management.team_memberships VALUES (116, 117, 13, 2, '2025-02-12 02:28:30.89557');
INSERT INTO league_management.team_memberships VALUES (114, 1, 17, 1, '2025-02-11 21:30:45.188603');
INSERT INTO league_management.team_memberships VALUES (127, 116, 39, 1, '2025-02-27 19:21:22.866381');
INSERT INTO league_management.team_memberships VALUES (128, 120, 40, 1, '2025-02-27 19:45:18.330045');
INSERT INTO league_management.team_memberships VALUES (129, 121, 41, 1, '2025-02-27 19:52:05.24703');
INSERT INTO league_management.team_memberships VALUES (130, 20, 17, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (131, 21, 17, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (132, 22, 17, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (133, 23, 17, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (134, 24, 17, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (135, 25, 17, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (136, 26, 17, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (137, 27, 17, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (138, 28, 17, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (139, 29, 17, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (140, 30, 17, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (123, 117, 5, 1, '2025-02-24 23:04:59.286052');
INSERT INTO league_management.team_memberships VALUES (113, 116, 35, 1, '2025-02-11 21:02:37.728242');
INSERT INTO league_management.team_memberships VALUES (141, 31, 17, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (142, 32, 17, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (143, 33, 17, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (144, 34, 39, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (145, 35, 39, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (146, 36, 39, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (147, 37, 39, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (148, 38, 39, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (149, 39, 39, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (150, 40, 39, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (151, 41, 39, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (152, 42, 39, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (153, 43, 39, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (154, 44, 39, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (155, 45, 40, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (156, 46, 40, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (157, 47, 40, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (158, 48, 40, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (159, 49, 40, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (160, 50, 40, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (161, 51, 40, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (162, 52, 40, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (163, 53, 40, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (164, 54, 40, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (165, 55, 40, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (166, 56, 40, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (167, 57, 40, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (168, 58, 40, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (169, 59, 40, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (170, 60, 41, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (171, 61, 41, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (172, 62, 41, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (173, 63, 41, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (174, 64, 41, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (175, 65, 41, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (176, 66, 41, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (177, 67, 41, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (178, 68, 41, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (179, 69, 41, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (180, 70, 41, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (181, 71, 41, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (182, 72, 41, 2, '2025-02-27 19:57:57.609182');
INSERT INTO league_management.team_memberships VALUES (183, 1, 10, 1, '2025-03-05 17:04:28.746666');
INSERT INTO league_management.team_memberships VALUES (184, 116, 19, 2, '2025-03-05 17:09:24.624157');


--
-- TOC entry 3685 (class 0 OID 77719)
-- Dependencies: 246
-- Data for Name: teams; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.teams VALUES (1, 'significant-otters', 'Significant Otters', NULL, '#942f2f', '42773d4b-a0db-45a5-b6e7-4ed0352a3a32', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (3, 'otter-chaos', 'Otter Chaos', NULL, '#2f945b', '6e1bec03-dc19-45cc-949d-9510b0132208', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (4, 'otter-nonsense', 'Otter Nonsense', NULL, '#2f3794', '55020d20-4bb8-4b07-a0f5-314431e1013f', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (5, 'frostbiters', 'Frostbiters', 'An icy team known for their chilling defense.', 'green', '40b541f0-6692-4c33-be1e-91fd2d0cd6d1', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (6, 'blazing-blizzards', 'Blazing Blizzards', 'A team that combines fiery offense with frosty precision.', 'purple', 'bfb64227-22c0-4a8f-9a40-7351dad6c63a', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (7, 'polar-puckers', 'Polar Puckers', 'Masters of the north, specializing in swift plays.', '#285fa2', '4a8f8471-9d19-4c48-bc56-022f9f0594f1', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (8, 'arctic-avengers', 'Arctic Avengers', 'A cold-blooded team with a knack for thrilling comebacks.', 'yellow', '72b0b271-3e6c-476b-8de4-7980577f9d72', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (9, 'glacial-guardians', 'Glacial Guardians', 'Defensive titans who freeze their opponents in their tracks.', 'pink', 'ab1c8fb0-8fe6-4c1b-ad44-6a0294e2068d', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (10, 'tundra-titans', 'Tundra Titans', 'A powerhouse team dominating the ice with strength and speed.', 'orange', '10a02058-bc90-4f5e-a8bb-58935074119d', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (11, 'permafrost-predators', 'Permafrost Predators', 'Known for their unrelenting pressure and icy precision.', '#bc83d4', 'a35d0e62-6e45-4cbf-9131-6b8bef866a65', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (12, 'snowstorm-scorchers', 'Snowstorm Scorchers', 'A team with a fiery spirit and unstoppable energy.', 'rebeccapurple', '2711261e-bf6f-4743-883f-583df10a8633', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (13, 'frozen-flames', 'Frozen Flames', 'Bringing the heat to the ice with blazing fast attacks.', 'cyan', 'ce6ee21f-dd90-4496-b0cf-5ad2feb01008', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (15, 'shadow-panthers', 'Shadow Panthers', 'A fierce team known for their unpredictable playstyle.', '#222222', 'b6c202f3-bd0a-4412-8f36-2ba04a0b09a5', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (16, 'crimson-vipers', 'Crimson Vipers', 'Fast and aggressive with deadly precision.', '#B22222', '59611bcf-40a1-47b3-a2b0-3abaa0642c14', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (18, 'thunder-hawks', 'Thunder Hawks', 'A high-energy team that dominates the rink.', '#8B0000', 'ed487c64-f246-483e-bdd3-37a45c7daff1', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (19, 'emerald-guardians', 'Emerald Guardians', 'A defensive powerhouse with an unbreakable strategy.', '#228B22', '45c16776-2b6f-4799-9118-6443fd091ef6', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (20, 'steel-titans', 'Steel Titans', 'Strong, resilient, and impossible to shake.', '#708090', 'd6bf0119-8553-4174-b919-1f2f5963021f', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (21, 'phoenix-fire', 'Phoenix Fire', 'Rises to the occasion in clutch moments.', '#FF4500', '520e9bfb-0dc4-437e-9d18-ba0c8362bab6', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (22, 'iron-wolves', 'Iron Wolves', 'A relentless team that never backs down.', '#2F4F4F', '33a6c42e-a819-4196-bdf9-1dbf05973f1f', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (23, 'midnight-reapers', 'Midnight Reapers', 'Lethal in the final minutes of every game.', '#4B0082', '147ac64b-e0b6-489f-9cc3-44f8a2177ebe', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (25, 'scarlet-blades', 'Scarlet Blades', 'Masters of precision passing and quick attacks.', '#DC143C', '2598f426-f3a9-491c-b897-3b9ae351404a', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (26, 'cobalt-chargers', 'Cobalt Chargers', 'Unstoppable speed and offensive firepower.', '#4169E1', '55b2026a-b69d-4dda-a508-d0fcc54c3ba2', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (27, 'onyx-predators', 'Onyx Predators', 'A physically dominant team that wears down opponents.', '#000000', '1b943fc9-f5fc-4c66-a5df-7547edb073f9', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (28, 'amber-raptors', 'Amber Raptors', 'Fast and unpredictable, known for creative plays.', '#FF8C00', 'b1cdaad7-b17a-4a07-9adf-5cbf3ea58292', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (29, 'silver-foxes', 'Silver Foxes', 'A veteran team with discipline and experience.', '#C0C0C0', 'cb65e419-d79a-4dbf-b89a-eb45b3db0e95', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (30, 'voltage-kings', 'Voltage Kings', 'Electrifying speed and a lightning-fast transition game.', '#FFFF00', '0ecb2e43-bf74-4fb1-b1f2-0aba58a83e33', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (31, 'obsidian-warriors', 'Obsidian Warriors', 'A tough and resilient team that grinds out wins.', '#1C1C1C', 'fa9df39d-3912-4d77-9672-af586571c4f5', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (32, 'titanium-blizzards', 'Titanium Blizzards', 'A well-balanced team with elite skill.', '#D3D3D3', '1ea4d2de-9727-4a0d-bb29-66c5047ed5ce', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (33, 'ruby-thunder', 'Ruby Thunder', 'A powerhouse with a thunderous offensive presence.', '#8B0000', 'a3cbfc64-6dee-49d0-a524-30df8303e540', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (34, 'sapphire-storm', 'Sapphire Storm', 'A dynamic team known for their speed and agility.', '#0000FF', '20e8872f-ed17-4429-ab07-1eaff7b99946', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (35, 'metcalfe-jets', 'Metcalfe Jets', 'A small town team.', '#3bb55f', '68004b56-9db1-475b-8e4a-2234daad0d71', 'active', '2025-02-11 17:14:31.669097');
INSERT INTO league_management.teams VALUES (17, 'golden-stingers', 'Golden Stingers', 'Masters of quick strikes and counterattacks.', '#FFD700', '532c12c8-74dd-4305-a597-2f6b0a670478', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (39, 'old-pirates', 'Old Pirates', 'We old', 'black', 'af235a0d-ef7a-4d9e-bbac-19a9e33fb254', 'active', '2025-02-27 19:21:22.85877');
INSERT INTO league_management.teams VALUES (40, 'the-cheaters', 'The Cheaters', '', 'blue', '41be063b-a602-45ea-97e2-a8f6260fc64e', 'active', '2025-02-27 19:45:18.325997');
INSERT INTO league_management.teams VALUES (41, 'grugs-n-co', 'Grugs ''n Co', 'The Grugiest out there!', '#a469bf', '4e333d5d-58b5-42dd-8ea6-81304a975501', 'active', '2025-02-27 19:52:05.242458');
INSERT INTO league_management.teams VALUES (24, 'neon-strikers', 'Neon Strikers', 'A high-scoring team with flashy plays.', '#00FF7F', '21634835-c743-4df8-8be8-7cc7df8cf5fe', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (2, 'otterwa-senators', 'Otterwa Senators', '', 'purple', '3a84f69c-abf2-4a93-85ee-94687ad0c1f3', 'active', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.teams VALUES (14, 'chill-crushers', 'Chill Crushers', 'Breaking the ice with powerful plays and intense rivalries.', 'lime', 'd980236e-931e-41db-a7e6-2303fc03c2b0', 'active', '2025-02-10 22:27:41.682766');


--
-- TOC entry 3687 (class 0 OID 77729)
-- Dependencies: 248
-- Data for Name: venues; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

INSERT INTO league_management.venues VALUES (1, 'canadian-tire-centre', 'Canadian Tire Centre', 'Home of the NHL''s Ottawa Senators, this state-of-the-art entertainment facility seats 19,153 spectators.', '1000 Palladium Dr, Ottawa, ON K2V 1A5', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues VALUES (2, 'bell-sensplex', 'Bell Sensplex', 'A multi-purpose sports facility featuring four NHL-sized ice rinks, including an Olympic-sized rink, operated by Capital Sports Management.', '1565 Maple Grove Rd, Ottawa, ON K2V 1A3', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues VALUES (3, 'td-place-arena', 'TD Place Arena', 'An indoor arena located at Lansdowne Park, hosting the Ottawa 67''s (OHL) and Ottawa Blackjacks (CEBL), with a seating capacity of up to 8,585.', '1015 Bank St, Ottawa, ON K1S 3W7', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues VALUES (4, 'minto-sports-complex-arena', 'Minto Sports Complex Arena', 'Part of the University of Ottawa, this complex contains two ice rinks, one with seating for 840 spectators, and the Draft Pub overlooking the ice.', '801 King Edward Ave, Ottawa, ON K1N 6N5', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues VALUES (5, 'carleton-university-ice-house', 'Carleton University Ice House', 'A leading indoor skating facility featuring two NHL-sized ice surfaces, home to the Carleton Ravens hockey teams.', '1125 Colonel By Dr, Ottawa, ON K1S 5B6', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues VALUES (6, 'howard-darwin-centennial-arena', 'Howard Darwin Centennial Arena', 'A community arena offering ice rentals and public skating programs, maleaged by the City of Ottawa.', '1765 Merivale Rd, Ottawa, ON K2G 1E1', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues VALUES (7, 'fred-barrett-arena', 'Fred Barrett Arena', 'A municipal arena providing ice rentals and public skating, located in the southern part of Ottawa.', '3280 Leitrim Rd, Ottawa, ON K1T 3Z4', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues VALUES (8, 'blackburn-arena', 'Blackburn Arena', 'A community arena offering skating programs and ice rentals, serving the Blackburn Hamlet area.', '200 Glen Park Dr, Gloucester, ON K1B 5A3', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues VALUES (9, 'bob-macquarrie-recreation-complex-orlans-arena', 'Bob MacQuarrie Recreation Complex – Orléans Arena', 'A recreation complex featuring an arena, pool, and fitness facilities, serving the Orléans community.', '1490 Youville Dr, Orléans, ON K1C 2X8', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues VALUES (10, 'brewer-arena', 'Brewer Arena', 'A municipal arena adjacent to Brewer Park, offering public skating and ice rentals.', '200 Hopewell Ave, Ottawa, ON K1S 2Z5', '2025-02-10 22:27:41.682766');
INSERT INTO league_management.venues VALUES (17, 'stuart-holmes-arena', 'Stuart Holmes Arena', 'Osgoode Community Centre and Stuart Holmes Arena', '5660 Osgoode Main St, Osgoode, ON K0A 2W0', '2025-02-26 19:38:00.932484');
INSERT INTO league_management.venues VALUES (18, 'larry-robinson-arena', 'Larry Robinson Arena', 'Metcalfe Community Centre and Larry Robinson Arena', '2785 8th Line Rd, Metcalfe, ON K0A 2P0', '2025-02-26 19:39:15.098359');
INSERT INTO league_management.venues VALUES (19, 'tom-brown-arena', 'Tom Brown Arena', 'A great arena in the heart of Hintonburg close to Bayview station.', '141 Bayview Station Rd, Ottawa, ON K1Y 4T1', '2025-02-27 20:10:58.060331');
INSERT INTO league_management.venues VALUES (20, 'tom-brown-arena-1', 'Tom Brown Arena', 'A great arena in the heart of Hintonburg close to Bayview station.', '141 Bayview Station Rd, Ottawa, ON K1Y 4T1', '2025-02-27 20:10:59.338935');
INSERT INTO league_management.venues VALUES (21, 'tom-brown-arena-2', 'Tom Brown Arena', 'A great arena in the heart of Hintonburg close to Bayview station.', '141 Bayview Station Rd, Ottawa, ON K1Y 4T1', '2025-02-27 20:11:03.495084');
INSERT INTO league_management.venues VALUES (22, 'tom-brown-arena-3', 'Tom Brown Arena', 'A great arena near Bayview Station', '141 Bayview Station Rd, Ottawa, ON K1Y 4T1', '2025-02-27 20:11:34.069334');
INSERT INTO league_management.venues VALUES (23, 'nepean-sportsplex', 'Nepean Sportsplex', 'A three rink facility also featuring many other sports.', '1701 Woodroffe Ave, Nepean, ON K2G 1W2', '2025-02-27 20:13:14.34994');
INSERT INTO league_management.venues VALUES (28, 'ray-friel-recreation-complex', 'Ray Friel Recreation Complex', NULL, '1585 Tenth Line Rd, Orléans, ON K1E 3E8', '2025-03-04 15:05:08.432248');
INSERT INTO league_management.venues VALUES (29, 'minto-recreation-complex-barrhaven', 'Minto Recreation Complex - Barrhaven', NULL, '3500 Cambrian Rd, Nepean, ON K2J 0E9', '2025-03-04 16:29:34.217502');
INSERT INTO league_management.venues VALUES (30, 'tom-brown-arena-4', 'Tom Brown Arena', NULL, '141 Bayview Station Rd, Ottawa, ON K1Y 4T1', '2025-03-05 16:38:53.545391');


--
-- TOC entry 3689 (class 0 OID 77736)
-- Dependencies: 250
-- Data for Name: assists; Type: TABLE DATA; Schema: stats; Owner: postgres
--

INSERT INTO stats.assists VALUES (1, 1, 31, 33, 2, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.assists VALUES (2, 1, 31, 32, 2, false, '2025-01-28 15:35:00.023976');
INSERT INTO stats.assists VALUES (3, 2, 31, 3, 2, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.assists VALUES (4, 3, 31, 16, 1, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.assists VALUES (5, 4, 31, 32, 2, true, '2025-01-28 15:35:00.023976');
INSERT INTO stats.assists VALUES (28, 31, 33, 7, 1, true, '2025-01-28 22:12:20.844298');
INSERT INTO stats.assists VALUES (29, 32, 33, 22, 1, true, '2025-01-28 22:22:01.452293');
INSERT INTO stats.assists VALUES (30, 34, 33, 6, 1, true, '2025-01-28 22:26:59.666412');
INSERT INTO stats.assists VALUES (33, 37, 33, 25, 1, true, '2025-01-28 22:28:27.851364');
INSERT INTO stats.assists VALUES (46, 55, 43, 61, 5, true, '2025-01-29 18:21:40.518237');
INSERT INTO stats.assists VALUES (51, 60, 28, 35, 2, true, '2025-01-29 21:15:30.875789');
INSERT INTO stats.assists VALUES (52, 61, 28, 3, 2, true, '2025-01-29 21:15:51.821809');
INSERT INTO stats.assists VALUES (53, 62, 28, 43, 3, true, '2025-01-29 21:16:33.021139');
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
INSERT INTO stats.assists VALUES (89, 95, 50, 37, 2, true, '2025-02-11 16:18:42.893918');
INSERT INTO stats.assists VALUES (90, 98, 36, 45, 3, true, '2025-02-11 17:16:39.326494');
INSERT INTO stats.assists VALUES (91, 101, 51, 1, 35, true, '2025-02-12 02:15:18.804293');
INSERT INTO stats.assists VALUES (92, 103, 54, 1, 35, true, '2025-02-12 02:33:55.52354');
INSERT INTO stats.assists VALUES (94, 111, 50, 33, 2, true, '2025-02-14 18:05:10.928176');
INSERT INTO stats.assists VALUES (95, 111, 50, 30, 2, false, '2025-02-14 18:05:10.929672');
INSERT INTO stats.assists VALUES (96, 113, 52, 63, 5, true, '2025-02-17 21:18:06.699663');
INSERT INTO stats.assists VALUES (97, 114, 52, 12, 6, true, '2025-02-17 21:18:48.682257');
INSERT INTO stats.assists VALUES (98, 116, 52, 1, 5, true, '2025-02-17 21:19:19.801104');
INSERT INTO stats.assists VALUES (100, 118, 38, 38, 2, true, '2025-02-20 00:25:37.087884');
INSERT INTO stats.assists VALUES (101, 120, 38, 33, 2, true, '2025-02-20 15:16:33.959967');
INSERT INTO stats.assists VALUES (102, 120, 38, 36, 2, false, '2025-02-20 15:16:33.961699');
INSERT INTO stats.assists VALUES (103, 121, 38, 37, 2, true, '2025-02-20 15:18:05.38192');
INSERT INTO stats.assists VALUES (104, 121, 38, 3, 2, false, '2025-02-20 15:18:05.383739');
INSERT INTO stats.assists VALUES (105, 122, 38, 33, 2, true, '2025-02-20 15:21:11.089281');
INSERT INTO stats.assists VALUES (106, 124, 37, 18, 1, true, '2025-02-20 15:22:39.001118');
INSERT INTO stats.assists VALUES (107, 125, 37, 41, 3, true, '2025-02-20 15:23:22.150926');
INSERT INTO stats.assists VALUES (108, 126, 37, 11, 3, true, '2025-02-20 15:24:02.323941');
INSERT INTO stats.assists VALUES (109, 126, 37, 48, 3, false, '2025-02-20 15:24:02.325659');
INSERT INTO stats.assists VALUES (110, 127, 28, 10, 2, true, '2025-02-21 16:22:33.444665');
INSERT INTO stats.assists VALUES (111, 128, 28, 10, 2, true, '2025-02-21 16:23:22.293324');
INSERT INTO stats.assists VALUES (112, 128, 28, 27, 2, false, '2025-02-21 16:23:22.294799');
INSERT INTO stats.assists VALUES (113, 129, 28, 8, 3, true, '2025-02-21 18:32:41.828068');
INSERT INTO stats.assists VALUES (117, 133, 66, 121, 41, true, '2025-02-27 20:20:40.943285');
INSERT INTO stats.assists VALUES (120, 136, 66, 121, 41, true, '2025-02-27 20:22:23.341795');
INSERT INTO stats.assists VALUES (121, 137, 66, 66, 41, true, '2025-02-27 20:23:04.019619');
INSERT INTO stats.assists VALUES (122, 138, 65, 36, 39, true, '2025-02-27 20:42:22.524556');
INSERT INTO stats.assists VALUES (123, 139, 65, 36, 39, true, '2025-02-27 20:42:55.382342');
INSERT INTO stats.assists VALUES (124, 140, 65, 26, 17, true, '2025-02-27 20:44:20.424963');
INSERT INTO stats.assists VALUES (125, 141, 65, 1, 17, true, '2025-02-27 20:44:53.805425');
INSERT INTO stats.assists VALUES (126, 142, 65, 32, 17, true, '2025-02-27 20:45:36.156246');
INSERT INTO stats.assists VALUES (127, 143, 65, 36, 39, true, '2025-02-27 20:45:59.058778');
INSERT INTO stats.assists VALUES (132, 150, 39, 10, 2, true, '2025-03-06 16:16:45.916189');
INSERT INTO stats.assists VALUES (133, 151, 39, 7, 1, true, '2025-03-06 16:25:14.578861');
INSERT INTO stats.assists VALUES (134, 152, 39, 17, 1, true, '2025-03-06 16:28:12.596594');
INSERT INTO stats.assists VALUES (135, 153, 39, 37, 2, true, '2025-03-06 21:15:48.120487');
INSERT INTO stats.assists VALUES (136, 154, 39, 18, 1, true, '2025-03-06 21:16:10.300566');
INSERT INTO stats.assists VALUES (139, 156, 40, 5, 4, true, '2025-03-21 15:40:42.871091');
INSERT INTO stats.assists VALUES (140, 156, 40, 59, 4, false, '2025-03-21 15:40:42.872444');


--
-- TOC entry 3691 (class 0 OID 77742)
-- Dependencies: 252
-- Data for Name: goals; Type: TABLE DATA; Schema: stats; Owner: postgres
--

INSERT INTO stats.goals VALUES (1, 31, 3, 2, 1, '00:11:20', false, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.goals VALUES (2, 31, 10, 2, 1, '00:15:37', false, true, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.goals VALUES (3, 31, 6, 1, 2, '00:05:40', false, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.goals VALUES (4, 31, 3, 2, 2, '00:18:10', false, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.goals VALUES (5, 31, 28, 2, 3, '00:18:20', false, false, true, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.goals VALUES (31, 33, 6, 1, 2, '00:03:32', false, false, false, '2025-01-28 22:12:20.836554', NULL);
INSERT INTO stats.goals VALUES (32, 33, 7, 1, 2, '00:06:55', false, true, false, '2025-01-28 22:22:01.446369', NULL);
INSERT INTO stats.goals VALUES (34, 33, 20, 1, 3, '00:16:51', false, false, false, '2025-01-28 22:26:59.659856', NULL);
INSERT INTO stats.goals VALUES (37, 33, 6, 1, 3, '00:19:28', false, false, true, '2025-01-28 22:28:27.845173', NULL);
INSERT INTO stats.goals VALUES (53, 43, 1, 5, 1, '00:02:14', false, false, false, '2025-01-29 18:21:12.871841', NULL);
INSERT INTO stats.goals VALUES (54, 43, 73, 6, 1, '00:04:15', false, false, false, '2025-01-29 18:21:28.21693', NULL);
INSERT INTO stats.goals VALUES (55, 43, 1, 5, 2, '00:04:16', false, false, false, '2025-01-29 18:21:40.511549', NULL);
INSERT INTO stats.goals VALUES (58, 28, 27, 2, 1, '00:06:07', false, false, false, '2025-01-29 21:14:43.596312', NULL);
INSERT INTO stats.goals VALUES (60, 28, 3, 2, 1, '00:16:24', false, false, false, '2025-01-29 21:15:30.869789', NULL);
INSERT INTO stats.goals VALUES (61, 28, 10, 2, 2, '00:06:10', false, false, false, '2025-01-29 21:15:51.815019', NULL);
INSERT INTO stats.goals VALUES (62, 28, 11, 3, 2, '00:10:23', false, true, false, '2025-01-29 21:16:33.015637', NULL);
INSERT INTO stats.goals VALUES (64, 28, 32, 2, 3, '00:12:56', false, false, false, '2025-01-29 21:17:20.723557', NULL);
INSERT INTO stats.goals VALUES (65, 28, 10, 2, 3, '00:17:17', false, false, false, '2025-01-29 21:18:11.700948', NULL);
INSERT INTO stats.goals VALUES (66, 34, 10, 2, 3, '00:19:50', false, false, false, '2025-01-30 19:29:25.056506', NULL);
INSERT INTO stats.goals VALUES (70, 46, 94, 8, 1, '00:03:12', false, false, false, '2025-01-31 12:48:22.153813', NULL);
INSERT INTO stats.goals VALUES (71, 46, 13, 7, 1, '00:03:13', false, false, false, '2025-01-31 12:48:49.317687', NULL);
INSERT INTO stats.goals VALUES (72, 46, 4, 8, 1, '00:07:19', false, false, false, '2025-01-31 12:49:13.94251', NULL);
INSERT INTO stats.goals VALUES (73, 46, 93, 8, 2, '00:11:20', false, false, false, '2025-01-31 12:49:39.53854', NULL);
INSERT INTO stats.goals VALUES (74, 46, 4, 8, 3, '00:16:21', false, false, false, '2025-01-31 12:49:58.803182', NULL);
INSERT INTO stats.goals VALUES (75, 47, 1, 5, 1, '00:09:00', false, false, false, '2025-01-31 13:49:17.005933', NULL);
INSERT INTO stats.goals VALUES (76, 47, 1, 5, 1, '00:13:17', false, true, false, '2025-01-31 13:50:09.7489', NULL);
INSERT INTO stats.goals VALUES (77, 47, 14, 9, 2, '00:08:13', false, false, false, '2025-01-31 14:04:31.827789', NULL);
INSERT INTO stats.goals VALUES (78, 47, 68, 5, 3, '00:18:56', false, false, true, '2025-01-31 14:04:53.654327', NULL);
INSERT INTO stats.goals VALUES (79, 43, 12, 6, 2, '00:10:24', false, false, false, '2025-01-31 14:06:18.15422', NULL);
INSERT INTO stats.goals VALUES (80, 43, 12, 6, 3, '00:14:25', false, false, false, '2025-01-31 14:09:45.226699', NULL);
INSERT INTO stats.goals VALUES (82, 43, 63, 5, 3, '00:19:23', false, false, false, '2025-01-31 14:11:04.925064', NULL);
INSERT INTO stats.goals VALUES (83, 43, 74, 6, 3, '00:19:44', false, false, false, '2025-01-31 14:14:42.804546', NULL);
INSERT INTO stats.goals VALUES (84, 48, 4, 8, 1, '00:10:00', false, false, false, '2025-01-31 14:22:50.332613', NULL);
INSERT INTO stats.goals VALUES (85, 48, 12, 6, 1, '00:15:00', false, false, false, '2025-01-31 14:23:05.013364', NULL);
INSERT INTO stats.goals VALUES (86, 48, 12, 6, 2, '00:07:00', false, false, false, '2025-01-31 14:23:28.606041', NULL);
INSERT INTO stats.goals VALUES (87, 48, 12, 6, 3, '00:13:06', false, false, false, '2025-01-31 14:24:19.139733', NULL);
INSERT INTO stats.goals VALUES (88, 34, 9, 4, 1, '00:19:51', false, false, false, '2025-01-31 14:51:01.641769', NULL);
INSERT INTO stats.goals VALUES (89, 34, 5, 4, 2, '00:06:38', false, true, false, '2025-01-31 14:51:58.867463', NULL);
INSERT INTO stats.goals VALUES (90, 34, 5, 4, 3, '00:07:37', false, false, false, '2025-01-31 14:52:32.568702', NULL);
INSERT INTO stats.goals VALUES (92, 49, 10, 2, 1, '00:15:00', false, false, false, '2025-01-31 16:13:08.17596', NULL);
INSERT INTO stats.goals VALUES (93, 49, 63, 5, 2, '00:07:18', false, false, false, '2025-01-31 16:13:22.432711', NULL);
INSERT INTO stats.goals VALUES (94, 49, 3, 2, 3, '00:08:21', false, false, false, '2025-01-31 16:14:16.677822', NULL);
INSERT INTO stats.goals VALUES (95, 50, 30, 2, 1, '00:10:00', false, false, false, '2025-02-11 16:18:42.886551', NULL);
INSERT INTO stats.goals VALUES (96, 50, 29, 2, 1, '00:14:00', false, true, false, '2025-02-11 16:19:12.338693', NULL);
INSERT INTO stats.goals VALUES (97, 50, 12, 6, 3, '00:16:00', false, false, false, '2025-02-11 16:19:41.199947', NULL);
INSERT INTO stats.goals VALUES (98, 36, 47, 3, 1, '00:04:07', false, false, false, '2025-02-11 17:16:39.320918', NULL);
INSERT INTO stats.goals VALUES (99, 36, 36, 2, 1, '00:07:08', false, false, false, '2025-02-11 17:16:50.020966', NULL);
INSERT INTO stats.goals VALUES (100, 51, 1, 35, 1, '00:04:01', false, false, false, '2025-02-12 02:15:08.255402', NULL);
INSERT INTO stats.goals VALUES (101, 51, 116, 35, 3, '00:07:02', false, false, false, '2025-02-12 02:15:18.800357', NULL);
INSERT INTO stats.goals VALUES (102, 51, 1, 35, 3, '00:12:04', false, false, false, '2025-02-12 02:15:47.557999', NULL);
INSERT INTO stats.goals VALUES (103, 54, 116, 35, 1, '00:04:00', false, false, false, '2025-02-12 02:33:55.5194', NULL);
INSERT INTO stats.goals VALUES (104, 54, 1, 35, 1, '00:09:00', false, false, false, '2025-02-12 02:35:28.7082', NULL);
INSERT INTO stats.goals VALUES (105, 54, 116, 35, 3, '00:14:00', false, false, false, '2025-02-12 02:35:49.655329', NULL);
INSERT INTO stats.goals VALUES (106, 51, 117, 15, 3, '00:06:05', false, false, false, '2025-02-13 14:10:31.699027', NULL);
INSERT INTO stats.goals VALUES (107, 51, 117, 15, 2, '00:11:05', false, false, false, '2025-02-13 14:10:48.515808', NULL);
INSERT INTO stats.goals VALUES (108, 51, 117, 15, 1, '00:15:05', false, false, false, '2025-02-13 14:11:04.032675', NULL);
INSERT INTO stats.goals VALUES (109, 51, 117, 15, 3, '00:16:05', false, false, false, '2025-02-13 14:11:21.474113', NULL);
INSERT INTO stats.goals VALUES (111, 50, 37, 2, 3, '00:07:00', false, false, false, '2025-02-14 18:05:10.923627', NULL);
INSERT INTO stats.goals VALUES (112, 52, 74, 6, 1, '00:03:00', false, false, false, '2025-02-17 21:17:34.531674', NULL);
INSERT INTO stats.goals VALUES (113, 52, 68, 5, 1, '00:12:00', false, false, false, '2025-02-17 21:18:06.694639', NULL);
INSERT INTO stats.goals VALUES (114, 52, 78, 6, 2, '00:16:21', false, false, false, '2025-02-17 21:18:48.677973', NULL);
INSERT INTO stats.goals VALUES (115, 52, 1, 5, 3, '00:06:48', false, false, false, '2025-02-17 21:19:02.613872', NULL);
INSERT INTO stats.goals VALUES (116, 52, 66, 5, 3, '00:08:53', false, false, false, '2025-02-17 21:19:19.796745', NULL);
INSERT INTO stats.goals VALUES (118, 38, 3, 2, 1, '00:06:05', false, false, false, '2025-02-20 00:25:37.080964', NULL);
INSERT INTO stats.goals VALUES (119, 38, 32, 2, 1, '00:18:12', false, false, false, '2025-02-20 00:26:50.198279', NULL);
INSERT INTO stats.goals VALUES (120, 38, 38, 2, 2, '00:12:07', false, false, false, '2025-02-20 15:16:33.955691', NULL);
INSERT INTO stats.goals VALUES (121, 38, 10, 2, 3, '00:07:10', false, false, false, '2025-02-20 15:18:05.377944', NULL);
INSERT INTO stats.goals VALUES (122, 38, 31, 2, 3, '00:12:11', false, false, false, '2025-02-20 15:21:11.084428', NULL);
INSERT INTO stats.goals VALUES (123, 37, 11, 3, 1, '00:08:17', false, false, false, '2025-02-20 15:21:46.202201', NULL);
INSERT INTO stats.goals VALUES (124, 37, 26, 1, 1, '00:08:19', false, false, false, '2025-02-20 15:22:38.997546', NULL);
INSERT INTO stats.goals VALUES (125, 37, 47, 3, 2, '00:13:29', false, false, false, '2025-02-20 15:23:22.146531', NULL);
INSERT INTO stats.goals VALUES (126, 37, 8, 3, 3, '00:18:57', false, false, true, '2025-02-20 15:24:02.319539', NULL);
INSERT INTO stats.goals VALUES (127, 28, 27, 2, 3, '00:05:24', false, false, false, '2025-02-21 16:22:33.439433', NULL);
INSERT INTO stats.goals VALUES (128, 28, 3, 2, 1, '00:02:19', false, false, false, '2025-02-21 16:23:22.289496', NULL);
INSERT INTO stats.goals VALUES (129, 28, 40, 3, 2, '00:15:19', false, false, false, '2025-02-21 18:32:41.82416', NULL);
INSERT INTO stats.goals VALUES (132, 62, 1, 5, 1, '00:05:00', false, false, false, '2025-02-24 21:01:00.824607', NULL);
INSERT INTO stats.goals VALUES (133, 66, 67, 41, 1, '00:12:28', false, false, false, '2025-02-27 20:20:40.937988', NULL);
INSERT INTO stats.goals VALUES (136, 66, 60, 41, 3, '00:18:58', false, false, true, '2025-02-27 20:22:23.337023', NULL);
INSERT INTO stats.goals VALUES (137, 66, 67, 41, 2, '00:14:48', false, true, false, '2025-02-27 20:23:04.015704', NULL);
INSERT INTO stats.goals VALUES (138, 65, 116, 39, 1, '00:11:21', false, false, false, '2025-02-27 20:42:22.517379', NULL);
INSERT INTO stats.goals VALUES (139, 65, 116, 39, 1, '00:16:26', false, false, false, '2025-02-27 20:42:55.37735', NULL);
INSERT INTO stats.goals VALUES (140, 65, 1, 17, 2, '00:09:37', false, true, false, '2025-02-27 20:44:20.419633', NULL);
INSERT INTO stats.goals VALUES (141, 65, 32, 17, 2, '00:16:38', false, false, false, '2025-02-27 20:44:53.800468', NULL);
INSERT INTO stats.goals VALUES (142, 65, 33, 17, 3, '00:16:59', false, true, false, '2025-02-27 20:45:36.152074', NULL);
INSERT INTO stats.goals VALUES (143, 65, 116, 39, 3, '00:19:02', false, false, false, '2025-02-27 20:45:59.053584', NULL);
INSERT INTO stats.goals VALUES (150, 39, 27, 2, 1, '00:06:05', false, false, false, '2025-03-06 16:16:45.910979', '11.56% 50.63%');
INSERT INTO stats.goals VALUES (151, 39, 6, 1, 1, '00:09:32', false, false, false, '2025-03-06 16:25:14.572164', '89.14% 67.79%');
INSERT INTO stats.goals VALUES (152, 39, 7, 1, 2, '00:10:38', false, false, false, '2025-03-06 16:28:12.589656', '28.39% 28.96%');
INSERT INTO stats.goals VALUES (153, 39, 10, 2, 3, '00:13:45', false, false, false, '2025-03-06 21:15:48.106143', '21.17% 34.33%');
INSERT INTO stats.goals VALUES (154, 39, 17, 1, 3, '00:17:46', false, false, false, '2025-03-06 21:16:10.296135', '77.67% 69.08%');
INSERT INTO stats.goals VALUES (156, 40, 61, 4, 1, '00:08:12', false, false, false, '2025-03-21 15:40:42.867207', '76.75% 35.61%');
INSERT INTO stats.goals VALUES (157, 40, 48, 3, 1, '00:17:09', false, false, false, '2025-03-21 15:41:39.219853', '13.81% 58.41%');


--
-- TOC entry 3693 (class 0 OID 77750)
-- Dependencies: 254
-- Data for Name: penalties; Type: TABLE DATA; Schema: stats; Owner: postgres
--

INSERT INTO stats.penalties VALUES (1, 31, 7, 1, 1, '00:15:02', 'Tripping', 2, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.penalties VALUES (2, 31, 32, 2, 2, '00:08:22', 'Hooking', 2, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.penalties VALUES (3, 31, 32, 2, 3, '00:11:31', 'Interference', 2, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.penalties VALUES (7, 33, 15, 1, 1, '00:12:25', 'Tripping', 2, '2025-01-28 22:11:31.236037', NULL);
INSERT INTO stats.penalties VALUES (8, 33, 47, 3, 2, '00:05:48', 'Too Maley Players', 2, '2025-01-28 22:21:39.139248', NULL);
INSERT INTO stats.penalties VALUES (9, 33, 19, 1, 3, '00:12:42', 'Hooking', 2, '2025-01-28 22:22:38.701351', NULL);
INSERT INTO stats.penalties VALUES (11, 34, 10, 2, 2, '00:05:50', 'Holding', 2, '2025-01-29 17:32:25.075633', NULL);
INSERT INTO stats.penalties VALUES (12, 34, 32, 2, 3, '00:06:55', 'Hitting from behind', 5, '2025-01-29 19:37:54.835293', NULL);
INSERT INTO stats.penalties VALUES (13, 28, 27, 2, 2, '00:09:18', 'Roughing', 2, '2025-01-29 21:16:15.507966', NULL);
INSERT INTO stats.penalties VALUES (14, 50, 12, 6, 1, '00:13:00', 'Tripping', 2, '2025-02-11 16:18:59.776395', NULL);
INSERT INTO stats.penalties VALUES (15, 36, 8, 3, 1, '00:09:12', 'Hooking', 2, '2025-02-11 17:17:07.882261', NULL);
INSERT INTO stats.penalties VALUES (16, 51, 1, 35, 2, '00:12:05', 'Hooking', 2, '2025-02-12 02:16:00.63894', NULL);
INSERT INTO stats.penalties VALUES (17, 52, 71, 6, 2, '00:15:02', 'Tripping', 2, '2025-02-17 21:18:27.236359', NULL);
INSERT INTO stats.penalties VALUES (18, 38, 51, 4, 1, '00:14:11', 'Tripping', 2, '2025-02-20 00:26:17.971014', NULL);
INSERT INTO stats.penalties VALUES (19, 28, 31, 2, 3, '00:06:19', 'Tripping', 2, '2025-02-21 15:29:17.62621', NULL);
INSERT INTO stats.penalties VALUES (20, 28, 31, 2, 3, '00:01:19', 'Hooking', 2, '2025-02-21 15:37:39.732067', NULL);
INSERT INTO stats.penalties VALUES (21, 28, 31, 2, 2, '00:10:56', 'Hitting from behind', 5, '2025-02-21 15:38:45.985871', NULL);
INSERT INTO stats.penalties VALUES (24, 66, 46, 40, 2, '00:13:50', 'Hooking', 2, '2025-02-27 20:21:14.121894', NULL);
INSERT INTO stats.penalties VALUES (25, 65, 38, 39, 2, '00:08:27', 'High-sticking', 2, '2025-02-27 20:43:21.46157', NULL);
INSERT INTO stats.penalties VALUES (26, 65, 38, 39, 3, '00:16:39', 'Tripping', 2, '2025-02-27 20:45:13.781309', NULL);
INSERT INTO stats.penalties VALUES (28, 39, 36, 2, 1, '00:14:40', 'Interference', 2, '2025-03-06 16:26:11.969488', '58.53% 4.29%');
INSERT INTO stats.penalties VALUES (29, 39, 33, 2, 3, '00:03:43', 'Tripping', 2, '2025-03-06 21:14:40.399447', '25.15% 50.85%');
INSERT INTO stats.penalties VALUES (30, 40, 9, 4, 2, '00:10:10', 'Hooking', 2, '2025-03-21 15:44:35.632088', '43.29% 37.75%');


--
-- TOC entry 3695 (class 0 OID 77756)
-- Dependencies: 256
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
INSERT INTO stats.saves VALUES (40, 50, 79, 6, 140, 1, '00:05:00', false, false, '2025-02-11 16:18:29.395591');
INSERT INTO stats.saves VALUES (41, 52, 79, 6, 160, 1, '00:08:00', false, false, '2025-02-17 21:17:47.209811');
INSERT INTO stats.saves VALUES (42, 38, 38, 2, 167, 1, '00:10:06', false, false, '2025-02-20 00:25:55.269077');
INSERT INTO stats.saves VALUES (43, 38, 38, 2, 170, 2, '00:13:19', false, false, '2025-02-20 15:16:46.155501');
INSERT INTO stats.saves VALUES (44, 38, 38, 2, 171, 2, '00:15:05', false, false, '2025-02-20 15:17:02.725168');
INSERT INTO stats.saves VALUES (45, 38, 62, 4, 172, 2, '00:17:06', false, false, '2025-02-20 15:17:32.894629');
INSERT INTO stats.saves VALUES (46, 38, 62, 4, 173, 2, '00:17:09', false, false, '2025-02-20 15:17:47.280375');
INSERT INTO stats.saves VALUES (47, 37, 50, 3, 177, 1, '00:13:18', false, false, '2025-02-20 15:22:06.339135');
INSERT INTO stats.saves VALUES (48, 37, 26, 1, 179, 2, '00:08:19', false, false, '2025-02-20 15:23:04.140587');
INSERT INTO stats.saves VALUES (49, 28, 50, 3, 182, 3, '00:10:08', false, false, '2025-02-21 15:25:28.160198');
INSERT INTO stats.saves VALUES (50, 28, 50, 3, 183, 2, '00:03:25', false, false, '2025-02-21 15:25:49.58014');
INSERT INTO stats.saves VALUES (51, 28, 50, 3, 184, 1, '00:03:18', false, false, '2025-02-21 15:26:38.947338');
INSERT INTO stats.saves VALUES (52, 28, 50, 3, 185, 3, '00:18:18', false, false, '2025-02-21 15:26:59.159242');
INSERT INTO stats.saves VALUES (53, 28, 38, 2, 189, 2, '00:15:16', false, false, '2025-02-21 18:33:12.734149');
INSERT INTO stats.saves VALUES (54, 28, 38, 2, 190, 1, '00:15:06', false, false, '2025-02-21 18:34:03.769192');
INSERT INTO stats.saves VALUES (55, 28, 38, 2, 191, 3, '00:04:19', false, false, '2025-02-21 18:34:14.275618');
INSERT INTO stats.saves VALUES (66, 66, 121, 41, 206, 2, '00:08:46', false, false, '2025-02-27 20:20:58.155516');
INSERT INTO stats.saves VALUES (67, 65, 35, 39, 212, 1, '00:15:22', false, false, '2025-02-27 20:42:35.02129');
INSERT INTO stats.saves VALUES (68, 65, 35, 39, 214, 2, '00:09:23', false, false, '2025-02-27 20:43:41.510633');
INSERT INTO stats.saves VALUES (69, 65, 35, 39, 215, 2, '00:09:36', false, true, '2025-02-27 20:44:01.392725');
INSERT INTO stats.saves VALUES (74, 39, 26, 1, 230, 1, '00:06:00', false, true, '2025-03-06 16:15:29.769649');
INSERT INTO stats.saves VALUES (75, 39, 26, 1, 231, 1, '00:06:02', false, false, '2025-03-06 16:15:54.739719');
INSERT INTO stats.saves VALUES (76, 39, 38, 2, 233, 1, '00:08:24', false, true, '2025-03-06 16:23:04.819396');
INSERT INTO stats.saves VALUES (77, 39, 38, 2, 234, 1, '00:08:51', false, false, '2025-03-06 16:24:36.25734');
INSERT INTO stats.saves VALUES (78, 39, 26, 1, 236, 2, '00:05:34', false, true, '2025-03-06 16:27:18.749979');


--
-- TOC entry 3697 (class 0 OID 77763)
-- Dependencies: 258
-- Data for Name: shots; Type: TABLE DATA; Schema: stats; Owner: postgres
--

INSERT INTO stats.shots VALUES (1, 31, 3, 2, 1, '00:05:15', NULL, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.shots VALUES (2, 31, 6, 1, 1, '00:07:35', NULL, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.shots VALUES (3, 31, 31, 2, 1, '00:09:05', NULL, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.shots VALUES (4, 31, 18, 1, 1, '00:10:03', NULL, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.shots VALUES (5, 31, 3, 2, 1, '00:11:20', 1, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.shots VALUES (6, 31, 10, 2, 1, '00:15:37', 2, false, true, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.shots VALUES (7, 31, 3, 2, 1, '00:17:43', NULL, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.shots VALUES (8, 31, 10, 2, 2, '00:01:11', NULL, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.shots VALUES (9, 31, 6, 1, 2, '00:05:40', 3, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.shots VALUES (10, 31, 21, 1, 2, '00:07:15', NULL, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.shots VALUES (11, 31, 34, 2, 2, '00:11:15', NULL, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.shots VALUES (12, 31, 3, 2, 2, '00:18:10', 4, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.shots VALUES (13, 31, 27, 2, 3, '00:07:12', NULL, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.shots VALUES (14, 31, 22, 1, 3, '00:11:56', NULL, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.shots VALUES (15, 31, 36, 2, 3, '00:15:15', NULL, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.shots VALUES (16, 31, 28, 2, 3, '00:18:20', 5, false, false, '2025-01-28 15:35:00.023976', NULL);
INSERT INTO stats.shots VALUES (60, 33, 26, 1, 1, '00:07:02', NULL, false, false, '2025-01-28 22:10:08.819217', NULL);
INSERT INTO stats.shots VALUES (62, 33, 6, 1, 2, '00:03:32', 31, false, false, '2025-01-28 22:12:20.846527', NULL);
INSERT INTO stats.shots VALUES (63, 33, 8, 3, 2, '00:05:47', NULL, false, false, '2025-01-28 22:21:11.452163', NULL);
INSERT INTO stats.shots VALUES (64, 33, 7, 1, 2, '00:06:55', 32, false, true, '2025-01-28 22:22:01.455122', NULL);
INSERT INTO stats.shots VALUES (66, 33, 20, 1, 3, '00:16:51', 34, false, false, '2025-01-28 22:26:59.668639', NULL);
INSERT INTO stats.shots VALUES (69, 33, 6, 1, 3, '00:19:28', 37, false, false, '2025-01-28 22:28:27.853387', NULL);
INSERT INTO stats.shots VALUES (81, 34, 51, 4, 1, '00:15:18', NULL, false, false, '2025-01-29 17:30:20.970281', NULL);
INSERT INTO stats.shots VALUES (91, 43, 1, 5, 1, '00:02:14', 53, false, false, '2025-01-29 18:21:12.878535', NULL);
INSERT INTO stats.shots VALUES (92, 43, 73, 6, 1, '00:04:15', 54, false, false, '2025-01-29 18:21:28.221923', NULL);
INSERT INTO stats.shots VALUES (93, 43, 1, 5, 2, '00:04:16', 55, false, false, '2025-01-29 18:21:40.520499', NULL);
INSERT INTO stats.shots VALUES (96, 28, 27, 2, 1, '00:06:07', 58, false, false, '2025-01-29 21:14:43.602289', NULL);
INSERT INTO stats.shots VALUES (98, 28, 3, 2, 1, '00:16:24', 60, false, false, '2025-01-29 21:15:30.877857', NULL);
INSERT INTO stats.shots VALUES (99, 28, 10, 2, 2, '00:06:10', 61, false, false, '2025-01-29 21:15:51.825065', NULL);
INSERT INTO stats.shots VALUES (100, 28, 11, 3, 2, '00:10:23', 62, false, true, '2025-01-29 21:16:33.02304', NULL);
INSERT INTO stats.shots VALUES (102, 28, 30, 2, 3, '00:12:56', 64, false, false, '2025-01-29 21:17:20.732602', NULL);
INSERT INTO stats.shots VALUES (103, 28, 10, 2, 3, '00:17:17', 65, false, false, '2025-01-29 21:18:11.70895', NULL);
INSERT INTO stats.shots VALUES (104, 34, 10, 2, 3, '00:19:50', 66, false, false, '2025-01-30 19:29:25.066441', NULL);
INSERT INTO stats.shots VALUES (109, 46, 94, 8, 1, '00:03:12', 70, false, false, '2025-01-31 12:48:22.164783', NULL);
INSERT INTO stats.shots VALUES (110, 46, 13, 7, 1, '00:03:13', 71, false, false, '2025-01-31 12:48:49.32671', NULL);
INSERT INTO stats.shots VALUES (111, 46, 4, 8, 1, '00:07:19', 72, false, false, '2025-01-31 12:49:13.951748', NULL);
INSERT INTO stats.shots VALUES (112, 46, 93, 8, 2, '00:11:20', 73, false, false, '2025-01-31 12:49:39.545655', NULL);
INSERT INTO stats.shots VALUES (113, 46, 4, 8, 3, '00:16:21', 74, false, false, '2025-01-31 12:49:58.812247', NULL);
INSERT INTO stats.shots VALUES (114, 47, 1, 5, 1, '00:09:00', 75, false, false, '2025-01-31 13:49:17.016808', NULL);
INSERT INTO stats.shots VALUES (115, 47, 1, 5, 1, '00:13:17', 76, false, true, '2025-01-31 13:50:09.756151', NULL);
INSERT INTO stats.shots VALUES (117, 47, 14, 9, 2, '00:03:11', NULL, false, false, '2025-01-31 13:51:29.431308', NULL);
INSERT INTO stats.shots VALUES (118, 47, 66, 5, 2, '00:05:12', NULL, false, false, '2025-01-31 14:03:58.495521', NULL);
INSERT INTO stats.shots VALUES (119, 47, 14, 9, 2, '00:08:13', 77, false, false, '2025-01-31 14:04:31.83424', NULL);
INSERT INTO stats.shots VALUES (120, 47, 68, 5, 3, '00:18:56', 78, false, false, '2025-01-31 14:04:53.660301', NULL);
INSERT INTO stats.shots VALUES (121, 43, 12, 6, 2, '00:10:24', 79, false, false, '2025-01-31 14:06:18.160428', NULL);
INSERT INTO stats.shots VALUES (122, 43, 12, 6, 3, '00:14:25', 80, false, false, '2025-01-31 14:09:45.235912', NULL);
INSERT INTO stats.shots VALUES (124, 43, 63, 5, 3, '00:19:23', 82, false, false, '2025-01-31 14:11:04.931927', NULL);
INSERT INTO stats.shots VALUES (125, 43, 74, 6, 3, '00:19:44', 83, false, false, '2025-01-31 14:14:42.811083', NULL);
INSERT INTO stats.shots VALUES (126, 48, 4, 8, 1, '00:10:00', 84, false, false, '2025-01-31 14:22:50.340325', NULL);
INSERT INTO stats.shots VALUES (127, 48, 12, 6, 1, '00:15:00', 85, false, false, '2025-01-31 14:23:05.020307', NULL);
INSERT INTO stats.shots VALUES (128, 48, 12, 6, 2, '00:07:00', 86, false, false, '2025-01-31 14:23:28.613506', NULL);
INSERT INTO stats.shots VALUES (130, 48, 12, 6, 3, '00:13:06', 87, false, false, '2025-01-31 14:24:19.14811', NULL);
INSERT INTO stats.shots VALUES (131, 34, 9, 4, 1, '00:19:51', 88, false, false, '2025-01-31 14:51:01.648853', NULL);
INSERT INTO stats.shots VALUES (132, 34, 5, 4, 2, '00:06:38', 89, false, true, '2025-01-31 14:51:58.873246', NULL);
INSERT INTO stats.shots VALUES (133, 34, 5, 4, 3, '00:07:37', 90, false, false, '2025-01-31 14:52:32.574245', NULL);
INSERT INTO stats.shots VALUES (135, 49, 10, 2, 1, '00:15:00', 92, false, false, '2025-01-31 16:13:08.181947', NULL);
INSERT INTO stats.shots VALUES (136, 49, 63, 5, 2, '00:07:18', 93, false, false, '2025-01-31 16:13:22.437177', NULL);
INSERT INTO stats.shots VALUES (137, 49, 3, 2, 2, '00:11:19', NULL, false, false, '2025-01-31 16:13:31.262792', NULL);
INSERT INTO stats.shots VALUES (138, 49, 1, 5, 2, '00:15:20', NULL, false, false, '2025-01-31 16:13:46.281404', NULL);
INSERT INTO stats.shots VALUES (139, 49, 3, 2, 3, '00:08:21', 94, false, false, '2025-01-31 16:14:16.68463', NULL);
INSERT INTO stats.shots VALUES (140, 50, 3, 2, 1, '00:05:00', NULL, false, false, '2025-02-11 16:18:29.391681', NULL);
INSERT INTO stats.shots VALUES (141, 50, 30, 2, 1, '00:10:00', 95, false, false, '2025-02-11 16:18:42.896329', NULL);
INSERT INTO stats.shots VALUES (142, 50, 29, 2, 1, '00:14:00', 96, false, true, '2025-02-11 16:19:12.343197', NULL);
INSERT INTO stats.shots VALUES (143, 50, 12, 6, 3, '00:16:00', 97, false, false, '2025-02-11 16:19:41.204413', NULL);
INSERT INTO stats.shots VALUES (144, 36, 47, 3, 1, '00:04:07', 98, false, false, '2025-02-11 17:16:39.328626', NULL);
INSERT INTO stats.shots VALUES (145, 36, 36, 2, 1, '00:07:08', 99, false, false, '2025-02-11 17:16:50.025299', NULL);
INSERT INTO stats.shots VALUES (146, 51, 1, 35, 1, '00:04:01', 100, false, false, '2025-02-12 02:15:08.26085', NULL);
INSERT INTO stats.shots VALUES (147, 51, 116, 35, 3, '00:07:02', 101, false, false, '2025-02-12 02:15:18.805778', NULL);
INSERT INTO stats.shots VALUES (148, 51, 1, 35, 3, '00:10:03', NULL, false, false, '2025-02-12 02:15:34.454305', NULL);
INSERT INTO stats.shots VALUES (149, 51, 1, 35, 3, '00:12:04', 102, false, false, '2025-02-12 02:15:47.561952', NULL);
INSERT INTO stats.shots VALUES (150, 54, 116, 35, 1, '00:04:00', 103, false, false, '2025-02-12 02:33:55.525163', NULL);
INSERT INTO stats.shots VALUES (151, 54, 1, 35, 1, '00:09:00', 104, false, false, '2025-02-12 02:35:28.714908', NULL);
INSERT INTO stats.shots VALUES (152, 54, 116, 35, 3, '00:14:00', 105, false, false, '2025-02-12 02:35:49.65978', NULL);
INSERT INTO stats.shots VALUES (153, 51, 117, 15, 3, '00:06:05', 106, false, false, '2025-02-13 14:10:31.712666', NULL);
INSERT INTO stats.shots VALUES (154, 51, 117, 15, 2, '00:11:05', 107, false, false, '2025-02-13 14:10:48.519702', NULL);
INSERT INTO stats.shots VALUES (155, 51, 117, 15, 1, '00:15:05', 108, false, false, '2025-02-13 14:11:04.037873', NULL);
INSERT INTO stats.shots VALUES (156, 51, 117, 15, 3, '00:16:05', 109, false, false, '2025-02-13 14:11:21.477969', NULL);
INSERT INTO stats.shots VALUES (158, 50, 37, 2, 3, '00:07:00', 111, false, false, '2025-02-14 18:05:10.930747', NULL);
INSERT INTO stats.shots VALUES (159, 52, 74, 6, 1, '00:03:00', 112, false, false, '2025-02-17 21:17:34.537506', NULL);
INSERT INTO stats.shots VALUES (160, 52, 68, 5, 1, '00:08:00', NULL, false, false, '2025-02-17 21:17:47.205754', NULL);
INSERT INTO stats.shots VALUES (161, 52, 68, 5, 1, '00:12:00', 113, false, false, '2025-02-17 21:18:06.70136', NULL);
INSERT INTO stats.shots VALUES (162, 52, 78, 6, 2, '00:16:21', 114, false, false, '2025-02-17 21:18:48.683812', NULL);
INSERT INTO stats.shots VALUES (163, 52, 1, 5, 3, '00:06:48', 115, false, false, '2025-02-17 21:19:02.617533', NULL);
INSERT INTO stats.shots VALUES (164, 52, 66, 5, 3, '00:08:53', 116, false, false, '2025-02-17 21:19:19.802753', NULL);
INSERT INTO stats.shots VALUES (166, 38, 3, 2, 1, '00:06:05', 118, false, false, '2025-02-20 00:25:37.089886', NULL);
INSERT INTO stats.shots VALUES (167, 38, 51, 4, 1, '00:10:06', NULL, false, false, '2025-02-20 00:25:55.266117', NULL);
INSERT INTO stats.shots VALUES (168, 38, 32, 2, 1, '00:18:12', 119, false, false, '2025-02-20 00:26:50.202042', NULL);
INSERT INTO stats.shots VALUES (169, 38, 38, 2, 2, '00:12:07', 120, false, false, '2025-02-20 15:16:33.963012', NULL);
INSERT INTO stats.shots VALUES (170, 38, 58, 4, 2, '00:13:19', NULL, false, false, '2025-02-20 15:16:46.152377', NULL);
INSERT INTO stats.shots VALUES (171, 38, 5, 4, 2, '00:15:05', NULL, false, false, '2025-02-20 15:17:02.722138', NULL);
INSERT INTO stats.shots VALUES (172, 38, 10, 2, 2, '00:17:06', NULL, false, false, '2025-02-20 15:17:32.891169', NULL);
INSERT INTO stats.shots VALUES (173, 38, 35, 2, 2, '00:17:09', NULL, false, false, '2025-02-20 15:17:47.277514', NULL);
INSERT INTO stats.shots VALUES (174, 38, 10, 2, 3, '00:07:10', 121, false, false, '2025-02-20 15:18:05.384833', NULL);
INSERT INTO stats.shots VALUES (175, 38, 31, 2, 3, '00:12:11', 122, false, false, '2025-02-20 15:21:11.091276', NULL);
INSERT INTO stats.shots VALUES (176, 37, 11, 3, 1, '00:08:17', 123, false, false, '2025-02-20 15:21:46.206553', NULL);
INSERT INTO stats.shots VALUES (177, 37, 22, 1, 1, '00:13:18', NULL, false, false, '2025-02-20 15:22:06.336102', NULL);
INSERT INTO stats.shots VALUES (178, 37, 26, 1, 1, '00:08:19', 124, false, false, '2025-02-20 15:22:39.002372', NULL);
INSERT INTO stats.shots VALUES (179, 37, 43, 3, 2, '00:08:19', NULL, false, false, '2025-02-20 15:23:04.13742', NULL);
INSERT INTO stats.shots VALUES (180, 37, 47, 3, 2, '00:13:29', 125, false, false, '2025-02-20 15:23:22.152623', NULL);
INSERT INTO stats.shots VALUES (181, 37, 8, 3, 3, '00:18:57', 126, false, false, '2025-02-20 15:24:02.326799', NULL);
INSERT INTO stats.shots VALUES (182, 28, 10, 2, 3, '00:10:08', NULL, false, false, '2025-02-21 15:25:28.153353', NULL);
INSERT INTO stats.shots VALUES (183, 28, 10, 2, 2, '00:03:25', NULL, false, false, '2025-02-21 15:25:49.577466', NULL);
INSERT INTO stats.shots VALUES (184, 28, 3, 2, 1, '00:03:18', NULL, false, false, '2025-02-21 15:26:38.944898', NULL);
INSERT INTO stats.shots VALUES (185, 28, 36, 2, 3, '00:18:18', NULL, false, false, '2025-02-21 15:26:59.156195', NULL);
INSERT INTO stats.shots VALUES (186, 28, 27, 2, 3, '00:05:24', 127, false, false, '2025-02-21 16:22:33.447074', NULL);
INSERT INTO stats.shots VALUES (187, 28, 3, 2, 1, '00:02:19', 128, false, false, '2025-02-21 16:23:22.296047', NULL);
INSERT INTO stats.shots VALUES (188, 28, 40, 3, 2, '00:15:19', 129, false, false, '2025-02-21 18:32:41.829474', NULL);
INSERT INTO stats.shots VALUES (189, 28, 40, 3, 2, '00:15:16', NULL, false, false, '2025-02-21 18:33:12.731374', NULL);
INSERT INTO stats.shots VALUES (190, 28, 39, 3, 1, '00:15:06', NULL, false, false, '2025-02-21 18:34:03.765653', NULL);
INSERT INTO stats.shots VALUES (191, 28, 48, 3, 3, '00:04:19', NULL, false, false, '2025-02-21 18:34:14.27228', NULL);
INSERT INTO stats.shots VALUES (204, 62, 1, 5, 1, '00:05:00', 132, false, false, '2025-02-24 21:01:00.828964', NULL);
INSERT INTO stats.shots VALUES (205, 66, 67, 41, 1, '00:12:28', 133, false, false, '2025-02-27 20:20:40.94504', NULL);
INSERT INTO stats.shots VALUES (206, 66, 58, 40, 2, '00:08:46', NULL, false, false, '2025-02-27 20:20:58.152528', NULL);
INSERT INTO stats.shots VALUES (209, 66, 60, 41, 3, '00:18:58', 136, false, false, '2025-02-27 20:22:23.343431', NULL);
INSERT INTO stats.shots VALUES (210, 66, 67, 41, 2, '00:14:48', 137, false, true, '2025-02-27 20:23:04.021656', NULL);
INSERT INTO stats.shots VALUES (211, 65, 116, 39, 1, '00:11:21', 138, false, false, '2025-02-27 20:42:22.52659', NULL);
INSERT INTO stats.shots VALUES (212, 65, 26, 17, 1, '00:15:22', NULL, false, false, '2025-02-27 20:42:35.018483', NULL);
INSERT INTO stats.shots VALUES (213, 65, 116, 39, 1, '00:16:26', 139, false, false, '2025-02-27 20:42:55.384173', NULL);
INSERT INTO stats.shots VALUES (214, 65, 27, 17, 2, '00:09:23', NULL, false, true, '2025-02-27 20:43:41.507362', NULL);
INSERT INTO stats.shots VALUES (215, 65, 26, 17, 2, '00:09:36', NULL, false, true, '2025-02-27 20:44:01.388496', NULL);
INSERT INTO stats.shots VALUES (216, 65, 1, 17, 2, '00:09:37', 140, false, true, '2025-02-27 20:44:20.426753', NULL);
INSERT INTO stats.shots VALUES (217, 65, 32, 17, 2, '00:16:38', 141, false, false, '2025-02-27 20:44:53.807232', NULL);
INSERT INTO stats.shots VALUES (218, 65, 33, 17, 3, '00:16:59', 142, false, true, '2025-02-27 20:45:36.158993', NULL);
INSERT INTO stats.shots VALUES (219, 65, 116, 39, 3, '00:19:02', 143, false, false, '2025-02-27 20:45:59.060593', NULL);
INSERT INTO stats.shots VALUES (230, 39, 10, 2, 1, '00:06:00', NULL, false, false, '2025-03-06 16:15:29.765492', '15.81% 33.04%');
INSERT INTO stats.shots VALUES (231, 39, 27, 2, 1, '00:06:02', NULL, false, false, '2025-03-06 16:15:54.735266', '12.76% 51.06%');
INSERT INTO stats.shots VALUES (232, 39, 27, 2, 1, '00:06:05', 150, false, false, '2025-03-06 16:16:45.918185', '11.56% 50.63%');
INSERT INTO stats.shots VALUES (233, 39, 25, 1, 1, '00:08:24', NULL, false, false, '2025-03-06 16:23:04.816076', '78.41% 26.39%');
INSERT INTO stats.shots VALUES (234, 39, 18, 1, 1, '00:08:51', NULL, false, false, '2025-03-06 16:24:36.252657', '74.16% 74.66%');
INSERT INTO stats.shots VALUES (235, 39, 6, 1, 1, '00:09:32', 151, false, false, '2025-03-06 16:25:14.581161', '89.14% 67.79%');
INSERT INTO stats.shots VALUES (236, 39, 34, 2, 2, '00:05:34', NULL, false, false, '2025-03-06 16:27:18.746254', '83.22% 33.04%');
INSERT INTO stats.shots VALUES (237, 39, 7, 1, 2, '00:10:38', 152, false, false, '2025-03-06 16:28:12.599198', '28.39% 28.96%');
INSERT INTO stats.shots VALUES (239, 39, 10, 2, 3, '00:13:45', 153, false, false, '2025-03-06 21:15:48.12276', '21.17% 34.33%');
INSERT INTO stats.shots VALUES (240, 39, 17, 1, 3, '00:17:46', 154, false, false, '2025-03-06 21:16:10.302262', '77.67% 69.08%');
INSERT INTO stats.shots VALUES (242, 40, 61, 4, 1, '00:08:12', 156, false, false, '2025-03-21 15:40:42.873592', '76.75% 35.61%');
INSERT INTO stats.shots VALUES (243, 40, 48, 3, 1, '00:17:09', 157, false, false, '2025-03-21 15:41:39.225086', '13.81% 58.41%');


--
-- TOC entry 3699 (class 0 OID 77770)
-- Dependencies: 260
-- Data for Name: shutouts; Type: TABLE DATA; Schema: stats; Owner: postgres
--



--
-- TOC entry 3727 (class 0 OID 0)
-- Dependencies: 221
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: admin; Owner: postgres
--

SELECT pg_catalog.setval('admin.users_user_id_seq', 132, true);


--
-- TOC entry 3728 (class 0 OID 0)
-- Dependencies: 223
-- Name: arenas_arena_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.arenas_arena_id_seq', 42, true);


--
-- TOC entry 3729 (class 0 OID 0)
-- Dependencies: 225
-- Name: division_rosters_division_roster_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.division_rosters_division_roster_id_seq', 157, true);


--
-- TOC entry 3730 (class 0 OID 0)
-- Dependencies: 227
-- Name: division_teams_division_team_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.division_teams_division_team_id_seq', 62, true);


--
-- TOC entry 3731 (class 0 OID 0)
-- Dependencies: 229
-- Name: divisions_division_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.divisions_division_id_seq', 48, true);


--
-- TOC entry 3732 (class 0 OID 0)
-- Dependencies: 231
-- Name: games_game_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.games_game_id_seq', 71, true);


--
-- TOC entry 3733 (class 0 OID 0)
-- Dependencies: 233
-- Name: league_admins_league_admin_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.league_admins_league_admin_id_seq', 42, true);


--
-- TOC entry 3734 (class 0 OID 0)
-- Dependencies: 235
-- Name: league_venues_league_venue_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.league_venues_league_venue_id_seq', 19, true);


--
-- TOC entry 3735 (class 0 OID 0)
-- Dependencies: 237
-- Name: leagues_league_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.leagues_league_id_seq', 27, true);


--
-- TOC entry 3736 (class 0 OID 0)
-- Dependencies: 239
-- Name: playoffs_playoff_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.playoffs_playoff_id_seq', 1, false);


--
-- TOC entry 3737 (class 0 OID 0)
-- Dependencies: 241
-- Name: season_admins_season_admin_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.season_admins_season_admin_id_seq', 2, true);


--
-- TOC entry 3738 (class 0 OID 0)
-- Dependencies: 243
-- Name: seasons_season_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.seasons_season_id_seq', 23, true);


--
-- TOC entry 3739 (class 0 OID 0)
-- Dependencies: 245
-- Name: team_memberships_team_membership_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.team_memberships_team_membership_id_seq', 185, true);


--
-- TOC entry 3740 (class 0 OID 0)
-- Dependencies: 247
-- Name: teams_team_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.teams_team_id_seq', 42, true);


--
-- TOC entry 3741 (class 0 OID 0)
-- Dependencies: 249
-- Name: venues_venue_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.venues_venue_id_seq', 30, true);


--
-- TOC entry 3742 (class 0 OID 0)
-- Dependencies: 251
-- Name: assists_assist_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.assists_assist_id_seq', 140, true);


--
-- TOC entry 3743 (class 0 OID 0)
-- Dependencies: 253
-- Name: goals_goal_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.goals_goal_id_seq', 157, true);


--
-- TOC entry 3744 (class 0 OID 0)
-- Dependencies: 255
-- Name: penalties_penalty_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.penalties_penalty_id_seq', 30, true);


--
-- TOC entry 3745 (class 0 OID 0)
-- Dependencies: 257
-- Name: saves_save_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.saves_save_id_seq', 79, true);


--
-- TOC entry 3746 (class 0 OID 0)
-- Dependencies: 259
-- Name: shots_shot_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.shots_shot_id_seq', 243, true);


--
-- TOC entry 3747 (class 0 OID 0)
-- Dependencies: 261
-- Name: shutouts_shutout_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.shutouts_shutout_id_seq', 1, false);


--
-- TOC entry 3404 (class 2606 OID 77797)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3406 (class 2606 OID 77799)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 3408 (class 2606 OID 77801)
-- Name: users users_username_key; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 3410 (class 2606 OID 77803)
-- Name: arenas arenas_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.arenas
    ADD CONSTRAINT arenas_pkey PRIMARY KEY (arena_id);


--
-- TOC entry 3412 (class 2606 OID 77805)
-- Name: division_rosters division_rosters_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_rosters
    ADD CONSTRAINT division_rosters_pkey PRIMARY KEY (division_roster_id);


--
-- TOC entry 3414 (class 2606 OID 77807)
-- Name: division_teams division_teams_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_teams
    ADD CONSTRAINT division_teams_pkey PRIMARY KEY (division_team_id);


--
-- TOC entry 3416 (class 2606 OID 77809)
-- Name: divisions divisions_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.divisions
    ADD CONSTRAINT divisions_pkey PRIMARY KEY (division_id);


--
-- TOC entry 3418 (class 2606 OID 77811)
-- Name: games games_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games
    ADD CONSTRAINT games_pkey PRIMARY KEY (game_id);


--
-- TOC entry 3420 (class 2606 OID 77813)
-- Name: league_admins league_admins_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins
    ADD CONSTRAINT league_admins_pkey PRIMARY KEY (league_admin_id);


--
-- TOC entry 3422 (class 2606 OID 77815)
-- Name: league_venues league_venues_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_venues
    ADD CONSTRAINT league_venues_pkey PRIMARY KEY (league_venue_id);


--
-- TOC entry 3424 (class 2606 OID 77817)
-- Name: leagues leagues_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.leagues
    ADD CONSTRAINT leagues_pkey PRIMARY KEY (league_id);


--
-- TOC entry 3426 (class 2606 OID 77819)
-- Name: leagues leagues_slug_key; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.leagues
    ADD CONSTRAINT leagues_slug_key UNIQUE (slug);


--
-- TOC entry 3428 (class 2606 OID 77821)
-- Name: playoffs playoffs_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.playoffs
    ADD CONSTRAINT playoffs_pkey PRIMARY KEY (playoff_id);


--
-- TOC entry 3430 (class 2606 OID 77823)
-- Name: season_admins season_admins_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins
    ADD CONSTRAINT season_admins_pkey PRIMARY KEY (season_admin_id);


--
-- TOC entry 3432 (class 2606 OID 77825)
-- Name: seasons seasons_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.seasons
    ADD CONSTRAINT seasons_pkey PRIMARY KEY (season_id);


--
-- TOC entry 3434 (class 2606 OID 77827)
-- Name: team_memberships team_memberships_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships
    ADD CONSTRAINT team_memberships_pkey PRIMARY KEY (team_membership_id);


--
-- TOC entry 3436 (class 2606 OID 77829)
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (team_id);


--
-- TOC entry 3438 (class 2606 OID 77831)
-- Name: teams teams_slug_key; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.teams
    ADD CONSTRAINT teams_slug_key UNIQUE (slug);


--
-- TOC entry 3440 (class 2606 OID 77833)
-- Name: venues venues_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.venues
    ADD CONSTRAINT venues_pkey PRIMARY KEY (venue_id);


--
-- TOC entry 3442 (class 2606 OID 77835)
-- Name: venues venues_slug_key; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.venues
    ADD CONSTRAINT venues_slug_key UNIQUE (slug);


--
-- TOC entry 3444 (class 2606 OID 77837)
-- Name: assists assists_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT assists_pkey PRIMARY KEY (assist_id);


--
-- TOC entry 3446 (class 2606 OID 77839)
-- Name: goals goals_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals
    ADD CONSTRAINT goals_pkey PRIMARY KEY (goal_id);


--
-- TOC entry 3448 (class 2606 OID 77841)
-- Name: penalties penalties_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties
    ADD CONSTRAINT penalties_pkey PRIMARY KEY (penalty_id);


--
-- TOC entry 3450 (class 2606 OID 77843)
-- Name: saves saves_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT saves_pkey PRIMARY KEY (save_id);


--
-- TOC entry 3452 (class 2606 OID 77845)
-- Name: shots shots_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT shots_pkey PRIMARY KEY (shot_id);


--
-- TOC entry 3454 (class 2606 OID 77847)
-- Name: shutouts shutouts_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts
    ADD CONSTRAINT shutouts_pkey PRIMARY KEY (shutout_id);


--
-- TOC entry 3499 (class 2620 OID 77848)
-- Name: games insert_game_status_check; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER insert_game_status_check BEFORE INSERT ON league_management.games FOR EACH ROW EXECUTE FUNCTION league_management.mark_game_as_published();


--
-- TOC entry 3495 (class 2620 OID 78077)
-- Name: divisions publish_division; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER publish_division BEFORE UPDATE OF status ON league_management.divisions FOR EACH ROW EXECUTE FUNCTION league_management.auto_publish_season();


--
-- TOC entry 3504 (class 2620 OID 78079)
-- Name: seasons publish_season; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER publish_season BEFORE UPDATE OF status ON league_management.seasons FOR EACH ROW EXECUTE FUNCTION league_management.auto_publish_league();


--
-- TOC entry 3496 (class 2620 OID 77849)
-- Name: divisions set_divisions_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER set_divisions_slug BEFORE INSERT ON league_management.divisions FOR EACH ROW EXECUTE FUNCTION league_management.generate_division_slug();


--
-- TOC entry 3501 (class 2620 OID 77850)
-- Name: leagues set_leagues_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER set_leagues_slug BEFORE INSERT ON league_management.leagues FOR EACH ROW EXECUTE FUNCTION league_management.generate_league_slug();


--
-- TOC entry 3505 (class 2620 OID 77851)
-- Name: seasons set_seasons_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER set_seasons_slug BEFORE INSERT ON league_management.seasons FOR EACH ROW EXECUTE FUNCTION league_management.generate_season_slug();


--
-- TOC entry 3508 (class 2620 OID 77852)
-- Name: teams set_teams_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER set_teams_slug BEFORE INSERT ON league_management.teams FOR EACH ROW EXECUTE FUNCTION league_management.generate_team_slug();


--
-- TOC entry 3511 (class 2620 OID 78063)
-- Name: venues set_venues_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER set_venues_slug BEFORE INSERT ON league_management.venues FOR EACH ROW EXECUTE FUNCTION league_management.generate_venue_slug();


--
-- TOC entry 3497 (class 2620 OID 77853)
-- Name: divisions update_divisions_join_code; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_divisions_join_code BEFORE UPDATE OF join_code ON league_management.divisions FOR EACH ROW EXECUTE FUNCTION league_management.division_join_code_cleanup();


--
-- TOC entry 3498 (class 2620 OID 77854)
-- Name: divisions update_divisions_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_divisions_slug BEFORE UPDATE OF name ON league_management.divisions FOR EACH ROW EXECUTE FUNCTION league_management.generate_division_slug();


--
-- TOC entry 3500 (class 2620 OID 77855)
-- Name: games update_game_status_check; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_game_status_check BEFORE UPDATE OF status ON league_management.games FOR EACH ROW EXECUTE FUNCTION league_management.mark_game_as_published();


--
-- TOC entry 3502 (class 2620 OID 77856)
-- Name: leagues update_leagues_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_leagues_slug BEFORE UPDATE OF name ON league_management.leagues FOR EACH ROW EXECUTE FUNCTION league_management.generate_league_slug();


--
-- TOC entry 3503 (class 2620 OID 78075)
-- Name: leagues update_leagues_status; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_leagues_status BEFORE UPDATE OF status ON league_management.leagues FOR EACH ROW EXECUTE FUNCTION league_management.auto_update_season_status();


--
-- TOC entry 3506 (class 2620 OID 77857)
-- Name: seasons update_seasons_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_seasons_slug BEFORE UPDATE OF name ON league_management.seasons FOR EACH ROW EXECUTE FUNCTION league_management.generate_season_slug();


--
-- TOC entry 3507 (class 2620 OID 78073)
-- Name: seasons update_seasons_status; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_seasons_status BEFORE UPDATE OF status ON league_management.seasons FOR EACH ROW EXECUTE FUNCTION league_management.auto_update_division_status();


--
-- TOC entry 3509 (class 2620 OID 77858)
-- Name: teams update_teams_join_code; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_teams_join_code BEFORE UPDATE OF join_code ON league_management.teams FOR EACH ROW EXECUTE FUNCTION league_management.join_code_cleanup();


--
-- TOC entry 3510 (class 2620 OID 77859)
-- Name: teams update_teams_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_teams_slug BEFORE UPDATE OF name ON league_management.teams FOR EACH ROW EXECUTE FUNCTION league_management.generate_team_slug();


--
-- TOC entry 3512 (class 2620 OID 78064)
-- Name: venues update_venues_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER update_venues_slug BEFORE UPDATE OF name ON league_management.venues FOR EACH ROW EXECUTE FUNCTION league_management.generate_venue_slug();


--
-- TOC entry 3513 (class 2620 OID 77860)
-- Name: goals goal_update_game_score; Type: TRIGGER; Schema: stats; Owner: postgres
--

CREATE TRIGGER goal_update_game_score AFTER INSERT OR DELETE ON stats.goals FOR EACH ROW EXECUTE FUNCTION league_management.update_game_score();


--
-- TOC entry 3455 (class 2606 OID 77861)
-- Name: arenas fk_arena_venue_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.arenas
    ADD CONSTRAINT fk_arena_venue_id FOREIGN KEY (venue_id) REFERENCES league_management.venues(venue_id) ON DELETE CASCADE;


--
-- TOC entry 3456 (class 2606 OID 77866)
-- Name: division_rosters fk_division_rosters_division_team_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_rosters
    ADD CONSTRAINT fk_division_rosters_division_team_id FOREIGN KEY (division_team_id) REFERENCES league_management.division_teams(division_team_id) ON DELETE CASCADE;


--
-- TOC entry 3457 (class 2606 OID 77871)
-- Name: division_rosters fk_division_rosters_team_membership_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_rosters
    ADD CONSTRAINT fk_division_rosters_team_membership_id FOREIGN KEY (team_membership_id) REFERENCES league_management.team_memberships(team_membership_id) ON DELETE CASCADE;


--
-- TOC entry 3458 (class 2606 OID 77876)
-- Name: division_teams fk_division_teams_division_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_teams
    ADD CONSTRAINT fk_division_teams_division_id FOREIGN KEY (division_id) REFERENCES league_management.divisions(division_id) ON DELETE CASCADE;


--
-- TOC entry 3459 (class 2606 OID 77881)
-- Name: division_teams fk_division_teams_team_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_teams
    ADD CONSTRAINT fk_division_teams_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3460 (class 2606 OID 77886)
-- Name: divisions fk_divisions_season_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.divisions
    ADD CONSTRAINT fk_divisions_season_id FOREIGN KEY (season_id) REFERENCES league_management.seasons(season_id) ON DELETE CASCADE;


--
-- TOC entry 3461 (class 2606 OID 77891)
-- Name: games fk_game_arena_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games
    ADD CONSTRAINT fk_game_arena_id FOREIGN KEY (arena_id) REFERENCES league_management.arenas(arena_id);


--
-- TOC entry 3462 (class 2606 OID 77896)
-- Name: games fk_game_division_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games
    ADD CONSTRAINT fk_game_division_id FOREIGN KEY (division_id) REFERENCES league_management.divisions(division_id) ON DELETE CASCADE;


--
-- TOC entry 3463 (class 2606 OID 77901)
-- Name: games fk_game_playoff_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games
    ADD CONSTRAINT fk_game_playoff_id FOREIGN KEY (playoff_id) REFERENCES league_management.playoffs(playoff_id) ON DELETE CASCADE;


--
-- TOC entry 3464 (class 2606 OID 77906)
-- Name: league_admins fk_league_admins_league_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins
    ADD CONSTRAINT fk_league_admins_league_id FOREIGN KEY (league_id) REFERENCES league_management.leagues(league_id) ON DELETE CASCADE;


--
-- TOC entry 3465 (class 2606 OID 77911)
-- Name: league_admins fk_league_admins_user_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins
    ADD CONSTRAINT fk_league_admins_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3466 (class 2606 OID 77916)
-- Name: league_venues fk_league_venue_league_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_venues
    ADD CONSTRAINT fk_league_venue_league_id FOREIGN KEY (league_id) REFERENCES league_management.leagues(league_id) ON DELETE CASCADE;


--
-- TOC entry 3467 (class 2606 OID 77921)
-- Name: league_venues fk_league_venue_venue_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_venues
    ADD CONSTRAINT fk_league_venue_venue_id FOREIGN KEY (venue_id) REFERENCES league_management.venues(venue_id) ON DELETE CASCADE;


--
-- TOC entry 3468 (class 2606 OID 77926)
-- Name: playoffs fk_playoffs_season_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.playoffs
    ADD CONSTRAINT fk_playoffs_season_id FOREIGN KEY (season_id) REFERENCES league_management.seasons(season_id) ON DELETE CASCADE;


--
-- TOC entry 3469 (class 2606 OID 77931)
-- Name: season_admins fk_season_admins_season_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins
    ADD CONSTRAINT fk_season_admins_season_id FOREIGN KEY (season_id) REFERENCES league_management.seasons(season_id) ON DELETE CASCADE;


--
-- TOC entry 3470 (class 2606 OID 77936)
-- Name: season_admins fk_season_admins_user_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins
    ADD CONSTRAINT fk_season_admins_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3471 (class 2606 OID 77941)
-- Name: seasons fk_seasons_league_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.seasons
    ADD CONSTRAINT fk_seasons_league_id FOREIGN KEY (league_id) REFERENCES league_management.leagues(league_id) ON DELETE CASCADE;


--
-- TOC entry 3472 (class 2606 OID 77946)
-- Name: team_memberships fk_team_memberships_team_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships
    ADD CONSTRAINT fk_team_memberships_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3473 (class 2606 OID 77951)
-- Name: team_memberships fk_team_memberships_user_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships
    ADD CONSTRAINT fk_team_memberships_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3474 (class 2606 OID 77956)
-- Name: assists fk_assists_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT fk_assists_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3475 (class 2606 OID 77961)
-- Name: assists fk_assists_goal_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT fk_assists_goal_id FOREIGN KEY (goal_id) REFERENCES stats.goals(goal_id) ON DELETE CASCADE;


--
-- TOC entry 3476 (class 2606 OID 77966)
-- Name: assists fk_assists_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT fk_assists_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3477 (class 2606 OID 77971)
-- Name: assists fk_assists_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT fk_assists_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3478 (class 2606 OID 77976)
-- Name: goals fk_goals_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals
    ADD CONSTRAINT fk_goals_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3479 (class 2606 OID 77981)
-- Name: goals fk_goals_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals
    ADD CONSTRAINT fk_goals_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3480 (class 2606 OID 77986)
-- Name: goals fk_goals_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals
    ADD CONSTRAINT fk_goals_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3481 (class 2606 OID 77991)
-- Name: penalties fk_penalties_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties
    ADD CONSTRAINT fk_penalties_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3482 (class 2606 OID 77996)
-- Name: penalties fk_penalties_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties
    ADD CONSTRAINT fk_penalties_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3483 (class 2606 OID 78001)
-- Name: penalties fk_penalties_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties
    ADD CONSTRAINT fk_penalties_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3484 (class 2606 OID 78006)
-- Name: saves fk_saves_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT fk_saves_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3485 (class 2606 OID 78011)
-- Name: saves fk_saves_shot_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT fk_saves_shot_id FOREIGN KEY (shot_id) REFERENCES stats.shots(shot_id) ON DELETE CASCADE;


--
-- TOC entry 3486 (class 2606 OID 78016)
-- Name: saves fk_saves_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT fk_saves_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3487 (class 2606 OID 78021)
-- Name: saves fk_saves_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT fk_saves_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3488 (class 2606 OID 78026)
-- Name: shots fk_shots_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT fk_shots_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3489 (class 2606 OID 78031)
-- Name: shots fk_shots_goal_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT fk_shots_goal_id FOREIGN KEY (goal_id) REFERENCES stats.goals(goal_id) ON DELETE CASCADE;


--
-- TOC entry 3490 (class 2606 OID 78036)
-- Name: shots fk_shots_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT fk_shots_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3491 (class 2606 OID 78041)
-- Name: shots fk_shots_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT fk_shots_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 3492 (class 2606 OID 78046)
-- Name: shutouts fk_shutouts_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts
    ADD CONSTRAINT fk_shutouts_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id) ON DELETE CASCADE;


--
-- TOC entry 3493 (class 2606 OID 78051)
-- Name: shutouts fk_shutouts_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts
    ADD CONSTRAINT fk_shutouts_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id) ON DELETE CASCADE;


--
-- TOC entry 3494 (class 2606 OID 78056)
-- Name: shutouts fk_shutouts_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts
    ADD CONSTRAINT fk_shutouts_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id) ON DELETE CASCADE;


-- Completed on 2025-04-03 14:51:52 EDT

--
-- PostgreSQL database dump complete
--

