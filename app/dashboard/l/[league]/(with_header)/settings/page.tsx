import { canEditLeague, getLeague, getLeagueMetaData } from "@/actions/leagues";
import EditLeague from "@/components/dashboard/leagues/EditLeague/EditLeague";
import Icon from "@/components/ui/Icon/Icon";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";

type PageProps = {
  params: Promise<{ league: string }>;
};

export async function generateMetadata({ params }: PageProps) {
  const { league } = await params;

  const { data: leagueMetaData } = await getLeagueMetaData(league, {
    prefix: "Settings",
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
  const { canEdit, isAdmin } = await canEditLeague(leagueData.league_id);
  const backLink = createDashboardUrl({ l: league });

  // If not a league admin, redirect back to league
  if (!canEdit) redirect(backLink);

  return (
    <>
      <h2 className="push">
        <Icon label="Information" icon="info" gap="em-s" />
      </h2>
      <EditLeague league={leagueData} backLink={backLink} isAdmin={isAdmin} />
    </>
  );
}
