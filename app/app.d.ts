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
  color?: string;
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

type QuickTeam = Pick<TeamData, "team_id" | "name">;

type TeamRosterItem = {
  team_id: number;
  user_id: number;
  first_name: string;
  last_name: string;
  position: string;
};

type LeagueData = {
  league_id: number;
  slug: string;
  name: string;
  description?: string;
  sport: string;
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
  division_id: number;
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
  date_time: Date | string;
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
  has_been_published: boolean;
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
};

type StatsData = {
  type: string;
  item_id: number;
  user_id: number;
  username: string;
  user_last_name: string;
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
};

type StatLeaderBoardItem = {
  team: string;
  first_name: string;
  last_name: string;
  username: string;
  count: number;
};

// type ShotStatData = BaseStatsData & {
//   shot_id: number;
// };

// type GoalStatData = BaseStatsData & {
//   goal_id: number;
//   shorthanded: boolean;
//   power_play: boolean;
//   empty_net: boolean;
//   assists?: AssistStatData[];
// };

// type AssistStatData = Omit<BaseStatsData, "period" | "period_time"> & {
//   assist_id: number;
//   goal_id: number;
//   primary_assist: boolean;
// };

// type SaveStatData = BaseStatsData & {
//   save_id: number;
//   penalty_kill: boolean;
//   rebound: boolean;
// };

// type PenaltyStatData = BaseStatsData & {
//   penalty_id: number;
//   infraction: string;
//   minutes: number;
// };

// type GameFeedItemData = BaseStatsData &
//   Partial<ShotStatData> &
//   Partial<GoalStatData> &
//   Partial<SaveStatData> &
//   Partial<PenaltyStatData>;

type AdminRole = {
  league_role_id: number | undefined;
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
