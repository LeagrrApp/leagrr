CREATE OR REPLACE FUNCTION auto_update_season_status()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_leagues_status
    BEFORE UPDATE OF status ON league_management.leagues
	FOR EACH ROW
	EXECUTE FUNCTION auto_update_season_status();