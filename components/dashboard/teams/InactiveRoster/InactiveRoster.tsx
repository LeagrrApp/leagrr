"use client";

import { addPlayerToDivisionTeam } from "@/actions/teamMemberships";
import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import Table from "@/components/ui/Table/Table";
import { roster_roles } from "@/lib/definitions";
import {
  convertRolesToChoices,
  createDashboardUrl,
  nameDisplay,
} from "@/utils/helpers/formatting";
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
  const [teamMemberToActivate, setTeamMemberToActivate] = useState<
    TeamUserData | undefined
  >(teamMembers[0]);
  const [state, action, pending] = useActionState(addPlayerToDivisionTeam, {
    link: pathname,
    data: {},
  });
  const [rosterRoleValue, setRosterRoleValue] = useState<number>(4);

  function handleClick(user_id: number) {
    const teamMember = teamMembers.find((tm) => tm.user_id === user_id);

    if (!teamMember) return;

    setTeamMemberToActivate(teamMember);

    dialogRef?.current?.showModal();
  }

  const colHeaders = [
    { title: "Name", highlightCol: true },
    { title: "Pronouns" },
    { title: "Gender" },
    { title: "Add" },
  ];

  const hColWidth = 40;
  const colWidth = `${(100 - hColWidth) / colHeaders.length - 1}%`;

  const rosterRoleOptions = convertRolesToChoices(roster_roles);

  return (
    <>
      <h3>Inactive Team Members</h3>
      {teamMembers && teamMembers.length > 0 ? (
        <>
          <p className="push-m">
            These team members are not currently active in this division.
          </p>
          <Table
            className="push-l"
            hColWidth={`${hColWidth}%`}
            colWidth={colWidth}
          >
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
              {teamMembers.map((p) => {
                return (
                  <tr key={p.username}>
                    <th scope="row">
                      <Link href={createDashboardUrl({ u: p.username })}>
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
                        <Icon icon="person_add" label="Add" hideLabel />
                      </Button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </Table>
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
                <Col fullSpan>
                  <Select
                    name="roster_role"
                    label="Roster Role"
                    choices={rosterRoleOptions}
                    errors={{
                      errs: state?.errors?.roster_role,
                      type: "danger",
                    }}
                    selected={rosterRoleValue}
                    onChange={(e) =>
                      setRosterRoleValue(parseInt(e.target.value))
                    }
                  />
                </Col>
                {rosterRoleValue !== 1 && (
                  <>
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
                  </>
                )}
                <Button type="submit" disabled={pending}>
                  <Icon icon="add_circle" label="Activate" />
                </Button>
                <Button
                  onClick={() => dialogRef?.current?.close()}
                  variant="grey"
                >
                  <Icon icon="cancel" label="Cancel" />
                </Button>
              </Grid>
            </form>
          </Dialog>
        </>
      ) : (
        <p>There are currently no inactive team members!</p>
      )}
    </>
  );
}
