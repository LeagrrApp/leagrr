export function capitalize(string: string): string {
  return `${string.substring(0, 1).toUpperCase()}${string.substring(1)}`;
}

export function createDashboardUrl(
  dirs: {
    l?: string;
    s?: string;
    d?: string | number;
    g?: string | number;
    t?: string;
    u?: string;
    admin?: string;
  },
  additional?: string,
): string {
  let url = `/dashboard`;

  if (dirs.t) {
    url = `${url}/t/${dirs.t}`;
  }

  if (dirs.l) {
    url = `${url}/l/${dirs.l}`;
  }

  if (dirs.s) {
    url = `${url}/s/${dirs.s}`;
  }

  if (dirs.d) {
    url = `${url}/d/${dirs.d}`;
  }

  if (dirs.g) {
    url = `${url}/g/${dirs.g}`;
  }

  if (dirs.u) {
    url = `${url}/u/${dirs.u}`;
  }

  if (dirs.admin) {
    url = `${url}/admin/${dirs.admin}`;
  }

  if (additional) {
    url = `${url}/${additional}`;
  }

  return url;
}

export function makeAcronym(
  string: string,
  settings?: {
    ignoredWords?: string[];
    includePeriods?: boolean;
  },
): string {
  let ignoredWords = ["and", "or", "of", "to", "the"];

  if (settings?.ignoredWords) {
    ignoredWords = [...ignoredWords, ...settings.ignoredWords];
  }

  const stringCleaned = string.replace(/[^a-zA-Z ]/g, "");

  const stringAsArray = stringCleaned.split(" ");

  const acronymArray: string[] = [];

  stringAsArray.forEach((w) => {
    if (!ignoredWords.includes(w)) {
      acronymArray.push(w.substring(0, 1));
    }
  });

  let finalString = acronymArray
    .join(settings?.includePeriods ? "." : "")
    .toUpperCase();

  if (settings?.includePeriods) {
    finalString = `${finalString}.`;
  }

  return finalString;
}

export function nameDisplay(
  first_name: string,
  last_name: string,
  style?:
    | "full"
    | "first_name"
    | "last_name"
    | "initials"
    | "first_initial"
    | "last_initial"
    | "last_first",
  last_name_first?: boolean,
): string {
  switch (style) {
    case "first_name":
      return first_name;
    case "last_name":
      return last_name;
    case "initials":
      if (last_name_first) {
        return makeAcronym(`${last_name} ${first_name}`);
      }
      return makeAcronym(`${first_name} ${last_name}`);
    case "first_initial":
      if (last_name_first) {
        return `${last_name}, ${first_name.substring(0, 1)}.`;
      }
      return `${first_name.substring(0, 1)}. ${last_name}`;
    case "last_initial":
      if (last_name_first) {
        return `${last_name.substring(0, 1)}., ${first_name}`;
      }
      return `${first_name} ${last_name.substring(0, 1)}.`;
    default:
      if (last_name_first) {
        return `${last_name}, ${first_name}`;
      }
      return `${first_name} ${last_name}`;
  }
}

export function formatTimePeriod(time_period: {
  minutes: number;
  seconds: number;
}): string {
  const minutes_string = time_period.minutes ? time_period.minutes : "0";
  const seconds_string = time_period.seconds
    ? time_period.seconds > 9
      ? time_period.seconds
      : `0${time_period.seconds}`
    : "00";
  return `${minutes_string}:${seconds_string}`;
}

export function formatDateForInput(date: string | Date): string {
  const formattedDate = new Date(date)
    .toLocaleString("en-CA", {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "numeric",
      minute: "2-digit",
      hour12: false,
      timeZone: new Intl.DateTimeFormat().resolvedOptions().timeZone,
    })
    .replace(",", "");
  return formattedDate;
}

export function addNumberOrdinals(number: number) {
  const cleanedNumberToCheck = parseInt(
    number.toString().substring(number.toString().length - 1),
  );

  switch (cleanedNumberToCheck) {
    case 1:
      return `${number}st`;
    case 2:
      return `${number}nd`;
    case 3:
      return `${number}rd`;
    default:
      return `${number}th`;
  }
}

export const color_options = [
  "primary",
  "secondary",
  "accent",
  "success",
  "warning",
  "caution",
  "danger",
  "white",
  "black",
  "grey",
];

export function applyColor(
  color: string,
  variant?: "dark" | "darker" | "medium" | "light" | "lightest",
): string {
  if (color_options.includes(color)) {
    return variant
      ? `var(--color-${color}-${variant})`
      : `var(--color-${color})`;
  }
  return color;
}

export function createPeriodTimeString(
  minutes: number,
  seconds: number,
): string {
  const period_time = `00:${minutes < 10 ? `0${minutes}` : minutes}:${
    seconds < 10 ? `0${seconds}` : seconds
  }`;
  return period_time;
}

export function createMetaTitle(
  titles: string[],
  options?: {
    excludeDashboard?: boolean;
  },
): string {
  if (options?.excludeDashboard) {
    return `${titles.join(" | ")} | Leagrr`;
  }
  return `${titles.join(" | ")} | Dashboard | Leagrr`;
}

export function applyAppropriateTextColor(color: string): string {
  const lightColors = [
    "aqua",
    "cyan",
    "grey",
    "magenta",
    "orange",
    "pink",
    "red",
    "violet",
    "white",
    "yellow",
  ];

  if (lightColors.includes(color)) {
    return "black";
  }
  return "white";
}

export function convert_roles_to_select_choices(roles: Map<number, RoleData>) {
  const choices: { value: number; label: string }[] = [];

  roles.forEach((r) => {
    choices.push({
      value: r.role,
      label: r.title,
    });
  });

  return choices;
}

export function addressAsGoogleMapsLink(address: string): string {
  return `https://www.google.com/maps/place/${address.replaceAll(" ", "+")}`;
}

export function convertGameFeedItemsToRinkItems(
  feedItems: StatsData[],
  game: GameData,
) {
  return feedItems
    .filter((item) => {
      if (item.coordinates) return true;
    })
    .map((item) => {
      const newRinkItem: RinkItem = {
        item_id: item.item_id,
        icon: "target",
        coordinates: item.coordinates || "",
        color:
          item.team_id === game.home_team_id
            ? game.home_team_color
            : game.away_team_color,
        type: item.type,
      };

      switch (item.type) {
        case "goals":
          newRinkItem.icon = "e911_emergency";
          break;
        // case "saves":
        //   newRinkItem.icon = "security";
        //   break;
        case "penalties":
          newRinkItem.icon = "gavel";
          break;
        default:
          break;
      }

      return newRinkItem;
    });
}
