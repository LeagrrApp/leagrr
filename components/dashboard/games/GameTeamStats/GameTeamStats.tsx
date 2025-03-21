import { getTeamGameStats } from "@/actions/games";
import Card from "@/components/ui/Card/Card";
import Indicator from "@/components/ui/Indicator/Indicator";
import Table from "@/components/ui/Table/Table";
import { verifySession } from "@/lib/session";
import {
  createDashboardUrl,
  makeAcronym,
  nameDisplay,
} from "@/utils/helpers/formatting";
import { applyClasses } from "@/utils/helpers/html-attributes";
import Link from "next/link";
import css from "./gameTeamStats.module.css";

interface GameTeamStatsProps {
  game: GameData;
  team: Pick<TeamData, "team_id" | "name" | "slug"> & {
    score: number;
  };
  isHome?: boolean;
}

export default async function GameTeamStats({
  game,
  team,
  isHome,
}: GameTeamStatsProps) {
  const { user_id } = await verifySession();

  const classes = [css.team_stats];
  if (isHome) classes.push(css.team_stats_home);

  const { data: teamGameStats } = await getTeamGameStats(
    game.game_id,
    team.team_id,
    game.division_id,
  );

  if (!teamGameStats)
    return (
      <div className={applyClasses(classes)}>
        <Card className="push" padding="ml">
          <p>Unable to load team stats...</p>
        </Card>
      </div>
    );

  if (teamGameStats.length === 0) {
    return (
      <div className={applyClasses(classes)}>
        <div className={css.team_stats_block}>
          <h3 className={css.team_stats_heading}>{team.name}</h3>
          <Card className="push" padding="ml">
            <p>This team does not have any player data.</p>
          </Card>
        </div>
      </div>
    );
  }

  const players = teamGameStats.filter((p) => p.position !== "Goalie");
  const goalies = teamGameStats.filter((p) => p.position === "Goalie");

  // player table settings
  const playerHeadings = [
    { title: "Number", shorthand: "Num" },
    { title: "Name", shorthand: "Name", highlightCol: true },
    { title: "Position", shorthand: "POS" },
    { title: "Goals", shorthand: "G" },
    { title: "Assists", shorthand: "A" },
    { title: "Points", shorthand: "P" },
    { title: "Shots", shorthand: "S" },
    {
      title: "Penalties in Minutes",
      shorthand: "PIM",
    },
  ];
  const playerHColWidth = 40;
  const playerColWidth = `${
    (100 - playerHColWidth) / playerHeadings.length - 1
  }%`;

  // goalie table settings
  const goalieHeadings = [
    { title: "Number", shorthand: "Num" },
    { title: "Name", shorthand: "Name", highlightCol: true },
    { title: "Shots Against", shorthand: "SA" },
    { title: "Saves", shorthand: "SV" },
    { title: "Goals Against", shorthand: "GA" },
    { title: "Save Percentage", shorthand: "SV%" },
  ];
  const goalieHColWidth = 45;
  const goalieColWidth = `${
    (100 - goalieHColWidth) / goalieHeadings.length - 1
  }%`;

  return (
    <div className={applyClasses(classes)}>
      <h3 className={css.team_stats_team_name}>{team.name}</h3>
      <div className={css.team_stats_block}>
        <h4 className={css.team_stats_heading}>Player Stats</h4>
        <Card padding="ml">
          <Table hColWidth={`${playerHColWidth}%`} colWidth={playerColWidth}>
            <thead>
              <tr>
                {playerHeadings.map((th) => (
                  <th
                    key={th.title}
                    scope="col"
                    title={th.title}
                    data-highlight-col={th.highlightCol ? true : undefined}
                  >
                    <span aria-hidden="true">{th.shorthand}</span>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {players.map((p) => {
                if (p.position !== "Goalie") {
                  const isUser = user_id === p.user_id;
                  return (
                    <tr
                      key={p.user_id}
                      data-highlighted={isUser ? true : undefined}
                    >
                      <td>{p.number}</td>
                      <th scope="row" data-highlight-col>
                        <Link href={createDashboardUrl({ u: p.username })}>
                          {nameDisplay(
                            p.first_name,
                            p.last_name,
                            "first_initial",
                          )}
                          {isUser && <Indicator />}
                        </Link>
                      </th>
                      <td>{makeAcronym(p.position || "")}</td>
                      <td>{p.goals}</td>
                      <td>{p.assists}</td>
                      <td>{p.points}</td>
                      <td>{p.shots}</td>
                      <td>{p.penalties_in_minutes || 0}</td>
                    </tr>
                  );
                }
                return null;
              })}
            </tbody>
          </Table>
        </Card>
      </div>
      <div className={css.team_stats_block}>
        <h4 className={css.team_stats_heading}>Goalie Stats</h4>
        <Card padding="ml">
          <Table hColWidth={`${goalieHColWidth}%`} colWidth={goalieColWidth}>
            <thead>
              <tr>
                {goalieHeadings.map((th) => (
                  <th
                    key={th.title}
                    scope="col"
                    title={th.title}
                    data-highlight-col={th.highlightCol ? true : undefined}
                  >
                    <span aria-hidden="true">{th.shorthand}</span>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {goalies.map((p) => {
                if (p.position === "Goalie") {
                  return (
                    <tr key={p.user_id}>
                      <td>{p.number}</td>
                      <th scope="row">
                        <Link href={createDashboardUrl({ u: p.username })}>
                          {nameDisplay(
                            p.first_name,
                            p.last_name,
                            "first_initial",
                          )}
                        </Link>
                      </th>
                      <td>
                        {isHome ? game.away_team_shots : game.home_team_shots}
                      </td>
                      <td>{p.saves}</td>
                      <td>
                        {isHome ? game.away_team_score : game.home_team_score}
                      </td>
                      <td>
                        {p.saves
                          ? Math.round(
                              (p.saves /
                                (isHome
                                  ? game.away_team_shots
                                  : game.home_team_shots)) *
                                1000,
                            ) / 1000
                          : `-`}
                      </td>
                    </tr>
                  );
                }
                return null;
              })}
            </tbody>
          </Table>
        </Card>
      </div>
    </div>
  );
}
