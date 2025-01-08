-- Get list of league admins
SELECT
  u.first_name,
  u.last_name,
  l.name as league,
  r.name as role
FROM
  league_admins as a
JOIN
  leagues as l
ON
  l.league_id = a.league_id
JOIN
  users as u
ON
  u.user_id = a.user_id
JOIN
  league_roles as r
ON
  r.league_role_id = a.league_role_id;

-- Get seasons
SELECT
  CONCAT(s.name, ' (', l.name, ')') as season,
  s.description as description,
  s.start_date,
  s.end_date
FROM
  seasons as s
JOIN
  leagues as l
ON
  l.league_id = s.league_id
WHERE
  s.end_date > CURRENT_DATE;

-- Get list of season admins
SELECT
  u.first_name,
  u.last_name,
  CONCAT(s.name, ' (', l.name, ')') as season,
  r.name as role
FROM
  season_admins as a
JOIN
  seasons as s
ON
  s.season_id = a.season_id
JOIN
  users as u
ON
  u.user_id = a.user_id
JOIN
  season_roles as r
ON
  r.season_role_id = a.season_role_id
JOIN
  leagues as l
ON
  l.league_id = s.league_id;

-- Get Season's divisions
SELECT
  d.name as division,
  d.tier as tier,
  s.name as season,
  l.name as league
FROM
  divisions as d
JOIN
  seasons as s
ON
  s.season_id = d.season_id
JOIN
  leagues as l
ON
  l.league_id = s.league_id
WHERE
  s.season_id = 4
ORDER BY
  d.tier ASC;

-- Select members of a team, show their role
SELECT
  u.user_id,
  CONCAT(u.first_name, ' ', u.last_name) as player,
  t.name as team,
  tr.name as role
FROM
  admin.users as u
JOIN
  league_management.team_memberships as tm
ON
  u.user_id = tm.user_id
JOIN
  league_management.teams as t
ON
  t.team_id = tm.team_id
JOIN
  admin.team_roles as tr
ON
  tr.team_role_id = tm.team_role_id
WHERE
  t.name = 'Otter Chaos'
ORDER BY
  u.last_name
;

-- Select teams by division, show team captain
SELECT
  t.name as team,
  l.name as league,
  s.name as season,
  d.name as division,
  CONCAT(u.first_name, ' ', u.last_name) as captain,
  u.email as contact
FROM
  league_management.teams as t
JOIN
  league_management.division_teams as dt
ON
  t.team_id = dt.team_id
JOIN
  league_management.divisions as d
ON
  d.division_id = dt.division_id
JOIN
  league_management.team_memberships as tm
ON
  t.team_id = tm.team_id
JOIN 
  admin.users as u
ON
  u.user_id = tm.user_id
JOIN 
  league_management.seasons as s
ON
  s.season_id = d.season_id
JOIN 
  league_management.leagues as l
ON
  l.league_id = s.league_id
WHERE
  tm.team_role_id = 4 AND l.name = 'Hometown Hockey';

-- Get all upcoming games by division, get team contact emails, display venue and arena
SELECT
  g.date_time,
  (SELECT name FROM teams WHERE team_id = g.home_team_id) as home_team,
  (SELECT name FROM teams WHERE team_id = g.away_team_id) as away_team,
  concat(v.name, ' - ', a.name) as location
FROM
  league_management.games as g
JOIN
  league_management.arenas as a
ON
  a.arena_id = g.arena_id
JOIN
  league_management.venues as v
ON
  a.venue_id = v.venue_id
WHERE g.date_time > CURRENT_DATE
ORDER BY g.date_time DESC;

-- Game Score
SELECT
  g.date_time,
  (SELECT name FROM teams WHERE team_id = g.home_team_id) as home_team,
  (SELECT COUNT(goal_id) FROM stats.goals WHERE game_id = g.game_id AND team_id = g.home_team_id) as home_score,
  (SELECT name FROM teams WHERE team_id = g.away_team_id) as away_team,
  (SELECT COUNT(goal_id) FROM stats.goals WHERE game_id = g.game_id AND team_id = g.away_team_id) as away_score
FROM
  league_management.games as g
WHERE
  g.game_id = 2;

-- Game Stats by team
SELECT
  team.name as team,
  CONCAT(player.first_name, ' ', player.last_name) AS player,
  (SELECT COUNT(*) FROM stats.goals WHERE user_id = player.user_id AND game_id = game.game_id AND team_id = game.home_team_id) as goals,
  (SELECT COUNT(*) FROM stats.assists WHERE user_id = player.user_id AND game_id = game.game_id AND team_id = game.home_team_id) as assists
FROM
  league_management.games as game
JOIN
  league_management.teams as team
ON
  game.home_team_id = team.team_id
JOIN
  league_management.team_memberships as tm
ON
  tm.team_id = team.team_id
JOIN
  admin.users as player
ON
  tm.user_id = player.user_id
WHERE
  game.game_id = 2
ORDER BY
  goals DESC, assists DESC
;
