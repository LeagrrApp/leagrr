import { getTeam, getTeamDashboardData } from "@/actions/teams";
import DashboardUnit from "@/components/dashboard/DashboardUnit/DashboardUnit";
import DashboardUnitHeader from "@/components/dashboard/DashboardUnitHeader/DashboardUnitHeader";
import GamePreview from "@/components/dashboard/games/GamePreview/GamePreview";
import TeamHeader from "@/components/dashboard/teams/TeamHeader/TeamHeader";
import Card from "@/components/ui/Card/Card";
import Container from "@/components/ui/Container/Container";
import Icon from "@/components/ui/Icon/Icon";
import { createMetaTitle } from "@/utils/helpers/formatting";
import { notFound } from "next/navigation";
import css from "./page.module.css";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ team: string }>;
}) {
  const { team } = await params;

  const { data: teamData } = await getTeam(team);

  const titleArray = teamData?.name ? [teamData.name, "Teams"] : ["Teams"];

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

  const { data: teamData } = await getTeam(team);

  console.log(teamData);

  if (!teamData) notFound();

  const { nextGame, prevGame } = await getTeamDashboardData(teamData.team_id);

  return (
    <>
      <TeamHeader team={teamData} canEdit={true} />

      <Container className={css.team_grid}>
        <DashboardUnit gridArea="next_game">
          <DashboardUnitHeader>
            <h2>
              <Icon
                label="Next Game"
                icon="event_upcoming"
                labelFirst
                gap="m"
              />
            </h2>
          </DashboardUnitHeader>
          {nextGame ? (
            <GamePreview game={nextGame} />
          ) : (
            <Card padding="base">
              <p>There are no upcoming games.</p>
            </Card>
          )}
        </DashboardUnit>
        <DashboardUnit gridArea="prev_game">
          <DashboardUnitHeader>
            <h2>
              <Icon
                label="Last Game"
                icon="event_available"
                labelFirst
                gap="m"
              />
            </h2>
          </DashboardUnitHeader>
          {prevGame ? (
            <GamePreview game={prevGame} currentTeam={teamData.team_id} />
          ) : (
            <Card padding="base">
              <p>There is no completed game data.</p>
            </Card>
          )}
        </DashboardUnit>
      </Container>
    </>
  );
}
