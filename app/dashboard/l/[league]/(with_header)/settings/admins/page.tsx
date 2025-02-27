import { getLeagueAdmins } from "@/actions/leagueAdmins";
import { canEditLeague, getLeague, getLeagueMetaData } from "@/actions/leagues";
import LeagueAdmins from "@/components/dashboard/leagues/LeagueAdmins/LeagueAdmins";
import Icon from "@/components/ui/Icon/Icon";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";

type PageProps = {
  params: Promise<{ league: string }>;
};

export async function generateMetadata({ params }: PageProps) {
  const { league } = await params;

  const { data: leagueMetaData } = await getLeagueMetaData(league, {
    prefix: ["Admins", "Settings"],
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
  const { isCommissioner, isAdmin } = await canEditLeague(leagueData.league_id);

  // If not a league commissioner or site admin, redirect back to league
  if (!isAdmin && !isCommissioner)
    redirect(createDashboardUrl({ l: league }, "settings"));

  const { data: admins } = await getLeagueAdmins(league);

  return (
    <>
      <h2 className="push">
        <Icon label="Admins" icon="admin_panel_settings" gap="em-s" />
      </h2>
      <LeagueAdmins admins={admins} />
    </>
  );
}
