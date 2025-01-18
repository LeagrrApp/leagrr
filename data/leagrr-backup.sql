--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2 (Debian 17.2-1.pgdg120+1)
-- Dumped by pg_dump version 17.2

-- Started on 2025-01-14 13:54:39 EST

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
-- TOC entry 7 (class 2615 OID 30759)
-- Name: admin; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA admin;


ALTER SCHEMA admin OWNER TO postgres;

--
-- TOC entry 6 (class 2615 OID 30758)
-- Name: league_management; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA league_management;


ALTER SCHEMA league_management OWNER TO postgres;

--
-- TOC entry 8 (class 2615 OID 30760)
-- Name: stats; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA stats;


ALTER SCHEMA stats OWNER TO postgres;

--
-- TOC entry 274 (class 1255 OID 31227)
-- Name: generate_unique_slug(); Type: FUNCTION; Schema: league_management; Owner: postgres
--

CREATE FUNCTION league_management.generate_unique_slug() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    base_slug TEXT;
    final_slug TEXT;
    slug_rank INT;
BEGIN
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
    SELECT COUNT(*) INTO slug_rank
    FROM league_management.leagues
    WHERE slug LIKE base_slug || '%';

    IF slug_rank = 0 THEN
        -- No duplicates found, assign base slug
        final_slug := base_slug;
    ELSE
        -- Duplicates found, append the count as a suffix
        final_slug := base_slug || '-' || slug_rank;
    END IF;

    -- Assign the final slug to the new record
    NEW.slug := final_slug;

    RETURN NEW;
END;
$$;


ALTER FUNCTION league_management.generate_unique_slug() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 233 (class 1259 OID 30824)
-- Name: genders; Type: TABLE; Schema: admin; Owner: postgres
--

CREATE TABLE admin.genders (
    gender_id integer NOT NULL,
    slug character varying(50) NOT NULL,
    name character varying(50) NOT NULL,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE admin.genders OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 30823)
-- Name: genders_gender_id_seq; Type: SEQUENCE; Schema: admin; Owner: postgres
--

CREATE SEQUENCE admin.genders_gender_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE admin.genders_gender_id_seq OWNER TO postgres;

--
-- TOC entry 3724 (class 0 OID 0)
-- Dependencies: 232
-- Name: genders_gender_id_seq; Type: SEQUENCE OWNED BY; Schema: admin; Owner: postgres
--

ALTER SEQUENCE admin.genders_gender_id_seq OWNED BY admin.genders.gender_id;


--
-- TOC entry 223 (class 1259 OID 30772)
-- Name: league_roles; Type: TABLE; Schema: admin; Owner: postgres
--

CREATE TABLE admin.league_roles (
    league_role_id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE admin.league_roles OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 30771)
-- Name: league_roles_league_role_id_seq; Type: SEQUENCE; Schema: admin; Owner: postgres
--

CREATE SEQUENCE admin.league_roles_league_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE admin.league_roles_league_role_id_seq OWNER TO postgres;

--
-- TOC entry 3725 (class 0 OID 0)
-- Dependencies: 222
-- Name: league_roles_league_role_id_seq; Type: SEQUENCE OWNED BY; Schema: admin; Owner: postgres
--

ALTER SEQUENCE admin.league_roles_league_role_id_seq OWNED BY admin.league_roles.league_role_id;


--
-- TOC entry 227 (class 1259 OID 30792)
-- Name: playoff_structures; Type: TABLE; Schema: admin; Owner: postgres
--

CREATE TABLE admin.playoff_structures (
    playoff_structure_id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE admin.playoff_structures OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 30791)
-- Name: playoff_structures_playoff_structure_id_seq; Type: SEQUENCE; Schema: admin; Owner: postgres
--

CREATE SEQUENCE admin.playoff_structures_playoff_structure_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE admin.playoff_structures_playoff_structure_id_seq OWNER TO postgres;

--
-- TOC entry 3726 (class 0 OID 0)
-- Dependencies: 226
-- Name: playoff_structures_playoff_structure_id_seq; Type: SEQUENCE OWNED BY; Schema: admin; Owner: postgres
--

ALTER SEQUENCE admin.playoff_structures_playoff_structure_id_seq OWNED BY admin.playoff_structures.playoff_structure_id;


--
-- TOC entry 225 (class 1259 OID 30782)
-- Name: season_roles; Type: TABLE; Schema: admin; Owner: postgres
--

CREATE TABLE admin.season_roles (
    season_role_id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE admin.season_roles OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 30781)
-- Name: season_roles_season_role_id_seq; Type: SEQUENCE; Schema: admin; Owner: postgres
--

CREATE SEQUENCE admin.season_roles_season_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE admin.season_roles_season_role_id_seq OWNER TO postgres;

--
-- TOC entry 3727 (class 0 OID 0)
-- Dependencies: 224
-- Name: season_roles_season_role_id_seq; Type: SEQUENCE OWNED BY; Schema: admin; Owner: postgres
--

ALTER SEQUENCE admin.season_roles_season_role_id_seq OWNED BY admin.season_roles.season_role_id;


--
-- TOC entry 231 (class 1259 OID 30812)
-- Name: sports; Type: TABLE; Schema: admin; Owner: postgres
--

CREATE TABLE admin.sports (
    sport_id integer NOT NULL,
    slug character varying(50) NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE admin.sports OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 30811)
-- Name: sports_sport_id_seq; Type: SEQUENCE; Schema: admin; Owner: postgres
--

CREATE SEQUENCE admin.sports_sport_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE admin.sports_sport_id_seq OWNER TO postgres;

--
-- TOC entry 3728 (class 0 OID 0)
-- Dependencies: 230
-- Name: sports_sport_id_seq; Type: SEQUENCE OWNED BY; Schema: admin; Owner: postgres
--

ALTER SEQUENCE admin.sports_sport_id_seq OWNED BY admin.sports.sport_id;


--
-- TOC entry 229 (class 1259 OID 30802)
-- Name: team_roles; Type: TABLE; Schema: admin; Owner: postgres
--

CREATE TABLE admin.team_roles (
    team_role_id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE admin.team_roles OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 30801)
-- Name: team_roles_team_role_id_seq; Type: SEQUENCE; Schema: admin; Owner: postgres
--

CREATE SEQUENCE admin.team_roles_team_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE admin.team_roles_team_role_id_seq OWNER TO postgres;

--
-- TOC entry 3729 (class 0 OID 0)
-- Dependencies: 228
-- Name: team_roles_team_role_id_seq; Type: SEQUENCE OWNED BY; Schema: admin; Owner: postgres
--

ALTER SEQUENCE admin.team_roles_team_role_id_seq OWNED BY admin.team_roles.team_role_id;


--
-- TOC entry 221 (class 1259 OID 30762)
-- Name: user_roles; Type: TABLE; Schema: admin; Owner: postgres
--

CREATE TABLE admin.user_roles (
    user_role_id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE admin.user_roles OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 30761)
-- Name: user_roles_user_role_id_seq; Type: SEQUENCE; Schema: admin; Owner: postgres
--

CREATE SEQUENCE admin.user_roles_user_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE admin.user_roles_user_role_id_seq OWNER TO postgres;

--
-- TOC entry 3730 (class 0 OID 0)
-- Dependencies: 220
-- Name: user_roles_user_role_id_seq; Type: SEQUENCE OWNED BY; Schema: admin; Owner: postgres
--

ALTER SEQUENCE admin.user_roles_user_role_id_seq OWNED BY admin.user_roles.user_role_id;


--
-- TOC entry 235 (class 1259 OID 30834)
-- Name: users; Type: TABLE; Schema: admin; Owner: postgres
--

CREATE TABLE admin.users (
    user_id integer NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(50) NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    gender_id integer,
    pronouns character varying(50),
    user_role integer DEFAULT 3 NOT NULL,
    password_hash character varying(100),
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE admin.users OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 30833)
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
-- TOC entry 3731 (class 0 OID 0)
-- Dependencies: 234
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: admin; Owner: postgres
--

ALTER SEQUENCE admin.users_user_id_seq OWNED BY admin.users.user_id;


--
-- TOC entry 259 (class 1259 OID 31045)
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
-- TOC entry 258 (class 1259 OID 31044)
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
-- TOC entry 3732 (class 0 OID 0)
-- Dependencies: 258
-- Name: arenas_arena_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.arenas_arena_id_seq OWNED BY league_management.arenas.arena_id;


--
-- TOC entry 253 (class 1259 OID 31000)
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
-- TOC entry 252 (class 1259 OID 30999)
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
-- TOC entry 3733 (class 0 OID 0)
-- Dependencies: 252
-- Name: division_rosters_division_roster_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.division_rosters_division_roster_id_seq OWNED BY league_management.division_rosters.division_roster_id;


--
-- TOC entry 251 (class 1259 OID 30982)
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
-- TOC entry 250 (class 1259 OID 30981)
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
-- TOC entry 3734 (class 0 OID 0)
-- Dependencies: 250
-- Name: division_teams_division_team_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.division_teams_division_team_id_seq OWNED BY league_management.division_teams.division_team_id;


--
-- TOC entry 249 (class 1259 OID 30966)
-- Name: divisions; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.divisions (
    division_id integer NOT NULL,
    slug character varying(50) NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    tier integer,
    gender character varying(10) DEFAULT 'Co-ed'::character varying NOT NULL,
    season_id integer,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.divisions OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 30965)
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
-- TOC entry 3735 (class 0 OID 0)
-- Dependencies: 248
-- Name: divisions_division_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.divisions_division_id_seq OWNED BY league_management.divisions.division_id;


--
-- TOC entry 261 (class 1259 OID 31060)
-- Name: games; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.games (
    game_id integer NOT NULL,
    home_team_id integer,
    home_team_score integer DEFAULT 0,
    away_team_id integer,
    away_team_score integer DEFAULT 0,
    division_id integer NOT NULL,
    date_time timestamp without time zone,
    arena_id integer,
    status character varying(20),
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.games OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 31059)
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
-- TOC entry 3736 (class 0 OID 0)
-- Dependencies: 260
-- Name: games_game_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.games_game_id_seq OWNED BY league_management.games.game_id;


--
-- TOC entry 243 (class 1259 OID 30910)
-- Name: league_admins; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.league_admins (
    league_admin_id integer NOT NULL,
    league_role_id integer,
    league_id integer,
    user_id integer,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.league_admins OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 30909)
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
-- TOC entry 3737 (class 0 OID 0)
-- Dependencies: 242
-- Name: league_admins_league_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.league_admins_league_admin_id_seq OWNED BY league_management.league_admins.league_admin_id;


--
-- TOC entry 241 (class 1259 OID 30893)
-- Name: leagues; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.leagues (
    league_id integer NOT NULL,
    slug character varying(50) NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    sport_id integer,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.leagues OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 30892)
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
-- TOC entry 3738 (class 0 OID 0)
-- Dependencies: 240
-- Name: leagues_league_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.leagues_league_id_seq OWNED BY league_management.leagues.league_id;


--
-- TOC entry 255 (class 1259 OID 31018)
-- Name: playoffs; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.playoffs (
    playoff_id integer NOT NULL,
    slug character varying(50) NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    playoff_structure_id integer,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.playoffs OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 31017)
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
-- TOC entry 3739 (class 0 OID 0)
-- Dependencies: 254
-- Name: playoffs_playoff_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.playoffs_playoff_id_seq OWNED BY league_management.playoffs.playoff_id;


--
-- TOC entry 247 (class 1259 OID 30943)
-- Name: season_admins; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.season_admins (
    season_admin_id integer NOT NULL,
    season_role_id integer,
    season_id integer,
    user_id integer,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.season_admins OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 30942)
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
-- TOC entry 3740 (class 0 OID 0)
-- Dependencies: 246
-- Name: season_admins_season_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.season_admins_season_admin_id_seq OWNED BY league_management.season_admins.season_admin_id;


--
-- TOC entry 245 (class 1259 OID 30933)
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
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.seasons OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 30932)
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
-- TOC entry 3741 (class 0 OID 0)
-- Dependencies: 244
-- Name: seasons_season_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.seasons_season_id_seq OWNED BY league_management.seasons.season_id;


--
-- TOC entry 239 (class 1259 OID 30869)
-- Name: team_memberships; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.team_memberships (
    team_membership_id integer NOT NULL,
    user_id integer NOT NULL,
    team_id integer NOT NULL,
    team_role_id integer DEFAULT 1,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.team_memberships OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 30868)
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
-- TOC entry 3742 (class 0 OID 0)
-- Dependencies: 238
-- Name: team_memberships_team_membership_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.team_memberships_team_membership_id_seq OWNED BY league_management.team_memberships.team_membership_id;


--
-- TOC entry 237 (class 1259 OID 30857)
-- Name: teams; Type: TABLE; Schema: league_management; Owner: postgres
--

CREATE TABLE league_management.teams (
    team_id integer NOT NULL,
    slug character varying(50) NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE league_management.teams OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 30856)
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
-- TOC entry 3743 (class 0 OID 0)
-- Dependencies: 236
-- Name: teams_team_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.teams_team_id_seq OWNED BY league_management.teams.team_id;


--
-- TOC entry 257 (class 1259 OID 31033)
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
-- TOC entry 256 (class 1259 OID 31032)
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
-- TOC entry 3744 (class 0 OID 0)
-- Dependencies: 256
-- Name: venues_venue_id_seq; Type: SEQUENCE OWNED BY; Schema: league_management; Owner: postgres
--

ALTER SEQUENCE league_management.venues_venue_id_seq OWNED BY league_management.venues.venue_id;


--
-- TOC entry 265 (class 1259 OID 31101)
-- Name: assists; Type: TABLE; Schema: stats; Owner: postgres
--

CREATE TABLE stats.assists (
    assist_id integer NOT NULL,
    goal_id integer NOT NULL,
    game_id integer NOT NULL,
    user_id integer NOT NULL,
    team_id integer NOT NULL,
    primary_assist boolean DEFAULT false,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE stats.assists OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 31100)
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
-- TOC entry 3745 (class 0 OID 0)
-- Dependencies: 264
-- Name: assists_assist_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.assists_assist_id_seq OWNED BY stats.assists.assist_id;


--
-- TOC entry 263 (class 1259 OID 31075)
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
-- TOC entry 262 (class 1259 OID 31074)
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
-- TOC entry 3746 (class 0 OID 0)
-- Dependencies: 262
-- Name: goals_goal_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.goals_goal_id_seq OWNED BY stats.goals.goal_id;


--
-- TOC entry 267 (class 1259 OID 31130)
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
-- TOC entry 266 (class 1259 OID 31129)
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
-- TOC entry 3747 (class 0 OID 0)
-- Dependencies: 266
-- Name: penalties_penalty_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.penalties_penalty_id_seq OWNED BY stats.penalties.penalty_id;


--
-- TOC entry 271 (class 1259 OID 31179)
-- Name: saves; Type: TABLE; Schema: stats; Owner: postgres
--

CREATE TABLE stats.saves (
    save_id integer NOT NULL,
    game_id integer NOT NULL,
    user_id integer NOT NULL,
    team_id integer NOT NULL,
    period integer,
    period_time interval,
    penalty_kill boolean DEFAULT false,
    rebound boolean DEFAULT false,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE stats.saves OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 31178)
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
-- TOC entry 3748 (class 0 OID 0)
-- Dependencies: 270
-- Name: saves_save_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.saves_save_id_seq OWNED BY stats.saves.save_id;


--
-- TOC entry 269 (class 1259 OID 31154)
-- Name: shots; Type: TABLE; Schema: stats; Owner: postgres
--

CREATE TABLE stats.shots (
    shot_id integer NOT NULL,
    game_id integer NOT NULL,
    user_id integer NOT NULL,
    team_id integer NOT NULL,
    period integer,
    period_time interval,
    shorthanded boolean DEFAULT false,
    power_play boolean DEFAULT false,
    created_on timestamp without time zone DEFAULT now()
);


ALTER TABLE stats.shots OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 31153)
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
-- TOC entry 3749 (class 0 OID 0)
-- Dependencies: 268
-- Name: shots_shot_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.shots_shot_id_seq OWNED BY stats.shots.shot_id;


--
-- TOC entry 273 (class 1259 OID 31204)
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
-- TOC entry 272 (class 1259 OID 31203)
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
-- TOC entry 3750 (class 0 OID 0)
-- Dependencies: 272
-- Name: shutouts_shutout_id_seq; Type: SEQUENCE OWNED BY; Schema: stats; Owner: postgres
--

ALTER SEQUENCE stats.shutouts_shutout_id_seq OWNED BY stats.shutouts.shutout_id;


--
-- TOC entry 3356 (class 2604 OID 30827)
-- Name: genders gender_id; Type: DEFAULT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.genders ALTER COLUMN gender_id SET DEFAULT nextval('admin.genders_gender_id_seq'::regclass);


--
-- TOC entry 3346 (class 2604 OID 30775)
-- Name: league_roles league_role_id; Type: DEFAULT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.league_roles ALTER COLUMN league_role_id SET DEFAULT nextval('admin.league_roles_league_role_id_seq'::regclass);


--
-- TOC entry 3350 (class 2604 OID 30795)
-- Name: playoff_structures playoff_structure_id; Type: DEFAULT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.playoff_structures ALTER COLUMN playoff_structure_id SET DEFAULT nextval('admin.playoff_structures_playoff_structure_id_seq'::regclass);


--
-- TOC entry 3348 (class 2604 OID 30785)
-- Name: season_roles season_role_id; Type: DEFAULT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.season_roles ALTER COLUMN season_role_id SET DEFAULT nextval('admin.season_roles_season_role_id_seq'::regclass);


--
-- TOC entry 3354 (class 2604 OID 30815)
-- Name: sports sport_id; Type: DEFAULT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.sports ALTER COLUMN sport_id SET DEFAULT nextval('admin.sports_sport_id_seq'::regclass);


--
-- TOC entry 3352 (class 2604 OID 30805)
-- Name: team_roles team_role_id; Type: DEFAULT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.team_roles ALTER COLUMN team_role_id SET DEFAULT nextval('admin.team_roles_team_role_id_seq'::regclass);


--
-- TOC entry 3344 (class 2604 OID 30765)
-- Name: user_roles user_role_id; Type: DEFAULT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.user_roles ALTER COLUMN user_role_id SET DEFAULT nextval('admin.user_roles_user_role_id_seq'::regclass);


--
-- TOC entry 3358 (class 2604 OID 30837)
-- Name: users user_id; Type: DEFAULT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users ALTER COLUMN user_id SET DEFAULT nextval('admin.users_user_id_seq'::regclass);


--
-- TOC entry 3385 (class 2604 OID 31048)
-- Name: arenas arena_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.arenas ALTER COLUMN arena_id SET DEFAULT nextval('league_management.arenas_arena_id_seq'::regclass);


--
-- TOC entry 3379 (class 2604 OID 31003)
-- Name: division_rosters division_roster_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_rosters ALTER COLUMN division_roster_id SET DEFAULT nextval('league_management.division_rosters_division_roster_id_seq'::regclass);


--
-- TOC entry 3377 (class 2604 OID 30985)
-- Name: division_teams division_team_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_teams ALTER COLUMN division_team_id SET DEFAULT nextval('league_management.division_teams_division_team_id_seq'::regclass);


--
-- TOC entry 3374 (class 2604 OID 30969)
-- Name: divisions division_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.divisions ALTER COLUMN division_id SET DEFAULT nextval('league_management.divisions_division_id_seq'::regclass);


--
-- TOC entry 3387 (class 2604 OID 31063)
-- Name: games game_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games ALTER COLUMN game_id SET DEFAULT nextval('league_management.games_game_id_seq'::regclass);


--
-- TOC entry 3368 (class 2604 OID 30913)
-- Name: league_admins league_admin_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins ALTER COLUMN league_admin_id SET DEFAULT nextval('league_management.league_admins_league_admin_id_seq'::regclass);


--
-- TOC entry 3366 (class 2604 OID 30896)
-- Name: leagues league_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.leagues ALTER COLUMN league_id SET DEFAULT nextval('league_management.leagues_league_id_seq'::regclass);


--
-- TOC entry 3381 (class 2604 OID 31021)
-- Name: playoffs playoff_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.playoffs ALTER COLUMN playoff_id SET DEFAULT nextval('league_management.playoffs_playoff_id_seq'::regclass);


--
-- TOC entry 3372 (class 2604 OID 30946)
-- Name: season_admins season_admin_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins ALTER COLUMN season_admin_id SET DEFAULT nextval('league_management.season_admins_season_admin_id_seq'::regclass);


--
-- TOC entry 3370 (class 2604 OID 30936)
-- Name: seasons season_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.seasons ALTER COLUMN season_id SET DEFAULT nextval('league_management.seasons_season_id_seq'::regclass);


--
-- TOC entry 3363 (class 2604 OID 30872)
-- Name: team_memberships team_membership_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships ALTER COLUMN team_membership_id SET DEFAULT nextval('league_management.team_memberships_team_membership_id_seq'::regclass);


--
-- TOC entry 3361 (class 2604 OID 30860)
-- Name: teams team_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.teams ALTER COLUMN team_id SET DEFAULT nextval('league_management.teams_team_id_seq'::regclass);


--
-- TOC entry 3383 (class 2604 OID 31036)
-- Name: venues venue_id; Type: DEFAULT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.venues ALTER COLUMN venue_id SET DEFAULT nextval('league_management.venues_venue_id_seq'::regclass);


--
-- TOC entry 3396 (class 2604 OID 31104)
-- Name: assists assist_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists ALTER COLUMN assist_id SET DEFAULT nextval('stats.assists_assist_id_seq'::regclass);


--
-- TOC entry 3391 (class 2604 OID 31078)
-- Name: goals goal_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals ALTER COLUMN goal_id SET DEFAULT nextval('stats.goals_goal_id_seq'::regclass);


--
-- TOC entry 3399 (class 2604 OID 31133)
-- Name: penalties penalty_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties ALTER COLUMN penalty_id SET DEFAULT nextval('stats.penalties_penalty_id_seq'::regclass);


--
-- TOC entry 3406 (class 2604 OID 31182)
-- Name: saves save_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves ALTER COLUMN save_id SET DEFAULT nextval('stats.saves_save_id_seq'::regclass);


--
-- TOC entry 3402 (class 2604 OID 31157)
-- Name: shots shot_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots ALTER COLUMN shot_id SET DEFAULT nextval('stats.shots_shot_id_seq'::regclass);


--
-- TOC entry 3410 (class 2604 OID 31207)
-- Name: shutouts shutout_id; Type: DEFAULT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts ALTER COLUMN shutout_id SET DEFAULT nextval('stats.shutouts_shutout_id_seq'::regclass);


--
-- TOC entry 3678 (class 0 OID 30824)
-- Dependencies: 233
-- Data for Name: genders; Type: TABLE DATA; Schema: admin; Owner: postgres
--

COPY admin.genders (gender_id, slug, name, created_on) FROM stdin;
1	woman	Woman	2025-01-04 15:48:42.16748
2	man	Man	2025-01-04 15:48:42.16748
3	non-binary-non-conforming	Non-binary/Non-conforming	2025-01-04 15:48:42.16748
4	two-spirit	Two-spirit	2025-01-04 15:48:42.16748
\.


--
-- TOC entry 3668 (class 0 OID 30772)
-- Dependencies: 223
-- Data for Name: league_roles; Type: TABLE DATA; Schema: admin; Owner: postgres
--

COPY admin.league_roles (league_role_id, name, description, created_on) FROM stdin;
1	Commissioner	\N	2025-01-04 15:48:42.161313
2	Manager	\N	2025-01-04 15:48:42.161313
\.


--
-- TOC entry 3672 (class 0 OID 30792)
-- Dependencies: 227
-- Data for Name: playoff_structures; Type: TABLE DATA; Schema: admin; Owner: postgres
--

COPY admin.playoff_structures (playoff_structure_id, name, description, created_on) FROM stdin;
1	Bracket	\N	2025-01-04 15:48:42.163783
2	Round Robin + Bracket	\N	2025-01-04 15:48:42.163783
\.


--
-- TOC entry 3670 (class 0 OID 30782)
-- Dependencies: 225
-- Data for Name: season_roles; Type: TABLE DATA; Schema: admin; Owner: postgres
--

COPY admin.season_roles (season_role_id, name, description, created_on) FROM stdin;
1	Manager	\N	2025-01-04 15:48:42.16255
2	Time Keeper	\N	2025-01-04 15:48:42.16255
3	Referee	\N	2025-01-04 15:48:42.16255
\.


--
-- TOC entry 3676 (class 0 OID 30812)
-- Dependencies: 231
-- Data for Name: sports; Type: TABLE DATA; Schema: admin; Owner: postgres
--

COPY admin.sports (sport_id, slug, name, description, created_on) FROM stdin;
1	hockey	Hockey	\N	2025-01-04 15:48:42.166241
2	soccer	Soccer	\N	2025-01-04 15:48:42.166241
3	basketball	Basketball	\N	2025-01-04 15:48:42.166241
4	pickleball	Pickleball	\N	2025-01-04 15:48:42.166241
5	badminton	Badminton	\N	2025-01-04 15:48:42.166241
\.


--
-- TOC entry 3674 (class 0 OID 30802)
-- Dependencies: 229
-- Data for Name: team_roles; Type: TABLE DATA; Schema: admin; Owner: postgres
--

COPY admin.team_roles (team_role_id, name, description, created_on) FROM stdin;
1	Player	\N	2025-01-04 15:48:42.165053
2	Manager	\N	2025-01-04 15:48:42.165053
3	Coach	\N	2025-01-04 15:48:42.165053
4	Captain	\N	2025-01-04 15:48:42.165053
5	Alternate Captain	\N	2025-01-04 15:48:42.165053
\.


--
-- TOC entry 3666 (class 0 OID 30762)
-- Dependencies: 221
-- Data for Name: user_roles; Type: TABLE DATA; Schema: admin; Owner: postgres
--

COPY admin.user_roles (user_role_id, name, description, created_on) FROM stdin;
1	Admin	\N	2025-01-04 15:48:42.160011
2	Commissioner	\N	2025-01-04 15:48:42.160011
3	User	\N	2025-01-04 15:48:42.160011
\.


--
-- TOC entry 3680 (class 0 OID 30834)
-- Dependencies: 235
-- Data for Name: users; Type: TABLE DATA; Schema: admin; Owner: postgres
--

COPY admin.users (user_id, username, email, first_name, last_name, gender_id, pronouns, user_role, password_hash, created_on) FROM stdin;
2	goose	hello+1@adamrobillard.ca	Hannah	Brown	1	she/her	3	heyHannah123	2025-01-04 15:48:42.168771
4	caleb	hello+4@adamrobillard.ca	Caleb	Smith	2	he/him	2	heyCaleb123	2025-01-04 15:48:42.168771
5	kat	hello+5@adamrobillard.ca	Kat	Ferguson	3	they/them	2	heyKat123	2025-01-04 15:48:42.168771
6	trainMan	hello+6@adamrobillard.ca	Stephen	Spence	2	he/him	3	heyStephen123	2025-01-04 15:48:42.168771
7	theGoon	hello+7@adamrobillard.ca	Levi	Bradley	3	they/them	3	heyLevi123	2025-01-04 15:48:42.168771
8	cheryl	hello+8@adamrobillard.ca	Cheryl	Chaos	\N	\N	3	heyCheryl123	2025-01-04 15:48:42.168771
9	mason	hello+9@adamrobillard.ca	Mason	Nonsense	\N	\N	3	heyMasonl123	2025-01-04 15:48:42.168771
10	jayce	hello+10@adamrobillard.ca	Jayce	LeClaire	3	they/them	3	heyJaycel123	2025-01-04 15:48:42.168771
11	britt	hello+110@adamrobillard.ca	Britt	Neron	3	they/them	3	heyBrittl123	2025-01-04 15:48:42.168771
12	tesolin	hello+12@adamrobillard.ca	Zachary	Tesolin	2	he/him	3	heyZach123	2025-01-04 15:48:42.168771
13	robocop	hello+13@adamrobillard.ca	Andrew	Robillard	2	he/him	3	heyAndrew123	2025-01-04 15:48:42.168771
14	trex	hello+14@adamrobillard.ca	Tim	Robillard	2	he/him	3	heyTim123	2025-01-04 15:48:42.168771
15	lukasbauer	lukas.bauer@example.com	Lukas	Bauer	2	he/him	3	heyLukas123	2025-01-04 15:48:42.172724
16	emmaschmidt	emma.schmidt@example.com	Emma	Schmidt	1	she/her	3	heyEmma123	2025-01-04 15:48:42.172724
17	liammüller	liam.mueller@example.com	Liam	Müller	2	he/him	3	heyLiam123	2025-01-04 15:48:42.172724
18	hannafischer	hanna.fischer@example.com	Hanna	Fischer	1	she/her	3	heyHanna123	2025-01-04 15:48:42.172724
19	oliverkoch	oliver.koch@example.com	Oliver	Koch	2	he/him	3	heyOliver123	2025-01-04 15:48:42.172724
20	clararichter	clara.richter@example.com	Clara	Richter	1	she/her	3	heyClara123	2025-01-04 15:48:42.172724
21	noahtaylor	noah.taylor@example.com	Noah	Taylor	2	he/him	3	heyNoah123	2025-01-04 15:48:42.172724
22	lisahoffmann	lisa.hoffmann@example.com	Lisa	Hoffmann	1	she/her	3	heyLisa123	2025-01-04 15:48:42.172724
23	matteorossetti	matteo.rossetti@example.com	Matteo	Rossetti	2	he/him	3	heyMatteo123	2025-01-04 15:48:42.172724
24	giuliarossi	giulia.rossi@example.com	Giulia	Rossi	1	she/her	3	heyGiulia123	2025-01-04 15:48:42.172724
25	danielebrown	daniele.brown@example.com	Daniele	Brown	3	they/them	3	heyDaniele123	2025-01-04 15:48:42.172724
26	sofialopez	sofia.lopez@example.com	Sofia	Lopez	1	she/her	3	heySofia123	2025-01-04 15:48:42.172724
27	sebastienmartin	sebastien.martin@example.com	Sebastien	Martin	2	he/him	3	heySebastien123	2025-01-04 15:48:42.172724
28	elisavolkova	elisa.volkova@example.com	Elisa	Volkova	1	she/her	3	heyElisa123	2025-01-04 15:48:42.172724
29	adriangarcia	adrian.garcia@example.com	Adrian	Garcia	2	he/him	3	heyAdrian123	2025-01-04 15:48:42.172724
30	amelialeroux	amelia.leroux@example.com	Amelia	LeRoux	1	she/her	3	heyAmelia123	2025-01-04 15:48:42.172724
31	kasperskov	kasper.skov@example.com	Kasper	Skov	2	he/him	3	heyKasper123	2025-01-04 15:48:42.172724
32	elinefransen	eline.fransen@example.com	Eline	Fransen	1	she/her	3	heyEline123	2025-01-04 15:48:42.172724
33	andreakovacs	andrea.kovacs@example.com	Andrea	Kovacs	3	they/them	3	heyAndrea123	2025-01-04 15:48:42.172724
34	petersmith	peter.smith@example.com	Peter	Smith	2	he/him	3	heyPeter123	2025-01-04 15:48:42.172724
35	janinanowak	janina.nowak@example.com	Janina	Nowak	1	she/her	3	heyJanina123	2025-01-04 15:48:42.172724
36	niklaspetersen	niklas.petersen@example.com	Niklas	Petersen	2	he/him	3	heyNiklas123	2025-01-04 15:48:42.172724
37	martakalinski	marta.kalinski@example.com	Marta	Kalinski	1	she/her	3	heyMarta123	2025-01-04 15:48:42.172724
38	tomasmarquez	tomas.marquez@example.com	Tomas	Marquez	2	he/him	3	heyTomas123	2025-01-04 15:48:42.172724
39	ireneschneider	irene.schneider@example.com	Irene	Schneider	1	she/her	3	heyIrene123	2025-01-04 15:48:42.172724
40	maximilianbauer	maximilian.bauer@example.com	Maximilian	Bauer	2	he/him	3	heyMaximilian123	2025-01-04 15:48:42.172724
41	annaschaefer	anna.schaefer@example.com	Anna	Schaefer	1	she/her	3	heyAnna123	2025-01-04 15:48:42.172724
42	lucasvargas	lucas.vargas@example.com	Lucas	Vargas	2	he/him	3	heyLucas123	2025-01-04 15:48:42.172724
43	sofiacosta	sofia.costa@example.com	Sofia	Costa	1	she/her	3	heySofia123	2025-01-04 15:48:42.172724
44	alexanderricci	alexander.ricci@example.com	Alexander	Ricci	2	he/him	3	heyAlexander123	2025-01-04 15:48:42.172724
45	noemiecaron	noemie.caron@example.com	Noemie	Caron	1	she/her	3	heyNoemie123	2025-01-04 15:48:42.172724
46	pietrocapello	pietro.capello@example.com	Pietro	Capello	2	he/him	3	heyPietro123	2025-01-04 15:48:42.172724
47	elisabethjensen	elisabeth.jensen@example.com	Elisabeth	Jensen	1	she/her	3	heyElisabeth123	2025-01-04 15:48:42.172724
48	dimitripapadopoulos	dimitri.papadopoulos@example.com	Dimitri	Papadopoulos	2	he/him	3	heyDimitri123	2025-01-04 15:48:42.172724
49	marielaramos	mariela.ramos@example.com	Mariela	Ramos	1	she/her	3	heyMariela123	2025-01-04 15:48:42.172724
50	valeriekeller	valerie.keller@example.com	Valerie	Keller	1	she/her	3	heyValerie123	2025-01-04 15:48:42.172724
51	dominikbauer	dominik.bauer@example.com	Dominik	Bauer	2	he/him	3	heyDominik123	2025-01-04 15:48:42.172724
52	evaweber	eva.weber@example.com	Eva	Weber	1	she/her	3	heyEva123	2025-01-04 15:48:42.172724
53	sebastiancortes	sebastian.cortes@example.com	Sebastian	Cortes	2	he/him	3	heySebastian123	2025-01-04 15:48:42.172724
54	manongarcia	manon.garcia@example.com	Manon	Garcia	1	she/her	3	heyManon123	2025-01-04 15:48:42.172724
55	benjaminflores	benjamin.flores@example.com	Benjamin	Flores	2	he/him	3	heyBenjamin123	2025-01-04 15:48:42.172724
56	saradalgaard	sara.dalgaard@example.com	Sara	Dalgaard	1	she/her	3	heySara123	2025-01-04 15:48:42.172724
57	jonasmartinez	jonas.martinez@example.com	Jonas	Martinez	2	he/him	3	heyJonas123	2025-01-04 15:48:42.172724
58	alessiadonati	alessia.donati@example.com	Alessia	Donati	1	she/her	3	heyAlessia123	2025-01-04 15:48:42.172724
59	lucaskovac	lucas.kovac@example.com	Lucas	Kovac	3	they/them	3	heyLucas123	2025-01-04 15:48:42.172724
60	emiliekoch	emilie.koch@example.com	Emilie	Koch	1	she/her	3	heyEmilie123	2025-01-04 15:48:42.172724
61	danieljones	daniel.jones@example.com	Daniel	Jones	2	he/him	3	heyDaniel123	2025-01-04 15:48:42.172724
62	mathildevogel	mathilde.vogel@example.com	Mathilde	Vogel	1	she/her	3	heyMathilde123	2025-01-04 15:48:42.172724
63	thomasleroux	thomas.leroux@example.com	Thomas	LeRoux	2	he/him	3	heyThomas123	2025-01-04 15:48:42.172724
64	angelaperez	angela.perez@example.com	Angela	Perez	1	she/her	3	heyAngela123	2025-01-04 15:48:42.172724
65	henrikstrom	henrik.strom@example.com	Henrik	Strom	2	he/him	3	heyHenrik123	2025-01-04 15:48:42.172724
66	paulinaklein	paulina.klein@example.com	Paulina	Klein	1	she/her	3	heyPaulina123	2025-01-04 15:48:42.172724
67	raphaelgonzalez	raphael.gonzalez@example.com	Raphael	Gonzalez	2	he/him	3	heyRaphael123	2025-01-04 15:48:42.172724
68	annaluisachavez	anna-luisa.chavez@example.com	Anna-Luisa	Chavez	1	she/her	3	heyAnna-Luisa123	2025-01-04 15:48:42.172724
69	fabiomercier	fabio.mercier@example.com	Fabio	Mercier	2	he/him	3	heyFabio123	2025-01-04 15:48:42.172724
70	nataliefischer	natalie.fischer@example.com	Natalie	Fischer	1	she/her	3	heyNatalie123	2025-01-04 15:48:42.172724
71	georgmayer	georg.mayer@example.com	Georg	Mayer	2	he/him	3	heyGeorg123	2025-01-04 15:48:42.172724
72	julianweiss	julian.weiss@example.com	Julian	Weiss	2	he/him	3	heyJulian123	2025-01-04 15:48:42.172724
73	katharinalopez	katharina.lopez@example.com	Katharina	Lopez	1	she/her	3	heyKatharina123	2025-01-04 15:48:42.172724
74	simonealvarez	simone.alvarez@example.com	Simone	Alvarez	3	they/them	3	heySimone123	2025-01-04 15:48:42.172724
75	frederikschmidt	frederik.schmidt@example.com	Frederik	Schmidt	2	he/him	3	heyFrederik123	2025-01-04 15:48:42.172724
76	mariakoval	maria.koval@example.com	Maria	Koval	1	she/her	3	heyMaria123	2025-01-04 15:48:42.172724
77	lukemccarthy	luke.mccarthy@example.com	Luke	McCarthy	2	he/him	3	heyLuke123	2025-01-04 15:48:42.172724
78	larissahansen	larissa.hansen@example.com	Larissa	Hansen	1	she/her	3	heyLarissa123	2025-01-04 15:48:42.172724
79	adamwalker	adam.walker@example.com	Adam	Walker	2	he/him	3	heyAdam123	2025-01-04 15:48:42.172724
80	paolamendes	paola.mendes@example.com	Paola	Mendes	1	she/her	3	heyPaola123	2025-01-04 15:48:42.172724
81	ethanwilliams	ethan.williams@example.com	Ethan	Williams	2	he/him	3	heyEthan123	2025-01-04 15:48:42.172724
82	evastark	eva.stark@example.com	Eva	Stark	1	she/her	3	heyEva123	2025-01-04 15:48:42.172724
83	juliankovacic	julian.kovacic@example.com	Julian	Kovacic	2	he/him	3	heyJulian123	2025-01-04 15:48:42.172724
84	ameliekrause	amelie.krause@example.com	Amelie	Krause	1	she/her	3	heyAmelie123	2025-01-04 15:48:42.172724
85	ryanschneider	ryan.schneider@example.com	Ryan	Schneider	2	he/him	3	heyRyan123	2025-01-04 15:48:42.172724
86	monikathomsen	monika.thomsen@example.com	Monika	Thomsen	1	she/her	3	heyMonika123	2025-01-04 15:48:42.172724
87	daniellefoster	danielle.foster@example.com	Danielle	Foster	4	she/her	3	heyDanielle123	2025-01-04 15:48:42.172724
88	harrykhan	harry.khan@example.com	Harry	Khan	2	he/him	3	heyHarry123	2025-01-04 15:48:42.172724
89	sophielindgren	sophie.lindgren@example.com	Sophie	Lindgren	1	she/her	3	heySophie123	2025-01-04 15:48:42.172724
90	oskarpetrov	oskar.petrov@example.com	Oskar	Petrov	2	he/him	3	heyOskar123	2025-01-04 15:48:42.172724
91	lindavon	linda.von@example.com	Linda	Von	1	she/her	3	heyLinda123	2025-01-04 15:48:42.172724
92	andreaspeicher	andreas.peicher@example.com	Andreas	Peicher	2	he/him	3	heyAndreas123	2025-01-04 15:48:42.172724
93	josephinejung	josephine.jung@example.com	Josephine	Jung	1	she/her	3	heyJosephine123	2025-01-04 15:48:42.172724
94	marianapaz	mariana.paz@example.com	Mariana	Paz	1	she/her	3	heyMariana123	2025-01-04 15:48:42.172724
95	fionaberg	fiona.berg@example.com	Fiona	Berg	1	she/her	3	heyFiona123	2025-01-04 15:48:42.172724
96	joachimkraus	joachim.kraus@example.com	Joachim	Kraus	2	he/him	3	heyJoachim123	2025-01-04 15:48:42.172724
97	michellebauer	michelle.bauer@example.com	Michelle	Bauer	1	she/her	3	heyMichelle123	2025-01-04 15:48:42.172724
98	mariomatteo	mario.matteo@example.com	Mario	Matteo	2	he/him	3	heyMario123	2025-01-04 15:48:42.172724
99	elizabethsmith	elizabeth.smith@example.com	Elizabeth	Smith	1	she/her	3	heyElizabeth123	2025-01-04 15:48:42.172724
100	ianlennox	ian.lennox@example.com	Ian	Lennox	2	he/him	3	heyIan123	2025-01-04 15:48:42.172724
101	evabradley	eva.bradley@example.com	Eva	Bradley	1	she/her	3	heyEva123	2025-01-04 15:48:42.172724
102	francescoantoni	francesco.antoni@example.com	Francesco	Antoni	2	he/him	3	heyFrancesco123	2025-01-04 15:48:42.172724
103	celinebrown	celine.brown@example.com	Celine	Brown	1	she/her	3	heyCeline123	2025-01-04 15:48:42.172724
104	georgiamills	georgia.mills@example.com	Georgia	Mills	1	she/her	3	heyGeorgia123	2025-01-04 15:48:42.172724
105	antoineclark	antoine.clark@example.com	Antoine	Clark	2	he/him	3	heyAntoine123	2025-01-04 15:48:42.172724
106	valentinwebb	valentin.webb@example.com	Valentin	Webb	2	he/him	3	heyValentin123	2025-01-04 15:48:42.172724
107	oliviamorales	olivia.morales@example.com	Olivia	Morales	1	she/her	3	heyOlivia123	2025-01-04 15:48:42.172724
108	mathieuhebert	mathieu.hebert@example.com	Mathieu	Hebert	2	he/him	3	heyMathieu123	2025-01-04 15:48:42.172724
109	rosepatel	rose.patel@example.com	Rose	Patel	1	she/her	3	heyRose123	2025-01-04 15:48:42.172724
110	travisrichards	travis.richards@example.com	Travis	Richards	2	he/him	3	heyTravis123	2025-01-04 15:48:42.172724
111	josefinklein	josefinklein@example.com	Josefin	Klein	1	she/her	3	heyJosefin123	2025-01-04 15:48:42.172724
112	finnandersen	finn.andersen@example.com	Finn	Andersen	2	he/him	3	heyFinn123	2025-01-04 15:48:42.172724
113	sofiaparker	sofia.parker@example.com	Sofia	Parker	1	she/her	3	heySofia123	2025-01-04 15:48:42.172724
114	theogibson	theo.gibson@example.com	Theo	Gibson	2	he/him	3	heyTheo123	2025-01-04 15:48:42.172724
1	moose	hello+2@adamrobillard.ca	Adam	Robillard	3	any/all	1	$2b$10$7pjrECYElk1ithndcAhtcuPytB2Hc8DiDi3e8gAEXYcfIjOVZdEfS	2025-01-04 15:48:42.168771
3	caboose	hello+3@adamrobillard.ca	Aida	Robillard	3	any/all	1	$2b$10$UM16ckCNhox47R0yOq873uCUX4Pal3GEVlNY8kYszWGGM.Y3kyiZC	2025-01-04 15:48:42.168771
150	gloose	hello+69@adamrobillard.ca	Adam	Robillard	\N	\N	3	$2b$10$qUUjzmm5bns.noufUNgXo.Pb.uQA83Hg/HJYgVQT9lVT/iTtXtvs2	2025-01-08 13:49:02.333955
166	floose	hello@adamrobillard.ca	Adam	Robillard	\N	\N	3	$2b$10$UM16ckCNhox47R0yOq873uCUX4Pal3GEVlNY8kYszWGGM.Y3kyiZC	2025-01-09 13:39:59.308214
167	joose	joe@example.com	Joe	Shmoe	\N	\N	3	$2b$10$H2JAiSZQtXIa7md9NErIeeqlkbMEIQJKaDpTnidB/PCsVZZLTbFPS	2025-01-13 20:26:22.644207
168	swoose	cool@example.com	Hannah	Brown	\N	\N	3	$2b$10$99E/cmhMolqnQFi3E6CXHOpB7zYYANgDToz1F.WkFrZMOXCFBvxji	2025-01-14 18:48:11.489097
\.


--
-- TOC entry 3704 (class 0 OID 31045)
-- Dependencies: 259
-- Data for Name: arenas; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

COPY league_management.arenas (arena_id, slug, name, description, venue_id, created_on) FROM stdin;
1	arena	Arena	\N	1	2025-01-04 15:48:42.196531
2	1	1	\N	2	2025-01-04 15:48:42.196531
3	2	2	\N	2	2025-01-04 15:48:42.196531
4	3	3	\N	2	2025-01-04 15:48:42.196531
5	4	4	\N	2	2025-01-04 15:48:42.196531
6	arena	Arena	\N	3	2025-01-04 15:48:42.196531
7	a	A	\N	4	2025-01-04 15:48:42.196531
8	b	B	\N	4	2025-01-04 15:48:42.196531
9	a	A	\N	5	2025-01-04 15:48:42.196531
10	b	B	\N	5	2025-01-04 15:48:42.196531
11	arena	Arena	\N	6	2025-01-04 15:48:42.196531
12	a	A	\N	7	2025-01-04 15:48:42.196531
13	b	B	\N	7	2025-01-04 15:48:42.196531
14	arena	Arena	\N	8	2025-01-04 15:48:42.196531
15	a	A	\N	9	2025-01-04 15:48:42.196531
16	b	B	\N	9	2025-01-04 15:48:42.196531
17	arena	Arena	\N	10	2025-01-04 15:48:42.196531
\.


--
-- TOC entry 3698 (class 0 OID 31000)
-- Dependencies: 253
-- Data for Name: division_rosters; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

COPY league_management.division_rosters (division_roster_id, division_team_id, user_id, created_on) FROM stdin;
\.


--
-- TOC entry 3696 (class 0 OID 30982)
-- Dependencies: 251
-- Data for Name: division_teams; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

COPY league_management.division_teams (division_team_id, division_id, team_id, created_on) FROM stdin;
1	1	1	2025-01-04 15:48:42.19371
2	1	2	2025-01-04 15:48:42.19371
3	1	3	2025-01-04 15:48:42.19371
4	1	4	2025-01-04 15:48:42.19371
5	4	5	2025-01-04 15:48:42.19371
6	4	6	2025-01-04 15:48:42.19371
7	4	7	2025-01-04 15:48:42.19371
8	4	8	2025-01-04 15:48:42.19371
9	4	9	2025-01-04 15:48:42.19371
\.


--
-- TOC entry 3694 (class 0 OID 30966)
-- Dependencies: 249
-- Data for Name: divisions; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

COPY league_management.divisions (division_id, slug, name, description, tier, gender, season_id, created_on) FROM stdin;
1	div-inc	Div Inc	\N	1	Co-ed	1	2025-01-04 15:48:42.192301
2	div-1	Div 1	\N	1	Co-ed	3	2025-01-04 15:48:42.192301
3	div-2	Div 2	\N	1	Co-ed	3	2025-01-04 15:48:42.192301
4	div-1	Div 1	\N	1	Co-ed	4	2025-01-04 15:48:42.192301
5	div-2	Div 2	\N	2	Co-ed	4	2025-01-04 15:48:42.192301
6	div-3	Div 3	\N	3	Co-ed	4	2025-01-04 15:48:42.192301
7	div-4	Div 4	\N	4	Co-ed	4	2025-01-04 15:48:42.192301
8	div-5	Div 5	\N	5	Co-ed	4	2025-01-04 15:48:42.192301
9	men-35	Men 35+	\N	6	Men	4	2025-01-04 15:48:42.192301
10	women-35	Women 35+	\N	6	Women	4	2025-01-04 15:48:42.192301
\.


--
-- TOC entry 3706 (class 0 OID 31060)
-- Dependencies: 261
-- Data for Name: games; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

COPY league_management.games (game_id, home_team_id, home_team_score, away_team_id, away_team_score, division_id, date_time, arena_id, status, created_on) FROM stdin;
1	1	0	4	0	1	2024-09-08 17:45:00	10	\N	2025-01-04 15:48:42.198036
2	2	0	3	0	1	2024-09-08 18:45:00	10	\N	2025-01-04 15:48:42.198036
3	3	0	1	0	1	2024-09-16 22:00:00	9	\N	2025-01-04 15:48:42.198036
4	4	0	2	0	1	2024-09-16 23:00:00	9	\N	2025-01-04 15:48:42.198036
5	1	0	2	0	1	2024-09-25 21:00:00	9	\N	2025-01-04 15:48:42.198036
6	3	0	4	0	1	2024-09-25 22:00:00	9	\N	2025-01-04 15:48:42.198036
7	1	0	4	0	1	2024-10-03 19:30:00	10	\N	2025-01-04 15:48:42.198036
8	2	0	3	0	1	2024-10-03 20:30:00	10	\N	2025-01-04 15:48:42.198036
9	3	0	1	0	1	2024-10-14 19:00:00	9	\N	2025-01-04 15:48:42.198036
10	4	0	2	0	1	2024-10-14 20:00:00	9	\N	2025-01-04 15:48:42.198036
11	1	0	4	0	1	2024-10-19 20:00:00	9	\N	2025-01-04 15:48:42.198036
12	2	0	3	0	1	2024-10-19 21:00:00	9	\N	2025-01-04 15:48:42.198036
13	1	0	2	0	1	2024-10-30 21:30:00	10	\N	2025-01-04 15:48:42.198036
14	3	0	4	0	1	2024-10-30 22:30:00	10	\N	2025-01-04 15:48:42.198036
15	1	0	4	0	1	2024-11-08 20:30:00	10	\N	2025-01-04 15:48:42.198036
16	2	0	3	0	1	2024-11-08 21:30:00	10	\N	2025-01-04 15:48:42.198036
17	3	0	1	0	1	2024-11-18 20:00:00	9	\N	2025-01-04 15:48:42.198036
18	4	0	2	0	1	2024-11-18 21:00:00	9	\N	2025-01-04 15:48:42.198036
19	1	0	2	0	1	2024-11-27 18:30:00	10	\N	2025-01-04 15:48:42.198036
20	3	0	4	0	1	2024-11-27 19:30:00	10	\N	2025-01-04 15:48:42.198036
21	1	0	4	0	1	2024-12-05 20:30:00	10	\N	2025-01-04 15:48:42.198036
22	2	0	3	0	1	2024-12-05 21:30:00	10	\N	2025-01-04 15:48:42.198036
23	3	0	1	0	1	2024-12-14 18:00:00	9	\N	2025-01-04 15:48:42.198036
24	4	0	2	0	1	2024-12-14 19:00:00	9	\N	2025-01-04 15:48:42.198036
25	1	0	2	0	1	2024-12-23 19:00:00	9	\N	2025-01-04 15:48:42.198036
26	3	0	4	0	1	2024-12-23 20:00:00	9	\N	2025-01-04 15:48:42.198036
27	3	0	4	0	1	2025-01-23 20:00:00	9	\N	2025-01-04 15:48:42.198036
28	1	0	2	0	1	2025-01-23 19:00:00	9	\N	2025-01-04 15:48:42.198036
29	4	0	2	0	1	2025-01-11 20:45:00	10	\N	2025-01-04 15:48:42.198036
30	3	0	1	0	1	2025-01-11 19:45:00	10	\N	2025-01-04 15:48:42.198036
31	2	0	3	0	1	2025-01-02 21:30:00	10	\N	2025-01-04 15:48:42.198036
32	1	0	4	0	1	2025-01-02 20:30:00	10	\N	2025-01-04 15:48:42.198036
\.


--
-- TOC entry 3688 (class 0 OID 30910)
-- Dependencies: 243
-- Data for Name: league_admins; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

COPY league_management.league_admins (league_admin_id, league_role_id, league_id, user_id, created_on) FROM stdin;
1	1	1	5	2025-01-04 15:48:42.188202
2	1	1	10	2025-01-04 15:48:42.188202
3	1	1	11	2025-01-04 15:48:42.188202
4	1	2	4	2025-01-04 15:48:42.188202
5	1	3	1	2025-01-04 15:48:42.188202
6	1	31	1	2025-01-14 16:33:01.028903
7	1	32	1	2025-01-14 16:35:39.879048
\.


--
-- TOC entry 3686 (class 0 OID 30893)
-- Dependencies: 241
-- Data for Name: leagues; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

COPY league_management.leagues (league_id, slug, name, description, sport_id, created_on) FROM stdin;
1	ottawa-pride-hockey	Ottawa Pride Hockey	\N	1	2025-01-04 15:48:42.186811
2	fia-hockey	FIA Hockey	\N	1	2025-01-04 15:48:42.186811
3	hometown-hockey	Hometown Hockey	\N	1	2025-01-04 15:48:42.186811
31	hockey-time-party	Hockey Time Party	This is a great hockey league!	1	2025-01-14 16:33:01.02446
32	sick-sellies-soccer	Sick Sellies Soccer	This is a great soccer league!	2	2025-01-14 16:35:39.875062
\.


--
-- TOC entry 3700 (class 0 OID 31018)
-- Dependencies: 255
-- Data for Name: playoffs; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

COPY league_management.playoffs (playoff_id, slug, name, description, playoff_structure_id, created_on) FROM stdin;
\.


--
-- TOC entry 3692 (class 0 OID 30943)
-- Dependencies: 247
-- Data for Name: season_admins; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

COPY league_management.season_admins (season_admin_id, season_role_id, season_id, user_id, created_on) FROM stdin;
1	1	3	1	2025-01-04 15:48:42.190904
2	1	4	3	2025-01-04 15:48:42.190904
\.


--
-- TOC entry 3690 (class 0 OID 30933)
-- Dependencies: 245
-- Data for Name: seasons; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

COPY league_management.seasons (season_id, slug, name, description, league_id, start_date, end_date, created_on) FROM stdin;
1	winter-2024-2025	Winter 2024/2025	\N	1	2024-09-01	2025-03-31	2025-01-04 15:48:42.189845
2	2023-2024-season	2023-2024 Season	\N	2	2023-09-01	2024-03-31	2025-01-04 15:48:42.189845
3	2024-2025-season	2024-2025 Season	\N	2	2024-09-01	2025-03-31	2025-01-04 15:48:42.189845
4	2024-2025-season	2024-2025 Season	\N	3	2024-09-01	2025-03-31	2025-01-04 15:48:42.189845
\.


--
-- TOC entry 3684 (class 0 OID 30869)
-- Dependencies: 239
-- Data for Name: team_memberships; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

COPY league_management.team_memberships (team_membership_id, user_id, team_id, team_role_id, created_on) FROM stdin;
1	6	1	4	2025-01-04 15:48:42.179702
2	7	1	5	2025-01-04 15:48:42.179702
3	10	2	4	2025-01-04 15:48:42.179702
4	3	2	5	2025-01-04 15:48:42.179702
5	8	3	4	2025-01-04 15:48:42.179702
6	11	3	5	2025-01-04 15:48:42.179702
7	9	4	4	2025-01-04 15:48:42.179702
8	5	4	5	2025-01-04 15:48:42.179702
9	15	1	1	2025-01-04 15:48:42.181587
10	16	1	1	2025-01-04 15:48:42.181587
11	17	1	1	2025-01-04 15:48:42.181587
12	18	1	1	2025-01-04 15:48:42.181587
13	19	1	1	2025-01-04 15:48:42.181587
14	20	1	1	2025-01-04 15:48:42.181587
15	21	1	1	2025-01-04 15:48:42.181587
16	22	1	1	2025-01-04 15:48:42.181587
17	23	1	1	2025-01-04 15:48:42.181587
18	24	1	1	2025-01-04 15:48:42.181587
19	25	1	1	2025-01-04 15:48:42.181587
20	26	1	1	2025-01-04 15:48:42.181587
21	27	2	1	2025-01-04 15:48:42.181587
22	28	2	1	2025-01-04 15:48:42.181587
23	29	2	1	2025-01-04 15:48:42.181587
24	30	2	1	2025-01-04 15:48:42.181587
25	31	2	1	2025-01-04 15:48:42.181587
26	32	2	1	2025-01-04 15:48:42.181587
27	33	2	1	2025-01-04 15:48:42.181587
28	34	2	1	2025-01-04 15:48:42.181587
29	35	2	1	2025-01-04 15:48:42.181587
30	36	2	1	2025-01-04 15:48:42.181587
31	37	2	1	2025-01-04 15:48:42.181587
32	38	2	1	2025-01-04 15:48:42.181587
33	39	3	1	2025-01-04 15:48:42.181587
34	40	3	1	2025-01-04 15:48:42.181587
35	41	3	1	2025-01-04 15:48:42.181587
36	42	3	1	2025-01-04 15:48:42.181587
37	43	3	1	2025-01-04 15:48:42.181587
38	44	3	1	2025-01-04 15:48:42.181587
39	45	3	1	2025-01-04 15:48:42.181587
40	46	3	1	2025-01-04 15:48:42.181587
41	47	3	1	2025-01-04 15:48:42.181587
42	48	3	1	2025-01-04 15:48:42.181587
43	49	3	1	2025-01-04 15:48:42.181587
44	50	3	1	2025-01-04 15:48:42.181587
45	51	4	1	2025-01-04 15:48:42.181587
46	52	4	1	2025-01-04 15:48:42.181587
47	53	4	1	2025-01-04 15:48:42.181587
48	54	4	1	2025-01-04 15:48:42.181587
49	55	4	1	2025-01-04 15:48:42.181587
50	56	4	1	2025-01-04 15:48:42.181587
51	57	4	1	2025-01-04 15:48:42.181587
52	58	4	1	2025-01-04 15:48:42.181587
53	59	4	1	2025-01-04 15:48:42.181587
54	60	4	1	2025-01-04 15:48:42.181587
55	61	4	1	2025-01-04 15:48:42.181587
56	62	4	1	2025-01-04 15:48:42.181587
57	1	5	4	2025-01-04 15:48:42.183753
58	12	6	4	2025-01-04 15:48:42.183753
59	13	7	4	2025-01-04 15:48:42.183753
60	4	8	4	2025-01-04 15:48:42.183753
61	14	9	4	2025-01-04 15:48:42.183753
62	60	5	1	2025-01-04 15:48:42.184873
63	61	5	1	2025-01-04 15:48:42.184873
64	62	5	1	2025-01-04 15:48:42.184873
65	63	5	1	2025-01-04 15:48:42.184873
66	64	5	1	2025-01-04 15:48:42.184873
67	65	5	1	2025-01-04 15:48:42.184873
68	66	5	1	2025-01-04 15:48:42.184873
69	67	5	1	2025-01-04 15:48:42.184873
70	68	5	1	2025-01-04 15:48:42.184873
71	69	5	1	2025-01-04 15:48:42.184873
72	70	6	1	2025-01-04 15:48:42.184873
73	71	6	1	2025-01-04 15:48:42.184873
74	72	6	1	2025-01-04 15:48:42.184873
75	73	6	1	2025-01-04 15:48:42.184873
76	74	6	1	2025-01-04 15:48:42.184873
77	75	6	1	2025-01-04 15:48:42.184873
78	76	6	1	2025-01-04 15:48:42.184873
79	77	6	1	2025-01-04 15:48:42.184873
80	78	6	1	2025-01-04 15:48:42.184873
81	79	6	1	2025-01-04 15:48:42.184873
82	80	7	1	2025-01-04 15:48:42.184873
83	81	7	1	2025-01-04 15:48:42.184873
84	82	7	1	2025-01-04 15:48:42.184873
85	83	7	1	2025-01-04 15:48:42.184873
86	84	7	1	2025-01-04 15:48:42.184873
87	85	7	1	2025-01-04 15:48:42.184873
88	86	7	1	2025-01-04 15:48:42.184873
89	87	7	1	2025-01-04 15:48:42.184873
90	88	7	1	2025-01-04 15:48:42.184873
91	89	7	1	2025-01-04 15:48:42.184873
92	90	8	1	2025-01-04 15:48:42.184873
93	91	8	1	2025-01-04 15:48:42.184873
94	92	8	1	2025-01-04 15:48:42.184873
95	93	8	1	2025-01-04 15:48:42.184873
96	94	8	1	2025-01-04 15:48:42.184873
97	95	8	1	2025-01-04 15:48:42.184873
98	96	8	1	2025-01-04 15:48:42.184873
99	97	8	1	2025-01-04 15:48:42.184873
100	98	8	1	2025-01-04 15:48:42.184873
101	99	8	1	2025-01-04 15:48:42.184873
102	100	9	1	2025-01-04 15:48:42.184873
103	101	9	1	2025-01-04 15:48:42.184873
104	102	9	1	2025-01-04 15:48:42.184873
105	103	9	1	2025-01-04 15:48:42.184873
106	104	9	1	2025-01-04 15:48:42.184873
107	105	9	1	2025-01-04 15:48:42.184873
108	106	9	1	2025-01-04 15:48:42.184873
109	107	9	1	2025-01-04 15:48:42.184873
110	108	9	1	2025-01-04 15:48:42.184873
111	109	9	1	2025-01-04 15:48:42.184873
112	1	2	5	2025-01-13 17:14:43.521391
\.


--
-- TOC entry 3682 (class 0 OID 30857)
-- Dependencies: 237
-- Data for Name: teams; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

COPY league_management.teams (team_id, slug, name, description, created_on) FROM stdin;
1	significant-otters	Significant Otters	\N	2025-01-04 15:48:42.178389
2	otterwa-senators	Otterwa Senators	\N	2025-01-04 15:48:42.178389
3	otter-chaos	Otter Chaos	\N	2025-01-04 15:48:42.178389
4	otter-nonsense	Otter Nonsense	\N	2025-01-04 15:48:42.178389
5	frostbiters	Frostbiters	An icy team known for their chilling defense.	2025-01-04 15:48:42.178389
6	blazing-blizzards	Blazing Blizzards	A team that combines fiery offense with frosty precision.	2025-01-04 15:48:42.178389
7	polar-puckers	Polar Puckers	Masters of the north, specializing in swift plays.	2025-01-04 15:48:42.178389
8	arctic-avengers	Arctic Avengers	A cold-blooded team with a knack for thrilling comebacks.	2025-01-04 15:48:42.178389
9	glacial-guardians	Glacial Guardians	Defensive titans who freeze their opponents in their tracks.	2025-01-04 15:48:42.178389
10	tundra-titans	Tundra Titans	A powerhouse team dominating the ice with strength and speed.	2025-01-04 15:48:42.178389
11	permafrost-predators	Permafrost Predators	Known for their unrelenting pressure and icy precision.	2025-01-04 15:48:42.178389
12	snowstorm-scorchers	Snowstorm Scorchers	A team with a fiery spirit and unstoppable energy.	2025-01-04 15:48:42.178389
13	frozen-flames	Frozen Flames	Bringing the heat to the ice with blazing fast attacks.	2025-01-04 15:48:42.178389
14	chill-crushers	Chill Crushers	Breaking the ice with powerful plays and intense rivalries.	2025-01-04 15:48:42.178389
\.


--
-- TOC entry 3702 (class 0 OID 31033)
-- Dependencies: 257
-- Data for Name: venues; Type: TABLE DATA; Schema: league_management; Owner: postgres
--

COPY league_management.venues (venue_id, slug, name, description, address, created_on) FROM stdin;
1	canadian-tire-centre	Canadian Tire Centre	Home of the NHL's Ottawa Senators, this state-of-the-art entertainment facility seats 19,153 spectators.	1000 Palladium Dr, Ottawa, ON K2V 1A5	2025-01-04 15:48:42.19522
2	bell-sensplex	Bell Sensplex	A multi-purpose sports facility featuring four NHL-sized ice rinks, including an Olympic-sized rink, operated by Capital Sports Management.	1565 Maple Grove Rd, Ottawa, ON K2V 1A3	2025-01-04 15:48:42.19522
3	td-place-arena	TD Place Arena	An indoor arena located at Lansdowne Park, hosting the Ottawa 67's (OHL) and Ottawa Blackjacks (CEBL), with a seating capacity of up to 8,585.	1015 Bank St, Ottawa, ON K1S 3W7	2025-01-04 15:48:42.19522
4	minto-sports-complex-arena	Minto Sports Complex Arena	Part of the University of Ottawa, this complex contains two ice rinks, one with seating for 840 spectators, and the Draft Pub overlooking the ice.	801 King Edward Ave, Ottawa, ON K1N 6N5	2025-01-04 15:48:42.19522
5	carleton-university-ice-house	Carleton University Ice House	A leading indoor skating facility featuring two NHL-sized ice surfaces, home to the Carleton Ravens hockey teams.	1125 Colonel By Dr, Ottawa, ON K1S 5B6	2025-01-04 15:48:42.19522
6	howard-darwin-centennial-arena	Howard Darwin Centennial Arena	A community arena offering ice rentals and public skating programs, managed by the City of Ottawa.	1765 Merivale Rd, Ottawa, ON K2G 1E1	2025-01-04 15:48:42.19522
7	fred-barrett-arena	Fred Barrett Arena	A municipal arena providing ice rentals and public skating, located in the southern part of Ottawa.	3280 Leitrim Rd, Ottawa, ON K1T 3Z4	2025-01-04 15:48:42.19522
8	blackburn-arena	Blackburn Arena	A community arena offering skating programs and ice rentals, serving the Blackburn Hamlet area.	200 Glen Park Dr, Gloucester, ON K1B 5A3	2025-01-04 15:48:42.19522
9	bob-macquarrie-recreation-complex-orlans-arena	Bob MacQuarrie Recreation Complex – Orléans Arena	A recreation complex featuring an arena, pool, and fitness facilities, serving the Orléans community.	1490 Youville Dr, Orléans, ON K1C 2X8	2025-01-04 15:48:42.19522
10	brewer-arena	Brewer Arena	A municipal arena adjacent to Brewer Park, offering public skating and ice rentals.	200 Hopewell Ave, Ottawa, ON K1S 2Z5	2025-01-04 15:48:42.19522
\.


--
-- TOC entry 3710 (class 0 OID 31101)
-- Dependencies: 265
-- Data for Name: assists; Type: TABLE DATA; Schema: stats; Owner: postgres
--

COPY stats.assists (assist_id, goal_id, game_id, user_id, team_id, primary_assist, created_on) FROM stdin;
1	1	2	29	2	t	2025-01-04 15:48:42.2015
2	1	2	3	2	f	2025-01-04 15:48:42.2015
3	2	2	10	2	t	2025-01-04 15:48:42.2015
4	3	2	48	3	t	2025-01-04 15:48:42.2015
\.


--
-- TOC entry 3708 (class 0 OID 31075)
-- Dependencies: 263
-- Data for Name: goals; Type: TABLE DATA; Schema: stats; Owner: postgres
--

COPY stats.goals (goal_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, empty_net, created_on) FROM stdin;
1	2	3	2	1	05:27:00	f	f	f	2025-01-04 15:48:42.199921
2	2	10	2	1	15:33:00	f	f	f	2025-01-04 15:48:42.199921
3	2	11	3	2	03:19:00	f	f	f	2025-01-04 15:48:42.199921
4	2	3	2	2	18:27:00	f	f	f	2025-01-04 15:48:42.199921
\.


--
-- TOC entry 3712 (class 0 OID 31130)
-- Dependencies: 267
-- Data for Name: penalties; Type: TABLE DATA; Schema: stats; Owner: postgres
--

COPY stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) FROM stdin;
\.


--
-- TOC entry 3716 (class 0 OID 31179)
-- Dependencies: 271
-- Data for Name: saves; Type: TABLE DATA; Schema: stats; Owner: postgres
--

COPY stats.saves (save_id, game_id, user_id, team_id, period, period_time, penalty_kill, rebound, created_on) FROM stdin;
\.


--
-- TOC entry 3714 (class 0 OID 31154)
-- Dependencies: 269
-- Data for Name: shots; Type: TABLE DATA; Schema: stats; Owner: postgres
--

COPY stats.shots (shot_id, game_id, user_id, team_id, period, period_time, shorthanded, power_play, created_on) FROM stdin;
\.


--
-- TOC entry 3718 (class 0 OID 31204)
-- Dependencies: 273
-- Data for Name: shutouts; Type: TABLE DATA; Schema: stats; Owner: postgres
--

COPY stats.shutouts (shutout_id, game_id, user_id, team_id, created_on) FROM stdin;
\.


--
-- TOC entry 3751 (class 0 OID 0)
-- Dependencies: 232
-- Name: genders_gender_id_seq; Type: SEQUENCE SET; Schema: admin; Owner: postgres
--

SELECT pg_catalog.setval('admin.genders_gender_id_seq', 4, true);


--
-- TOC entry 3752 (class 0 OID 0)
-- Dependencies: 222
-- Name: league_roles_league_role_id_seq; Type: SEQUENCE SET; Schema: admin; Owner: postgres
--

SELECT pg_catalog.setval('admin.league_roles_league_role_id_seq', 2, true);


--
-- TOC entry 3753 (class 0 OID 0)
-- Dependencies: 226
-- Name: playoff_structures_playoff_structure_id_seq; Type: SEQUENCE SET; Schema: admin; Owner: postgres
--

SELECT pg_catalog.setval('admin.playoff_structures_playoff_structure_id_seq', 2, true);


--
-- TOC entry 3754 (class 0 OID 0)
-- Dependencies: 224
-- Name: season_roles_season_role_id_seq; Type: SEQUENCE SET; Schema: admin; Owner: postgres
--

SELECT pg_catalog.setval('admin.season_roles_season_role_id_seq', 3, true);


--
-- TOC entry 3755 (class 0 OID 0)
-- Dependencies: 230
-- Name: sports_sport_id_seq; Type: SEQUENCE SET; Schema: admin; Owner: postgres
--

SELECT pg_catalog.setval('admin.sports_sport_id_seq', 5, true);


--
-- TOC entry 3756 (class 0 OID 0)
-- Dependencies: 228
-- Name: team_roles_team_role_id_seq; Type: SEQUENCE SET; Schema: admin; Owner: postgres
--

SELECT pg_catalog.setval('admin.team_roles_team_role_id_seq', 5, true);


--
-- TOC entry 3757 (class 0 OID 0)
-- Dependencies: 220
-- Name: user_roles_user_role_id_seq; Type: SEQUENCE SET; Schema: admin; Owner: postgres
--

SELECT pg_catalog.setval('admin.user_roles_user_role_id_seq', 3, true);


--
-- TOC entry 3758 (class 0 OID 0)
-- Dependencies: 234
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: admin; Owner: postgres
--

SELECT pg_catalog.setval('admin.users_user_id_seq', 168, true);


--
-- TOC entry 3759 (class 0 OID 0)
-- Dependencies: 258
-- Name: arenas_arena_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.arenas_arena_id_seq', 1, false);


--
-- TOC entry 3760 (class 0 OID 0)
-- Dependencies: 252
-- Name: division_rosters_division_roster_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.division_rosters_division_roster_id_seq', 1, false);


--
-- TOC entry 3761 (class 0 OID 0)
-- Dependencies: 250
-- Name: division_teams_division_team_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.division_teams_division_team_id_seq', 9, true);


--
-- TOC entry 3762 (class 0 OID 0)
-- Dependencies: 248
-- Name: divisions_division_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.divisions_division_id_seq', 10, true);


--
-- TOC entry 3763 (class 0 OID 0)
-- Dependencies: 260
-- Name: games_game_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.games_game_id_seq', 32, true);


--
-- TOC entry 3764 (class 0 OID 0)
-- Dependencies: 242
-- Name: league_admins_league_admin_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.league_admins_league_admin_id_seq', 7, true);


--
-- TOC entry 3765 (class 0 OID 0)
-- Dependencies: 240
-- Name: leagues_league_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.leagues_league_id_seq', 32, true);


--
-- TOC entry 3766 (class 0 OID 0)
-- Dependencies: 254
-- Name: playoffs_playoff_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.playoffs_playoff_id_seq', 1, false);


--
-- TOC entry 3767 (class 0 OID 0)
-- Dependencies: 246
-- Name: season_admins_season_admin_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.season_admins_season_admin_id_seq', 2, true);


--
-- TOC entry 3768 (class 0 OID 0)
-- Dependencies: 244
-- Name: seasons_season_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.seasons_season_id_seq', 4, true);


--
-- TOC entry 3769 (class 0 OID 0)
-- Dependencies: 238
-- Name: team_memberships_team_membership_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.team_memberships_team_membership_id_seq', 112, true);


--
-- TOC entry 3770 (class 0 OID 0)
-- Dependencies: 236
-- Name: teams_team_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.teams_team_id_seq', 1, false);


--
-- TOC entry 3771 (class 0 OID 0)
-- Dependencies: 256
-- Name: venues_venue_id_seq; Type: SEQUENCE SET; Schema: league_management; Owner: postgres
--

SELECT pg_catalog.setval('league_management.venues_venue_id_seq', 1, false);


--
-- TOC entry 3772 (class 0 OID 0)
-- Dependencies: 264
-- Name: assists_assist_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.assists_assist_id_seq', 4, true);


--
-- TOC entry 3773 (class 0 OID 0)
-- Dependencies: 262
-- Name: goals_goal_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.goals_goal_id_seq', 4, true);


--
-- TOC entry 3774 (class 0 OID 0)
-- Dependencies: 266
-- Name: penalties_penalty_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.penalties_penalty_id_seq', 1, false);


--
-- TOC entry 3775 (class 0 OID 0)
-- Dependencies: 270
-- Name: saves_save_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.saves_save_id_seq', 1, false);


--
-- TOC entry 3776 (class 0 OID 0)
-- Dependencies: 268
-- Name: shots_shot_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.shots_shot_id_seq', 1, false);


--
-- TOC entry 3777 (class 0 OID 0)
-- Dependencies: 272
-- Name: shutouts_shutout_id_seq; Type: SEQUENCE SET; Schema: stats; Owner: postgres
--

SELECT pg_catalog.setval('stats.shutouts_shutout_id_seq', 1, false);


--
-- TOC entry 3427 (class 2606 OID 30830)
-- Name: genders genders_pkey; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.genders
    ADD CONSTRAINT genders_pkey PRIMARY KEY (gender_id);


--
-- TOC entry 3429 (class 2606 OID 30832)
-- Name: genders genders_slug_key; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.genders
    ADD CONSTRAINT genders_slug_key UNIQUE (slug);


--
-- TOC entry 3415 (class 2606 OID 30780)
-- Name: league_roles league_roles_pkey; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.league_roles
    ADD CONSTRAINT league_roles_pkey PRIMARY KEY (league_role_id);


--
-- TOC entry 3419 (class 2606 OID 30800)
-- Name: playoff_structures playoff_structures_pkey; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.playoff_structures
    ADD CONSTRAINT playoff_structures_pkey PRIMARY KEY (playoff_structure_id);


--
-- TOC entry 3417 (class 2606 OID 30790)
-- Name: season_roles season_roles_pkey; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.season_roles
    ADD CONSTRAINT season_roles_pkey PRIMARY KEY (season_role_id);


--
-- TOC entry 3423 (class 2606 OID 30820)
-- Name: sports sports_pkey; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.sports
    ADD CONSTRAINT sports_pkey PRIMARY KEY (sport_id);


--
-- TOC entry 3425 (class 2606 OID 30822)
-- Name: sports sports_slug_key; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.sports
    ADD CONSTRAINT sports_slug_key UNIQUE (slug);


--
-- TOC entry 3421 (class 2606 OID 30810)
-- Name: team_roles team_roles_pkey; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.team_roles
    ADD CONSTRAINT team_roles_pkey PRIMARY KEY (team_role_id);


--
-- TOC entry 3413 (class 2606 OID 30770)
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_role_id);


--
-- TOC entry 3431 (class 2606 OID 30845)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3433 (class 2606 OID 30841)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 3435 (class 2606 OID 30843)
-- Name: users users_username_key; Type: CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 3465 (class 2606 OID 31053)
-- Name: arenas arenas_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.arenas
    ADD CONSTRAINT arenas_pkey PRIMARY KEY (arena_id);


--
-- TOC entry 3457 (class 2606 OID 31006)
-- Name: division_rosters division_rosters_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_rosters
    ADD CONSTRAINT division_rosters_pkey PRIMARY KEY (division_roster_id);


--
-- TOC entry 3455 (class 2606 OID 30988)
-- Name: division_teams division_teams_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_teams
    ADD CONSTRAINT division_teams_pkey PRIMARY KEY (division_team_id);


--
-- TOC entry 3453 (class 2606 OID 30975)
-- Name: divisions divisions_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.divisions
    ADD CONSTRAINT divisions_pkey PRIMARY KEY (division_id);


--
-- TOC entry 3467 (class 2606 OID 31068)
-- Name: games games_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games
    ADD CONSTRAINT games_pkey PRIMARY KEY (game_id);


--
-- TOC entry 3447 (class 2606 OID 30916)
-- Name: league_admins league_admins_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins
    ADD CONSTRAINT league_admins_pkey PRIMARY KEY (league_admin_id);


--
-- TOC entry 3443 (class 2606 OID 30901)
-- Name: leagues leagues_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.leagues
    ADD CONSTRAINT leagues_pkey PRIMARY KEY (league_id);


--
-- TOC entry 3445 (class 2606 OID 30903)
-- Name: leagues leagues_slug_key; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.leagues
    ADD CONSTRAINT leagues_slug_key UNIQUE (slug);


--
-- TOC entry 3459 (class 2606 OID 31026)
-- Name: playoffs playoffs_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.playoffs
    ADD CONSTRAINT playoffs_pkey PRIMARY KEY (playoff_id);


--
-- TOC entry 3451 (class 2606 OID 30949)
-- Name: season_admins season_admins_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins
    ADD CONSTRAINT season_admins_pkey PRIMARY KEY (season_admin_id);


--
-- TOC entry 3449 (class 2606 OID 30941)
-- Name: seasons seasons_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.seasons
    ADD CONSTRAINT seasons_pkey PRIMARY KEY (season_id);


--
-- TOC entry 3441 (class 2606 OID 30876)
-- Name: team_memberships team_memberships_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships
    ADD CONSTRAINT team_memberships_pkey PRIMARY KEY (team_membership_id);


--
-- TOC entry 3437 (class 2606 OID 30865)
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (team_id);


--
-- TOC entry 3439 (class 2606 OID 30867)
-- Name: teams teams_slug_key; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.teams
    ADD CONSTRAINT teams_slug_key UNIQUE (slug);


--
-- TOC entry 3461 (class 2606 OID 31041)
-- Name: venues venues_pkey; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.venues
    ADD CONSTRAINT venues_pkey PRIMARY KEY (venue_id);


--
-- TOC entry 3463 (class 2606 OID 31043)
-- Name: venues venues_slug_key; Type: CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.venues
    ADD CONSTRAINT venues_slug_key UNIQUE (slug);


--
-- TOC entry 3471 (class 2606 OID 31108)
-- Name: assists assists_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT assists_pkey PRIMARY KEY (assist_id);


--
-- TOC entry 3469 (class 2606 OID 31084)
-- Name: goals goals_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals
    ADD CONSTRAINT goals_pkey PRIMARY KEY (goal_id);


--
-- TOC entry 3473 (class 2606 OID 31137)
-- Name: penalties penalties_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties
    ADD CONSTRAINT penalties_pkey PRIMARY KEY (penalty_id);


--
-- TOC entry 3477 (class 2606 OID 31187)
-- Name: saves saves_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT saves_pkey PRIMARY KEY (save_id);


--
-- TOC entry 3475 (class 2606 OID 31162)
-- Name: shots shots_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT shots_pkey PRIMARY KEY (shot_id);


--
-- TOC entry 3479 (class 2606 OID 31210)
-- Name: shutouts shutouts_pkey; Type: CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts
    ADD CONSTRAINT shutouts_pkey PRIMARY KEY (shutout_id);


--
-- TOC entry 3519 (class 2620 OID 31228)
-- Name: leagues set_leagues_slug; Type: TRIGGER; Schema: league_management; Owner: postgres
--

CREATE TRIGGER set_leagues_slug BEFORE INSERT ON league_management.leagues FOR EACH ROW WHEN ((new.slug IS NULL)) EXECUTE FUNCTION league_management.generate_unique_slug();


--
-- TOC entry 3480 (class 2606 OID 30851)
-- Name: users fk_users_gender_id; Type: FK CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users
    ADD CONSTRAINT fk_users_gender_id FOREIGN KEY (gender_id) REFERENCES admin.genders(gender_id);


--
-- TOC entry 3481 (class 2606 OID 30846)
-- Name: users fk_users_user_role; Type: FK CONSTRAINT; Schema: admin; Owner: postgres
--

ALTER TABLE ONLY admin.users
    ADD CONSTRAINT fk_users_user_role FOREIGN KEY (user_role) REFERENCES admin.user_roles(user_role_id);


--
-- TOC entry 3498 (class 2606 OID 31054)
-- Name: arenas fk_arena_venue_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.arenas
    ADD CONSTRAINT fk_arena_venue_id FOREIGN KEY (venue_id) REFERENCES league_management.venues(venue_id);


--
-- TOC entry 3495 (class 2606 OID 31007)
-- Name: division_rosters fk_division_rosters_division_team_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_rosters
    ADD CONSTRAINT fk_division_rosters_division_team_id FOREIGN KEY (division_team_id) REFERENCES league_management.division_teams(division_team_id);


--
-- TOC entry 3496 (class 2606 OID 31012)
-- Name: division_rosters fk_division_rosters_user_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_rosters
    ADD CONSTRAINT fk_division_rosters_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id);


--
-- TOC entry 3493 (class 2606 OID 30989)
-- Name: division_teams fk_division_teams_division_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_teams
    ADD CONSTRAINT fk_division_teams_division_id FOREIGN KEY (division_id) REFERENCES league_management.divisions(division_id);


--
-- TOC entry 3494 (class 2606 OID 30994)
-- Name: division_teams fk_division_teams_team_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.division_teams
    ADD CONSTRAINT fk_division_teams_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id);


--
-- TOC entry 3492 (class 2606 OID 30976)
-- Name: divisions fk_divisions_season_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.divisions
    ADD CONSTRAINT fk_divisions_season_id FOREIGN KEY (season_id) REFERENCES league_management.seasons(season_id);


--
-- TOC entry 3499 (class 2606 OID 31069)
-- Name: games fk_game_arena_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.games
    ADD CONSTRAINT fk_game_arena_id FOREIGN KEY (arena_id) REFERENCES league_management.arenas(arena_id);


--
-- TOC entry 3486 (class 2606 OID 30922)
-- Name: league_admins fk_league_admins_league_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins
    ADD CONSTRAINT fk_league_admins_league_id FOREIGN KEY (league_id) REFERENCES league_management.leagues(league_id);


--
-- TOC entry 3487 (class 2606 OID 30917)
-- Name: league_admins fk_league_admins_league_role_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins
    ADD CONSTRAINT fk_league_admins_league_role_id FOREIGN KEY (league_role_id) REFERENCES admin.league_roles(league_role_id);


--
-- TOC entry 3488 (class 2606 OID 30927)
-- Name: league_admins fk_league_admins_user_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.league_admins
    ADD CONSTRAINT fk_league_admins_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id);


--
-- TOC entry 3485 (class 2606 OID 30904)
-- Name: leagues fk_leagues_sport_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.leagues
    ADD CONSTRAINT fk_leagues_sport_id FOREIGN KEY (sport_id) REFERENCES admin.sports(sport_id);


--
-- TOC entry 3497 (class 2606 OID 31027)
-- Name: playoffs fk_playoffs_playoff_structure_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.playoffs
    ADD CONSTRAINT fk_playoffs_playoff_structure_id FOREIGN KEY (playoff_structure_id) REFERENCES admin.playoff_structures(playoff_structure_id);


--
-- TOC entry 3489 (class 2606 OID 30955)
-- Name: season_admins fk_season_admins_season_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins
    ADD CONSTRAINT fk_season_admins_season_id FOREIGN KEY (season_id) REFERENCES league_management.seasons(season_id);


--
-- TOC entry 3490 (class 2606 OID 30950)
-- Name: season_admins fk_season_admins_season_role_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins
    ADD CONSTRAINT fk_season_admins_season_role_id FOREIGN KEY (season_role_id) REFERENCES admin.season_roles(season_role_id);


--
-- TOC entry 3491 (class 2606 OID 30960)
-- Name: season_admins fk_season_admins_user_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.season_admins
    ADD CONSTRAINT fk_season_admins_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id);


--
-- TOC entry 3482 (class 2606 OID 30882)
-- Name: team_memberships fk_team_memberships_team_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships
    ADD CONSTRAINT fk_team_memberships_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id);


--
-- TOC entry 3483 (class 2606 OID 30887)
-- Name: team_memberships fk_team_memberships_team_role_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships
    ADD CONSTRAINT fk_team_memberships_team_role_id FOREIGN KEY (team_role_id) REFERENCES admin.team_roles(team_role_id);


--
-- TOC entry 3484 (class 2606 OID 30877)
-- Name: team_memberships fk_team_memberships_user_id; Type: FK CONSTRAINT; Schema: league_management; Owner: postgres
--

ALTER TABLE ONLY league_management.team_memberships
    ADD CONSTRAINT fk_team_memberships_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id);


--
-- TOC entry 3503 (class 2606 OID 31114)
-- Name: assists fk_assists_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT fk_assists_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id);


--
-- TOC entry 3504 (class 2606 OID 31109)
-- Name: assists fk_assists_goal_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT fk_assists_goal_id FOREIGN KEY (goal_id) REFERENCES stats.goals(goal_id);


--
-- TOC entry 3505 (class 2606 OID 31124)
-- Name: assists fk_assists_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT fk_assists_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id);


--
-- TOC entry 3506 (class 2606 OID 31119)
-- Name: assists fk_assists_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.assists
    ADD CONSTRAINT fk_assists_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id);


--
-- TOC entry 3500 (class 2606 OID 31085)
-- Name: goals fk_goals_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals
    ADD CONSTRAINT fk_goals_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id);


--
-- TOC entry 3501 (class 2606 OID 31095)
-- Name: goals fk_goals_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals
    ADD CONSTRAINT fk_goals_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id);


--
-- TOC entry 3502 (class 2606 OID 31090)
-- Name: goals fk_goals_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.goals
    ADD CONSTRAINT fk_goals_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id);


--
-- TOC entry 3507 (class 2606 OID 31138)
-- Name: penalties fk_penalties_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties
    ADD CONSTRAINT fk_penalties_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id);


--
-- TOC entry 3508 (class 2606 OID 31148)
-- Name: penalties fk_penalties_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties
    ADD CONSTRAINT fk_penalties_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id);


--
-- TOC entry 3509 (class 2606 OID 31143)
-- Name: penalties fk_penalties_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.penalties
    ADD CONSTRAINT fk_penalties_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id);


--
-- TOC entry 3513 (class 2606 OID 31188)
-- Name: saves fk_saves_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT fk_saves_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id);


--
-- TOC entry 3514 (class 2606 OID 31198)
-- Name: saves fk_saves_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT fk_saves_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id);


--
-- TOC entry 3515 (class 2606 OID 31193)
-- Name: saves fk_saves_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.saves
    ADD CONSTRAINT fk_saves_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id);


--
-- TOC entry 3510 (class 2606 OID 31163)
-- Name: shots fk_shots_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT fk_shots_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id);


--
-- TOC entry 3511 (class 2606 OID 31173)
-- Name: shots fk_shots_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT fk_shots_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id);


--
-- TOC entry 3512 (class 2606 OID 31168)
-- Name: shots fk_shots_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shots
    ADD CONSTRAINT fk_shots_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id);


--
-- TOC entry 3516 (class 2606 OID 31211)
-- Name: shutouts fk_shutouts_game_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts
    ADD CONSTRAINT fk_shutouts_game_id FOREIGN KEY (game_id) REFERENCES league_management.games(game_id);


--
-- TOC entry 3517 (class 2606 OID 31221)
-- Name: shutouts fk_shutouts_team_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts
    ADD CONSTRAINT fk_shutouts_team_id FOREIGN KEY (team_id) REFERENCES league_management.teams(team_id);


--
-- TOC entry 3518 (class 2606 OID 31216)
-- Name: shutouts fk_shutouts_user_id; Type: FK CONSTRAINT; Schema: stats; Owner: postgres
--

ALTER TABLE ONLY stats.shutouts
    ADD CONSTRAINT fk_shutouts_user_id FOREIGN KEY (user_id) REFERENCES admin.users(user_id);


-- Completed on 2025-01-14 13:54:39 EST

--
-- PostgreSQL database dump complete
--

