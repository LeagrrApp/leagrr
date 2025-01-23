import { getDivision } from "@/actions/divisions";
import DivisionStandings from "@/components/dashboard/divisions/DivisionStandings/DivisionStandings";
import { notFound } from "next/navigation";
import css from "./page.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";
import Icon from "@/components/ui/Icon/Icon";
import Card from "@/components/ui/Card/Card";
import { canEditLeague } from "@/actions/leagues";
import Button from "@/components/ui/Button/Button";

export default async function Page({
  params,
}: {
  params: Promise<{ division: string; season: string; league: string }>;
}) {
  const { division, season, league } = await params;

  const { data: divisionData } = await getDivision(division, season, league);

  if (!divisionData) notFound();

  const { canEdit } = await canEditLeague(league);

  const { teams } = divisionData;

  return (
    <div className={css.division_grid}>
      <div
        className={apply_classes([css.division_unit, css.division_standings])}
      >
        <h3>
          <Icon icon="trophy" label="Standings" labelFirst />
        </h3>
        {teams && teams.length > 0 ? (
          <DivisionStandings teams={teams} />
        ) : (
          <Card padding="base">
            <p className="push">There are no teams in this division yet!</p>
            {canEdit && <Button href="#">Invite teams</Button>}
          </Card>
        )}
      </div>
      <div
        className={apply_classes([css.division_unit, css.division_schedule])}
      >
        <h3>
          <Icon icon="calendar_month" label="Schedule" labelFirst />
        </h3>
      </div>
      <div className={apply_classes([css.division_unit, css.division_stats])}>
        <h3>
          <Icon icon="leaderboard" label="Stats" labelFirst />
        </h3>
      </div>
    </div>
  );
}
