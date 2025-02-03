import {
  canEditTeam,
  deleteTeam,
  getTeam,
  getTeamRole,
  verifyTeamRoleLevel,
} from "@/actions/teams";
import { verifyUserRole } from "@/actions/users";
import ModalConfirmAction from "@/components/dashboard/ModalConfirmAction/ModalConfirmAction";
import EditTeam from "@/components/dashboard/teams/EditTeam";
import Container from "@/components/ui/Container/Container";
import {
  createDashboardUrl,
  createMetaTitle,
} from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";
import { useState } from "react";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ team: string }>;
}) {
  const { team } = await params;

  const { data: teamData } = await getTeam(team);

  const titleArray = teamData?.name
    ? ["Edit", teamData.name, "Teams"]
    : ["Edit", "Teams"];

  return {
    title: createMetaTitle(titleArray),
    description: teamData?.description,
  };
}

export default async function Page({
  params,
}: {
  params: Promise<{ team: string }>;
}) {
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
    <>
      <h2>Edit</h2>
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
        />
      )}
    </>
  );
}
