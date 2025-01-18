SELECT
	l.name,
	l.slug,
	a.user_id
FROM
	league_management.league_admins as a
JOIN
	league_management.leagues as l
ON
	l.league_id = a.league_id
WHERE
	a.user_id = 166;