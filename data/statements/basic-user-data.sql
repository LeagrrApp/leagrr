select
	u.user_id,
	u.username,
	u.email,
	u.first_name,
	u.last_name,
	u.user_role,
	(
		select
			name
		from
			admin.user_roles as r
		where
			r.user_role_id = u.user_role
	) as role,
	(
		select
			name
		from
			admin.genders as g
		where
			g.gender_id = u.gender_id
	) as gender
from
	admin.users as u
order by
	user_id asc