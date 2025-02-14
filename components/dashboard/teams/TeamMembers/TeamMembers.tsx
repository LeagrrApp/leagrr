"use client";

import { editTeamMembership, removeTeamMembership } from "@/actions/teams";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Select from "@/components/ui/forms/Select";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import Table from "@/components/ui/Table/Table";
import { team_roles } from "@/lib/definitions";
import { createDashboardUrl, nameDisplay } from "@/utils/helpers/formatting";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useActionState, useRef, useState } from "react";

interface TeamMembersProps {
  team_id: number;
  teamMembers: TeamUserData[];
  canEdit: boolean;
}

export default function TeamMembers({
  team_id,
  teamMembers,
  canEdit,
}: TeamMembersProps) {
  const pathname = usePathname();

  const editDialogRef = useRef<HTMLDialogElement>(null);
  const removeDialogRef = useRef<HTMLDialogElement>(null);
  const [teamMemberToEdit, setTeamMemberToEdit] = useState<
    TeamUserData | undefined
  >(teamMembers[0]);
  const [editState, editAction, editPending] = useActionState(
    editTeamMembership,
    {
      link: pathname,
      data: {},
    },
  );
  const [removeState, removeAction, removePending] = useActionState(
    removeTeamMembership,
    {
      link: pathname,
      data: {},
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

  let colHeaders = [
    { title: "Name", highlightCol: true },
    { title: "Pronouns" },
    { title: "Gender" },
    { title: "Team Role" },
    { title: "Joined" },
  ];

  if (canEdit) {
    colHeaders = [...colHeaders, ...[{ title: "Edit" }, { title: "Remove" }]];
  }

  const hColWidth = 20;
  const colWidth = `${(100 - hColWidth) / colHeaders.length - 1}%`;

  return (
    <>
      {teamMembers && teamMembers.length >= 1 ? (
        // <Table hColWidth={`${hColWidth}%`} colWidth={colWidth}>
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
            {teamMembers.map((p) => {
              const joined = p.joined
                ? p.joined.toLocaleDateString("en-CA", {
                    month: "short",
                    day: "2-digit",
                    year: "numeric",
                  })
                : "";

              const role = p.team_role && team_roles.get(p.team_role)?.title;

              return (
                <tr key={p.username}>
                  <th scope="row">
                    <Link href={createDashboardUrl({ u: p.username })}>
                      {nameDisplay(p.first_name, p.last_name, "full")}
                    </Link>
                  </th>
                  <td>{p.pronouns}</td>
                  <td>{p.gender}</td>
                  <td>{role === "Manager" ? <strong>{role}</strong> : role}</td>
                  <td>{joined}</td>
                  {canEdit && (
                    <>
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
                    </>
                  )}
                </tr>
              );
            })}
          </tbody>
        </Table>
      ) : (
        <p>
          This team has no members. Use the team invite join code to invite new
          members!
        </p>
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
                  name="team_membership_id"
                  value={teamMemberToEdit.team_membership_id}
                />
                <Col fullSpan>
                  <Select
                    name="team_role"
                    label="Team Role"
                    choices={[
                      { label: "Manager", value: 1 },
                      { label: "Member", value: 2 },
                    ]}
                    errors={{
                      errs: editState?.errors?.team_role,
                      type: "danger",
                    }}
                    selected={teamMemberToEdit.team_role}
                  />
                </Col>
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
                  name="team_membership_id"
                  value={teamMemberToEdit.team_membership_id}
                />
                {removeState?.message && removeState?.status === 400 && (
                  <Alert alert={removeState.message} type="danger" />
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
