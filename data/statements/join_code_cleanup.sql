CREATE OR REPLACE FUNCTION join_code_cleanup()
RETURNS TRIGGER AS $$
DECLARE
    base_join_code TEXT;
    temp_join_code TEXT;
    final_join_code TEXT;
    join_code_rank INT;
    exact_match INT;
BEGIN
	IF NEW.join_code <> OLD.join_code THEN
	    -- Clean up original join_code
	    base_join_code := lower(
	                      regexp_replace(
	                          regexp_replace(
	                              regexp_replace(NEW.join_code, '\s+', '-', 'g'),
	                              '[^a-zA-Z0-9\-]', '', 'g'
	                          ),
	                      '-+', '-', 'g')
	                  );
	
	    -- Check if this join_code already exists and if so, append a number to ensure uniqueness
	
		-- this SELECT checks if there are other EXACT join_code matches
	    SELECT COUNT(*) INTO exact_match
	    FROM league_management.teams
	    WHERE join_code = base_join_code;
	
	    IF exact_match = 0 THEN
	        -- No duplicates found, assign base join_code
	        final_join_code := base_join_code;
	    ELSE
			-- this SELECT checks if there are teams with join_codes starting with the base_join_code
		    SELECT COUNT(*) INTO join_code_rank
		    FROM league_management.teams
		    WHERE join_code LIKE base_join_code || '%';
			
	        -- Duplicates found, append the count as a suffix
	        temp_join_code := base_join_code || '-' || join_code_rank;
			
			-- check if exact match of temp_join_code found
			SELECT COUNT(*) INTO exact_match
		    FROM league_management.teams
		    WHERE join_code = temp_join_code;
	
			IF exact_match = 1 THEN
				-- increase join_code_rank by 1 and create final join_code
				final_join_code := base_join_code || '-' || (join_code_rank + 1);
			ELSE
				-- change temp join_code to final join_code
				final_join_code = temp_join_code;
			END IF;
	    END IF;
	
	    -- Assign the final join_code to the new record
	    NEW.join_code := final_join_code;

	END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_teams_join_code
    BEFORE UPDATE OF join_code ON league_management.teams
	FOR EACH ROW
	EXECUTE FUNCTION join_code_cleanup();