CREATE OR REPLACE FUNCTION mark_game_as_published()
RETURNS TRIGGER AS $$
BEGIN

	IF NEW.status <> OLD.status AND NEW.status != 'draft' THEN
		NEW.has_been_published = true;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER insert_game_status_check
    BEFORE INSERT ON league_management.games
	FOR EACH ROW
	EXECUTE FUNCTION mark_game_as_published();

CREATE OR REPLACE TRIGGER update_game_status_check
    BEFORE UPDATE OF status ON league_management.games
	FOR EACH ROW
	EXECUTE FUNCTION mark_game_as_published();

UPDATE league_management.games AS g
SET 
	status = 'completed'
WHERE
	game_id = 31
RETURNING *