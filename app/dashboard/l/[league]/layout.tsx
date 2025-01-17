import { getLeagueData } from "@/actions/leagues";
import { verifyUserRole } from "@/actions/users";
import DBHeader from "@/components/dashboard/DashboardHeader/DBHeader";
import SeasonSelector from "@/components/dashboard/SeasonSelector/SeasonSelector";
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
  await verifySession();

  // get league slug
  const { league: slug } = await params;

  // load league data
  const { data: league } = await getLeagueData(slug);

  // if league data is unavailable, redirect to notfound
  if (!league) notFound();

  // verify user role to allow site admin to also edit league
  const isAdmin = await verifyUserRole(1);

  // check league role or site admin role to verify can edit league
  const canEditLeague =
    league.league_role_id === (1 || 2) || (isAdmin as boolean);

  // add link to settings if can edit
  const editLink = canEditLeague ? `/dashboard/l/${slug}/edit` : undefined;

  return (
    <>
      <DBHeader
        headline={league.name}
        byline={league.description}
        status={league.status}
        editLink={editLink}
      >
        {league?.seasons && league?.seasons?.length !== 0 && (
          <SeasonSelector
            seasons={league?.seasons}
            hasAdminRole={canEditLeague}
          />
        )}
      </DBHeader>

      {children}
    </>
  );
}
