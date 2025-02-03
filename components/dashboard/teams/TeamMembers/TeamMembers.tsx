import Card from "@/components/ui/Card/Card";
import css from "./teamMembers.module.css";
import Table from "@/components/ui/Table/Table";
import { verifySession } from "@/lib/session";
import Link from "next/link";
import { makeAcronym, nameDisplay } from "@/utils/helpers/formatting";

interface TeamMembersProps {
  teamMembers: any[];
}

export default async function TeamMembers({ teamMembers }: TeamMembersProps) {
  const { user_id } = await verifySession();

  const players = teamMembers.filter((p) => p.position !== "Goalie");
  const goalies = teamMembers.filter((p) => p.position === "Goalie");

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
  const goalieHColWidth = 40;
  const goalieColWidth = `${
    (100 - goalieHColWidth) / goalieHeadings.length - 1
  }%`;
  return (
    <>
      <h3 className={css.team_stats_heading}>Player Stats</h3>
      <Card className="push" padding="ml">
        <Table hColWidth={`${playerHColWidth}%`} colWidth={playerColWidth}>
          <thead>
            <tr>
              {playerHeadings.map((th) => (
                <th
                  key={th.title}
                  data-highlight-col={th.highlightCol ? true : undefined}
                  scope="col"
                  title={th.title}
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
                      <Link href={`/dashboard/u/${p.username}`}>
                        {nameDisplay(p.first_name, p.last_name, "full")}
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
      <h3 className={css.team_stats_heading}>Goalie Stats</h3>
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
              if (p.position === "Goalie")
                return (
                  <tr key={p.user_id}>
                    <td>{p.number}</td>
                    <th scope="row">
                      <Link href={`/dashboard/u/${p.username}`}>
                        {p.first_name} {p.last_name}
                      </Link>
                    </th>
                    <td>{p.shots_against}</td>
                    <td>{p.saves}</td>
                    <td>{p.goals_against}</td>
                    <td>
                      {Math.round((p.saves / p.shots_against) * 1000) / 1000}
                    </td>
                  </tr>
                );

              return null;
            })}
          </tbody>
        </Table>
      </Card>
    </>
  );
}
