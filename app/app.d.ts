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

type TeamData = {
  team_id: number;
  slug: string;
  name: string;
  description?: string;
  join_code?: string;
  status?: string;
};

type TeamStandingsData = Pick<
  TeamData,
  "team_id" | "slug" | "name" | "status"
> & {
  games_played: number;
  wins: number;
  losses: number;
  ties: number;
  points: number;
  goals_for: number;
  goals_against: number;
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
  league_id: number;
  start_date?: Date | string;
  end_date?: Date | string;
  status?: string;
  divisions?: DivisionData[];
  league_slug?: string;
};

type DivisionData = {
  division_id: string;
  name: string;
  description?: string;
  slug: string;
  gender?: string;
  tier?: number;
  join_code?: string;
  status?: string;
  season_slug: string;
  season_id: number;
  league_slug: string;
  league_id: number;
  teams?: TeamStandingsData[];
  games?: GameData[];
};

type DivisionPreview = Required<
  Pick<
    DivisionData,
    "division_id" | "name" | "slug" | "gender" | "tier" | "status"
  >
>;

type GameData = {
  game_id: number;
  home_team_id: number;
  home_team: string;
  home_team_score: number;
  away_team_id: number;
  away_team: string;
  away_team_score: number;
  division_id: number;
  playoff_id?: number;
  date_time: Date | string;
  arena_id: number;
  status:
    | "draft"
    | "public"
    | "completed"
    | "cancelled"
    | "postponed"
    | "archived";
  arena: string;
  arena_id: number;
  venue: string;
};

type AdminRole = {
  league_role_id: number | undefined;
};

type MenuItemData = {
  slug: string;
  name: string;
  img?: string;
};
