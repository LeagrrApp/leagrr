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