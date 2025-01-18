type ResultProps<T> = {
  message: string;
  status: number;
  data?: T;
};

type UserData = {
  user_id: number;
  first_name?: string;
  last_name?: string;
  username?: string;
  email?: string;
  pronouns?: string;
  user_role: number;
  role_name?: string;
  password_hash?: string;
};

type LeagueData = {
  league_id: number;
  slug: string;
  name: string;
  description?: string;
  sport_id: number;
  sport?: string;
  status: string;
  seasons?: SeasonData[];
  league_role_id?: number;
};

type SeasonData = {
  season_id: number;
  slug: string;
  name?: string;
  description?: string;
  league_id?: number;
  start_date?: Date | string;
  end_date?: Date | string;
  status?: string;
  divisions?: DivisionData[];
  league_slug?: string;
};

type DivisionData = {
  name: string;
  description?: string;
  slug: string;
  gender?: string;
  tier?: number;
  join_code?: string;
  season_id?: number;
  status?: string;
};

type AdminRole = {
  league_role_id: number | undefined;
};

type MenuItemData = {
  slug: string;
  name: string;
  img?: string;
};
