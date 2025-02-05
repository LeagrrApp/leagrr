"use client";

import { addPlayerToDivisionTeam } from "@/actions/teams";
import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import Table from "@/components/ui/Table/Table";
import { nameDisplay } from "@/utils/helpers/formatting";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useActionState, useRef, useState } from "react";

interface InactiveRosterProps {
  team_id: number;
  teamMembers: TeamUserData[];
  division_team_id: number;
}

export default function InactiveRoster({
  team_id,
  teamMembers,
  division_team_id,
}: InactiveRosterProps) {
  const pathname = usePathname();

  const dialogRef = useRef<HTMLDialogElement>(null);
  const [teamMemberToActivate, setTeamMemberToActivate] =
    useState<TeamUserData>(teamMembers[0]);
  const [state, action, pending] = useActionState(addPlayerToDivisionTeam, {
    link: pathname,
  });

  function handleClick(user_id: number) {
    const teamMember = teamMembers.find((tm) => tm.user_id === user_id);

    if (!teamMember) return;

    setTeamMemberToActivate(teamMember);

    dialogRef?.current?.showModal();
  }

  const inActiveHeaders = [
    { title: "Name" },
    { title: "Pronouns" },
    { title: "Gender" },
    { title: "Add" },
  ];

  return (
    <>
      <h3>Inactive Team Members</h3>
      <p className="push-m">
        These team members are not currently active in this division.
      </p>
      {teamMembers && teamMembers.length > 0 && (
        <Table className="push-l">
          <thead>
            <tr>
              {inActiveHeaders.map((th) => (
                <th key={th.title} scope="col">
                  {th.title}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {teamMembers.map((p) => {
              return (
                <tr key={p.username}>
                  <th scope="row">
                    <Link href={`/dashboard/u/${p.username}`}>
                      {nameDisplay(p.first_name, p.last_name, "full")}
                    </Link>
                  </th>
                  <td>{p.pronouns}</td>
                  <td>{p.gender}</td>
                  <td>
                    <Button
                      onClick={() => handleClick(p.user_id)}
                      style={{ position: "relative" }}
                    >
                      <Icon icon="add_circle" label="Activate" />
                    </Button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </Table>
      )}
      <Dialog ref={dialogRef}>
        <form action={action}>
          <Grid cols={2} gap="base">
            <Col fullSpan>
              <h3>Activate {teamMemberToActivate?.first_name}</h3>
            </Col>
            <input type="hidden" name="team_id" value={team_id} />
            <input
              type="hidden"
              name="team_membership_id"
              value={teamMemberToActivate?.team_membership_id}
            />
            <input
              type="hidden"
              name="division_team_id"
              value={division_team_id}
            />
            <Input
              name="number"
              label="Number"
              type="number"
              min="1"
              max="98"
              defaultValue="1"
              errors={{ errs: state?.errors?.number, type: "danger" }}
            />
            <Select
              name="position"
              label="Position"
              choices={[
                "Center",
                "Right Wing",
                "Left Wing",
                "Defense",
                "Goalie",
              ]}
              errors={{ errs: state?.errors?.position, type: "danger" }}
            />
            <Button type="submit" disabled={pending}>
              <Icon icon="add_circle" label="Activate" />
            </Button>
            <Button onClick={() => dialogRef?.current?.close()} variant="grey">
              <Icon icon="cancel" label="Cancel" />
            </Button>
          </Grid>
        </form>
      </Dialog>
    </>
  );
}
