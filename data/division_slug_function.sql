CREATE OR REPLACE FUNCTION generate_division_slug()
RETURNS TRIGGER AS $$
DECLARE
    base_slug TEXT;
    temp_slug TEXT;
    final_slug TEXT;
    slug_rank INT;
    exact_match INT;
BEGIN

	IF NEW.name <> OLD.name OR tg_op = 'INSERT' THEN
	
	    -- Generate the initial slug by processing the name
	    base_slug := lower(
	                      regexp_replace(
	                          regexp_replace(
	                              regexp_replace(NEW.name, '\s+', '-', 'g'),
	                              '[^a-zA-Z0-9\-]', '', 'g'
	                          ),
	                      '-+', '-', 'g')
	                  );
	
	    -- Check if this slug already exists and if so, append a number to ensure uniqueness
	
		-- this SELECT checks if there are other EXACT slug matches
	    SELECT COUNT(*) INTO exact_match
	    FROM league_management.divisions
	    WHERE slug = base_slug AND season_id = NEW.season_id;
	
	    IF exact_match = 0 THEN
	        -- No duplicates found, assign base slug
	        final_slug := base_slug;
	    ELSE
			-- this SELECT checks if there are divisions with slugs starting with the base_slug
		    SELECT COUNT(*) INTO slug_rank
		    FROM league_management.divisions
		    WHERE slug LIKE base_slug || '%' AND season_id = NEW.season_id;
			
	        -- Duplicates found, append the count as a suffix
	        temp_slug := base_slug || '-' || slug_rank;
			
			-- check if exact match of temp_slug found
			SELECT COUNT(*) INTO exact_match
		    FROM league_management.divisions
		    WHERE slug = temp_slug AND season_id = NEW.season_id;
	
			IF exact_match = 1 THEN
				-- increase slug_rank by 1 and create final slug
				final_slug := base_slug || '-' || (slug_rank + 1);
			ELSE
				-- change temp slug to final slug
				final_slug = temp_slug;
			END IF;
	    END IF;
	
	    -- Assign the final slug to the new record
	    NEW.slug := final_slug;
	
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER set_divisions_slug
    BEFORE INSERT ON league_management.divisions
	FOR EACH ROW
	EXECUTE FUNCTION generate_division_slug();

CREATE OR REPLACE TRIGGER update_divisions_slug
    BEFORE UPDATE OF name ON league_management.divisions
	FOR EACH ROW
	EXECUTE FUNCTION generate_division_slug();