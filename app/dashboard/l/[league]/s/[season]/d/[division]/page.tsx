import { getDivision, getDivisionMetaInfo } from "@/actions/divisions";
import DivisionStandings from "@/components/dashboard/divisions/DivisionStandings/DivisionStandings";
import { notFound } from "next/navigation";
import css from "./page.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";
import Icon from "@/components/ui/Icon/Icon";
import Card from "@/components/ui/Card/Card";
import { canEditLeague } from "@/actions/leagues";
import Button from "@/components/ui/Button/Button";
import DivisionSchedule from "@/components/dashboard/divisions/DivisionSchedule/DivisionSchedule";
import DashboardUnit from "@/components/dashboard/DashboardUnit/DashboardUnit";
import DashboardUnitHeader from "@/components/dashboard/DashboardUnitHeader/DashboardUnitHeader";
import { createDashboardUrl } from "@/utils/helpers/formatting";

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

  const { canEdit } = await canEditLeague(league);

  const { teams, games } = divisionData;

  return (
    <div className={css.division_grid}>
      {teams && teams.length > 0 ? (
        <DivisionStandings teams={teams} />
      ) : (
        <DashboardUnit gridArea="standings">
          <DashboardUnitHeader>
            <h3>
              <Icon icon="trophy" label="Standings" labelFirst />
            </h3>
          </DashboardUnitHeader>
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
        </DashboardUnit>
      )}

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
      <div className={apply_classes([css.division_unit, css.division_stats])}>
        <h3>
          <Icon icon="leaderboard" label="Stats" labelFirst />
        </h3>
      </div>
    </div>
  );
}
