"use client";

import { removeTeamFromDivision } from "@/actions/divisions";
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

interface DivisionTeamsProps {
  teams: DivisionTeamData[];
  division: DivisionData;
}

export default function DivisionTeams({ teams, division }: DivisionTeamsProps) {
  const pathname = usePathname();

  const removeDialogRef = useRef<HTMLDialogElement>(null);
  const [teamToRemove, setTeamToRemove] = useState<DivisionTeamData>(teams[0]);
  const [state, action, pending] = useActionState(removeTeamFromDivision, {
    link: pathname,
    data: {},
  });

  function handleClick(team_id: number) {
    const team = teams.find((t) => t.team_id === team_id);

    if (team) {
      setTeamToRemove(team);

      removeDialogRef?.current?.showModal();
    }
  }

  const colHeaders = [
    { title: "Colour" },
    { title: "Name", highlightCol: true },
    { title: "Remove" },
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
                  variant="danger"
                  onClick={() => handleClick(t.team_id)}
                >
                  <Icon icon="group_remove" label="Remove" hideLabel />
                </Button>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
      <Dialog ref={removeDialogRef}>
        <form action={action}>
          <Grid cols={2} gap="base">
            <Col fullSpan>
              <h3>Remove {teamToRemove?.name}?</h3>
            </Col>
            <input type="hidden" name="team_id" value={teamToRemove?.team_id} />
            <input
              type="hidden"
              name="division_id"
              value={division.division_id}
            />
            <input type="hidden" name="league_id" value={division.league_id} />
            <Button type="submit" disabled={pending} variant="danger">
              <Icon icon="delete" label="Confirm" />
            </Button>
            <Button
              onClick={() => removeDialogRef?.current?.close()}
              variant="grey"
            >
              <Icon icon="cancel" label="Cancel" />
            </Button>
            {state?.status === 400 && state?.message && (
              <Col fullSpan>
                <Alert type="danger" alert={state.message} />
              </Col>
            )}
          </Grid>
        </form>
      </Dialog>
    </>
  );
}
