CREATE OR REPLACE FUNCTION generate_season_slug()
RETURNS TRIGGER AS $$
DECLARE
    base_slug TEXT;
    final_slug TEXT;
    slug_rank INT;
BEGIN
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
    SELECT COUNT(*) INTO slug_rank
    FROM league_management.seasons
    WHERE slug LIKE base_slug || '%' AND league_id = NEW.league_id;

    IF slug_rank = 0 THEN
        -- No duplicates found, assign base slug
        final_slug := base_slug;
    ELSE
        -- Duplicates found, append the count as a suffix
        final_slug := base_slug || '-' || slug_rank;
    END IF;

    -- Assign the final slug to the new record
    NEW.slug := final_slug;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER set_seasons_slug
    BEFORE INSERT OR UPDATE ON league_management.seasons
	FOR EACH ROW
	EXECUTE FUNCTION generate_season_slug();