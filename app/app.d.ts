type ResultProps<T> = {
  message: string;
  status: number;
  data?: T;
};

type UserData = {
  user_id: number;
  username: string;
  email: string;
  first_name: string;
  last_name: string;
  gender: string;
  pronouns: string;
  user_role: number;
  img: string;
  status: "active" | "inactive" | "suspended" | "banned";
};

type UserSessionData = Required<
  Pick<
    UserData,
    "user_id" | "user_role" | "username" | "first_name" | "last_name" | "img"
  >
> & {
  time_zone: string;
};

type UserRosterData = {
  division_roster_id: number;
  team_id: number;
  team_name: string;
  team_slug: string;
  team_color: string;
  division_name: string;
  division_id: number;
  division_slug: string;
  season_name: string;
  season_id: number;
  season_slug: string;
  league_name: string;
  league_id: number;
  league_slug: string;
};

type UserRosterStats = Omit<
  PlayerStats,
  "user_id" | "username" | "first_name" | "last_name"
>;

type TeamData = {
  team_id: number;
  slug: string;
  name: string;
  description?: string;
  status?: "active" | "inactive" | "suspended" | "banned";
  color?: string;
  join_code?: string;
};

type TeamPageData = TeamData & {
  members: Omit<UserData, "password_hash">[];
};

type TeamDivisionsData = {
  division: string;
  division_id: number;
  division_slug: string;
  season: string;
  season_slug: string;
  start_date: Date;
  end_date: Date;
  league: string;
  league_slug: string;
};

type DivisionTeamData = Pick<
  TeamData,
  "team_id" | "slug" | "name" | "status" | "color"
> & {
  division_team_id: number;
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
  position?: number;
};

type QuickTeam = Pick<TeamData, "team_id" | "name">;

type TeamUserData = Required<
  Pick<
    UserData,
    | "user_id"
    | "first_name"
    | "last_name"
    | "username"
    | "email"
    | "pronouns"
    | "gender"
  >
> & {
  number?: number;
  position?: string;
  roster_role?: number;
  team_membership_id?: number;
  division_team_id?: number;
  division_roster_id?: number;
  joined?: Date;
  team_role?: number;
};

type TeamRosterItem = {
  team_id: number;
  user_id: number;
  first_name: string;
  last_name: string;
  position: string;
};

type LeagueStatus = "draft" | "public" | "archived" | "locked";

type LeagueData = {
  league_id: number;
  slug: string;
  name: string;
  description?: string;
  sport: "hockey" | "soccer" | "basketball" | "pickleball" | "badminton";
  status: LeagueStatus;
  seasons?: SeasonData[];
};

type SeasonData = {
  season_id: number;
  slug: string;
  name: string;
  description?: string;
  start_date?: Date | string;
  end_date?: Date | string;
  status: LeagueStatus;
  divisions?: DivisionData[];
  league_id: number;
  league_slug?: string;
  league: string;
};

type DivisionData = {
  division_id: number;
  name: string;
  description?: string;
  slug: string;
  gender: string;
  tier: number;
  join_code: string;
  status: LeagueStatus;
  season_slug: string;
  season_id: number;
  season_name?: string;
  league_slug: string;
  league_id: number;
  league_name?: string;
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
  home_team_slug: string;
  home_team_color: string;
  home_team_score: number;
  home_team_shots: number;
  away_team_id: number;
  away_team: string;
  away_team_slug: string;
  away_team_color: string;
  away_team_score: number;
  away_team_shots: number;
  division_id: number;
  playoff_id?: number;
  date_time: Date;
  arena_id: number;
  arena: string;
  venue: string;
  status:
    | "draft"
    | "public"
    | "completed"
    | "cancelled"
    | "postponed"
    | "archived";
  has_been_published?: boolean;
};

type AddGameData = {
  teams: QuickTeam[];
  locations: LocationData[];
};

type PlayerStats = {
  user_id: number;
  username: string;
  first_name: string;
  last_name: string;
  number?: number;
  position?: string;
  goals: number;
  assists: number;
  points: number;
  shots: number;
  saves: number;
  penalties_in_minutes: number;
  shots_against: number;
  goals_against: number;
};

type StatsData = {
  type: string;
  item_id: number;
  user_id: number;
  username: string;
  first_name: string;
  last_name: string;
  team_id: number;
  team: string;
  period: number;
  period_time: {
    minutes: number;
    seconds: number;
  };
  shorthanded?: boolean;
  power_play?: boolean;
  empty_net?: boolean;
  assists?: AssistStatData[];
  goal_id?: number;
  primary_assist?: boolean;
  penalty_kill?: boolean;
  rebound?: boolean;
  infraction?: string;
  minutes?: number;
  coordinates?: string;
};

type StatLeaderBoardItem = {
  team: string;
  first_name: string;
  last_name: string;
  username: string;
  count: number;
};

type RoleData = {
  role: number;
  title: string;
};

type LeagueAdminData = {
  league_admin_id: number;
  league_role: number;
  user_id: number;
  username: string;
  first_name: string;
  last_name: string;
};

type MenuItemData = {
  slug: string;
  name: string;
  img?: string;
};

type LocationData = {
  venue_slug: string;
  venue: string;
  arena: string;
  arena_id: number;
};

type LeagueVenueData = {
  league_venue_id: number;
  venue_id: number;
  venue: string;
  address: string;
  arenas: string;
};

type RinkItem = {
  icon: string;
  coordinates: string;
  color: string;
  item_id?: number;
  type?: string;
};
