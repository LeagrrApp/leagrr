"use client";

import {
  editPlayerOnDivisionTeam,
  removePlayerFromDivisionTeam,
} from "@/actions/teamMemberships";
import Alert from "@/components/ui/Alert/Alert";
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
  convert_roles_to_select_choices,
  createDashboardUrl,
  makeAcronym,
  nameDisplay,
} from "@/utils/helpers/formatting";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useActionState, useEffect, useRef, useState } from "react";

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
  const [teamMemberToEdit, setTeamMemberToEdit] = useState<
    TeamUserData | undefined
  >(teamMembers[0]);
  const [rosterRoleValue, setRosterRoleValue] = useState<number | undefined>(
    teamMemberToEdit?.roster_role,
  );
  const [editState, editAction, editPending] = useActionState(
    editPlayerOnDivisionTeam,
    {
      link: pathname,
      data: {},
    },
  );
  const [removeState, removeAction, removePending] = useActionState(
    removePlayerFromDivisionTeam,
    {
      link: pathname,
      data: {},
    },
  );

  useEffect(() => {
    if (teamMemberToEdit) setRosterRoleValue(teamMemberToEdit.roster_role);
  }, [teamMemberToEdit]);

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

  const playerColHeaders = [
    { title: "Name", highlightCol: true },
    { title: "Pronouns" },
    { title: "Gender" },
    { title: "Position", shorthand: "Pos" },
    { title: "Number", shorthand: "Num" },
    { title: "Edit" },
    { title: "Remove" },
  ];

  const playerHColWidth = 20;
  const playerColWidth = `${(100 - playerHColWidth) / playerColHeaders.length - 1}%`;

  const players = teamMembers.filter(
    (p) => p.roster_role !== 1 && p.roster_role !== 5,
  );

  const spares = teamMembers.filter((p) => p.roster_role === 5);

  const coachColHeaders = [
    { title: "Name", highlightCol: true },
    { title: "Pronouns" },
    { title: "Gender" },
    { title: "Edit" },
    { title: "Remove" },
  ];

  const coachHColWidth = 42;
  const coachColWidth = `${(100 - coachHColWidth) / coachColHeaders.length - 1}%`;

  const coaches = teamMembers.filter((p) => p.roster_role === 1);

  const rosterRoleOptions = convert_roles_to_select_choices(roster_roles);

  return (
    <>
      <h3 className="push">Active Roster</h3>
      {coaches && coaches.length >= 1 && (
        <>
          <h4 className="push-m">Coaches</h4>
          <Table
            className="push-l"
            hColWidth={`${coachHColWidth}%`}
            colWidth={coachColWidth}
          >
            <thead>
              <tr>
                {coachColHeaders.map((th) => (
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
              {coaches.map((p) => {
                return (
                  <tr key={p.username}>
                    <th scope="row">
                      <Link href={createDashboardUrl({ u: p.username })}>
                        {nameDisplay(p.first_name, p.last_name, "full")}
                      </Link>{" "}
                    </th>
                    <td>{p.pronouns}</td>
                    <td>{p.gender}</td>
                    <td>
                      <Button
                        style={{ position: "relative" }}
                        variant="grey"
                        onClick={() => handleClick(p.user_id)}
                      >
                        <Icon icon="edit_square" label="Edit" hideLabel />
                      </Button>
                    </td>
                    <td>
                      <Button
                        style={{ position: "relative" }}
                        variant="danger"
                        onClick={() => handleClick(p.user_id, true)}
                      >
                        <Icon icon="person_remove" label="Remove" hideLabel />
                      </Button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </Table>
        </>
      )}
      {players && players.length >= 1 && (
        <>
          <h4 className="push-m">Players</h4>
          <Table
            className="push-l"
            hColWidth={`${playerHColWidth}%`}
            colWidth={playerColWidth}
          >
            <thead>
              <tr>
                {playerColHeaders.map((th) => (
                  <th
                    key={th.title}
                    scope="col"
                    title={th.shorthand ? th.title : undefined}
                    data-highlight-col={th.highlightCol ? true : undefined}
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
              {players.map((p) => {
                const isCaptain = p.roster_role === 2;
                const isAlternateCaptain = p.roster_role === 3;

                return (
                  <tr key={p.username}>
                    <th scope="row">
                      <Link href={createDashboardUrl({ u: p.username })}>
                        {nameDisplay(p.first_name, p.last_name, "full")}
                      </Link>{" "}
                      {isCaptain && <strong title="Captain">(C)</strong>}
                      {isAlternateCaptain && (
                        <strong title="Alternate Captain">(A)</strong>
                      )}
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
                        <Icon icon="edit_square" label="Edit" hideLabel />
                      </Button>
                    </td>
                    <td>
                      <Button
                        style={{ position: "relative" }}
                        variant="danger"
                        onClick={() => handleClick(p.user_id, true)}
                      >
                        <Icon icon="person_remove" label="Remove" hideLabel />
                      </Button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </Table>
        </>
      )}
      {spares && spares.length >= 1 && (
        <>
          <h4 className="push-m">Spares</h4>
          <Table hColWidth={`${playerHColWidth}%`} colWidth={playerColWidth}>
            <thead>
              <tr>
                {playerColHeaders.map((th) => (
                  <th
                    key={th.title}
                    scope="col"
                    title={th.shorthand ? th.title : undefined}
                    data-highlight-col={th.highlightCol ? true : undefined}
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
              {spares.map((p) => {
                const isCaptain = p.roster_role === 2;
                const isAlternateCaptain = p.roster_role === 3;

                return (
                  <tr key={p.username}>
                    <th scope="row">
                      <Link href={createDashboardUrl({ u: p.username })}>
                        {nameDisplay(p.first_name, p.last_name, "full")}
                      </Link>{" "}
                      {isCaptain && <strong title="Captain">(C)</strong>}
                      {isAlternateCaptain && (
                        <strong title="Alternate Captain">(A)</strong>
                      )}
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
                        <Icon icon="edit_square" label="Edit" hideLabel />
                      </Button>
                    </td>
                    <td>
                      <Button
                        style={{ position: "relative" }}
                        variant="danger"
                        onClick={() => handleClick(p.user_id, true)}
                      >
                        <Icon icon="person_remove" label="Remove" hideLabel />
                      </Button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </Table>
        </>
      )}
      {teamMemberToEdit && (
        <>
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
                <Col fullSpan>
                  <Select
                    name="roster_role"
                    label="Roster Role"
                    choices={rosterRoleOptions}
                    errors={{
                      errs: editState?.errors?.roster_role,
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
                      defaultValue={teamMemberToEdit?.number?.toString()}
                      errors={{
                        errs: editState?.errors?.number,
                        type: "danger",
                      }}
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
                      errors={{
                        errs: editState?.errors?.position,
                        type: "danger",
                      }}
                      selected={teamMemberToEdit.position}
                    />
                  </>
                )}
                {editState?.message && editState?.status !== 200 && (
                  <Col fullSpan>
                    <Alert alert={editState.message} type="danger" />
                  </Col>
                )}
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
                {removeState?.message && removeState?.status !== 200 && (
                  <Col fullSpan>
                    <Alert alert={removeState.message} type="danger" />
                  </Col>
                )}
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
      )}
    </>
  );
}
