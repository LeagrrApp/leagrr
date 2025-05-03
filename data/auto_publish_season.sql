CREATE OR REPLACE FUNCTION auto_publish_season()
RETURNS TRIGGER AS $$
BEGIN

	IF
		NEW.status <> OLD.status AND NEW.status = 'public'
	THEN

		-- update all seasons with a league_id that matches changed league
	    UPDATE league_management.seasons
		SET
			status = NEW.status
		WHERE
			season_id = NEW.season_id;
	
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER publish_division
    BEFORE UPDATE OF status ON league_management.divisions
	FOR EACH ROW
	EXECUTE FUNCTION auto_publish_season();