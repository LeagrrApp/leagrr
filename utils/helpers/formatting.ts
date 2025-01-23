export function capitalize(string: string): string {
  return `${string.substring(0, 1).toUpperCase()}${string.substring(1)}`;
}

type Dirs = {};

export function createDashboardUrl(
  dirs: {
    l?: string;
    s?: string;
    d?: string;
    t?: string;
  },
  additional?: string
): string {
  let url = `/dashboard`;

  if (dirs.l) {
    url = `${url}/l/${dirs.l}`;
  }

  if (dirs.s) {
    url = `${url}/s/${dirs.s}`;
  }

  if (dirs.d) {
    url = `${url}/d/${dirs.d}`;
  }

  if (dirs.t) {
    url = `${url}/t/${dirs.t}`;
  }

  if (additional) {
    url = `${url}/${additional}`;
  }

  return url;
}
