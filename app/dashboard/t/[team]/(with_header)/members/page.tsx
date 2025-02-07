import { canEditTeam, getAllTeamMembers, getTeam } from "@/actions/teams";
import TeamMembers from "@/components/dashboard/teams/TeamMembers/TeamMembers";
import Alert from "@/components/ui/Alert/Alert";
import BackButton from "@/components/ui/BackButton/BackButton";
import Icon from "@/components/ui/Icon/Icon";
import {
  createDashboardUrl,
  createMetaTitle,
} from "@/utils/helpers/formatting";
import { notFound } from "next/navigation";
import css from "./page.module.css";
import TeamInvite from "@/components/dashboard/teams/TeamInvite/TeamInvite";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ team: string }>;
}) {
  const { team } = await params;

  const { data: teamData } = await getTeam(team);

  if (!teamData) return null;

  const titleArray = ["Members", teamData.name, "Teams"];

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

  // redirect if team not found
  if (!teamData) notFound();

  const { team_id, name } = teamData;

  const backLink = createDashboardUrl({ t: team });

  const { data: teamMembers } = await getAllTeamMembers(team_id);

  // Check if user has edit permissions
  const { canEdit } = await canEditTeam(team);

  return (
    <>
      <BackButton label="Back to team" href={backLink} />
      <h2 className="push-m">{canEdit ? "Manage" : "Team"} Members</h2>
      <p className="push">
        This list includes all <strong>{name}</strong> members across all
        divisions and team roles.
      </p>

      <div className={canEdit ? css.layout : undefined}>
        {teamMembers ? (
          <TeamMembers
            canEdit={canEdit}
            team_id={team_id}
            teamMembers={teamMembers}
          />
        ) : (
          <Alert
            alert="Sorry, we were unable to load team members"
            type="danger"
          />
        )}
        {canEdit && <TeamInvite team={teamData} />}
      </div>
    </>
  );
}
