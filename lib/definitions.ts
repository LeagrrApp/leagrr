import { convertRolesToChoices } from "@/utils/helpers/formatting";

export const sports_options: readonly [string, ...string[]] = [
  "hockey",
  "soccer",
  "basketball",
  "pickleball",
  "badminton",
];

export const status_options: readonly [string, ...string[]] = [
  "draft",
  "public",
  "archived",
];

export const user_status_options: readonly [string, ...string[]] = [
  "active",
  "inactive",
  "suspended",
  "banned",
];

export const game_status_options: readonly [string, ...string[]] = [
  "draft",
  "public",
  "archived",
  "completed",
  "cancelled",
  "postponed",
];

export const team_status_options: readonly [string, ...string[]] = [
  "active",
  "inactive",
  "suspended",
  "banned",
];

export const gender_options: readonly [string, ...string[]] = [
  "all",
  "men",
  "women",
];

export const color_options: readonly [string, ...string[]] = [
  "black",
  "blue",
  "brown",
  "cyan",
  "green",
  "grey",
  "indigo",
  "magenta",
  "orange",
  "pink",
  "purple",
  "red",
  "violet",
  "white",
  "yellow",
];

export const user_roles = new Map<number, RoleData>();

user_roles.set(1, { role: 1, title: "Admin" });
user_roles.set(2, { role: 2, title: "Commissioner" });
user_roles.set(3, { role: 3, title: "User" });

export const user_roles_options = convertRolesToChoices(user_roles);

export const league_roles = new Map<number, RoleData>();

league_roles.set(1, { role: 1, title: "Commissioner" });
league_roles.set(2, { role: 2, title: "Manager" });

export const league_roles_options = convertRolesToChoices(league_roles);

export const team_roles = new Map<number, RoleData>();

team_roles.set(1, { role: 1, title: "Manager" });
team_roles.set(2, { role: 2, title: "Member" });

export const team_roles_options = convertRolesToChoices(team_roles);

export const roster_roles = new Map<number, RoleData>();

roster_roles.set(1, { role: 1, title: "Coach" });
roster_roles.set(2, { role: 2, title: "Captain" });
roster_roles.set(3, { role: 3, title: "Alternate" });
roster_roles.set(4, { role: 4, title: "Player" });
roster_roles.set(5, { role: 5, title: "Spare" });

export const roster_roles_options = convertRolesToChoices(roster_roles);
