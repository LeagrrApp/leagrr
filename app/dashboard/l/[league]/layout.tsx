import { getLeagueData } from "@/actions/leagues";
import { verifyUserRole } from "@/actions/users";
import DBHeader from "@/components/dashboard/DashboardHeader/DBHeader";
import { verifySession } from "@/lib/session";
import Link from "next/link";
import { notFound } from "next/navigation";

export default async function Layout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ league: string }>;
}) {
  // confirm user is logged in, if not, redirect
  const userData = await verifySession();

  // get league slug
  const { league: slug } = await params;

  // load league data
  const { data: league } = await getLeagueData(slug);
  console.log(league);

  // if league data is unavailable, redirect to notfound
  if (!league) notFound();

  // verify user role to allow site admin to also edit league
  const isAdmin = await verifyUserRole(1);

  // check league role or site admin role to verify can edit league
  const canEditLeague = league.league_role_id || isAdmin;

  // add link to settings if can edit
  const settingsLink = canEditLeague
    ? `/dashboard/l/${slug}/settings`
    : undefined;

  return (
    <>
      <DBHeader
        headline={league.name}
        byline={league.description}
        status={league.status}
        settingsLink={settingsLink}
      />

      {league.seasons && (
        <ul>
          {league.seasons?.map((season) => (
            <li key={season.slug}>
              <Link href={`/dashboard/l/${slug}/s/${season.slug}`}>
                {season.name}
              </Link>
            </li>
          ))}
        </ul>
      )}

      {children}
    </>
  );
}
