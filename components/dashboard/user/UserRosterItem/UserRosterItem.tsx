import Card from "@/components/ui/Card/Card";
import Icon from "@/components/ui/Icon/Icon";
import Table from "@/components/ui/Table/Table";
import { applyColor, createDashboardUrl } from "@/utils/helpers/formatting";
import Link from "next/link";
import { CSSProperties } from "react";
import css from "./userRosterItem.module.css";

interface UserRosterItemProps {
  team: {
    rosterInfo: UserRosterData;
    userDivisionStats?: UserRosterStats;
    teamStandings?: TeamStandingsData;
  };
}

interface UserRosterItemStyles extends CSSProperties {
  "--color-team": string;
}

export default async function UserRosterItem({ team }: UserRosterItemProps) {
  const {
    team_name,
    team_slug,
    division_name,
    division_id,
    division_slug,
    season_slug,
    league_name,
    league_slug,
  } = team.rosterInfo;

  const player_stats_headings = [
    { title: "Position", shorthand: "POS", highlightCol: true },
    { title: "Number", shorthand: "Num" },
    { title: "Goals", shorthand: "G" },
    { title: "Assists", shorthand: "A" },
    { title: "Points", shorthand: "P" },
    { title: "Shots", shorthand: "S" },
    {
      title: "Penalties in Minutes",
      shorthand: "PIM",
    },
  ];

  const playerHColWidth = 20;
  const playerColWidth = `${
    (100 - playerHColWidth) / player_stats_headings.length - 1
  }%`;

  const team_stats_headings = [
    { title: "Rank", shorthand: "Rank", highlightCol: true },
    { title: "Games Played", shorthand: "GP" },
    { title: "Wins", shorthand: "W" },
    { title: "Losses", shorthand: "L" },
    { title: "Ties", shorthand: "T" },
    { title: "Points", shorthand: "PTS" },
    { title: "Goals For", shorthand: "GF" },
    { title: "Goals Against", shorthand: "GA" },
    { title: "Goal Differential", shorthand: "+/-" },
  ];

  const teamHColWidth = 15;
  const teamColWidth = `${
    (100 - teamHColWidth) / team_stats_headings.length - 1
  }%`;

  const styles: UserRosterItemStyles = {
    "--color-team": applyColor(team.rosterInfo.team_color),
  };

  let teamPlaceClass: string | undefined;

  switch (team?.teamStandings?.position) {
    case 1:
      teamPlaceClass = `${css.user_roster_placed} ${css.user_roster_first}`;
      break;
    case 2:
      teamPlaceClass = `${css.user_roster_placed} ${css.user_roster_second}`;
      break;
    case 3:
      teamPlaceClass = `${css.user_roster_placed} ${css.user_roster_third}`;
      break;
    default:
      break;
  }

  return (
    <article style={styles}>
      <Card className={css.user_roster} padding="ml">
        <header>
          <h3>
            <Link
              className={css.user_roster_heading_link}
              href={createDashboardUrl({ t: team_slug, d: division_id })}
            >
              {team_name}
            </Link>
          </h3>
          <Link
            className={css.user_roster_div_link}
            href={createDashboardUrl({
              l: league_slug,
              s: season_slug,
              d: division_slug,
            })}
          >
            {league_name} — {division_name}
          </Link>
        </header>

        {team.userDivisionStats && (
          <div>
            <h4 className={css.user_roster_sub_heading}>Your Stats</h4>
            <Table hColWidth={`${playerHColWidth}%`} colWidth={playerColWidth}>
              <thead>
                <tr>
                  {player_stats_headings.map((th) => (
                    <th
                      key={th.shorthand}
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
                <tr>
                  <td data-highlight-col>{team.userDivisionStats.position}</td>
                  <td>{team.userDivisionStats.number}</td>
                  <td>{team.userDivisionStats.goals}</td>
                  <td>{team.userDivisionStats.assists}</td>
                  <td>{team.userDivisionStats.points}</td>
                  <td>{team.userDivisionStats.shots}</td>
                  <td>{team.userDivisionStats.penalties_in_minutes}</td>
                </tr>
              </tbody>
            </Table>
          </div>
        )}
        {team.teamStandings && (
          <div>
            <h4 className={css.user_roster_sub_heading}>Team Stats</h4>
            <Table hColWidth={`${teamHColWidth}%`} colWidth={teamColWidth}>
              <thead>
                <tr>
                  {team_stats_headings.map((th) => (
                    <th
                      key={th.shorthand}
                      scope="col"
                      title={th.title}
                      data-highlight-col={th.highlightCol}
                    >
                      <span aria-hidden="true">{th.shorthand}</span>
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td align="center" data-highlight-col>
                    {team.teamStandings.position && teamPlaceClass ? (
                      <strong className={teamPlaceClass}>
                        <Icon
                          icon="trophy"
                          label={team.teamStandings.position.toString()}
                          gap="m"
                        />
                      </strong>
                    ) : (
                      <strong>{team.teamStandings.position}</strong>
                    )}
                  </td>
                  <td align="center">{team.teamStandings.games_played}</td>
                  <td align="center">{team.teamStandings.wins}</td>
                  <td align="center">{team.teamStandings.losses}</td>
                  <td align="center">{team.teamStandings.ties}</td>
                  <td align="center">{team.teamStandings.points}</td>
                  <td align="center">{team.teamStandings.goals_for || 0}</td>
                  <td align="center">
                    {team.teamStandings.goals_against || 0}
                  </td>
                  <td align="center">
                    {team.teamStandings.goals_for -
                      team.teamStandings.goals_against}
                  </td>
                </tr>
              </tbody>
            </Table>
          </div>
        )}
      </Card>
    </article>
  );
}
