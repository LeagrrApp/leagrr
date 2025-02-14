import { getDivisionUrlById } from "@/actions/divisions";
import { canEditTeam, getTeam, getTeamDashboardData } from "@/actions/teams";
import DashboardUnit from "@/components/dashboard/DashboardUnit/DashboardUnit";
import DashboardUnitHeader from "@/components/dashboard/DashboardUnitHeader/DashboardUnitHeader";
import DivisionStandings from "@/components/dashboard/divisions/DivisionStandings/DivisionStandings";
import GamePreview from "@/components/dashboard/games/GamePreview/GamePreview";
import DivisionRoster from "@/components/dashboard/teams/DivisionRoster/DivisionRoster";
import Button from "@/components/ui/Button/Button";
import Card from "@/components/ui/Card/Card";
import Icon from "@/components/ui/Icon/Icon";
import {
  createDashboardUrl,
  createMetaTitle,
} from "@/utils/helpers/formatting";
import { notFound } from "next/navigation";
import css from "./page.module.css";

type PageParams = {
  params: Promise<{ team: string; id: string }>;
};

export async function generateMetadata({ params }: PageParams) {
  const { team } = await params;

  const { data: teamData } = await getTeam(team);

  if (!teamData) return null;

  const titleArray = [teamData.name, "Teams"];

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
          <GamePreview
            game={nextGame}
            currentTeam={teamData.team_id}
            includeGameLink
          />
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
