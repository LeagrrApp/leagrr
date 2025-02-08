import {
  getDivision,
  getDivisionMetaInfo,
  getDivisionStatLeaders,
} from "@/actions/divisions";
import { canEditLeague } from "@/actions/leagues";
import DashboardUnit from "@/components/dashboard/DashboardUnit/DashboardUnit";
import DashboardUnitHeader from "@/components/dashboard/DashboardUnitHeader/DashboardUnitHeader";
import DivisionSchedule from "@/components/dashboard/divisions/DivisionSchedule/DivisionSchedule";
import DivisionStandings from "@/components/dashboard/divisions/DivisionStandings/DivisionStandings";
import DivisionStats from "@/components/dashboard/divisions/DivisionStats/DivisionStats";
import Button from "@/components/ui/Button/Button";
import Card from "@/components/ui/Card/Card";
import Icon from "@/components/ui/Icon/Icon";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { notFound } from "next/navigation";
import css from "./page.module.css";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ division: string; season: string; league: string }>;
}) {
  const { division, season, league } = await params;

  const { data: divisionMetaData } = await getDivisionMetaInfo(
    division,
    season,
    league,
  );

  return divisionMetaData;
}

export default async function Page({
  params,
}: {
  params: Promise<{ division: string; season: string; league: string }>;
}) {
  const { division, season, league } = await params;

  const { data: divisionData } = await getDivision(division, season, league);

  if (!divisionData) notFound();

  const { canEdit } = await canEditLeague(divisionData.league_id);

  const { teams, games } = divisionData;

  const { data: statLeaders } = await getDivisionStatLeaders(
    divisionData.division_id,
    1,
  );

  return (
    <div className={css.division_grid}>
      {games && games.length > 0 ? (
        <DivisionSchedule games={games} canEdit={canEdit} />
      ) : (
        <DashboardUnit gridArea="schedule">
          <DashboardUnitHeader>
            <h3>
              <Icon icon="calendar_month" label="Schedule" labelFirst />
            </h3>
          </DashboardUnitHeader>
          <Card padding="base">
            <p className="push">There are no upcoming games schedule!</p>
            {canEdit && (
              <Button
                href={createDashboardUrl(
                  { l: league, s: season, d: division },
                  "g",
                )}
              >
                Add games
              </Button>
            )}
          </Card>
        </DashboardUnit>
      )}

      <DashboardUnit gridArea="standings">
        <DashboardUnitHeader>
          <h3>
            <Icon icon="trophy" label="Standings" labelFirst />
          </h3>
        </DashboardUnitHeader>
        {teams && teams.length > 0 ? (
          <DivisionStandings
            teams={teams}
            division_id={divisionData.division_id}
          />
        ) : (
          <Card padding="base">
            <p className="push">There are no teams in this division yet!</p>
            {canEdit && (
              <Button
                href={createDashboardUrl(
                  { l: league, s: season, d: division },
                  "t",
                )}
              >
                Invite teams
              </Button>
            )}
          </Card>
        )}
      </DashboardUnit>

      {statLeaders && <DivisionStats statLeaders={statLeaders} />}
    </div>
  );
}
