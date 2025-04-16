import { canEditTeam, getTeam, getTeamMetaData } from "@/actions/teams";
import TeamJoinDivision from "@/components/dashboard/teams/TeamJoinDivision/TeamJoinDivision";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";

type PageProps = {
  params: Promise<{ team: string }>;
};

export async function generateMetadata({ params }: PageProps) {
  const { team } = await params;

  const { data: teamData } = await getTeam(team);

  if (!teamData) return null;

  const { data: teamMetaData } = await getTeamMetaData(team, {
    prefix: "Join Division",
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

  return <TeamJoinDivision team_id={teamData.team_id} team_slug={team} />;
}
