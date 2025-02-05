import {
  canEditTeam,
  getDivisionsByTeam,
  getTeam,
  getTeamDashboardData,
} from "@/actions/teams";
import {
  createDashboardUrl,
  createMetaTitle,
} from "@/utils/helpers/formatting";
import css from "./page.module.css";
import { notFound, redirect } from "next/navigation";
import DashboardUnit from "@/components/dashboard/DashboardUnit/DashboardUnit";
import DashboardUnitHeader from "@/components/dashboard/DashboardUnitHeader/DashboardUnitHeader";
import Icon from "@/components/ui/Icon/Icon";
import Card from "@/components/ui/Card/Card";
import GamePreview from "@/components/dashboard/games/GamePreview/GamePreview";
import TeamMembers from "@/components/dashboard/teams/DivisionRoster/DivisionRoster";
import Button from "@/components/ui/Button/Button";
import DivisionStandings from "@/components/dashboard/divisions/DivisionStandings/DivisionStandings";
import { getDivisionUrlById } from "@/actions/divisions";
import DivisionRoster from "@/components/dashboard/teams/DivisionRoster/DivisionRoster";

type PageParams = {
  params: Promise<{ team: string; id: string }>;
};

export async function generateMetadata({ params }: PageParams) {
  const { team } = await params;

  const { data: teamData } = await getTeam(team);

  const titleArray = teamData?.name ? [teamData.name, "Teams"] : ["Teams"];

  return {
    title: createMetaTitle(titleArray),
    description: teamData?.description,
  };
}

export default async function Page({ params }: PageParams) {
  const { team, id } = await params;

  const division_id = parseInt(id as string);

  // get team data
  const { data: teamData } = await getTeam(team);

  // redirect if team not found
  if (!teamData) notFound();

  const { team_id } = teamData;

  // get team dashboard data based on team and selected division
  const { nextGame, prevGame, teamMembers, divisionStandings } =
    await getTeamDashboardData(team_id, division_id);

  const leagueUrl = await getDivisionUrlById(division_id);

  const { canEdit } = await canEditTeam(team);

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
            <p>There are no completed games.</p>
          </Card>
        )}
      </DashboardUnit>

      <DashboardUnit gridArea="members">
        <DashboardUnitHeader>
          <h2>
            <Icon label="Roster" icon="group" labelFirst gap="m" />
          </h2>
          {canEdit && (
            <Button href={createDashboardUrl({ t: team, d: id }, "/roster")}>
              <Icon icon="group" label="Manage Roster" />
            </Button>
          )}
        </DashboardUnitHeader>
        <DivisionRoster divisionRoster={teamMembers} />
      </DashboardUnit>

      <DashboardUnit gridArea="leagues">
        <DashboardUnitHeader>
          <h2>
            <Icon label="Standings" icon="trophy" labelFirst gap="m" />
          </h2>
          <Button href={leagueUrl}>
            <Icon icon="trophy" label="View League" />
          </Button>
        </DashboardUnitHeader>
        {divisionStandings && divisionStandings.length > 0 ? (
          <DivisionStandings
            teams={divisionStandings}
            currentTeam={teamData.team_id}
            division_id={division_id}
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
