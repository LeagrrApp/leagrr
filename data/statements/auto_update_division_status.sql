CREATE OR REPLACE FUNCTION auto_update_division_status()
RETURNS TRIGGER AS $$
BEGIN

	IF
		NEW.status <> OLD.status AND NEW.status != 'public'
	THEN

		-- update all divisions with a season_id that matches changed season
	    UPDATE league_management.divisions
		SET
			status = NEW.status
		WHERE
			season_id = NEW.season_id;
	
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_seasons_status
    BEFORE UPDATE OF status ON league_management.seasons
	FOR EACH ROW
	EXECUTE FUNCTION auto_update_division_status();