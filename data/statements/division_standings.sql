SELECT
      t.team_id,
      t.name,
      t.slug,
      t.status,
      (
        SELECT
          COUNT(*)
        FROM
          league_management.games
        WHERE
          (
            (home_team_id = t.team_id)
            OR
            (away_team_id = t.team_id)
          )
          AND
          division_id = $1
          AND
          status = 'completed'
      )::int AS games_played,
      (
        SELECT
          COUNT(*)
        FROM
          league_management.games
        WHERE
          (
            (home_team_id = t.team_id AND home_team_score > away_team_score)
            OR
            (away_team_id = t.team_id AND away_team_score > home_team_score)
          )
          AND
          division_id = $1
          AND
          status = 'completed'
      )::int AS wins,
      (
        SELECT
          COUNT(*)
        FROM
          league_management.games
        WHERE
          (
            (home_team_id = t.team_id AND home_team_score < away_team_score)
            OR
            (away_team_id = t.team_id AND away_team_score < home_team_score)
          )
          AND
          division_id = $1
          AND
          status = 'completed'
      )::int AS losses,
      (
        SELECT
          COUNT(*)
        FROM
          league_management.games
        WHERE
          (
            home_team_id = t.team_id
            OR
            away_team_id = t.team_id
          )
          AND
            away_team_score = home_team_score
          AND
            division_id = $1
          AND
            status = 'completed'
      )::int AS ties,
      (
        (
          SELECT
            COUNT(*)
          FROM
            league_management.games
          WHERE
            (
              (home_team_id = t.team_id AND home_team_score > away_team_score)
              OR
              (away_team_id = t.team_id AND away_team_score > home_team_score)
            )
            AND
            division_id = $1
            AND
            status = 'completed'
        ) * 2
        +
        (
          SELECT
            COUNT(*)
          FROM
            league_management.games
          WHERE
            (
              home_team_id = t.team_id
              OR
              away_team_id = t.team_id
            )
            AND
              away_team_score = home_team_score
            AND
              division_id = $1
            AND
              status = 'completed'
        )
      )::int AS points,
      (
        (
          SELECT
            COALESCE(SUM(home_team_score), 0)
          FROM
            league_management.games
          WHERE
            home_team_id = t.team_id
            AND
            division_id = $1
            AND
            status = 'completed'
        ) + (
          SELECT
            COALESCE(SUM(away_team_score), 0)
          FROM
            league_management.games
          WHERE
            away_team_id = t.team_id
            AND
            division_id = $1
            AND
            status = 'completed'
        )
      )::int AS goals_for,
      (
        (
          SELECT
            COALESCE(SUM(away_team_score), 0)
          FROM
            league_management.games
          WHERE
            home_team_id = t.team_id
            AND
            division_id = $1
            AND
            status = 'completed'
        ) + (
          SELECT
            COALESCE(SUM(home_team_score), 0)
          FROM
            league_management.games
          WHERE
            away_team_id = t.team_id
            AND
            division_id = $1
            AND
            status = 'completed'
        )
      )::int AS goals_against
    FROM
      division_teams as dt
    JOIN
      teams as t
    ON
      t.team_id = dt.team_id
    WHERE
      dt.division_id = $1
    ORDER BY points DESC, games_played ASC, wins DESC, goals_for DESC, goals_against ASC