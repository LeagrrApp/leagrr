import {
  canEditTeam,
  getDivisionsByTeam,
  getTeam,
  getTeamDashboardData,
} from "@/actions/teams";
import DashboardUnit from "@/components/dashboard/DashboardUnit/DashboardUnit";
import DashboardUnitHeader from "@/components/dashboard/DashboardUnitHeader/DashboardUnitHeader";
import DivisionStandings from "@/components/dashboard/divisions/DivisionStandings/DivisionStandings";
import GamePreview from "@/components/dashboard/games/GamePreview/GamePreview";
import TeamMembers from "@/components/dashboard/teams/TeamMembers/TeamMembers";
import Button from "@/components/ui/Button/Button";
import Card from "@/components/ui/Card/Card";
import Container from "@/components/ui/Container/Container";
import Icon from "@/components/ui/Icon/Icon";
import {
  createDashboardUrl,
  createMetaTitle,
} from "@/utils/helpers/formatting";
import { notFound, redirect } from "next/navigation";
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
  searchParams,
}: {
  params: Promise<{ team: string }>;
  searchParams: Promise<{ [key: string]: string | undefined }>;
}) {
  const { team } = await params;
  const { div: queryDiv } = await searchParams;

  // get team data
  const { data: teamData } = await getTeam(team);

  // redirect if team not found
  if (!teamData) notFound();

  const { team_id } = teamData;

  // get list of public divisions the team is currently in
  const { data: divisions } = await getDivisionsByTeam(team_id);

  if (divisions.length === 0) {
    return (
      <>
        <h2>This team is not in any divisions yet.</h2>
        <Button href="#">Join a division</Button>
      </>
    );
  }

  // get data related to division
  // if searchParam provides specific division, get that division
  // if not, get first found division
  const currentDivision = queryDiv
    ? divisions.find((d) => d.division_id === parseInt(queryDiv))
    : divisions[0];

  // if the division in the searchParams doesn't exist, redirect to first found division
  if (!currentDivision) redirect(createDashboardUrl({ t: team }));

  // get team dashboard data based on team and selected division
  const { nextGame, prevGame, teamMembers, divisionStandings } =
    await getTeamDashboardData(team_id, currentDivision.division_id);

  return (
    <div className={css.team_grid}>
      <DashboardUnit gridArea="next_game">
        <DashboardUnitHeader>
          <h2>
            <Icon label="Next Game" icon="event_upcoming" labelFirst gap="m" />
          </h2>
        </DashboardUnitHeader>
        {nextGame ? (
          <GamePreview game={nextGame} includeGameLink />
        ) : (
          <Card padding="base">
            <p>There are no upcoming games.</p>
          </Card>
        )}
      </DashboardUnit>
      <DashboardUnit gridArea="prev_game">
        <DashboardUnitHeader>
          <h2>
            <Icon label="Last Game" icon="event_available" labelFirst gap="m" />
          </h2>
        </DashboardUnitHeader>
        {prevGame ? (
          <GamePreview
            game={prevGame}
            currentTeam={teamData.team_id}
            includeGameLink
          />
        ) : (
          <Card padding="base">
            <p>There is no completed game data.</p>
          </Card>
        )}
      </DashboardUnit>

      <DashboardUnit gridArea="members">
        <DashboardUnitHeader>
          <h2>
            <Icon label="Team Members" icon="group" labelFirst gap="m" />
          </h2>
        </DashboardUnitHeader>
        <TeamMembers teamMembers={teamMembers} />
      </DashboardUnit>

      <DashboardUnit gridArea="leagues">
        <DashboardUnitHeader>
          <h2>
            <Icon label="Standings" icon="trophy" labelFirst gap="m" />
          </h2>
          <Button
            href={createDashboardUrl({
              l: currentDivision.league_slug,
              s: currentDivision.season_slug,
              d: currentDivision.division_slug,
            })}
          >
            View League
          </Button>
        </DashboardUnitHeader>
        {divisionStandings && divisionStandings.length > 0 ? (
          <DivisionStandings
            teams={divisionStandings}
            currentTeam={teamData.team_id}
            division_id={currentDivision.division_id}
          />
        ) : (
          <Card padding="ml">
            <p>Standings are currently unavailable</p>
          </Card>
        )}
      </DashboardUnit>
    </div>
  );
}
