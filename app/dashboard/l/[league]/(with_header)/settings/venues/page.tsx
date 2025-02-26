import { canEditLeague, getLeague, getLeagueMetaData } from "@/actions/leagues";
import { getVenuesByLeagueId } from "@/actions/venues";
import LeagueVenues from "@/components/dashboard/leagues/LeagueVenues/LeagueVenues";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";

type PageProps = {
  params: Promise<{ league: string }>;
};

export async function generateMetadata({ params }: PageProps) {
  const { league } = await params;

  const { data: leagueMetaData } = await getLeagueMetaData(league, {
    prefix: ["Venues", "Settings"],
  });

  return leagueMetaData;
}

export default async function Page({ params }: PageProps) {
  const { league } = await params;

  // check user is has permission to access league settings
  const { data: leagueData } = await getLeague(league);

  // if league data not found, redirect
  if (!leagueData) notFound();

  // Get users role to check league permissions
  const { canEdit } = await canEditLeague(leagueData.league_id);
  const backLink = createDashboardUrl({ l: league });

  // If not a league admin, redirect back to league
  if (!canEdit) redirect(backLink);

  const { data: venues } = await getVenuesByLeagueId(leagueData.league_id);

  return (
    <>
      <h2 className="push">Venues</h2>

      <LeagueVenues venues={venues} league={leagueData} />
    </>
  );
}
