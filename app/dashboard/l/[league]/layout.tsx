import { canEditLeague, getLeagueData } from "@/actions/leagues";
import LeagueHeader from "@/components/dashboard/LeagueHeader/LeagueHeader";
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
  const { league: slug } = await params;

  // load league data
  const { data: league } = await getLeagueData(slug);

  // if league data is unavailable, redirect to notfound
  if (!league) notFound();

  // set check for whether user has permission to edit league
  const { canEdit } = await canEditLeague(league.league_id);

  return (
    <>
      <LeagueHeader league={league} canEdit={canEdit} />

      {children}
    </>
  );
}
