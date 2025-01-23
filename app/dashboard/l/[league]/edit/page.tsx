import { canEditLeague, deleteLeague, getLeagueData } from "@/actions/leagues";
import EditLeague from "@/components/dashboard/leagues/EditLeague";
import ModalConfirmAction from "@/components/dashboard/ModalConfirmAction/ModalConfirmAction";
import Container from "@/components/ui/Container/Container";
import { verifySession } from "@/lib/session";
import { notFound, redirect } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{ league: string }>;
}) {
  await verifySession();

  const { league } = await params;

  // check user is has permission to access league settings
  const { data: leagueData } = await getLeagueData(league);

  // if league data not found, redirect
  if (!leagueData) notFound();

  const { canEdit, role: league_role } = await canEditLeague(league);

  const canDelete = league_role === "admin" || league_role === "commissioner";

  const backLink = `/dashboard/l/${league}`;

  if (canEdit)
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

  redirect(backLink);
}
