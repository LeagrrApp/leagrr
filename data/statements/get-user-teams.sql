SELECT
	t.slug,
	t.name
FROM
	league_management.teams AS t
JOIN
	league_management.team_memberships as m
ON
	m.team_id = t.team_id
WHERE
	m.user_id = 1
ORDER BY
	t.name ASC;