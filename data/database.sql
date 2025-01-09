-- Create the leagrr Database on PostgreSQL server

----------------------------------------------------------
-- EMPTY THE LEAGRR DATABASE IN CASE IT CONTAINS CONTENT
----------------------------------------------------------

-- Create admin
DROP TABLE IF EXISTS admin.user_roles CASCADE;
DROP TABLE IF EXISTS admin.league_roles CASCADE;
DROP TABLE IF EXISTS admin.season_roles CASCADE;
DROP TABLE IF EXISTS admin.playoff_structures CASCADE;
DROP TABLE IF EXISTS admin.team_roles CASCADE;
DROP TABLE IF EXISTS admin.sports CASCADE;
DROP TABLE IF EXISTS admin.genders CASCADE;
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
CREATE SCHEMA league_management;
CREATE SCHEMA admin;
CREATE SCHEMA stats;

-- Alter roles to view schemas and tables
ALTER ROLE postgres SET search_path = league_management, admin;

-- Create admin.user_roles
-- Defines the roles assigned to all users for basic app wide permissions
CREATE TABLE admin.user_roles (
  user_role_id    SERIAL NOT NULL PRIMARY KEY,
  name            VARCHAR(50) NOT NULL,
  description     TEXT,
  created_on      TIMESTAMP DEFAULT NOW()
);

-- Create admin.league_roles
-- Defines the roles and permissions assignable to individual users for specific leagues
CREATE TABLE admin.league_roles (
  league_role_id    SERIAL NOT NULL PRIMARY KEY,
  name            VARCHAR(50) NOT NULL,
  description     TEXT,
  created_on      TIMESTAMP DEFAULT NOW()
);

-- Create admin.season_roles
-- Defines the roles and permissions assignable to individual users for specific seasons
CREATE TABLE admin.season_roles (
  season_role_id    SERIAL NOT NULL PRIMARY KEY,
  name            VARCHAR(50) NOT NULL,
  description     TEXT,
  created_on      TIMESTAMP DEFAULT NOW()
);

-- Create admin.playoff_structures
-- Define different types of playoff structures
CREATE TABLE admin.playoff_structures (
  playoff_structure_id    SERIAL NOT NULL PRIMARY KEY,
  name                    VARCHAR(50) NOT NULL,
  description             TEXT,
  created_on              TIMESTAMP DEFAULT NOW()
);

-- Create admin.team_roles
-- Defines the roles and permissions assignable to individual users for specific teams
CREATE TABLE admin.team_roles (
  team_role_id    SERIAL NOT NULL PRIMARY KEY,
  name            VARCHAR(50) NOT NULL,
  description     TEXT,
  created_on      TIMESTAMP DEFAULT NOW()
);

-- Create admin.sports
-- Define list of sports supported by the app
CREATE TABLE admin.sports (
  sport_id        SERIAL NOT NULL PRIMARY KEY,
  slug            VARCHAR(50) NOT NULL UNIQUE,
  name            VARCHAR(50) NOT NULL,
  description     TEXT,
  created_on      TIMESTAMP DEFAULT NOW()
);

-- Create admin.genders
-- List of gender options selected by users and used to restrict rosters in divisions
CREATE TABLE admin.genders (
  gender_id       SERIAL NOT NULL PRIMARY KEY,
  slug            VARCHAR(50) NOT NULL UNIQUE,
  name            VARCHAR(50) NOT NULL,
  created_on      TIMESTAMP DEFAULT NOW()
);

-- Create admin.users
-- Define user table for all user accounts
CREATE TABLE admin.users (
  user_id         SERIAL NOT NULL PRIMARY KEY,
  username        VARCHAR(50) NOT NULL UNIQUE,
  email           VARCHAR(50) NOT NULL UNIQUE,
  first_name      VARCHAR(50) NOT NULL,
  last_name       VARCHAR(50) NOT NULL,
  gender_id       INT,
  pronouns        VARCHAR(50),
  user_role       INT NOT NULL DEFAULT 3,
  password_hash   VARCHAR(100),
  created_on      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE admin.users
ADD CONSTRAINT fk_users_user_role FOREIGN KEY (user_role)
    REFERENCES admin.user_roles (user_role_id);

ALTER TABLE admin.users
ADD CONSTRAINT fk_users_gender_id FOREIGN KEY (gender_id)
    REFERENCES admin.genders (gender_id);

-- Create league_management.teams
-- Create team that can be connected to multiple divisions in different leagues.
CREATE TABLE league_management.teams (
  team_id         SERIAL NOT NULL PRIMARY KEY,
  slug            VARCHAR(50) NOT NULL UNIQUE,
  name            VARCHAR(50) NOT NULL,
  description     TEXT,
  created_on      TIMESTAMP DEFAULT NOW()
);

-- Create league_management.team_memberships
-- Joiner table adding users to teams with a specific team role
CREATE TABLE league_management.team_memberships (
  team_membership_id    SERIAL NOT NULL PRIMARY KEY,
  user_id               INT NOT NULL,
  team_id               INT NOT NULL,
  team_role_id          INT DEFAULT 1,
  created_on            TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.team_memberships
ADD CONSTRAINT fk_team_memberships_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id);

ALTER TABLE league_management.team_memberships
ADD CONSTRAINT fk_team_memberships_team_id FOREIGN KEY (team_id)
    REFERENCES league_management.teams (team_id);

ALTER TABLE league_management.team_memberships
ADD CONSTRAINT fk_team_memberships_team_role_id FOREIGN KEY (team_role_id)
    REFERENCES admin.team_roles (team_role_id);

-- Create league_management.leagues
-- Define league table structure
CREATE TABLE league_management.leagues (
  league_id         SERIAL NOT NULL PRIMARY KEY,
  slug            VARCHAR(50) NOT NULL UNIQUE,
  name            VARCHAR(50) NOT NULL,
  description     TEXT,
  sport_id        INT,
  created_on      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.leagues
ADD CONSTRAINT fk_leagues_sport_id FOREIGN KEY (sport_id)
    REFERENCES admin.sports (sport_id);

-- Create league_management.league_admins
-- A joiner table that connects a user with a league and assigns them a specific role
CREATE TABLE league_management.league_admins (
  league_admin_id     SERIAL NOT NULL PRIMARY KEY,
  league_role_id      INT,
  league_id           INT,
  user_id             INT,
  created_on          TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.league_admins
ADD CONSTRAINT fk_league_admins_league_role_id FOREIGN KEY (league_role_id)
    REFERENCES admin.league_roles (league_role_id);

ALTER TABLE league_management.league_admins
ADD CONSTRAINT fk_league_admins_league_id FOREIGN KEY (league_id)
    REFERENCES league_management.leagues (league_id);

ALTER TABLE league_management.league_admins
ADD CONSTRAINT fk_league_admins_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id);

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
  created_on      TIMESTAMP DEFAULT NOW()
);

-- Create league_management.season_admins
-- A joiner table that connects a user with a season and assigns them a specific role
CREATE TABLE league_management.season_admins (
  season_admin_id     SERIAL NOT NULL PRIMARY KEY,
  season_role_id      INT,
  season_id           INT,
  user_id             INT,
  created_on          TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.season_admins
ADD CONSTRAINT fk_season_admins_season_role_id FOREIGN KEY (season_role_id)
    REFERENCES admin.season_roles (season_role_id);

ALTER TABLE league_management.season_admins
ADD CONSTRAINT fk_season_admins_season_id FOREIGN KEY (season_id)
    REFERENCES league_management.seasons (season_id);

ALTER TABLE league_management.season_admins
ADD CONSTRAINT fk_season_admins_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id);

-- Create league_management.divisions
-- A division is a grouping of teams of same skill level within a season.
CREATE TABLE league_management.divisions (
  division_id     SERIAL NOT NULL PRIMARY KEY,
  slug            VARCHAR(50) NOT NULL,
  name            VARCHAR(50) NOT NULL,
  description     TEXT,
  tier            INT,
  gender          VARCHAR(10) NOT NULL DEFAULT 'Co-ed',
  season_id       INT,
  created_on      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.divisions
ADD CONSTRAINT fk_divisions_season_id FOREIGN KEY (season_id)
    REFERENCES league_management.seasons (season_id);

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
    REFERENCES league_management.divisions (division_id);

ALTER TABLE league_management.division_teams
ADD CONSTRAINT fk_division_teams_team_id FOREIGN KEY (team_id)
    REFERENCES league_management.teams (team_id);

-- Create league_management.division_rosters
-- Joiner table assigning players to a team within divisions
CREATE TABLE league_management.division_rosters (
  division_roster_id    SERIAL NOT NULL PRIMARY KEY,
  division_team_id      INT,
  user_id               INT,
  created_on            TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.division_rosters
ADD CONSTRAINT fk_division_rosters_division_team_id FOREIGN KEY (division_team_id)
    REFERENCES league_management.division_teams (division_team_id);

ALTER TABLE league_management.division_rosters
ADD CONSTRAINT fk_division_rosters_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id);

-- Create league_management.playoffs
-- Create a playoff round that is connected to a division and is assigned a playoff_structure
CREATE TABLE league_management.playoffs (
  playoff_id            SERIAL NOT NULL PRIMARY KEY,
  slug                  VARCHAR(50) NOT NULL,
  name                  VARCHAR(50) NOT NULL,
  description           TEXT,
  playoff_structure_id  INT,
  created_on            TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.playoffs
ADD CONSTRAINT fk_playoffs_playoff_structure_id FOREIGN KEY (playoff_structure_id)
    REFERENCES admin.playoff_structures (playoff_structure_id);

-- Create league_management.venues
CREATE TABLE league_management.venues (
  venue_id            SERIAL NOT NULL PRIMARY KEY,
  slug                VARCHAR(50) NOT NULL UNIQUE,
  name                VARCHAR(50) NOT NULL,
  description         TEXT,
  address             TEXT,
  created_on          TIMESTAMP DEFAULT NOW()
);

-- Create league_management.arenas
CREATE TABLE league_management.arenas (
  arena_id            SERIAL NOT NULL PRIMARY KEY,
  slug                VARCHAR(50) NOT NULL,
  name                VARCHAR(50) NOT NULL,
  description         TEXT,
  venue_id            INT NOT NULL,
  created_on          TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.arenas
ADD CONSTRAINT fk_arena_venue_id FOREIGN KEY (venue_id)
    REFERENCES league_management.venues (venue_id);

-- Create league_management.games
CREATE TABLE league_management.games (
  game_id           SERIAL NOT NULL PRIMARY KEY,
  home_team_id      INT,
  home_team_score   INT DEFAULT 0,
  away_team_id      INT,
  away_team_score   INT DEFAULT 0,
  division_id       INT NOT NULL,
  date_time         TIMESTAMP,
  arena_id          INT,
  status            VARCHAR(20),
  created_on        TIMESTAMP DEFAULT NOW()
);

ALTER TABLE league_management.games
ADD CONSTRAINT fk_game_arena_id FOREIGN KEY (arena_id)
    REFERENCES league_management.arenas (arena_id);

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
    REFERENCES league_management.games (game_id);

ALTER TABLE stats.goals
ADD CONSTRAINT fk_goals_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id);

ALTER TABLE stats.goals
ADD CONSTRAINT fk_goals_team_id FOREIGN KEY (team_id)
    REFERENCES league_management.teams (team_id);

-- Create Assist
-- An assist marks players who passed to the goal scorer
CREATE TABLE stats.assists (
  assist_id       SERIAL NOT NULL PRIMARY KEY,
  goal_id         INT NOT NULL,
  game_id         INT NOT NULL,
  user_id         INT NOT NULL,
  team_id         INT NOT NULL,
  primary_assist  BOOLEAN DEFAULT false,
  created_on      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE stats.assists
ADD CONSTRAINT fk_assists_goal_id FOREIGN KEY (goal_id)
    REFERENCES stats.goals (goal_id);

ALTER TABLE stats.assists
ADD CONSTRAINT fk_assists_game_id FOREIGN KEY (game_id)
    REFERENCES league_management.games (game_id);

ALTER TABLE stats.assists
ADD CONSTRAINT fk_assists_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id);

ALTER TABLE stats.assists
ADD CONSTRAINT fk_assists_team_id FOREIGN KEY (team_id)
    REFERENCES league_management.teams (team_id);

-- Create penalties
-- Tracks individual penalties committed by players and connects them with games
CREATE TABLE stats.penalties (
  penalty_id         SERIAL NOT NULL PRIMARY KEY,
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
    REFERENCES league_management.games (game_id);

ALTER TABLE stats.penalties
ADD CONSTRAINT fk_penalties_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id);

ALTER TABLE stats.penalties
ADD CONSTRAINT fk_penalties_team_id FOREIGN KEY (team_id)
    REFERENCES league_management.teams (team_id);

-- Create shots
-- Track shots and connect the shots to a game and a player
CREATE TABLE stats.shots (
  shot_id         SERIAL NOT NULL PRIMARY KEY,
  game_id         INT NOT NULL,
  user_id         INT NOT NULL,
  team_id         INT NOT NULL,
  period          INT,
  period_time     INTERVAL,
  shorthanded     BOOLEAN DEFAULT false,
  power_play      BOOLEAN DEFAULT false,
  created_on      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE stats.shots
ADD CONSTRAINT fk_shots_game_id FOREIGN KEY (game_id)
    REFERENCES league_management.games (game_id);

ALTER TABLE stats.shots
ADD CONSTRAINT fk_shots_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id);

ALTER TABLE stats.shots
ADD CONSTRAINT fk_shots_team_id FOREIGN KEY (team_id)
    REFERENCES league_management.teams (team_id);

-- Create saves
-- Track saves and connect the saves to a game and a player
CREATE TABLE stats.saves (
  save_id         SERIAL NOT NULL PRIMARY KEY,
  game_id         INT NOT NULL,
  user_id         INT NOT NULL,
  team_id         INT NOT NULL,
  period          INT,
  period_time     INTERVAL,
  penalty_kill    BOOLEAN DEFAULT false,
  rebound         BOOLEAN DEFAULT false,
  created_on      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE stats.saves
ADD CONSTRAINT fk_saves_game_id FOREIGN KEY (game_id)
    REFERENCES league_management.games (game_id);

ALTER TABLE stats.saves
ADD CONSTRAINT fk_saves_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id);

ALTER TABLE stats.saves
ADD CONSTRAINT fk_saves_team_id FOREIGN KEY (team_id)
    REFERENCES league_management.teams (team_id);

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
    REFERENCES league_management.games (game_id);

ALTER TABLE stats.shutouts
ADD CONSTRAINT fk_shutouts_user_id FOREIGN KEY (user_id)
    REFERENCES admin.users (user_id);

ALTER TABLE stats.shutouts
ADD CONSTRAINT fk_shutouts_team_id FOREIGN KEY (team_id)
    REFERENCES league_management.teams (team_id);

-----------------------------------
-- INSERT DATA INTO TABLES 
-----------------------------------

-- Default user_roles
INSERT INTO admin.user_roles
  (name)
VALUES
  ('Admin'),
  ('Commissioner'),
  ('User')
;

-- Default league_roles
INSERT INTO admin.league_roles
  (name)
VALUES
  ('Commissioner'),
  ('Manager')
;

-- Default season_roles
INSERT INTO admin.season_roles
  (name)
VALUES
  ('Manager'),
  ('Time Keeper'),
  ('Referee')
;

-- Default playoff_structure
INSERT INTO admin.playoff_structures
  (name)
VALUES
  ('Bracket'),
  ('Round Robin + Bracket')
;

-- Default team_roles
INSERT INTO admin.team_roles
  (name)
VALUES
  ('Player'),
  ('Manager'),
  ('Coach'),
  ('Captain'),
  ('Alternate Captain'),
  ('Spare')
;

-- Default sports
INSERT INTO admin.sports
  (slug, name)
VALUES
  ('hockey', 'Hockey'),
  ('soccer', 'Soccer'),
  ('basketball', 'Basketball'),
  ('pickleball', 'Pickleball'),
  ('badminton', 'Badminton')
;

-- Default genders
INSERT INTO admin.genders
  (slug, name)
VALUES
  ('woman', 'Woman'),
  ('man', 'Man'),
  ('non-binary-non-conforming', 'Non-binary/Non-conforming'),
  ('two-spirit', 'Two-spirit')
;

-- Default named users
INSERT INTO admin.users
  (username, email, first_name, last_name, gender_id, pronouns, user_role, password_hash)
VALUES
  -- 1
  ('moose', 'hello+2@adamrobillard.ca', 'Adam', 'Robillard', 3, 'any/all', 1, 'heyAdam123'),
  -- 2
  ('goose', 'hello+1@adamrobillard.ca', 'Hannah', 'Brown', 1, 'she/her', 3, 'heyHannah123'),
  -- 3
  ('caboose', 'hello+3@adamrobillard.ca', 'Aida', 'Robillard', 3, 'any/all', 1, 'heyAida123'),
  -- 4
  ('caleb', 'hello+4@adamrobillard.ca', 'Caleb', 'Smith', 2, 'he/him', 2, 'heyCaleb123'),
  -- 5
  ('kat', 'hello+5@adamrobillard.ca', 'Kat', 'Ferguson', 3, 'they/them', 2, 'heyKat123'),
  -- 6
  ('trainMan', 'hello+6@adamrobillard.ca', 'Stephen', 'Spence', 2, 'he/him', 3, 'heyStephen123'),
  -- 7
  ('theGoon', 'hello+7@adamrobillard.ca', 'Levi', 'Bradley', 3, 'they/them', 3, 'heyLevi123'),
  -- 8
  ('cheryl', 'hello+8@adamrobillard.ca', 'Cheryl', 'Chaos', null, null, 3, 'heyCheryl123'),
  -- 9
  ('mason', 'hello+9@adamrobillard.ca', 'Mason', 'Nonsense', null, null, 3, 'heyMasonl123'),
  -- 10
  ('jayce', 'hello+10@adamrobillard.ca', 'Jayce', 'LeClaire', 3, 'they/them', 3, 'heyJaycel123'),
  -- 11
  ('britt', 'hello+110@adamrobillard.ca', 'Britt', 'Neron', 3, 'they/them', 3, 'heyBrittl123'),
  -- 12
  ('tesolin', 'hello+12@adamrobillard.ca', 'Zachary', 'Tesolin', 2, 'he/him', 3, 'heyZach123'),
  -- 13
  ('robocop', 'hello+13@adamrobillard.ca', 'Andrew', 'Robillard', 2, 'he/him', 3, 'heyAndrew123'),
  -- 14
  ('trex', 'hello+14@adamrobillard.ca', 'Tim', 'Robillard', 2, 'he/him', 3, 'heyTim123')
;

-- Default generic users
INSERT INTO admin.users
  (username, email, first_name, last_name, gender_id, pronouns, password_hash)
VALUES
  ('lukasbauer', 'lukas.bauer@example.com', 'Lukas', 'Bauer', 2, 'he/him', 'heyLukas123'),
  ('emmaschmidt', 'emma.schmidt@example.com', 'Emma', 'Schmidt', 1, 'she/her', 'heyEmma123'),
  ('liammüller', 'liam.mueller@example.com', 'Liam', 'Müller', 2, 'he/him', 'heyLiam123'),
  ('hannafischer', 'hanna.fischer@example.com', 'Hanna', 'Fischer', 1, 'she/her', 'heyHanna123'),
  ('oliverkoch', 'oliver.koch@example.com', 'Oliver', 'Koch', 2, 'he/him', 'heyOliver123'),
  ('clararichter', 'clara.richter@example.com', 'Clara', 'Richter', 1, 'she/her', 'heyClara123'),
  ('noahtaylor', 'noah.taylor@example.com', 'Noah', 'Taylor', 2, 'he/him', 'heyNoah123'),
  ('lisahoffmann', 'lisa.hoffmann@example.com', 'Lisa', 'Hoffmann', 1, 'she/her', 'heyLisa123'),
  ('matteorossetti', 'matteo.rossetti@example.com', 'Matteo', 'Rossetti', 2, 'he/him', 'heyMatteo123'),
  ('giuliarossi', 'giulia.rossi@example.com', 'Giulia', 'Rossi', 1, 'she/her', 'heyGiulia123'),
  ('danielebrown', 'daniele.brown@example.com', 'Daniele', 'Brown', 3, 'they/them', 'heyDaniele123'),
  ('sofialopez', 'sofia.lopez@example.com', 'Sofia', 'Lopez', 1, 'she/her', 'heySofia123'),
  ('sebastienmartin', 'sebastien.martin@example.com', 'Sebastien', 'Martin', 2, 'he/him', 'heySebastien123'),
  ('elisavolkova', 'elisa.volkova@example.com', 'Elisa', 'Volkova', 1, 'she/her', 'heyElisa123'),
  ('adriangarcia', 'adrian.garcia@example.com', 'Adrian', 'Garcia', 2, 'he/him', 'heyAdrian123'),
  ('amelialeroux', 'amelia.leroux@example.com', 'Amelia', 'LeRoux', 1, 'she/her', 'heyAmelia123'),
  ('kasperskov', 'kasper.skov@example.com', 'Kasper', 'Skov', 2, 'he/him', 'heyKasper123'),
  ('elinefransen', 'eline.fransen@example.com', 'Eline', 'Fransen', 1, 'she/her', 'heyEline123'),
  ('andreakovacs', 'andrea.kovacs@example.com', 'Andrea', 'Kovacs', 3, 'they/them', 'heyAndrea123'),
  ('petersmith', 'peter.smith@example.com', 'Peter', 'Smith', 2, 'he/him', 'heyPeter123'),
  ('janinanowak', 'janina.nowak@example.com', 'Janina', 'Nowak', 1, 'she/her', 'heyJanina123'),
  ('niklaspetersen', 'niklas.petersen@example.com', 'Niklas', 'Petersen', 2, 'he/him', 'heyNiklas123'),
  ('martakalinski', 'marta.kalinski@example.com', 'Marta', 'Kalinski', 1, 'she/her', 'heyMarta123'),
  ('tomasmarquez', 'tomas.marquez@example.com', 'Tomas', 'Marquez', 2, 'he/him', 'heyTomas123'),
  ('ireneschneider', 'irene.schneider@example.com', 'Irene', 'Schneider', 1, 'she/her', 'heyIrene123'),
  ('maximilianbauer', 'maximilian.bauer@example.com', 'Maximilian', 'Bauer', 2, 'he/him', 'heyMaximilian123'),
  ('annaschaefer', 'anna.schaefer@example.com', 'Anna', 'Schaefer', 1, 'she/her', 'heyAnna123'),
  ('lucasvargas', 'lucas.vargas@example.com', 'Lucas', 'Vargas', 2, 'he/him', 'heyLucas123'),
  ('sofiacosta', 'sofia.costa@example.com', 'Sofia', 'Costa', 1, 'she/her', 'heySofia123'),
  ('alexanderricci', 'alexander.ricci@example.com', 'Alexander', 'Ricci', 2, 'he/him', 'heyAlexander123'),
  ('noemiecaron', 'noemie.caron@example.com', 'Noemie', 'Caron', 1, 'she/her', 'heyNoemie123'),
  ('pietrocapello', 'pietro.capello@example.com', 'Pietro', 'Capello', 2, 'he/him', 'heyPietro123'),
  ('elisabethjensen', 'elisabeth.jensen@example.com', 'Elisabeth', 'Jensen', 1, 'she/her', 'heyElisabeth123'),
  ('dimitripapadopoulos', 'dimitri.papadopoulos@example.com', 'Dimitri', 'Papadopoulos', 2, 'he/him', 'heyDimitri123'),
  ('marielaramos', 'mariela.ramos@example.com', 'Mariela', 'Ramos', 1, 'she/her', 'heyMariela123'),
  ('valeriekeller', 'valerie.keller@example.com', 'Valerie', 'Keller', 1, 'she/her', 'heyValerie123'),
  ('dominikbauer', 'dominik.bauer@example.com', 'Dominik', 'Bauer', 2, 'he/him', 'heyDominik123'),
  ('evaweber', 'eva.weber@example.com', 'Eva', 'Weber', 1, 'she/her', 'heyEva123'),
  ('sebastiancortes', 'sebastian.cortes@example.com', 'Sebastian', 'Cortes', 2, 'he/him', 'heySebastian123'),
  ('manongarcia', 'manon.garcia@example.com', 'Manon', 'Garcia', 1, 'she/her', 'heyManon123'),
  ('benjaminflores', 'benjamin.flores@example.com', 'Benjamin', 'Flores', 2, 'he/him', 'heyBenjamin123'),
  ('saradalgaard', 'sara.dalgaard@example.com', 'Sara', 'Dalgaard', 1, 'she/her', 'heySara123'),
  ('jonasmartinez', 'jonas.martinez@example.com', 'Jonas', 'Martinez', 2, 'he/him', 'heyJonas123'),
  ('alessiadonati', 'alessia.donati@example.com', 'Alessia', 'Donati', 1, 'she/her', 'heyAlessia123'),
  ('lucaskovac', 'lucas.kovac@example.com', 'Lucas', 'Kovac', 3, 'they/them', 'heyLucas123'),
  ('emiliekoch', 'emilie.koch@example.com', 'Emilie', 'Koch', 1, 'she/her', 'heyEmilie123'),
  ('danieljones', 'daniel.jones@example.com', 'Daniel', 'Jones', 2, 'he/him', 'heyDaniel123'),
  ('mathildevogel', 'mathilde.vogel@example.com', 'Mathilde', 'Vogel', 1, 'she/her', 'heyMathilde123'),
  ('thomasleroux', 'thomas.leroux@example.com', 'Thomas', 'LeRoux', 2, 'he/him', 'heyThomas123'),
  ('angelaperez', 'angela.perez@example.com', 'Angela', 'Perez', 1, 'she/her', 'heyAngela123'),
  ('henrikstrom', 'henrik.strom@example.com', 'Henrik', 'Strom', 2, 'he/him', 'heyHenrik123'),
  ('paulinaklein', 'paulina.klein@example.com', 'Paulina', 'Klein', 1, 'she/her', 'heyPaulina123'),
  ('raphaelgonzalez', 'raphael.gonzalez@example.com', 'Raphael', 'Gonzalez', 2, 'he/him', 'heyRaphael123'),
  ('annaluisachavez', 'anna-luisa.chavez@example.com', 'Anna-Luisa', 'Chavez', 1, 'she/her', 'heyAnna-Luisa123'),
  ('fabiomercier', 'fabio.mercier@example.com', 'Fabio', 'Mercier', 2, 'he/him', 'heyFabio123'),
  ('nataliefischer', 'natalie.fischer@example.com', 'Natalie', 'Fischer', 1, 'she/her', 'heyNatalie123'),
  ('georgmayer', 'georg.mayer@example.com', 'Georg', 'Mayer', 2, 'he/him', 'heyGeorg123'),
  ('julianweiss', 'julian.weiss@example.com', 'Julian', 'Weiss', 2, 'he/him', 'heyJulian123'),
  ('katharinalopez', 'katharina.lopez@example.com', 'Katharina', 'Lopez', 1, 'she/her', 'heyKatharina123'),
  ('simonealvarez', 'simone.alvarez@example.com', 'Simone', 'Alvarez', 3, 'they/them', 'heySimone123'),
  ('frederikschmidt', 'frederik.schmidt@example.com', 'Frederik', 'Schmidt', 2, 'he/him', 'heyFrederik123'),
  ('mariakoval', 'maria.koval@example.com', 'Maria', 'Koval', 1, 'she/her', 'heyMaria123'),
  ('lukemccarthy', 'luke.mccarthy@example.com', 'Luke', 'McCarthy', 2, 'he/him', 'heyLuke123'),
  ('larissahansen', 'larissa.hansen@example.com', 'Larissa', 'Hansen', 1, 'she/her', 'heyLarissa123'),
  ('adamwalker', 'adam.walker@example.com', 'Adam', 'Walker', 2, 'he/him', 'heyAdam123'),
  ('paolamendes', 'paola.mendes@example.com', 'Paola', 'Mendes', 1, 'she/her', 'heyPaola123'),
  ('ethanwilliams', 'ethan.williams@example.com', 'Ethan', 'Williams', 2, 'he/him', 'heyEthan123'),
  ('evastark', 'eva.stark@example.com', 'Eva', 'Stark', 1, 'she/her', 'heyEva123'),
  ('juliankovacic', 'julian.kovacic@example.com', 'Julian', 'Kovacic', 2, 'he/him', 'heyJulian123'),
  ('ameliekrause', 'amelie.krause@example.com', 'Amelie', 'Krause', 1, 'she/her', 'heyAmelie123'),
  ('ryanschneider', 'ryan.schneider@example.com', 'Ryan', 'Schneider', 2, 'he/him', 'heyRyan123'),
  ('monikathomsen', 'monika.thomsen@example.com', 'Monika', 'Thomsen', 1, 'she/her', 'heyMonika123'),
  ('daniellefoster', 'danielle.foster@example.com', 'Danielle', 'Foster', 4, 'she/her', 'heyDanielle123'),
  ('harrykhan', 'harry.khan@example.com', 'Harry', 'Khan', 2, 'he/him', 'heyHarry123'),
  ('sophielindgren', 'sophie.lindgren@example.com', 'Sophie', 'Lindgren', 1, 'she/her', 'heySophie123'),
  ('oskarpetrov', 'oskar.petrov@example.com', 'Oskar', 'Petrov', 2, 'he/him', 'heyOskar123'),
  ('lindavon', 'linda.von@example.com', 'Linda', 'Von', 1, 'she/her', 'heyLinda123'),
  ('andreaspeicher', 'andreas.peicher@example.com', 'Andreas', 'Peicher', 2, 'he/him', 'heyAndreas123'),
  ('josephinejung', 'josephine.jung@example.com', 'Josephine', 'Jung', 1, 'she/her', 'heyJosephine123'),
  ('marianapaz', 'mariana.paz@example.com', 'Mariana', 'Paz', 1, 'she/her', 'heyMariana123'),
  ('fionaberg', 'fiona.berg@example.com', 'Fiona', 'Berg', 1, 'she/her', 'heyFiona123'),
  ('joachimkraus', 'joachim.kraus@example.com', 'Joachim', 'Kraus', 2, 'he/him', 'heyJoachim123'),
  ('michellebauer', 'michelle.bauer@example.com', 'Michelle', 'Bauer', 1, 'she/her', 'heyMichelle123'),
  ('mariomatteo', 'mario.matteo@example.com', 'Mario', 'Matteo', 2, 'he/him', 'heyMario123'),
  ('elizabethsmith', 'elizabeth.smith@example.com', 'Elizabeth', 'Smith', 1, 'she/her', 'heyElizabeth123'),
  ('ianlennox', 'ian.lennox@example.com', 'Ian', 'Lennox', 2, 'he/him', 'heyIan123'),
  ('evabradley', 'eva.bradley@example.com', 'Eva', 'Bradley', 1, 'she/her', 'heyEva123'),
  ('francescoantoni', 'francesco.antoni@example.com', 'Francesco', 'Antoni', 2, 'he/him', 'heyFrancesco123'),
  ('celinebrown', 'celine.brown@example.com', 'Celine', 'Brown', 1, 'she/her', 'heyCeline123'),
  ('georgiamills', 'georgia.mills@example.com', 'Georgia', 'Mills', 1, 'she/her', 'heyGeorgia123'),
  ('antoineclark', 'antoine.clark@example.com', 'Antoine', 'Clark', 2, 'he/him', 'heyAntoine123'),
  ('valentinwebb', 'valentin.webb@example.com', 'Valentin', 'Webb', 2, 'he/him', 'heyValentin123'),
  ('oliviamorales', 'olivia.morales@example.com', 'Olivia', 'Morales', 1, 'she/her', 'heyOlivia123'),
  ('mathieuhebert', 'mathieu.hebert@example.com', 'Mathieu', 'Hebert', 2, 'he/him', 'heyMathieu123'),
  ('rosepatel', 'rose.patel@example.com', 'Rose', 'Patel', 1, 'she/her', 'heyRose123'),
  ('travisrichards', 'travis.richards@example.com', 'Travis', 'Richards', 2, 'he/him', 'heyTravis123'),
  ('josefinklein', 'josefinklein@example.com', 'Josefin', 'Klein', 1, 'she/her', 'heyJosefin123'),
  ('finnandersen', 'finn.andersen@example.com', 'Finn', 'Andersen', 2, 'he/him', 'heyFinn123'),
  ('sofiaparker', 'sofia.parker@example.com', 'Sofia', 'Parker', 1, 'she/her', 'heySofia123'),
  ('theogibson', 'theo.gibson@example.com', 'Theo', 'Gibson', 2, 'he/him', 'heyTheo123')
;

-- Add OPH teams
INSERT INTO league_management.teams
  (team_id, slug, name, description)
VALUES
  (1, 'significant-otters', 'Significant Otters', null),
  (2, 'otterwa-senators', 'Otterwa Senators', null),
  (3, 'otter-chaos', 'Otter Chaos', null),
  (4, 'otter-nonsense', 'Otter Nonsense', null),
  (5, 'frostbiters', 'Frostbiters', 'An icy team known for their chilling defense.'),
  (6, 'blazing-blizzards', 'Blazing Blizzards', 'A team that combines fiery offense with frosty precision.'),
  (7, 'polar-puckers', 'Polar Puckers', 'Masters of the north, specializing in swift plays.'),
  (8, 'arctic-avengers', 'Arctic Avengers', 'A cold-blooded team with a knack for thrilling comebacks.'),
  (9, 'glacial-guardians', 'Glacial Guardians', 'Defensive titans who freeze their opponents in their tracks.'),
  (10, 'tundra-titans', 'Tundra Titans', 'A powerhouse team dominating the ice with strength and speed.'),
  (11, 'permafrost-predators', 'Permafrost Predators', 'Known for their unrelenting pressure and icy precision.'),
  (12, 'snowstorm-scorchers', 'Snowstorm Scorchers', 'A team with a fiery spirit and unstoppable energy.'),
  (13, 'frozen-flames', 'Frozen Flames', 'Bringing the heat to the ice with blazing fast attacks.'),
  (14, 'chill-crushers', 'Chill Crushers', 'Breaking the ice with powerful plays and intense rivalries.')
;

-- Add captains to OPH teams
INSERT INTO league_management.team_memberships
  (user_id, team_id, team_role_id)
VALUES
  (6, 1, 4), -- Stephen
  (7, 1, 5), -- Levi
  (10, 2, 4), -- Jayce
  (3, 2, 5), -- Aida
  (8, 3, 4), -- Cheryl
  (11, 3, 5), -- Britt
  (9, 4, 4), -- Mason
  (5, 4, 5)  -- Kat
;

-- Add sample players to OPH teams as players
INSERT INTO league_management.team_memberships
  (user_id, team_id)
VALUES
  (15, 1),
  (16, 1),
  (17, 1),
  (18, 1),
  (19, 1),
  (20, 1),
  (21, 1),
  (22, 1),
  (23, 1),
  (24, 1),
  (25, 1),
  (26, 1),
  (27, 2),
  (28, 2),
  (29, 2),
  (30, 2),
  (31, 2),
  (32, 2),
  (33, 2),
  (34, 2),
  (35, 2),
  (36, 2),
  (37, 2),
  (38, 2),
  (39, 3),
  (40, 3),
  (41, 3),
  (42, 3),
  (43, 3),
  (44, 3),
  (45, 3),
  (46, 3),
  (47, 3),
  (48, 3),
  (49, 3),
  (50, 3),
  (51, 4),
  (52, 4),
  (53, 4),
  (54, 4),
  (55, 4),
  (56, 4),
  (57, 4),
  (58, 4),
  (59, 4),
  (60, 4),
  (61, 4),
  (62, 4)
;

-- Add captains to Hometown Hockey
INSERT INTO league_management.team_memberships
  (user_id, team_id, team_role_id)
VALUES
  (1, 5, 4), -- Adam
  (12, 6, 4), -- Zach
  (13, 7, 4), -- Andrew
  (4, 8, 4), -- Caleb
  (14, 9, 4) -- Tim
;

INSERT INTO league_management.team_memberships
  (user_id, team_id)
VALUES
  (60, 5),
  (61, 5),
  (62, 5),
  (63, 5),
  (64, 5),
  (65, 5),
  (66, 5),
  (67, 5),
  (68, 5),
  (69, 5),
  (70, 6),
  (71, 6),
  (72, 6),
  (73, 6),
  (74, 6),
  (75, 6),
  (76, 6),
  (77, 6),
  (78, 6),
  (79, 6),
  (80, 7),
  (81, 7),
  (82, 7),
  (83, 7),
  (84, 7),
  (85, 7),
  (86, 7),
  (87, 7),
  (88, 7),
  (89, 7),
  (90, 8),
  (91, 8),
  (92, 8),
  (93, 8),
  (94, 8),
  (95, 8),
  (96, 8),
  (97, 8),
  (98, 8),
  (99, 8),
  (100, 9),
  (101, 9),
  (102, 9),
  (103, 9),
  (104, 9),
  (105, 9),
  (106, 9),
  (107, 9),
  (108, 9),
  (109, 9)
;

-- Default leagues
INSERT INTO league_management.leagues
  (slug, name, sport_id)
VALUES 
  ('ottawa-pride-hockey', 'Ottawa Pride Hockey', 1),
  ('fia-hockey', 'FIA Hockey', 1),
  ('hometown-hockey', 'Hometown Hockey', 1)
;

-- Default league_admins
INSERT INTO league_management.league_admins
  (league_role_id, league_id, user_id)
VALUES 
  (1, 1, 5), -- Kat
  (1, 1, 10), -- Jayce
  (1, 1, 11), -- Britt
  (1, 2, 4), -- Caleb
  (1, 3, 1) -- Adam
;

-- Default seasons
INSERT INTO league_management.seasons
  (slug, name, league_id, start_date, end_date)
VALUES
  ('winter-2024-2025', 'Winter 2024/2025', 1, '2024-09-01', '2025-03-31'),
  ('2023-2024-season', '2023-2024 Season', 2, '2023-09-01', '2024-03-31'),
  ('2024-2025-season', '2024-2025 Season', 2, '2024-09-01', '2025-03-31'),
  ('2024-2025-season', '2024-2025 Season', 3, '2024-09-01', '2025-03-31')
;

-- Default season_admins
INSERT INTO league_management.season_admins
  (season_role_id, season_id, user_id)
VALUES
  (1, 3, 1),
  (1, 4, 3)
;

-- Default divisions
INSERT INTO league_management.divisions
  (slug, name, tier, season_id, gender)
VALUES
  ('div-inc', 'Div Inc', 1, 1, 'Co-ed'),
  ('div-1', 'Div 1', 1, 3, 'Co-ed'),
  ('div-2', 'Div 2', 1, 3, 'Co-ed'),
  ('div-1', 'Div 1', 1, 4, 'Co-ed'),
  ('div-2', 'Div 2', 2, 4, 'Co-ed'),
  ('div-3', 'Div 3', 3, 4, 'Co-ed'),
  ('div-4', 'Div 4', 4, 4, 'Co-ed'),
  ('div-5', 'Div 5', 5, 4, 'Co-ed'),
  ('men-35', 'Men 35+', 6, 4, 'Men'),
  ('women-35', 'Women 35+', 6, 4, 'Women')
;

-- Default division_teams
INSERT INTO league_management.division_teams
  (division_id, team_id)
VALUES
  (1, 1),
  (1, 2),
  (1, 3),
  (1, 4),
  (4, 5),
  (4, 6),
  (4, 7),
  (4, 8),
  (4, 9)
;

-- Default list of venues
INSERT INTO league_management.venues
  (venue_id, slug, name, description, address)
VALUES
  (1, 'canadian-tire-centre', 'Canadian Tire Centre', 'Home of the NHL''s Ottawa Senators, this state-of-the-art entertainment facility seats 19,153 spectators.', '1000 Palladium Dr, Ottawa, ON K2V 1A5'),
  (2, 'bell-sensplex', 'Bell Sensplex', 'A multi-purpose sports facility featuring four NHL-sized ice rinks, including an Olympic-sized rink, operated by Capital Sports Management.', '1565 Maple Grove Rd, Ottawa, ON K2V 1A3'),
  (3, 'td-place-arena', 'TD Place Arena', 'An indoor arena located at Lansdowne Park, hosting the Ottawa 67''s (OHL) and Ottawa Blackjacks (CEBL), with a seating capacity of up to 8,585.', '1015 Bank St, Ottawa, ON K1S 3W7'),
  (4, 'minto-sports-complex-arena', 'Minto Sports Complex Arena', 'Part of the University of Ottawa, this complex contains two ice rinks, one with seating for 840 spectators, and the Draft Pub overlooking the ice.', '801 King Edward Ave, Ottawa, ON K1N 6N5'),
  (5, 'carleton-university-ice-house', 'Carleton University Ice House', 'A leading indoor skating facility featuring two NHL-sized ice surfaces, home to the Carleton Ravens hockey teams.', '1125 Colonel By Dr, Ottawa, ON K1S 5B6'),
  (6, 'howard-darwin-centennial-arena', 'Howard Darwin Centennial Arena', 'A community arena offering ice rentals and public skating programs, managed by the City of Ottawa.', '1765 Merivale Rd, Ottawa, ON K2G 1E1'),
  (7, 'fred-barrett-arena', 'Fred Barrett Arena', 'A municipal arena providing ice rentals and public skating, located in the southern part of Ottawa.', '3280 Leitrim Rd, Ottawa, ON K1T 3Z4'),
  (8, 'blackburn-arena', 'Blackburn Arena', 'A community arena offering skating programs and ice rentals, serving the Blackburn Hamlet area.', '200 Glen Park Dr, Gloucester, ON K1B 5A3'),
  (9, 'bob-macquarrie-recreation-complex-orlans-arena', 'Bob MacQuarrie Recreation Complex – Orléans Arena', 'A recreation complex featuring an arena, pool, and fitness facilities, serving the Orléans community.', '1490 Youville Dr, Orléans, ON K1C 2X8'),
  (10, 'brewer-arena', 'Brewer Arena', 'A municipal arena adjacent to Brewer Park, offering public skating and ice rentals.', '200 Hopewell Ave, Ottawa, ON K1S 2Z5')
;

-- Default venue arenas
INSERT INTO league_management.arenas
  (arena_id, slug, name, venue_id)
VALUES
  (1, 'arena', 'Arena', 1),
  (2, '1', '1', 2),
  (3, '2', '2', 2),
  (4, '3', '3', 2),
  (5, '4', '4', 2),
  (6, 'arena', 'Arena', 3),
  (7, 'a', 'A', 4),
  (8, 'b', 'B', 4),
  (9, 'a', 'A', 5),
  (10, 'b', 'B', 5),
  (11, 'arena', 'Arena', 6),
  (12, 'a', 'A', 7),
  (13, 'b', 'B', 7),
  (14, 'arena', 'Arena', 8),
  (15, 'a', 'A', 9),
  (16, 'b', 'B', 9),
  (17, 'arena', 'Arena', 10)
;

-- List of OPH games
INSERT INTO league_management.games
  (home_team_id, away_team_id, division_id, date_time, arena_id)
VALUES
  (1, 4, 1, '2024-09-08 17:45:00', 10),
  (2, 3, 1, '2024-09-08 18:45:00', 10),
  (3, 1, 1, '2024-09-16 22:00:00', 9),
  (4, 2, 1, '2024-09-16 23:00:00', 9),
  (1, 2, 1, '2024-09-25 21:00:00', 9),
  (3, 4, 1, '2024-09-25 22:00:00', 9),
  (1, 4, 1, '2024-10-03 19:30:00', 10),
  (2, 3, 1, '2024-10-03 20:30:00', 10),
  (3, 1, 1, '2024-10-14 19:00:00', 9),
  (4, 2, 1, '2024-10-14 20:00:00', 9),
  (1, 4, 1, '2024-10-19 20:00:00', 9),
  (2, 3, 1, '2024-10-19 21:00:00', 9),
  (1, 2, 1, '2024-10-30 21:30:00', 10),
  (3, 4, 1, '2024-10-30 22:30:00', 10),
  (1, 4, 1, '2024-11-08 20:30:00', 10),
  (2, 3, 1, '2024-11-08 21:30:00', 10),
  (3, 1, 1, '2024-11-18 20:00:00', 9),
  (4, 2, 1, '2024-11-18 21:00:00', 9),
  (1, 2, 1, '2024-11-27 18:30:00', 10),
  (3, 4, 1, '2024-11-27 19:30:00', 10),
  (1, 4, 1, '2024-12-05 20:30:00', 10),
  (2, 3, 1, '2024-12-05 21:30:00', 10),
  (3, 1, 1, '2024-12-14 18:00:00', 9),
  (4, 2, 1, '2024-12-14 19:00:00', 9),
  (1, 2, 1, '2024-12-23 19:00:00', 9),
  (3, 4, 1, '2024-12-23 20:00:00', 9),
  (3, 4, 1, '2025-01-23 20:00:00', 9),
  (1, 2, 1, '2025-01-23 19:00:00', 9),
  (4, 2, 1, '2025-01-11 20:45:00', 10),
  (3, 1, 1, '2025-01-11 19:45:00', 10),
  (2, 3, 1, '2025-01-02 21:30:00', 10),
  (1, 4, 1, '2025-01-02 20:30:00', 10)
;

-- GOALS
INSERT INTO stats.goals
  (game_id, user_id, team_id, period, period_time)
VALUES
  (2, 3, 2, 1, '05:27'),
  (2, 10, 2, 1, '15:33'),
  (2, 11, 3, 2, '03:19'),
  (2, 3, 2, 2, '18:27')
;

-- Assists
INSERT INTO stats.assists
  (game_id, goal_id, user_id, team_id, primary_assist)
VALUES
  (2, 1, 29, 2, 'true'),
  (2, 1, 3, 2, 'false'),
  (2, 2, 10, 2, 'true'),
  (2, 3, 48, 3, 'true')
;

--  user_id |      player      |       team       |       role        
-- ---------+------------------+------------------+-------------------
--       32 | Eline Fransen    | Otterwa Senators | Player
--       29 | Adrian Garcia    | Otterwa Senators | Player
--       37 | Marta Kalinski   | Otterwa Senators | Player
--       33 | Andrea Kovacs    | Otterwa Senators | Player
--       10 | Jayce LeClaire   | Otterwa Senators | Captain
--       30 | Amelia LeRoux    | Otterwa Senators | Player
--       38 | Tomas Marquez    | Otterwa Senators | Player
--       27 | Sebastien Martin | Otterwa Senators | Player
--       35 | Janina Nowak     | Otterwa Senators | Player
--       36 | Niklas Petersen  | Otterwa Senators | Player
--        3 | Aida Robillard   | Otterwa Senators | Alternate Captain
--       31 | Kasper Skov      | Otterwa Senators | Player
--       34 | Peter Smith      | Otterwa Senators | Player
--       28 | Elisa Volkova    | Otterwa Senators | Player

--  user_id |        player        |    team     |       role        
-- ---------+----------------------+-------------+-------------------
--       40 | Maximilian Bauer     | Otter Chaos | Player
--       46 | Pietro Capello       | Otter Chaos | Player
--       45 | Noemie Caron         | Otter Chaos | Player
--        8 | Cheryl Chaos         | Otter Chaos | Captain
--       43 | Sofia Costa          | Otter Chaos | Player
--       47 | Elisabeth Jensen     | Otter Chaos | Player
--       50 | Valerie Keller       | Otter Chaos | Player
--       11 | Britt Neron          | Otter Chaos | Alternate Captain
--       48 | Dimitri Papadopoulos | Otter Chaos | Player
--       49 | Mariela Ramos        | Otter Chaos | Player
--       44 | Alexander Ricci      | Otter Chaos | Player
--       41 | Anna Schaefer        | Otter Chaos | Player
--       39 | Irene Schneider      | Otter Chaos | Player
--       42 | Lucas Vargas         | Otter Chaos | Player