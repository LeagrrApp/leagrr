import { canEditLeague, getLeague } from "@/actions/leagues";
import LeagueHeader from "@/components/dashboard/leagues/LeagueHeader/LeagueHeader";
import { verifySession } from "@/lib/session";
import { notFound } from "next/navigation";
import { PropsWithChildren } from "react";

export default async function Layout({
  children,
  params,
}: PropsWithChildren<{
  params: Promise<{ league: string }>;
}>) {
  // confirm user is logged in, if not, redirect
  await verifySession();

  // get league slug
  const { league } = await params;

  // load league data
  const { data: leagueData } = await getLeague(league, {
    includeSeasons: true,
  });

  // if league data is unavailable, redirect to notfound
  if (!leagueData) notFound();

  // Check whether user has permission to edit league
  const { canEdit } = await canEditLeague(leagueData.league_id);

  return (
    <>
      <LeagueHeader league={leagueData} canEdit={canEdit} />

      {children}
    </>
  );
}
