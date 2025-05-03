CREATE OR REPLACE FUNCTION auto_publish_league()
RETURNS TRIGGER AS $$
BEGIN

	IF
		NEW.status <> OLD.status AND NEW.status = 'public'
	THEN

	    UPDATE league_management.leagues
		SET
			status = NEW.status
		WHERE
			league_id = NEW.league_id;
	
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER publish_season
    BEFORE UPDATE OF status ON league_management.seasons
	FOR EACH ROW
	EXECUTE FUNCTION auto_publish_league();