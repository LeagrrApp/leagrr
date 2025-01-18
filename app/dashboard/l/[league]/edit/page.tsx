import { deleteLeague, getLeagueData } from "@/actions/leagues";
import { verifyUserRole } from "@/actions/users";
import EditLeague from "@/components/dashboard/leagues/EditLeague";
import ModalConfirmAction from "@/components/dashboard/ModalConfirmAction/ModalConfirmAction";
import Container from "@/components/ui/Container/Container";
import Grid from "@/components/ui/layout/Grid";
import { verifySession } from "@/lib/session";
import { notFound, redirect } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{ league: string }>;
}) {
  await verifySession();

  const { league: slug } = await params;

  // check user is has permission to access league settings
  const { data: league } = await getLeagueData(slug);

  // if league data not found, redirect
  if (!league) notFound();

  const isAdmin = await verifyUserRole(1);
  const isCommissioner = league?.league_role_id === 1;
  const isManager = league?.league_role_id === 2;

  const backLink = `/dashboard/l/${slug}`;

  if (isCommissioner || isManager || isAdmin)
    return (
      <Container>
        <EditLeague league={league} backLink={backLink} />
        {(isCommissioner || isAdmin) && (
          <ModalConfirmAction
            defaultState={{
              league_id: league.league_id,
            }}
            actionFunction={deleteLeague}
            confirmationHeading={`Are you sure you want to delete ${league.name}?`}
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
