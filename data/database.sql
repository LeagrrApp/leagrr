-- Create the leagrr Database on PostgreSQL server

----------------------------------------------------------
-- EMPTY THE LEAGRR DATABASE IN CASE IT CONTAINS CONTENT
----------------------------------------------------------

-- Create admin
DROP TABLE IF EXISTS admin.users CASCADE;
DROP SCHEMA IF EXISTS admin CASCADE;

-- league_management
DROP TABLE IF EXISTS league_management.teams CASCADE;
DROP TABLE IF EXISTS league_management.team_memberships CASCADE;
DROP TABLE IF EXISTS league_management.leagues CASCADE;
DROP TABLE IF EXISTS league_management.league_admins CASCADE;
DROP TABLE IF EXISTS league_management.seasons CASCADE;
DROP TABLE IF EXISTS league_management.season_admins CASCADE;
DROP TABLE IF EXISTS league_management.divisions CASCADE;
DROP TABLE IF EXISTS league_management.division_teams CASCADE;
DROP TABLE IF EXISTS league_management.division_rosters CASCADE;
DROP TABLE IF EXISTS league_management.playoffs CASCADE;
DROP TABLE IF EXISTS league_management.venues CASCADE;
DROP TABLE IF EXISTS league_management.arenas CASCADE;
DROP TABLE IF EXISTS league_management.league_venues CASCADE;
DROP TABLE IF EXISTS league_management.games CASCADE;
DROP SCHEMA IF EXISTS league_management CASCADE;

-- stats
DROP TABLE IF EXISTS stats.goals CASCADE;
DROP TABLE IF EXISTS stats.assists CASCADE;
DROP TABLE IF EXISTS stats.penalties CASCADE;
DROP TABLE IF EXISTS stats.shots CASCADE;
DROP TABLE IF EXISTS stats.saves CASCADE;
DROP TABLE IF EXISTS stats.shutouts CASCADE;
DROP SCHEMA IF EXISTS stats CASCADE;

-----------------------------------
-- CREATE THE TABLE STRUCTURE
-----------------------------------

-- ADD SLUGS TO MOST TABLES!

-- Create the database schemas
CREATE SCHEMA admin;
CREATE SCHEMA league_management;
CREATE SCHEMA stats;

-- Alter roles to view schemas and tables
ALTER ROLE postgres SET search_path = league_management, admin;

-- Create admin.users
-- Define user table for all user accounts
CREATE TABLE admin.users (
  user_id         SERIAL NOT NULL PRIMARY KEY,
  username        VARCHAR(50) NOT NULL UNIQUE,
  email           VARCHAR(50) NOT NULL UNIQUE,
  first_name      VARCHAR(50) NOT NULL,
  last_name       VARCHAR(50) NOT NULL,
  gender          VARCHAR(50),
  pronouns        VARCHAR(50),
  user_role       INT NOT NULL DEFAULT 3,
  img             VARCHAR(100),
  privacy         VARCHAR(20) NOT NULL DEFAULT 'public',
  password_hash   VARCHAR(100),
  status          VARCHAR(20) NOT NULL DEFAULT 'active',
  created_on      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE IF EXISTS admin.users
    ADD CONSTRAINT user_privacy_enum CHECK (privacy IN ('public', 'team', 'private'));

ALTER TABLE IF EXISTS admin.users
    ADD CONSTRAINT user_status_enum CHECK (status IN ('active', 'inactive', 'suspended', 'banned'));


-- Create league_management.teams
-- Create team that can be connected to multiple divisions in different leagues.
CREATE TABLE league_management.teams (
  team_id         SERIAL NOT NULL PRIMARY KEY,
  slug            VARCHAR(50) NOT NULL UNIQUE,
  name            VARCHAR(50) NOT NULL,
  description     TEXT,
  color           VARCHAR(50),
  join_code       VARCHAR(50) NOT NULL DEFAULT gen_random_uuid(),
  status          VARCHAR(20) NOT NULL DEFAULT 'active',
  created_on      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE IF EXISTS league_management.teams
    ADD CONSTRAINT team_status_enum CHECK (status IN ('active', 'inactive', 'suspended', 'banned'));

CREATE OR REPLACE FUNCTION generate_team_slug()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER set_teams_slug
    BEFORE INSERT ON league_management.teams
	FOR EACH ROW
	EXECUTE FUNCTION generate_team_slug();

CREATE OR REPLACE TRIGGER update_teams_slug
    BEFORE UPDATE OF name ON league_management.teams
	FOR EACH ROW
	EXECUTE FUNCTION generate_team_slug();

CREATE OR REPLACE FUNCTION join_code_cleanup()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_teams_join_code
    BEFORE UPDATE OF join_code ON league_management.teams
	FOR EACH ROW
	EXECUTE FUNCTION join_code_cleanup();

-- Create league_management.team_memberships
-- Joiner table adding users to teams with a specific team role
CREATE TABLE league_management.team_memberships (
  team_membership_id    SERIAL NOT NULL PRIMARY KEY,
  user_id               INT NOT NULL,
  team_id               INT NOT NULL,
  team_role             INT DEFAULT 2,
  created_on            TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.team_memberships
ADD CONSTRAINT fk_team_memberships_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id) ON DELETE CASCADE;

ALTER TABLE league_management.team_memberships
ADD CONSTRAINT fk_team_memberships_team_id FOREIGN KEY (team_id)
    REFERENCES league_management.teams (team_id) ON DELETE CASCADE;

-- ALTER TABLE league_management.team_memberships
-- ADD CONSTRAINT fk_team_memberships_team_role_id FOREIGN KEY (team_role_id)
--     REFERENCES admin.team_roles (team_role_id);

-- Create league_management.leagues
-- Define league table structure
CREATE TABLE league_management.leagues (
  league_id         SERIAL NOT NULL PRIMARY KEY,
  slug            VARCHAR(50) NOT NULL UNIQUE,
  name            VARCHAR(50) NOT NULL,
  description     TEXT,
  sport           VARCHAR(50),
  status          VARCHAR(20) NOT NULL DEFAULT 'draft',
  created_on      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE IF EXISTS league_management.leagues
    ADD CONSTRAINT league_status_enum CHECK (status IN ('draft', 'public', 'archived', 'locked'));

-- ALTER TABLE league_management.leagues
-- ADD CONSTRAINT fk_leagues_sport_id FOREIGN KEY (sport_id)
--     REFERENCES admin.sports (sport_id);

CREATE OR REPLACE FUNCTION generate_league_slug()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER set_leagues_slug
    BEFORE INSERT ON league_management.leagues
	FOR EACH ROW
	EXECUTE FUNCTION generate_league_slug();

CREATE OR REPLACE TRIGGER update_leagues_slug
    BEFORE UPDATE OF name ON league_management.leagues
	FOR EACH ROW
	EXECUTE FUNCTION generate_league_slug();

-- Create league_management.league_admins
-- A joiner table that connects a user with a league and assigns them a specific role
CREATE TABLE league_management.league_admins (
  league_admin_id     SERIAL NOT NULL PRIMARY KEY,
  league_role      INT,
  league_id           INT,
  user_id             INT,
  created_on          TIMESTAMP DEFAULT NOW()
);

-- ALTER TABLE league_management.league_admins
-- ADD CONSTRAINT fk_league_admins_league_role_id FOREIGN KEY (league_role_id)
--     REFERENCES admin.league_roles (league_role_id) ON DELETE CASCADE;

ALTER TABLE league_management.league_admins
ADD CONSTRAINT fk_league_admins_league_id FOREIGN KEY (league_id)
    REFERENCES league_management.leagues (league_id) ON DELETE CASCADE;

ALTER TABLE league_management.league_admins
ADD CONSTRAINT fk_league_admins_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id) ON DELETE CASCADE;

-- Create league_management.seasons
-- Define season table. Seasons are reoccurring time periods within a league, can feature multiple divisions
CREATE TABLE league_management.seasons (
  season_id       SERIAL NOT NULL PRIMARY KEY,
  slug            VARCHAR(50) NOT NULL,
  name            VARCHAR(50) NOT NULL,
  description     TEXT,
  league_id       INT,
  start_date      DATE,
  end_date        DATE,
  status          VARCHAR(20) NOT NULL DEFAULT 'draft',
  created_on      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.seasons
ADD CONSTRAINT fk_seasons_league_id FOREIGN KEY (league_id)
    REFERENCES league_management.leagues (league_id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS league_management.seasons
    ADD CONSTRAINT season_status_enum CHECK (status IN ('draft', 'public', 'archived', 'locked'));

CREATE OR REPLACE FUNCTION generate_season_slug()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER set_seasons_slug
    BEFORE INSERT ON league_management.seasons
	FOR EACH ROW
	EXECUTE FUNCTION generate_season_slug();

CREATE OR REPLACE TRIGGER update_seasons_slug
    BEFORE UPDATE OF name ON league_management.seasons
	FOR EACH ROW
	EXECUTE FUNCTION generate_season_slug();

-- Create league_management.season_admins
-- A joiner table that connects a user with a season and assigns them a specific role
CREATE TABLE league_management.season_admins (
  season_admin_id     SERIAL NOT NULL PRIMARY KEY,
  season_role      INT,
  season_id           INT,
  user_id             INT,
  created_on          TIMESTAMP DEFAULT NOW()
);

-- ALTER TABLE league_management.season_admins
-- ADD CONSTRAINT fk_season_admins_season_role_id FOREIGN KEY (season_role_id)
--     REFERENCES admin.season_roles (season_role_id) ON DELETE CASCADE;

ALTER TABLE league_management.season_admins
ADD CONSTRAINT fk_season_admins_season_id FOREIGN KEY (season_id)
    REFERENCES league_management.seasons (season_id) ON DELETE CASCADE;

ALTER TABLE league_management.season_admins
ADD CONSTRAINT fk_season_admins_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id) ON DELETE CASCADE;

-- Create league_management.divisions
-- A division is a grouping of teams of same skill level within a season.
CREATE TABLE league_management.divisions (
  division_id     SERIAL NOT NULL PRIMARY KEY,
  slug            VARCHAR(50) NOT NULL,
  name            VARCHAR(50) NOT NULL,
  description     TEXT,
  tier            INT,
  gender          VARCHAR(10) NOT NULL DEFAULT 'All',
  season_id       INT,
  join_code       VARCHAR(50) NOT NULL DEFAULT gen_random_uuid(),
  status          VARCHAR(20) NOT NULL DEFAULT 'draft',
  created_on      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.divisions
ADD CONSTRAINT fk_divisions_season_id FOREIGN KEY (season_id)
    REFERENCES league_management.seasons (season_id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS league_management.divisions
    ADD CONSTRAINT division_gender_enum CHECK (gender IN ('all', 'men', 'women'));

ALTER TABLE IF EXISTS league_management.divisions
    ADD CONSTRAINT division_status_enum CHECK (status IN ('draft', 'public', 'archived', 'locked'));

CREATE OR REPLACE FUNCTION generate_division_slug()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER set_divisions_slug
    BEFORE INSERT ON league_management.divisions
	FOR EACH ROW
	EXECUTE FUNCTION generate_division_slug();

CREATE OR REPLACE TRIGGER update_divisions_slug
    BEFORE UPDATE OF name ON league_management.divisions
	FOR EACH ROW
	EXECUTE FUNCTION generate_division_slug();

CREATE OR REPLACE FUNCTION division_join_code_cleanup()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_divisions_join_code
    BEFORE UPDATE OF join_code ON league_management.divisions
	FOR EACH ROW
	EXECUTE FUNCTION division_join_code_cleanup();

-- Create league_management.division_teams
-- Joiner table connecting teams with divisions
CREATE TABLE league_management.division_teams (
  division_team_id    SERIAL NOT NULL PRIMARY KEY,
  division_id         INT,
  team_id             INT,
  created_on          TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.division_teams
ADD CONSTRAINT fk_division_teams_division_id FOREIGN KEY (division_id)
    REFERENCES league_management.divisions (division_id) ON DELETE CASCADE;

ALTER TABLE league_management.division_teams
ADD CONSTRAINT fk_division_teams_team_id FOREIGN KEY (team_id)
    REFERENCES league_management.teams (team_id) ON DELETE CASCADE;

-- Create league_management.division_rosters
-- Joiner table assigning players to a team within divisions
CREATE TABLE league_management.division_rosters (
  division_roster_id    SERIAL NOT NULL PRIMARY KEY,
  division_team_id      INT,
  team_membership_id    INT,
  position              VARCHAR(50),
  number                INT,
  roster_role           INT NOT NULL DEFAULT 4,
  created_on            TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.division_rosters
ADD CONSTRAINT fk_division_rosters_division_team_id FOREIGN KEY (division_team_id)
    REFERENCES league_management.division_teams (division_team_id) ON DELETE CASCADE;

ALTER TABLE league_management.division_rosters
ADD CONSTRAINT fk_division_rosters_team_membership_id FOREIGN KEY (team_membership_id)
    REFERENCES league_management.team_memberships (team_membership_id) ON DELETE CASCADE;

-- Create league_management.playoffs
-- Create a playoff round that is connected to a division and is assigned a playoff_structure
CREATE TABLE league_management.playoffs (
  playoff_id            SERIAL NOT NULL PRIMARY KEY,
  slug                  VARCHAR(50) NOT NULL,
  name                  VARCHAR(50) NOT NULL,
  description           TEXT,
  playoff_structure     VARCHAR(20) NOT NULL DEFAULT 'bracket',
  season_id             INT,
  status                VARCHAR(20) NOT NULL DEFAULT 'draft',
  created_on            TIMESTAMP DEFAULT NOW()
);

-- ALTER TABLE league_management.playoffs
-- ADD CONSTRAINT fk_playoffs_playoff_structure_id FOREIGN KEY (playoff_structure_id)
--     REFERENCES admin.playoff_structures (playoff_structure_id) ON DELETE CASCADE;

ALTER TABLE league_management.playoffs
ADD CONSTRAINT fk_playoffs_season_id FOREIGN KEY (season_id)
    REFERENCES league_management.seasons (season_id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS league_management.playoffs
    ADD CONSTRAINT playoffs_status_enum CHECK (status IN ('draft', 'public', 'archived'));

ALTER TABLE IF EXISTS league_management.playoffs
    ADD CONSTRAINT playoffs_structure_enum CHECK (playoff_structure IN ('bracket', 'round-robin'));

-- Create league_management.venues
CREATE TABLE league_management.venues (
  venue_id            SERIAL NOT NULL PRIMARY KEY,
  slug                VARCHAR(50) NOT NULL UNIQUE,
  name                VARCHAR(50) NOT NULL,
  description         TEXT,
  address             TEXT,
  created_on          TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION generate_venue_slug()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER set_venues_slug
    BEFORE INSERT ON league_management.venues
	FOR EACH ROW
	EXECUTE FUNCTION generate_venue_slug();

CREATE OR REPLACE TRIGGER update_venues_slug
    BEFORE UPDATE OF name ON league_management.venues
	FOR EACH ROW
	EXECUTE FUNCTION generate_venue_slug();

-- Create league_management.arenas
CREATE TABLE league_management.arenas (
  arena_id            SERIAL NOT NULL PRIMARY KEY,
  name                VARCHAR(50) NOT NULL,
  description         TEXT,
  venue_id            INT NOT NULL,
  created_on          TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.arenas
ADD CONSTRAINT fk_arena_venue_id FOREIGN KEY (venue_id)
    REFERENCES league_management.venues (venue_id) ON DELETE CASCADE;

-- Create league_management.league_venues
-- Joiner table that allows leagues to create a list of venues used within the league
CREATE TABLE league_management.league_venues (
  league_venue_id     SERIAL NOT NULL PRIMARY KEY,
  venue_id            INT,
  league_id           INT,
  created_on          TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.league_venues
ADD CONSTRAINT fk_league_venue_venue_id FOREIGN KEY (venue_id)
    REFERENCES league_management.venues (venue_id) ON DELETE CASCADE;

ALTER TABLE league_management.league_venues
ADD CONSTRAINT fk_league_venue_league_id FOREIGN KEY (league_id)
    REFERENCES league_management.leagues (league_id) ON DELETE CASCADE;

-- Create league_management.games
CREATE TABLE league_management.games (
  game_id               SERIAL NOT NULL PRIMARY KEY,
  home_team_id          INT NOT NULL,
  home_team_score       INT DEFAULT 0,
  away_team_id          INT NOT NULL,
  away_team_score       INT DEFAULT 0,
  division_id           INT,
  playoff_id            INT,
  date_time             TIMESTAMP NOT NULL,
  arena_id              INT,
  status                VARCHAR(20) NOT NULL DEFAULT 'draft',
  has_been_published    BOOLEAN DEFAULT false,
  created_on            TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.games
ADD CONSTRAINT fk_game_division_id FOREIGN KEY (division_id)
    REFERENCES league_management.divisions (division_id) ON DELETE CASCADE;

ALTER TABLE league_management.games
ADD CONSTRAINT fk_game_playoff_id FOREIGN KEY (playoff_id)
    REFERENCES league_management.playoffs (playoff_id) ON DELETE CASCADE;

ALTER TABLE league_management.games
ADD CONSTRAINT fk_game_arena_id FOREIGN KEY (arena_id)
    REFERENCES league_management.arenas (arena_id);

ALTER TABLE IF EXISTS league_management.games
    ADD CONSTRAINT game_status_enum CHECK (status IN ('draft', 'public', 'completed', 'cancelled', 'postponed', 'archived'));

CREATE OR REPLACE FUNCTION mark_game_as_published()
RETURNS TRIGGER AS $$
BEGIN

	IF NEW.status <> OLD.status AND NEW.status != 'draft' THEN
		NEW.has_been_published = true;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER insert_game_status_check
    BEFORE INSERT ON league_management.games
	FOR EACH ROW
	EXECUTE FUNCTION mark_game_as_published();

CREATE OR REPLACE TRIGGER update_game_status_check
    BEFORE UPDATE OF status ON league_management.games
	FOR EACH ROW
	EXECUTE FUNCTION mark_game_as_published();
  
-- Stats

-- Create goals
-- Track goals and connect the goal to a game and a player
CREATE TABLE stats.goals (
  goal_id         SERIAL NOT NULL PRIMARY KEY,
  game_id         INT NOT NULL,
  user_id         INT NOT NULL,
  team_id         INT NOT NULL,
  period          INT,
  period_time     INTERVAL,
  shorthanded     BOOLEAN DEFAULT false,
  power_play      BOOLEAN DEFAULT false,
  empty_net       BOOLEAN DEFAULT false,
  created_on      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE stats.goals
ADD CONSTRAINT fk_goals_game_id FOREIGN KEY (game_id)
    REFERENCES league_management.games (game_id) ON DELETE CASCADE;

ALTER TABLE stats.goals
ADD CONSTRAINT fk_goals_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id) ON DELETE CASCADE;

ALTER TABLE stats.goals
ADD CONSTRAINT fk_goals_team_id FOREIGN KEY (team_id)
    REFERENCES league_management.teams (team_id) ON DELETE CASCADE;

CREATE OR REPLACE FUNCTION update_game_score()
RETURNS TRIGGER AS $$
BEGIN

	UPDATE league_management.games AS g
	SET
		home_team_score = (SELECT COUNT(*) FROM stats.goals AS goals WHERE goals.team_id = g.home_team_id AND goals.game_id IN (NEW.game_id, OLD.game_id)),
		away_team_score = (SELECT COUNT(*) FROM stats.goals AS goals WHERE goals.team_id = g.away_team_id AND goals.game_id IN (NEW.game_id, OLD.game_id))
	WHERE
		g.game_id IN (NEW.game_id, OLD.game_id);
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER goal_update_game_score
    AFTER INSERT OR DELETE ON stats.goals
	FOR EACH ROW
	EXECUTE FUNCTION update_game_score();

-- Create Assist
-- An assist marks players who passed to the goal scorer
CREATE TABLE stats.assists (
  assist_id       SERIAL NOT NULL PRIMARY KEY,
  goal_id         INT NOT NULL,
  game_id         INT NOT NULL,
  user_id         INT NOT NULL,
  team_id         INT NOT NULL,
  primary_assist  BOOLEAN DEFAULT true,
  created_on      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE stats.assists
ADD CONSTRAINT fk_assists_goal_id FOREIGN KEY (goal_id)
    REFERENCES stats.goals (goal_id) ON DELETE CASCADE;

ALTER TABLE stats.assists
ADD CONSTRAINT fk_assists_game_id FOREIGN KEY (game_id)
    REFERENCES league_management.games (game_id) ON DELETE CASCADE;

ALTER TABLE stats.assists
ADD CONSTRAINT fk_assists_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id) ON DELETE CASCADE;

ALTER TABLE stats.assists
ADD CONSTRAINT fk_assists_team_id FOREIGN KEY (team_id)
    REFERENCES league_management.teams (team_id) ON DELETE CASCADE;

-- Create penalties
-- Tracks individual penalties committed by players and connects them with games
CREATE TABLE stats.penalties (
  penalty_id      SERIAL NOT NULL PRIMARY KEY,
  game_id         INT NOT NULL,
  user_id         INT NOT NULL,
  team_id         INT NOT NULL,
  period          INT,
  period_time     INTERVAL,
  infraction      VARCHAR(50) NOT NULL,
  minutes         INT NOT NULL DEFAULT 2,
  created_on      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE stats.penalties
ADD CONSTRAINT fk_penalties_game_id FOREIGN KEY (game_id)
    REFERENCES league_management.games (game_id) ON DELETE CASCADE;

ALTER TABLE stats.penalties
ADD CONSTRAINT fk_penalties_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id) ON DELETE CASCADE;

ALTER TABLE stats.penalties
ADD CONSTRAINT fk_penalties_team_id FOREIGN KEY (team_id)
    REFERENCES league_management.teams (team_id) ON DELETE CASCADE;

-- Create shots
-- Track shots and connect the shots to a game and a player
CREATE TABLE stats.shots (
  shot_id         SERIAL NOT NULL PRIMARY KEY,
  game_id         INT NOT NULL,
  user_id         INT NOT NULL,
  team_id         INT NOT NULL,
  period          INT,
  period_time     INTERVAL,
  goal_id         INT,
  shorthanded     BOOLEAN DEFAULT false,
  power_play      BOOLEAN DEFAULT false,
  created_on      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE stats.shots
ADD CONSTRAINT fk_shots_game_id FOREIGN KEY (game_id)
    REFERENCES league_management.games (game_id) ON DELETE CASCADE;

ALTER TABLE stats.shots
ADD CONSTRAINT fk_shots_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id) ON DELETE CASCADE;

ALTER TABLE stats.shots
ADD CONSTRAINT fk_shots_team_id FOREIGN KEY (team_id)
    REFERENCES league_management.teams (team_id) ON DELETE CASCADE;

ALTER TABLE stats.shots
ADD CONSTRAINT fk_shots_goal_id FOREIGN KEY (goal_id)
    REFERENCES stats.goals (goal_id) ON DELETE CASCADE;

-- Create saves
-- Track saves and connect the saves to a game and a player
CREATE TABLE stats.saves (
  save_id         SERIAL NOT NULL PRIMARY KEY,
  game_id         INT NOT NULL,
  user_id         INT NOT NULL,
  team_id         INT NOT NULL,
  shot_id         INT NOT NULL,
  period          INT,
  period_time     INTERVAL,
  penalty_kill    BOOLEAN DEFAULT false,
  rebound         BOOLEAN DEFAULT false,
  created_on      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE stats.saves
ADD CONSTRAINT fk_saves_game_id FOREIGN KEY (game_id)
    REFERENCES league_management.games (game_id) ON DELETE CASCADE;

ALTER TABLE stats.saves
ADD CONSTRAINT fk_saves_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id) ON DELETE CASCADE;

ALTER TABLE stats.saves
ADD CONSTRAINT fk_saves_team_id FOREIGN KEY (team_id)
    REFERENCES league_management.teams (team_id) ON DELETE CASCADE;

ALTER TABLE stats.saves
ADD CONSTRAINT fk_saves_shot_id FOREIGN KEY (shot_id)
    REFERENCES stats.shots (shot_id) ON DELETE CASCADE;

-- Create shutout
-- Track shoutouts and connect the shutout to a game and a player
CREATE TABLE stats.shutouts (
  shutout_id         SERIAL NOT NULL PRIMARY KEY,
  game_id            INT NOT NULL,
  user_id            INT NOT NULL,
  team_id            INT NOT NULL,
  created_on         TIMESTAMP DEFAULT NOW()
);

ALTER TABLE stats.shutouts
ADD CONSTRAINT fk_shutouts_game_id FOREIGN KEY (game_id)
    REFERENCES league_management.games (game_id) ON DELETE CASCADE;

ALTER TABLE stats.shutouts
ADD CONSTRAINT fk_shutouts_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id) ON DELETE CASCADE;

ALTER TABLE stats.shutouts
ADD CONSTRAINT fk_shutouts_team_id FOREIGN KEY (team_id)
    REFERENCES league_management.teams (team_id) ON DELETE CASCADE;

-----------------------------------
-- INSERT DATA INTO TABLES 
-----------------------------------

-- Default named users
INSERT INTO admin.users
  (username, email, first_name, last_name, gender, pronouns, user_role, password_hash)
VALUES
  -- 1
  ('moose', 'hello+2@adamrobillard.ca', 'Adam', 'Robillard', 'Non-binary', 'any/all', 1, '$2b$10$7pjrECYElk1ithndcAhtcuPytB2Hc8DiDi3e8gAEXYcfIjOVZdEfS'),
  -- 2
  ('goose', 'hello+1@adamrobillard.ca', 'Hannah', 'Brown', 'Female', 'she/her', 3, '$2b$10$99E/cmhMolqnQFi3E6CXHOpB7zYYANgDToz1F.WkFrZMOXCFBvxji'),
  -- 3
  ('caboose', 'hello+3@adamrobillard.ca', 'Aida', 'Robillard', 'Non-binary', 'any/all', 1, '$2b$10$UM16ckCNhox47R0yOq873uCUX4Pal3GEVlNY8kYszWGGM.Y3kyiZC'),
  -- 4
  ('caleb', 'caleb@example.com', 'Caleb', 'Smith', 'Male', 'he/him', 2, 'heyCaleb123'),
  -- 5
  ('kat', 'kat@example.com', 'Kat', 'Ferguson', 'Non-binary', 'they/them', 2, 'heyKat123'),
  -- 6
  ('trainMale', 'trainMale@example.com', 'Stephen', 'Spence', 'Male', 'he/him', 3, 'heyStephen123'),
  -- 7
  ('theGoon', 'theGoon@example.com', 'Levi', 'Bradley', 'Non-binary', 'they/them', 3, 'heyLevi123'),
  -- 8
  ('cheryl', 'cheryl@example.com', 'Cheryl', 'Chaos', null, null, 3, 'heyCheryl123'),
  -- 9
  ('mason', 'mason@example.com', 'Mason', 'Nonsense', null, null, 3, 'heyMasonl123'),
  -- 10
  ('jayce', 'jayce@example.com', 'Jayce', 'LeClaire', 'Non-binary', 'they/them', 3, 'heyJaycel123'),
  -- 11
  ('britt', 'britt@example.com', 'Britt', 'Neron', 'Non-binary', 'they/them', 3, 'heyBrittl123'),
  -- 12
  ('tesolin', 'tesolin@example.com', 'Zachary', 'Tesolin', 'Male', 'he/him', 3, 'heyZach123'),
  -- 13
  ('robocop', 'robocop@example.com', 'Andrew', 'Robillard', 'Male', 'he/him', 3, 'heyAndrew123'),
  -- 14
  ('trex', 'trex@example.com', 'Tim', 'Robillard', 'Male', 'he/him', 3, 'heyTim123')
;

UPDATE admin.users
SET
  img = '/profile.jpg'
WHERE
  user_id = 1;

-- Default generic users
INSERT INTO admin.users
  (username, email, first_name, last_name, gender, pronouns, user_role, password_hash)
VALUES
  ('lukasbauer', 'lukas.bauer@example.com', 'Lukas', 'Bauer', 'Male', 'he/him', 3, 'heyLukas123'), -- 15
  ('emmaschmidt', 'emma.schmidt@example.com', 'Emma', 'Schmidt', 'Female', 'she/her', 3, 'heyEmma123'), -- 16
  ('liammüller', 'liam.mueller@example.com', 'Liam', 'Müller', 'Male', 'he/him', 3, 'heyLiam123'), -- 17
  ('hannahfischer', 'hannah.fischer@example.com', 'Hannah', 'Fischer', 'Female', 'she/her', 3, 'heyHanna123'), -- 18
  ('oliverkoch', 'oliver.koch@example.com', 'Oliver', 'Koch', 'Male', 'he/him', 3, 'heyOliver123'), -- 19
  ('clararichter', 'clara.richter@example.com', 'Clara', 'Richter', 'Female', 'she/her', 3, 'heyClara123'), -- 20
  ('noahtaylor', 'noah.taylor@example.com', 'Noah', 'Taylor', 'Male', 'he/him', 3, 'heyNoah123'), -- 21
  ('lisahoffmalen', 'lisa.hoffmalen@example.com', 'Lisa', 'Hoffmalen', 'Female', 'she/her', 3, 'heyLisa123'), -- 22
  ('matteorossetti', 'matteo.rossetti@example.com', 'Matteo', 'Rossetti', 'Male', 'he/him', 3, 'heyMatteo123'), -- 23
  ('giuliarossi', 'giulia.rossi@example.com', 'Giulia', 'Rossi', 'Female', 'she/her', 3, 'heyGiulia123'), -- 24
  ('danielebrown', 'daniele.brown@example.com', 'Daniele', 'Brown', 'Non-binary', 'they/them', 3, 'heyDaniele123'), -- 25
  ('sofialopez', 'sofia.lopez@example.com', 'Sofia', 'Lopez', 'Female', 'she/her', 3, 'heySofia123'), -- 26
  ('sebastienmartin', 'sebastien.martin@example.com', 'Sebastien', 'Martin', 'Male', 'he/him', 3, 'heySebastien123'), -- 27
  ('elisavolkova', 'elisa.volkova@example.com', 'Elisa', 'Volkova', 'Female', 'she/her', 3, 'heyElisa123'), -- 28
  ('adriangarcia', 'adrian.garcia@example.com', 'Adrian', 'Garcia', 'Male', 'he/him', 3, 'heyAdrian123'), -- 29
  ('amelialeroux', 'amelia.leroux@example.com', 'Amelia', 'LeRoux', 'Female', 'she/her', 3, 'heyAmelia123'), -- 30
  ('kasperskov', 'kasper.skov@example.com', 'Kasper', 'Skov', 'Male', 'he/him', 3, 'heyKasper123'), -- 31
  ('elinefransen', 'eline.fransen@example.com', 'Eline', 'Fransen', 'Female', 'she/her', 3, 'heyEline123'), -- 32
  ('andreakovacs', 'andrea.kovacs@example.com', 'Andrea', 'Kovacs', 'Non-binary', 'they/them', 3, 'heyAndrea123'), -- 33
  ('petersmith', 'peter.smith@example.com', 'Peter', 'Smith', 'Male', 'he/him', 3, 'heyPeter123'), -- 34
  ('janinanowak', 'janina.nowak@example.com', 'Janina', 'Nowak', 'Female', 'she/her', 3, 'heyJanina123'), -- 35
  ('niklaspetersen', 'niklas.petersen@example.com', 'Niklas', 'Petersen', 'Male', 'he/him', 3, 'heyNiklas123'), -- 36
  ('martakalinski', 'marta.kalinski@example.com', 'Marta', 'Kalinski', 'Female', 'she/her', 3, 'heyMarta123'), -- 37
  ('tomasmarquez', 'tomas.marquez@example.com', 'Tomas', 'Marquez', 'Male', 'he/him', 3, 'heyTomas123'), -- 38
  ('ireneschneider', 'irene.schneider@example.com', 'Irene', 'Schneider', 'Female', 'she/her', 3, 'heyIrene123'), -- 39
  ('maximilianbauer', 'maximilian.bauer@example.com', 'Maximilian', 'Bauer', 'Male', 'he/him', 3, 'heyMaximilian123'), -- 40
  ('annaschaefer', 'anna.schaefer@example.com', 'Anna', 'Schaefer', 'Female', 'she/her', 3, 'heyAnna123'), -- 41
  ('lucasvargas', 'lucas.vargas@example.com', 'Lucas', 'Vargas', 'Male', 'he/him', 3, 'heyLucas123'), -- 42
  ('sofiacosta', 'sofia.costa@example.com', 'Sofia', 'Costa', 'Female', 'she/her', 3, 'heySofia123'), -- 43
  ('alexanderricci', 'alexander.ricci@example.com', 'Alexander', 'Ricci', 'Male', 'he/him', 3, 'heyAlexander123'), -- 44
  ('noemiecaron', 'noemie.caron@example.com', 'Noemie', 'Caron', 'Female', 'she/her', 3, 'heyNoemie123'), -- 45
  ('pietrocapello', 'pietro.capello@example.com', 'Pietro', 'Capello', 'Male', 'he/him', 3, 'heyPietro123'), -- 46
  ('elisabethjensen', 'elisabeth.jensen@example.com', 'Elisabeth', 'Jensen', 'Female', 'she/her', 3, 'heyElisabeth123'), -- 47
  ('dimitripapadopoulos', 'dimitri.papadopoulos@example.com', 'Dimitri', 'Papadopoulos', 'Male', 'he/him', 3, 'heyDimitri123'), -- 48
  ('marielaramos', 'mariela.ramos@example.com', 'Mariela', 'Ramos', 'Female', 'she/her', 3, 'heyMariela123'), -- 49
  ('valeriekeller', 'valerie.keller@example.com', 'Valerie', 'Keller', 'Female', 'she/her', 3, 'heyValerie123'), -- 50
  ('dominikbauer', 'dominik.bauer@example.com', 'Dominik', 'Bauer', 'Male', 'he/him', 3, 'heyDominik123'), -- 51
  ('evaweber', 'eva.weber@example.com', 'Eva', 'Weber', 'Female', 'she/her', 3, 'heyEva123'), -- 52
  ('sebastiancortes', 'sebastian.cortes@example.com', 'Sebastian', 'Cortes', 'Male', 'he/him', 3, 'heySebastian123'), -- 53
  ('maleongarcia', 'maleon.garcia@example.com', 'Maleon', 'Garcia', 'Female', 'she/her', 3, 'heyMaleon123'), -- 54
  ('benjaminflores', 'benjamin.flores@example.com', 'Benjamin', 'Flores', 'Male', 'he/him', 3, 'heyBenjamin123'), -- 55
  ('saradalgaard', 'sara.dalgaard@example.com', 'Sara', 'Dalgaard', 'Female', 'she/her', 3, 'heySara123'), -- 56
  ('jonasmartinez', 'jonas.martinez@example.com', 'Jonas', 'Martinez', 'Male', 'he/him', 3, 'heyJonas123'), -- 57
  ('alessiadonati', 'alessia.donati@example.com', 'Alessia', 'Donati', 'Female', 'she/her', 3, 'heyAlessia123'), -- 58
  ('lucaskovac', 'lucas.kovac@example.com', 'Lucas', 'Kovac', 'Non-binary', 'they/them', 3, 'heyLucas123'), -- 59
  ('emiliekoch', 'emilie.koch@example.com', 'Emilie', 'Koch', 'Female', 'she/her', 3, 'heyEmilie123'), -- 60
  ('danieljones', 'daniel.jones@example.com', 'Daniel', 'Jones', 'Male', 'he/him', 3, 'heyDaniel123'), -- 61
  ('mathildevogel', 'mathilde.vogel@example.com', 'Mathilde', 'Vogel', 'Female', 'she/her', 3, 'heyMathilde123'), -- 62
  ('thomasleroux', 'thomas.leroux@example.com', 'Thomas', 'LeRoux', 'Male', 'he/him', 3, 'heyThomas123'), -- 63
  ('angelaperez', 'angela.perez@example.com', 'Angela', 'Perez', 'Female', 'she/her', 3, 'heyAngela123'), -- 64
  ('henrikstrom', 'henrik.strom@example.com', 'Henrik', 'Strom', 'Male', 'he/him', 3, 'heyHenrik123'), -- 65
  ('paulinaklein', 'paulina.klein@example.com', 'Paulina', 'Klein', 'Female', 'she/her', 3, 'heyPaulina123'), -- 66
  ('raphaelgonzalez', 'raphael.gonzalez@example.com', 'Raphael', 'Gonzalez', 'Male', 'he/him', 3, 'heyRaphael123'), -- 67
  ('annaluisachavez', 'anna-luisa.chavez@example.com', 'Anna-Luisa', 'Chavez', 'Female', 'she/her', 3, 'heyAnna-Luisa123'), -- 68
  ('fabiomercier', 'fabio.mercier@example.com', 'Fabio', 'Mercier', 'Male', 'he/him', 3, 'heyFabio123'), -- 69
  ('nataliefischer', 'natalie.fischer@example.com', 'Natalie', 'Fischer', 'Female', 'she/her', 3, 'heyNatalie123'), -- 70
  ('georgmayer', 'georg.mayer@example.com', 'Georg', 'Mayer', 'Male', 'he/him', 3, 'heyGeorg123'), -- 71
  ('julianweiss', 'julian.weiss@example.com', 'Julian', 'Weiss', 'Male', 'he/him', 3, 'heyJulian123'), -- 72
  ('katharinalopez', 'katharina.lopez@example.com', 'Katharina', 'Lopez', 'Female', 'she/her', 3, 'heyKatharina123'), -- 73
  ('simonealvarez', 'simone.alvarez@example.com', 'Simone', 'Alvarez', 'Non-binary', 'they/them', 3, 'heySimone123'), -- 74
  ('frederikschmidt', 'frederik.schmidt@example.com', 'Frederik', 'Schmidt', 'Male', 'he/him', 3, 'heyFrederik123'), -- 75
  ('mariakoval', 'maria.koval@example.com', 'Maria', 'Koval', 'Female', 'she/her', 3, 'heyMaria123'), -- 76
  ('lukemccarthy', 'luke.mccarthy@example.com', 'Luke', 'McCarthy', 'Male', 'he/him', 3, 'heyLuke123'), -- 77
  ('larissahansen', 'larissa.hansen@example.com', 'Larissa', 'Hansen', 'Female', 'she/her', 3, 'heyLarissa123'), -- 78
  ('adamwalker', 'adam.walker@example.com', 'Adam', 'Walker', 'Male', 'he/him', 3, 'heyAdam123'), -- 79
  ('paolamendes', 'paola.mendes@example.com', 'Paola', 'Mendes', 'Female', 'she/her', 3, 'heyPaola123'), -- 80
  ('ethanwilliams', 'ethan.williams@example.com', 'Ethan', 'Williams', 'Male', 'he/him', 3, 'heyEthan123'), -- 81
  ('evastark', 'eva.stark@example.com', 'Eva', 'Stark', 'Female', 'she/her', 3, 'heyEva123'), -- 82
  ('juliankovacic', 'julian.kovacic@example.com', 'Julian', 'Kovacic', 'Male', 'he/him', 3, 'heyJulian123'), -- 83
  ('ameliekrause', 'amelie.krause@example.com', 'Amelie', 'Krause', 'Female', 'she/her', 3, 'heyAmelie123'), -- 84
  ('ryanschneider', 'ryan.schneider@example.com', 'Ryan', 'Schneider', 'Male', 'he/him', 3, 'heyRyan123'), -- 85
  ('monikathomsen', 'monika.thomsen@example.com', 'Monika', 'Thomsen', 'Female', 'she/her', 3, 'heyMonika123'), -- 86
  ('daniellefoster', 'danielle.foster@example.com', 'Danielle', 'Foster', 4, 'she/her', 3, 'heyDanielle123'), -- 87
  ('harrykhan', 'harry.khan@example.com', 'Harry', 'Khan', 'Male', 'he/him', 3, 'heyHarry123'), -- 88
  ('sophielindgren', 'sophie.lindgren@example.com', 'Sophie', 'Lindgren', 'Female', 'she/her', 3, 'heySophie123'), -- 89
  ('oskarpetrov', 'oskar.petrov@example.com', 'Oskar', 'Petrov', 'Male', 'he/him', 3, 'heyOskar123'), -- 90
  ('lindavon', 'linda.von@example.com', 'Linda', 'Von', 'Female', 'she/her', 3, 'heyLinda123'), -- 91
  ('andreaspeicher', 'andreas.peicher@example.com', 'Andreas', 'Peicher', 'Male', 'he/him', 3, 'heyAndreas123'), -- 92
  ('josephinejung', 'josephine.jung@example.com', 'Josephine', 'Jung', 'Female', 'she/her', 3, 'heyJosephine123'), -- 93
  ('marianapaz', 'mariana.paz@example.com', 'Mariana', 'Paz', 'Female', 'she/her', 3, 'heyMariana123'), -- 94
  ('fionaberg', 'fiona.berg@example.com', 'Fiona', 'Berg', 'Female', 'she/her', 3, 'heyFiona123'), -- 95
  ('joachimkraus', 'joachim.kraus@example.com', 'Joachim', 'Kraus', 'Male', 'he/him', 3, 'heyJoachim123'), -- 96
  ('michellebauer', 'michelle.bauer@example.com', 'Michelle', 'Bauer', 'Female', 'she/her', 3, 'heyMichelle123'), -- 97
  ('mariomatteo', 'mario.matteo@example.com', 'Mario', 'Matteo', 'Male', 'he/him', 3, 'heyMario123'), -- 98
  ('elizabethsmith', 'elizabeth.smith@example.com', 'Elizabeth', 'Smith', 'Female', 'she/her', 3, 'heyElizabeth123'), -- 99
  ('ianlennox', 'ian.lennox@example.com', 'Ian', 'Lennox', 'Male', 'he/him', 3, 'heyIan123'), -- 100
  ('evabradley', 'eva.bradley@example.com', 'Eva', 'Bradley', 'Female', 'she/her', 3, 'heyEva123'), -- 101
  ('francescoantoni', 'francesco.antoni@example.com', 'Francesco', 'Antoni', 'Male', 'he/him', 3, 'heyFrancesco123'), -- 102
  ('celinebrown', 'celine.brown@example.com', 'Celine', 'Brown', 'Female', 'she/her', 3, 'heyCeline123'), -- 103
  ('georgiamills', 'georgia.mills@example.com', 'Georgia', 'Mills', 'Female', 'she/her', 3, 'heyGeorgia123'), -- 104
  ('antoineclark', 'antoine.clark@example.com', 'Antoine', 'Clark', 'Male', 'he/him', 3, 'heyAntoine123'), -- 105
  ('valentinwebb', 'valentin.webb@example.com', 'Valentin', 'Webb', 'Male', 'he/him', 3, 'heyValentin123'), -- 106
  ('oliviamorales', 'olivia.morales@example.com', 'Olivia', 'Morales', 'Female', 'she/her', 3, 'heyOlivia123'), -- 107
  ('mathieuhebert', 'mathieu.hebert@example.com', 'Mathieu', 'Hebert', 'Male', 'he/him', 3, 'heyMathieu123'), -- 108
  ('rosepatel', 'rose.patel@example.com', 'Rose', 'Patel', 'Female', 'she/her', 3, 'heyRose123'), -- 109
  ('travisrichards', 'travis.richards@example.com', 'Travis', 'Richards', 'Male', 'he/him', 3, 'heyTravis123'), -- 110
  ('josefinklein', 'josefinklein@example.com', 'Josefin', 'Klein', 'Female', 'she/her', 3, 'heyJosefin123'), -- 111
  ('finnandersen', 'finn.andersen@example.com', 'Finn', 'Andersen', 'Male', 'he/him', 3, 'heyFinn123'), -- 112
  ('sofiaparker', 'sofia.parker@example.com', 'Sofia', 'Parker', 'Female', 'she/her', 3, 'heySofia123'), -- 113
  ('theogibson', 'theo.gibson@example.com', 'Theo', 'Gibson', 'Male', 'he/him', 3, 'heyTheo123'), -- 114
  ('floose', 'floose@example.com', 'Floose', 'McGoose', 3, 'any/all', 1, '$2b$10$7pjrECYElk1ithndcAhtcuPytB2Hc8DiDi3e8gAEXYcfIjOVZdEfS') -- 115
;

-- Add OPH teams
INSERT INTO league_management.teams
  (slug, name, description, color)
VALUES
  ('significant-otters', 'Significant Otters', null, '#942f2f'), -- 1
  ('otterwa-senators', 'Otterwa Senators', null, '#8d45a3'), -- 2
  ('otter-chaos', 'Otter Chaos', null, '#2f945b'), -- 3
  ('otter-nonsense', 'Otter Nonsense', null, '#2f3794'), -- 4
  ('frostbiters', 'Frostbiters', 'An icy team known for their chilling defense.', 'green'), -- 5
  ('blazing-blizzards', 'Blazing Blizzards', 'A team that combines fiery offense with frosty precision.', 'purple'), -- 6
  ('polar-puckers', 'Polar Puckers', 'Masters of the north, specializing in swift plays.', '#285fa2'), -- 7
  ('arctic-avengers', 'Arctic Avengers', 'A cold-blooded team with a knack for thrilling comebacks.', 'yellow'), -- 8
  ('glacial-guardians', 'Glacial Guardians', 'Defensive titans who freeze their opponents in their tracks.', 'pink'), -- 9
  ('tundra-titans', 'Tundra Titans', 'A powerhouse team dominating the ice with strength and speed.', 'orange'), -- 10
  ('permafrost-predators', 'Permafrost Predators', 'Known for their unrelenting pressure and icy precision.', '#bc83d4'), -- 11
  ('snowstorm-scorchers', 'Snowstorm Scorchers', 'A team with a fiery spirit and unstoppable energy.', 'rebeccapurple'), -- 12
  ('frozen-flames', 'Frozen Flames', 'Bringing the heat to the ice with blazing fast attacks.', 'cyan'), -- 13
  ('chill-crushers', 'Chill Crushers', 'Breaking the ice with powerful plays and intense rivalries.', 'lime') -- 14
;

-- new samples
INSERT INTO league_management.teams
  (name, description, color)
VALUES
  ('Shadow Panthers', 'A fierce team known for their unpredictable playstyle.', '#222222'), -- 15
  ('Crimson Vipers', 'Fast and aggressive with deadly precision.', '#B22222'), -- 16
  ('Golden Stingers', 'Masters of quick strikes and counterattacks.', '#FFD700'), -- 17
  ('Thunder Hawks', 'A high-energy team that dominates the rink.', '#8B0000'), -- 18
  ('Emerald Guardians', 'A defensive powerhouse with an unbreakable strategy.', '#228B22'), -- 19
  ('Steel Titans', 'Strong, resilient, and impossible to shake.', '#708090'), -- 20
  ('Phoenix Fire', 'Rises to the occasion in clutch moments.', '#FF4500'), -- 21
  ('Iron Wolves', 'A relentless team that never backs down.', '#2F4F4F'), -- 22
  ('Midnight Reapers', 'Lethal in the final minutes of every game.', '#4B0082'), -- 23
  ('Neon Strikers', 'A high-scoring team with flashy plays.', '#00FF7F'), -- 24
  ('Scarlet Blades', 'Masters of precision passing and quick attacks.', '#DC143C'), -- 25
  ('Cobalt Chargers', 'Unstoppable speed and offensive firepower.', '#4169E1'), -- 26
  ('Onyx Predators', 'A physically dominant team that wears down opponents.', '#000000'), -- 27
  ('Amber Raptors', 'Fast and unpredictable, known for creative plays.', '#FF8C00'), -- 28
  ('Silver Foxes', 'A veteran team with discipline and experience.', '#C0C0C0'), -- 29
  ('Voltage Kings', 'Electrifying speed and a lightning-fast transition game.', '#FFFF00'), -- 30
  ('Obsidian Warriors', 'A tough and resilient team that grinds out wins.', '#1C1C1C'), -- 31
  ('Titanium Blizzards', 'A well-balanced team with elite skill.', '#D3D3D3'), -- 32
  ('Ruby Thunder', 'A powerhouse with a thunderous offensive presence.', '#8B0000'), -- 33
  ('Sapphire Storm', 'A dynamic team known for their speed and agility.', '#0000FF') -- 34
;



-- Add captains to OPH teams
INSERT INTO league_management.team_memberships
  (user_id, team_id, team_role)
VALUES
  (6, 1, 1), -- Stephen
  (7, 1, 1), -- Levi
  (10, 2, 1), -- Jayce
  (3, 2, 1), -- Aida
  (8, 3, 1), -- Cheryl
  (11, 3, 1), -- Britt
  (9, 4, 1), -- Mason
  (5, 4, 1)  -- Kat
;

-- Add sample players to OPH teams as players
INSERT INTO league_management.team_memberships
  (user_id, team_id)
VALUES
  (15, 1), -- 9
  (16, 1), -- 10
  (17, 1), -- 11
  (18, 1), -- 12
  (19, 1), -- 13
  (20, 1), -- 14
  (21, 1), -- 15
  (22, 1), -- 16
  (23, 1), -- 17
  (24, 1), -- 18
  (25, 1), -- 19
  (26, 1), -- 20

  (27, 2), -- 21
  (28, 2), -- 22
  (29, 2), -- 23
  (30, 2), -- 24
  (31, 2), -- 25
  (32, 2), -- 26
  (33, 2), -- 27
  (34, 2), -- 28
  (35, 2), -- 29
  (36, 2), -- 30
  (37, 2), -- 31
  (38, 2), -- 32

  (39, 3), -- 33
  (40, 3), -- 34
  (41, 3), -- 35
  (42, 3), -- 36
  (43, 3), -- 37
  (44, 3), -- 38
  (45, 3), -- 39
  (46, 3), -- 40
  (47, 3), -- 41
  (48, 3), -- 42
  (49, 3), -- 43
  (50, 3), -- 44
  
  (51, 4), -- 45
  (52, 4), -- 46
  (53, 4), -- 47
  (54, 4), -- 48
  (55, 4), -- 49
  (56, 4), -- 50
  (57, 4), -- 51
  (58, 4), -- 52
  (59, 4), -- 53
  (60, 4), -- 54
  (61, 4), -- 55
  (62, 4) -- 56
;

-- Add captains to Hometown Hockey
INSERT INTO league_management.team_memberships
  (user_id, team_id, team_role)
VALUES
  (1, 5, 1), -- Adam - 57
  (12, 6, 1), -- Zach - 58
  (13, 7, 1), -- Andrew - 59
  (4, 8, 1), -- Caleb - 60
  (14, 9, 1) -- Tim - 61
;

INSERT INTO league_management.team_memberships
  (user_id, team_id)
VALUES
  (60, 5), -- 62
  (61, 5), -- 63
  (62, 5), -- 64
  (63, 5), -- 65
  (64, 5), -- 66
  (65, 5), -- 67
  (66, 5), -- 68
  (67, 5), -- 69
  (68, 5), -- 70
  (69, 5), -- 71
  (70, 6), -- 72
  (71, 6), -- 73
  (72, 6), -- 74
  (73, 6), -- 75
  (74, 6), -- 76
  (75, 6), -- 77
  (76, 6), -- 78
  (77, 6), -- 79
  (78, 6), -- 80
  (79, 6), -- 81
  (80, 7), -- 82
  (81, 7), -- 83
  (82, 7), -- 84
  (83, 7), -- 85
  (84, 7), -- 86
  (85, 7), -- 87
  (86, 7), -- 88
  (87, 7), -- 89
  (88, 7), -- 90
  (89, 7), -- 91
  (90, 8), -- 92
  (91, 8), -- 93
  (92, 8), -- 94
  (93, 8), -- 95
  (94, 8), -- 96
  (95, 8), -- 97
  (96, 8), -- 98
  (97, 8), -- 99
  (98, 8), -- 100
  (99, 8), -- 101
  (100, 9), -- 102
  (101, 9), -- 103
  (102, 9), -- 104
  (103, 9), -- 105
  (104, 9), -- 106
  (105, 9), -- 107
  (106, 9), -- 108
  (107, 9), -- 109
  (108, 9), -- 110
  (109, 9) -- 111
;

-- Default leagues
INSERT INTO league_management.leagues
  (slug, name, sport, status)
VALUES 
  ('ottawa-pride-hockey', 'Ottawa Pride Hockey', 'hockey', 'public'),
  ('fia-hockey', 'FIA Hockey', 'hockey', 'public'),
  ('hometown-hockey', 'Hometown Hockey', 'hockey', 'public')
;

-- Default league_admins
INSERT INTO league_management.league_admins
  (league_role, league_id, user_id)
VALUES 
  (1, 1, 5), -- Kat
  (1, 1, 10), -- Jayce
  (1, 1, 11), -- Britt
  (1, 2, 4), -- Caleb
  (1, 3, 1), -- Adam
  (2, 1, 1) -- Adam
;

-- Default seasons
INSERT INTO league_management.seasons
  (name, league_id, start_date, end_date, status)
VALUES
  ('Winter 2024/2025', 1, '2024-09-01', '2025-03-31', 'public'),
  ('2023-2024 Season', 2, '2023-09-01', '2024-03-31', 'public'),
  ('2024-2025 Season', 2, '2024-09-01', '2025-03-31', 'public'),
  ('2024-2025 Season', 3, '2024-09-01', '2025-03-31', 'public'),
  ('2025 Spring', 3, '2025-04-01', '2025-06-30', 'public')
;

-- Default season_admins
INSERT INTO league_management.season_admins
  (season_role, season_id, user_id)
VALUES
  (1, 3, 1),
  (1, 4, 3)
;

-- Default divisions
INSERT INTO league_management.divisions
  (name, tier, season_id, gender, status)
VALUES
  ('Div Inc', 1, 1, 'all', 'public'),
  ('Div 1', 1, 3, 'all', 'public'),
  ('Div 2', 1, 3, 'all', 'public'),
  ('Div 1', 1, 4, 'all', 'public'),
  ('Div 2', 2, 4, 'all', 'public'),
  ('Div 3', 3, 4, 'all', 'public'),
  ('Div 4', 4, 4, 'all', 'public'),
  ('Div 5', 5, 4, 'all', 'public'),
  ('Men 35+', 6, 4, 'men', 'public'),
  ('Women 35+', 6, 4, 'women', 'public'),
  ('Div 1', 1, 5, 'all', 'public'),
  ('Div 2', 2, 5, 'all', 'public'),
  ('Div 3', 3, 5, 'all', 'public'),
  ('Div 4', 4, 5, 'all', 'public'),
  ('Div 5', 5, 5, 'all', 'public'),
  ('Div 6', 6, 5, 'all', 'public'),
  ('Men 1', 1, 5, 'men', 'public'),
  ('Men 2', 2, 5, 'men', 'public'),
  ('Men 3', 3, 5, 'men', 'public'),
  ('Women 1', 1, 5, 'women', 'public'),
  ('Women 2', 2, 5, 'women', 'public'),
  ('Women 3', 3, 5, 'women', 'public')
;

-- Default division_teams
INSERT INTO league_management.division_teams
  (division_id, team_id)
VALUES
  (1, 1), -- 1
  (1, 2), -- 2
  (1, 3), -- 3
  (1, 4), -- 4
  (4, 5), -- 5
  (4, 6), -- 6
  (4, 7), -- 7
  (4, 8), -- 8
  (4, 9), -- 9
  (11, 10), -- 10
  (11, 11), -- 11
  (11, 12), -- 12
  (11, 13), -- 13
  (11, 14), -- 14
  (4, 2) -- 15
;

-- new sample teams
INSERT INTO league_management.division_teams
  (division_id, team_id)
VALUES
  (5, 15), -- 16
  (5, 16), -- 17
  (5, 17), -- 18
  (5, 18), -- 19
  (5, 19), -- 20
  (5, 20), -- 21
  (6, 21), -- 22
  (6, 22), -- 23
  (6, 23), -- 24
  (6, 24), -- 25
  (6, 25), -- 26
  (6, 26), -- 27
  (7, 27), -- 28
  (7, 28), -- 29
  (7, 29), -- 30
  (7, 30), -- 31
  (8, 31), -- 32
  (8, 32), -- 33
  (8, 33), -- 34
  (8, 34) -- 35
;

-- Default division_rosters
-- Put players who have a team role on list for team within specific season
INSERT INTO league_management.division_rosters
  (division_team_id, team_membership_id, position, number, roster_role)
VALUES
  -- Significant Otters
  (1, 1, 'Center', 30, 2),
  (1, 2, 'Defense', 25, 3),
  -- Otterwa Senators
  (2, 3, 'Defense', 18, 2),
  (2, 4, 'Defense', 47, 3),
  -- Otter Chaos
  (3, 5, 'Center', 12, 2),
  (3, 6, 'Left Wing', 9, 3),
  -- Otter Nonsense
  (4, 7, 'Right Wing', 8, 2),
  (4, 8, 'Defense', 10, 3),
  (5, 57, 'Defense', 93, 2), -- Adam
  (6, 58, 'Defense', 13, 2), -- Zach
  (7, 59, 'Defense', 6, 2), -- Andrew
  (8, 60, 'Defense', 19, 2), -- Caleb
  (9, 61, 'Left Wing', 9, 2) -- Tim
;

INSERT INTO league_management.division_rosters
  (division_team_id, team_membership_id, position, number)
VALUES
  -- Significant Otters
  (1, 9, 'Center', 8),
  (1, 10, 'Center', 9),
  (1, 11, 'Left Wing', 10),
  (1, 12, 'Left Wing', 11),
  (1, 13, 'Right Wing', 12),
  (1, 14, 'Right Wing', 13),
  (1, 15, 'Center', 14),
  (1, 16, 'Defense', 15),
  -- (1, 17, 'Defense', 16),
  -- (1, 18, 'Defense', 17),
  (1, 19, 'Defense', 18),
  (1, 20, 'Goalie', 33),
  -- Otterwa Senators
  (2, 21, 'Center', 20),
  (2, 22, 'Center', 21),
  -- (2, 23, 'Center', 22),
  -- (2, 24, 'Left Wing', 23),
  (2, 25, 'Left Wing', 24),
  (2, 26, 'Right Wing', 25),
  (2, 27, 'Right Wing', 26),
  (2, 28, 'Left Wing', 27),
  (2, 29, 'Right Wing', 28),
  (2, 30, 'Defense', 29),
  (2, 31, 'Defense', 30),
  (2, 32, 'Goalie', 31),
  -- Otter Chaos
  (3, 33, 'Center', 40),
  (3, 34, 'Center', 41),
  (3, 35, 'Left Wing', 42),
  (3, 36, 'Left Wing', 43),
  (3, 37, 'Right Wing', 44),
  -- (3, 38, 'Right Wing', 45),
  (3, 39, 'Center', 46),
  (3, 40, 'Defense', 47),
  (3, 41, 'Defense', 48),
  (3, 42, 'Defense', 49),
  -- (3, 43, 'Defense', 50),
  (3, 44, 'Goalie', 51),
  -- Otter Nonsense
  (4, 45, 'Center', 26),
  -- (4, 46, 'Center', 27),
  (4, 47, 'Left Wing', 28),
  -- (4, 48, 'Left Wing', 29),
  (4, 49, 'Right Wing', 30),
  (4, 50, 'Right Wing', 31),
  (4, 51, 'Center', 32),
  (4, 52, 'Defense', 33),
  (4, 53, 'Defense', 34),
  (4, 54, 'Defense', 35),
  (4, 55, 'Defense', 36),
  (4, 56, 'Goalie', 3),

  -- (5, 62, null, 60),
  (5, 63, null, 61),
  -- (5, 64, null, 62),
  (5, 65, null, 63),
  (5, 66, null, 64),
  (5, 67, null, 65),
  (5, 68, null, 66),
  (5, 69, null, 67),
  (5, 70, null, 68),
  (5, 71, 'Goalie', 69),

  (6, 72, null, 70),
  (6, 73, null, 71),
  -- (6, 74, null, 72),
  (6, 75, null, 73),
  (6, 76, null, 74),
  (6, 77, null, 75),
  (6, 78, null, 76),
  -- (6, 79, null, 77),
  (6, 80, null, 78),
  (6, 81, 'Goalie', 79),

  (7, 82, null, 80),
  (7, 83, null, 81),
  -- (7, 84, null, 82),
  (7, 85, null, 83),
  (7, 86, null, 84),
  -- (7, 87, null, 85),
  (7, 88, null, 86),
  (7, 89, null, 87),
  (7, 90, null, 88),
  (7, 91, 'Goalie', 89),

  -- (8, 92, null, 90),
  (8, 93, null, 91),
  (8, 94, null, 92),
  (8, 95, null, 93),
  (8, 96, null, 94),
  (8, 97, null, 95),
  (8, 98, null, 96),
  (8, 99, null, 97),
  -- (8, 100, null, 98),
  (8, 101, 'Goalie', 1),

  -- (9, 102, null, 20),
  (9, 103, null, 21),
  (9, 104, null, 22),
  (9, 105, null, 23),
  -- (9, 106, null, 24),
  (9, 107, null, 25),
  (9, 108, null, 26),
  (9, 109, null, 27),
  (9, 110, null, 28),
  (9, 111, 'Goalie', 29),

  -- Otterwa Senators - Hometown Hockey
  (15, 3, 'Defense', 18),
  (15, 4, 'Center', 47),
  (15, 21, 'Goalie', 20),
  (15, 22, 'Right Wing', 21),
  (15, 23, 'Center', 22),
  (15, 24, 'Left Wing', 23),
  (15, 27, 'Defense', 26),
  (15, 28, 'Left Wing', 27),
  (15, 29, 'Right Wing', 28),
  (15, 30, 'Defense', 29),
  (15, 31, 'Left Wing', 30)
;

-- Default list of venues
INSERT INTO league_management.venues
  (slug, name, description, address)
VALUES
  ('canadian-tire-centre', 'Canadian Tire Centre', 'Home of the NHL''s Ottawa Senators, this state-of-the-art entertainment facility seats 19,153 spectators.', '1000 Palladium Dr, Ottawa, ON K2V 1A5'),
  ('bell-sensplex', 'Bell Sensplex', 'A multi-purpose sports facility featuring four NHL-sized ice rinks, including an Olympic-sized rink, operated by Capital Sports Management.', '1565 Maple Grove Rd, Ottawa, ON K2V 1A3'),
  ('td-place-arena', 'TD Place Arena', 'An indoor arena located at Lansdowne Park, hosting the Ottawa 67''s (OHL) and Ottawa Blackjacks (CEBL), with a seating capacity of up to 8,585.', '1015 Bank St, Ottawa, ON K1S 3W7'),
  ('minto-sports-complex-arena', 'Minto Sports Complex Arena', 'Part of the University of Ottawa, this complex contains two ice rinks, one with seating for 840 spectators, and the Draft Pub overlooking the ice.', '801 King Edward Ave, Ottawa, ON K1N 6N5'),
  ('carleton-university-ice-house', 'Carleton University Ice House', 'A leading indoor skating facility featuring two NHL-sized ice surfaces, home to the Carleton Ravens hockey teams.', '1125 Colonel By Dr, Ottawa, ON K1S 5B6'),
  ('howard-darwin-centennial-arena', 'Howard Darwin Centennial Arena', 'A community arena offering ice rentals and public skating programs, maleaged by the City of Ottawa.', '1765 Merivale Rd, Ottawa, ON K2G 1E1'),
  ('fred-barrett-arena', 'Fred Barrett Arena', 'A municipal arena providing ice rentals and public skating, located in the southern part of Ottawa.', '3280 Leitrim Rd, Ottawa, ON K1T 3Z4'),
  ('blackburn-arena', 'Blackburn Arena', 'A community arena offering skating programs and ice rentals, serving the Blackburn Hamlet area.', '200 Glen Park Dr, Gloucester, ON K1B 5A3'),
  ('bob-macquarrie-recreation-complex-orlans-arena', 'Bob MacQuarrie Recreation Complex – Orléans Arena', 'A recreation complex featuring an arena, pool, and fitness facilities, serving the Orléans community.', '1490 Youville Dr, Orléans, ON K1C 2X8'),
  ('brewer-arena', 'Brewer Arena', 'A municipal arena adjacent to Brewer Park, offering public skating and ice rentals.', '200 Hopewell Ave, Ottawa, ON K1S 2Z5')
;

-- Default venue arenas
INSERT INTO league_management.arenas
  (slug, name, venue_id)
VALUES
  ('arena', 'Arena', 1),
  ('1', '1', 2),
  ('2', '2', 2),
  ('3', '3', 2),
  ('4', '4', 2),
  ('arena', 'Arena', 3),
  ('a', 'A', 4),
  ('b', 'B', 4),
  ('a', 'A', 5),
  ('b', 'B', 5),
  ('arena', 'Arena', 6),
  ('a', 'A', 7),
  ('b', 'B', 7),
  ('arena', 'Arena', 8),
  ('a', 'A', 9),
  ('b', 'B', 9),
  ('arena', 'Arena', 10)
;

-- Default venues attached to leagues
INSERT INTO league_management.league_venues
  (venue_id, league_id)
VALUES
  (5, 1),
  (7, 3),
  (6, 3),
  (10, 3)
;

-- List of games

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

ALTER SEQUENCE games_game_id_seq RESTART WITH 51;

-- Goal samples
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
INSERT INTO stats.goals VALUES (64, 28, 32, 2, 3, '00:12:56', false, false, false, '2025-01-29 21:17:20.723557');
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

ALTER SEQUENCE stats.goals_goal_id_seq RESTART WITH 95;

-- Assist samples
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

ALTER SEQUENCE stats.assists_assist_id_seq RESTART WITH 89;

-- Penalties

INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (1, 31, 7, 1, 1, '00:15:02', 'Tripping', 2, '2025-01-28 15:35:00.023976');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (2, 31, 32, 2, 2, '00:08:22', 'Hooking', 2, '2025-01-28 15:35:00.023976');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (3, 31, 32, 2, 3, '00:11:31', 'Interference', 2, '2025-01-28 15:35:00.023976');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (7, 33, 15, 1, 1, '00:12:25', 'Tripping', 2, '2025-01-28 22:11:31.236037');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (8, 33, 47, 3, 2, '00:05:48', 'Too Maley Players', 2, '2025-01-28 22:21:39.139248');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (9, 33, 19, 1, 3, '00:12:42', 'Hooking', 2, '2025-01-28 22:22:38.701351');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (11, 34, 10, 2, 2, '00:05:50', 'Holding', 2, '2025-01-29 17:32:25.075633');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (12, 34, 32, 2, 3, '00:06:55', 'Hitting from behind', 5, '2025-01-29 19:37:54.835293');
INSERT INTO stats.penalties (penalty_id, game_id, user_id, team_id, period, period_time, infraction, minutes, created_on) VALUES (13, 28, 27, 2, 2, '00:09:18', 'Roughing', 2, '2025-01-29 21:16:15.507966');

ALTER SEQUENCE stats.penalties_penalty_id_seq RESTART WITH 14;

-- Shots
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

ALTER SEQUENCE stats.shots_shot_id_seq RESTART WITH 140;

-- Saves

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

ALTER SEQUENCE stats.saves_save_id_seq RESTART WITH 40;