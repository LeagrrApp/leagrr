import {
  canEditLeague,
  deleteLeague,
  getLeague,
  getLeagueMetaData,
} from "@/actions/leagues";
import EditLeague from "@/components/dashboard/leagues/EditLeague";
import ModalConfirmAction from "@/components/dashboard/ModalConfirmAction/ModalConfirmAction";
import Container from "@/components/ui/Container/Container";
import { verifySession } from "@/lib/session";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";

type PageProps = {
  params: Promise<{ league: string }>;
};

export async function generateMetadata({ params }: PageProps) {
  const { league } = await params;

  const { data: leagueMetaData } = await getLeagueMetaData(league, {
    prefix: "Edit",
  });

  return leagueMetaData;
}

export default async function Page({ params }: PageProps) {
  await verifySession();

  const { league } = await params;

  // check user is has permission to access league settings
  const { data: leagueData } = await getLeague(league);

  // if league data not found, redirect
  if (!leagueData) notFound();

  // Get users role to check league permissions
  const { canEdit, role } = await canEditLeague(leagueData.league_id);
  const backLink = createDashboardUrl({ l: league });

  // If not a league admin, redirect back to league
  if (!canEdit) redirect(backLink);

  // Check if user has authority to delete
  const canDelete = role?.role === 1;

  return (
    <Container>
      <EditLeague league={leagueData} backLink={backLink} />
      {canDelete && (
        <ModalConfirmAction
          defaultState={{
            league_id: leagueData.league_id,
          }}
          actionFunction={deleteLeague}
          confirmationHeading={`Are you sure you want to delete ${leagueData.name}?`}
          confirmationByline={`This action is permanent cannot be undone. Consider setting the league's status to "Archived" instead.`}
          trigger={{
            icon: "delete",
            label: "Delete league",
            buttonStyles: {
              variant: "danger",
              fullWidth: true,
            },
          }}
        />
      )}
    </Container>
  );
}
