import Card from "@/components/ui/Card/Card";
import Table from "@/components/ui/Table/Table";
import Link from "next/link";

type DivisionStandingsProps = {
  teams: TeamStandingsData[];
};

export default function DivisionStandings({ teams }: DivisionStandingsProps) {
  console.log(teams);

  const table_headings = [
    { title: "Team", shorthand: "Team" },
    { title: "Games Played", shorthand: "GP" },
    { title: "Wins", shorthand: "W" },
    { title: "Losses", shorthand: "L" },
    { title: "Ties", shorthand: "T" },
    { title: "Points", shorthand: "PTS" },
    { title: "Goals For", shorthand: "GF" },
    { title: "Goals Against", shorthand: "GA" },
    { title: "Goal Differential", shorthand: "+/-" },
  ];

  // heading column width as percentage of the total table width
  const hColWidth = 30;

  // divide remaining percentage by number of columns not including heading column
  const colWidth = `${(100 - hColWidth) / table_headings.length - 1}%`;

  return (
    <Card padding="ml">
      <Table colWidth={colWidth}>
        <thead>
          <tr>
            {table_headings.map((th) => (
              <th scope="col" title={th.title}>
                <span aria-hidden="true">{th.shorthand}</span>
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {teams.map((t) => (
            <tr key={t.team_id}>
              <th scope="row">
                <Link href={`/dashboard/t/${t.slug}`}>{t.name}</Link>
              </th>
              <td>{t.games_played}</td>
              <td>{t.wins}</td>
              <td>{t.losses}</td>
              <td>{t.ties}</td>
              <td>{t.points}</td>
              <td>{t.goals_for || 0}</td>
              <td>{t.goals_against || 0}</td>
              <td>{t.goals_for - t.goals_against}</td>
            </tr>
          ))}
        </tbody>
      </Table>
    </Card>
  );
}
