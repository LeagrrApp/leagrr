"use client";

import { addTeamToDivision } from "@/actions/divisions";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import ColorIndicator from "@/components/ui/ColorIndicator/ColorIndicator";
import Dialog from "@/components/ui/Dialog/Dialog";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import Table from "@/components/ui/Table/Table";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useActionState, useRef, useState } from "react";

interface LeagueTeamsProps {
  teams: TeamData[];
  division: DivisionData;
}

export default function LeagueTeams({ teams, division }: LeagueTeamsProps) {
  const pathname = usePathname();

  const addDialogRef = useRef<HTMLDialogElement>(null);
  const [teamToAdd, setTeamToAdd] = useState<TeamData>(teams[0]);
  const [state, action, pending] = useActionState(addTeamToDivision, {
    link: pathname,
    data: {},
  });

  function handleClick(team_id: number) {
    const team = teams.find((t) => t.team_id === team_id);

    if (team) {
      setTeamToAdd(team);

      addDialogRef?.current?.showModal();
    }
  }

  const colHeaders = [
    { title: "Colour" },
    { title: "Name", highlightCol: true },
    { title: "Add" },
  ];

  const hColWidth = 70;
  const colWidth = `${(100 - hColWidth) / colHeaders.length - 1}%`;

  return (
    <>
      <Table hColWidth={`${hColWidth}%`} colWidth={colWidth}>
        <thead>
          <tr>
            {colHeaders.map((th) => (
              <th
                key={th.title}
                scope="col"
                data-highlight-col={th.highlightCol ? true : undefined}
              >
                {th.title}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {teams.map((t) => (
            <tr key={t.slug}>
              <td>
                <ColorIndicator color={t.color || "white"} />
              </td>
              <th scope="row">
                <Link href={createDashboardUrl({ t: t.slug })}>{t.name}</Link>
              </th>
              <td>
                <Button
                  style={{ position: "relative" }}
                  onClick={() => handleClick(t.team_id)}
                >
                  <Icon icon="group_add" label="add" hideLabel />
                </Button>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
      <Dialog ref={addDialogRef}>
        <form action={action}>
          <Grid cols={2} gap="base">
            <Col fullSpan>
              <h3>Add {teamToAdd?.name}?</h3>
            </Col>
            <input type="hidden" name="team_id" value={teamToAdd?.team_id} />
            <input
              type="hidden"
              name="division_id"
              value={division.division_id}
            />
            <input type="hidden" name="league_id" value={division.league_id} />
            {state?.message && state?.status === 400 && (
              <Col fullSpan>
                <Alert type="danger" alert={state.message} />
              </Col>
            )}
            <Button type="submit" disabled={pending}>
              <Icon icon="delete" label="Confirm" />
            </Button>
            <Button
              onClick={() => addDialogRef?.current?.close()}
              variant="grey"
            >
              <Icon icon="cancel" label="Cancel" />
            </Button>
          </Grid>
        </form>
      </Dialog>
    </>
  );
}
