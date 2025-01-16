import { deleteLeague, getLeagueData } from "@/actions/leagues";
import { verifyUserRole } from "@/actions/users";
import EditLeague from "@/components/dashboard/leagues/EditLeague/EditLeague";
import ModalConfirmAction from "@/components/dashboard/ModalConfirmAction/ModalConfirmAction";
import { verifySession } from "@/lib/session";
import { notFound, redirect } from "next/navigation";

export default async function Page({
  params,
}: {
  params: Promise<{ league: string }>;
}) {
  const userData = await verifySession();

  const { league: slug } = await params;

  // check user is has permission to access league settings
  const { data: league } = await getLeagueData(slug);

  // if league data not found, redirect
  if (!league) notFound();

  const isAdmin = await verifyUserRole(1);
  const isCommissioner = league?.league_role_id === 1;
  const isManager = league?.league_role_id === 2;

  if (isCommissioner || isManager || isAdmin)
    return (
      <>
        <h2>League Settings</h2>

        {(isCommissioner || isAdmin) && (
          <ModalConfirmAction
            defaultState={{
              league_id: league.league_id,
            }}
            actionFunction={deleteLeague}
            confirmationHeading={`Are you sure you want to delete ${league.name}?`}
            triggerIcon="delete"
            triggerLabel="Delete league"
            triggerIconPadding={["ml", "base"]}
          />
        )}

        <EditLeague league={league} user_id={userData.user_id} />
      </>
    );

  redirect(`/dashboard/l/${slug}`);
}
