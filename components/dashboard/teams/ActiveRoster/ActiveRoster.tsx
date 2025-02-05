"use client";

import {
  editPlayerOnDivisionTeam,
  removePlayerFromDivisionTeam,
} from "@/actions/teams";
import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import Table from "@/components/ui/Table/Table";
import { makeAcronym, nameDisplay } from "@/utils/helpers/formatting";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useActionState, useRef, useState } from "react";

interface ActiveRosterProps {
  team_id: number;
  teamMembers: TeamUserData[];
}

export default function ActiveRoster({
  team_id,
  teamMembers,
}: ActiveRosterProps) {
  const pathname = usePathname();

  const editDialogRef = useRef<HTMLDialogElement>(null);
  const removeDialogRef = useRef<HTMLDialogElement>(null);
  const [teamMemberToEdit, setTeamMemberToEdit] = useState<TeamUserData>(
    teamMembers[0],
  );
  const [editState, editAction, editPending] = useActionState(
    editPlayerOnDivisionTeam,
    {
      link: pathname,
    },
  );
  const [removeState, removeAction, removePending] = useActionState(
    removePlayerFromDivisionTeam,
    {
      link: pathname,
    },
  );

  function handleClick(user_id: number, remove?: boolean) {
    const teamMember = teamMembers.find((tm) => tm.user_id === user_id);

    if (!teamMember) return;

    setTeamMemberToEdit(teamMember);

    if (!remove) {
      editDialogRef?.current?.showModal();
    } else {
      removeDialogRef?.current?.showModal();
    }
  }

  const activeHeaders = [
    { title: "Name" },
    { title: "Pronouns" },
    { title: "Gender" },
    { title: "Position", shorthand: "Pos" },
    { title: "Number", shorthand: "Num" },
    { title: "Edit" },
    { title: "Remove" },
  ];

  return (
    <>
      <h3>Active Roster</h3>
      <p className="push-m">
        These players are currently active as part of the current division.
      </p>
      {teamMembers && teamMembers.length > 1 && (
        <Table>
          <thead>
            <tr>
              {activeHeaders.map((th) => (
                <th
                  key={th.title}
                  scope="col"
                  title={th.shorthand ? th.title : undefined}
                >
                  {th.shorthand ? (
                    <span aria-hidden="true">{th.shorthand}</span>
                  ) : (
                    <>{th.title}</>
                  )}
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
                  <td title={p.position}>{makeAcronym(p.position || "")}</td>
                  <td>{p.number}</td>
                  <td>
                    <Button
                      style={{ position: "relative" }}
                      variant="grey"
                      onClick={() => handleClick(p.user_id)}
                    >
                      <Icon icon="edit" label="Edit" hideLabel />
                    </Button>
                  </td>
                  <td>
                    <Button
                      style={{ position: "relative" }}
                      variant="danger"
                      onClick={() => handleClick(p.user_id, true)}
                    >
                      <Icon icon="delete" label="Remove" hideLabel />
                    </Button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </Table>
      )}
      <Dialog ref={editDialogRef}>
        <form action={editAction}>
          <Grid cols={2} gap="base">
            <Col fullSpan>
              <h3>Edit {teamMemberToEdit?.first_name}</h3>
            </Col>
            <input type="hidden" name="team_id" value={team_id} />
            <input
              type="hidden"
              name="division_roster_id"
              value={teamMemberToEdit.division_roster_id}
            />
            <Input
              name="number"
              label="Number"
              type="number"
              min="1"
              max="98"
              defaultValue={teamMemberToEdit.number.toString()}
              errors={{ errs: editState?.errors?.number, type: "danger" }}
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
              errors={{ errs: editState?.errors?.position, type: "danger" }}
              selected={teamMemberToEdit.position}
            />
            <Button type="submit" disabled={editPending}>
              <Icon icon="save" label="Save" />
            </Button>
            <Button
              onClick={() => editDialogRef?.current?.close()}
              variant="grey"
            >
              <Icon icon="cancel" label="Cancel" />
            </Button>
          </Grid>
        </form>
      </Dialog>
      <Dialog ref={removeDialogRef}>
        <form action={removeAction}>
          <Grid cols={2} gap="base">
            <Col fullSpan>
              <h3>Remove {teamMemberToEdit?.first_name}?</h3>
            </Col>
            <input type="hidden" name="team_id" value={team_id} />
            <input
              type="hidden"
              name="division_roster_id"
              value={teamMemberToEdit.division_roster_id}
            />
            <Button type="submit" disabled={removePending} variant="danger">
              <Icon icon="delete" label="Confirm" />
            </Button>
            <Button
              onClick={() => removeDialogRef?.current?.close()}
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
