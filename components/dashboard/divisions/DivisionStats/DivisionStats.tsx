import Icon from "@/components/ui/Icon/Icon";
import DashboardUnit from "../../DashboardUnit/DashboardUnit";
import DashboardUnitHeader from "../../DashboardUnitHeader/DashboardUnitHeader";
import css from "./divisionStats.module.css";
import Card from "@/components/ui/Card/Card";
import { capitalize } from "@/utils/helpers/formatting";
import ProfileImg from "@/components/ui/ProfileImg/ProfileImg";

type DivisionStatsProps = {
  statLeaders: {
    [key: string]: StatLeaderBoardItem[];
    points: StatLeaderBoardItem[];
    goals: StatLeaderBoardItem[];
    assists: StatLeaderBoardItem[];
    shutouts: StatLeaderBoardItem[];
  };
};

export default function DivisionStats({ statLeaders }: DivisionStatsProps) {
  const statTypes = Object.keys(statLeaders);

  return (
    <DashboardUnit gridArea="stats">
      <DashboardUnitHeader>
        <h3>
          <Icon icon="leaderboard" label="Stat Leaders" labelFirst />
        </h3>
      </DashboardUnitHeader>
      <div className={css.stats_grid}>
        {statTypes.map((type) => {
          if (
            statLeaders[type].length === 1 &&
            statLeaders[type][0].count > 0
          ) {
            const { team, first_name, last_name, count } = statLeaders[type][0];

            let icon = "leaderboard";

            switch (type) {
              case "goals":
                icon = "e911_emergency";
                break;
              case "shutouts":
                icon = "security";
                break;
              case "assists":
                icon = "handshake";
                break;
              default:
                break;
            }

            return (
              <Card key={type} padding="ml" className={css.stats_card}>
                <h4 className={css.stats_card_title}>
                  <Icon icon={icon} label={capitalize(type)} gap="s" />
                </h4>
                <ProfileImg label={`${first_name} ${last_name}`} size={150} />
                <h5 className={css.stats_card_name}>
                  {first_name} {last_name}
                </h5>
                <p className={css.stats_card_team}>{team}</p>
                <p className={css.stats_card_count}>{count}</p>
              </Card>
            );
          }

          return (
            <Card padding="ml" className={css.stats_card}>
              <h4 className={css.stats_card_title}>{capitalize(type)}</h4>
              <ProfileImg label="No leader" size={150} />
              <h5 className={css.stats_card_name}>No leader</h5>
            </Card>
          );
        })}
      </div>
    </DashboardUnit>
  );
}
