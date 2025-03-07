import {
  canEditTeam,
  deleteTeam,
  getTeam,
  getTeamMetaData,
} from "@/actions/teams";
import { verifyUserRole } from "@/actions/users";
import ModalConfirmAction from "@/components/dashboard/ModalConfirmAction/ModalConfirmAction";
import EditTeam from "@/components/dashboard/teams/EditTeam";
import TeamInvite from "@/components/dashboard/teams/TeamInvite/TeamInvite";
import BackButton from "@/components/ui/BackButton/BackButton";
import Col from "@/components/ui/layout/Col";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";
import css from "./page.module.css";

type PageProps = {
  params: Promise<{ team: string }>;
};

export async function generateMetadata({ params }: PageProps) {
  const { team } = await params;

  const { data: teamData } = await getTeam(team);

  if (!teamData) return null;

  const { data: teamMetaData } = await getTeamMetaData(team, {
    prefix: "Edit",
  });

  return teamMetaData;
}

export default async function Page({ params }: PageProps) {
  const { team } = await params;

  // get team data
  const { data: teamData } = await getTeam(team);

  if (!teamData) notFound();

  const backLink = createDashboardUrl({ t: team });

  // Redirect user if they do not have permission to edit
  const { canEdit } = await canEditTeam(team);
  if (!canEdit) redirect(backLink);

  const canDelete = await verifyUserRole(1);

  return (
    <div className={css.layout}>
      <Col fullSpan>
        <BackButton label="Back to team" href={backLink} />
        <h2>Edit Team</h2>
      </Col>
      <div>
        <EditTeam team={teamData} backLink={backLink} />
        {canDelete && (
          <ModalConfirmAction
            defaultState={{
              team_id: teamData.team_id,
            }}
            actionFunction={deleteTeam}
            confirmationHeading={`Are you sure you want to delete ${teamData.name}?`}
            confirmationByline={`This action is permanent cannot be undone and will likely have side effects on game and stat data. It is better to mark the team as "Inactive".`}
            trigger={{
              icon: "delete",
              label: "Delete Team",
              buttonStyles: {
                variant: "danger",
                fullWidth: true,
              },
            }}
            typeToConfirm={{
              type: "team",
              confirmString: `${team}`,
            }}
          />
        )}
      </div>
      <TeamInvite team={teamData} />
    </div>
  );
}
