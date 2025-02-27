"use client";

import { editLeagueAdmin, removeLeagueAdmin } from "@/actions/leagueAdmins";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Select from "@/components/ui/forms/Select";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import Table from "@/components/ui/Table/Table";
import { league_roles, league_roles_options } from "@/lib/definitions";
import { nameDisplay } from "@/utils/helpers/formatting";
import { useActionState, useEffect, useRef, useState } from "react";
import LeagueAdminsAdd from "./LeagueAdminsAdd/LeagueAdminsAdd";

interface LeagueAdminsProps {
  league: LeagueData;
  admins?: LeagueAdminData[];
}

export default function LeagueAdmins({ league, admins }: LeagueAdminsProps) {
  const editDialogRef = useRef<HTMLDialogElement>(null);
  const removeDialogRef = useRef<HTMLDialogElement>(null);
  const [editState, editAction, editPending] = useActionState(
    editLeagueAdmin,
    undefined,
  );
  const [removeState, removeAction, removePending] = useActionState(
    removeLeagueAdmin,
    undefined,
  );

  const [adminsList, setAdminsList] = useState<LeagueAdminData[]>(admins || []);
  const [adminToEdit, setAdminToEdit] = useState<LeagueAdminData | undefined>(
    () => {
      if (admins) {
        return admins[0];
      }
      return undefined;
    },
  );

  useEffect(() => {
    if (editState?.status === 200 && admins) {
      // success route, update list of admins

      // find the admin that was changed and update role
      const updatedAdmins = admins.map((a) => {
        if (
          a.league_admin_id === editState.data.league_admin_id &&
          editState.data.league_role
        ) {
          a.league_role = editState.data.league_role;
        }

        return a;
      });

      // set updated list to be displayed
      setAdminsList(updatedAdmins);

      // close dialog
      editDialogRef?.current?.close();
    }
  }, [editState, admins]);

  useEffect(() => {
    if (removeState?.status === 200 && admins) {
      // success route, update list of admins

      // filter out the removed admin
      const updatedAdmins = admins.filter(
        (a) => a.league_admin_id !== removeState.data.league_admin_id,
      );

      setAdminToEdit(updatedAdmins[0]);
      // set updated list to be displayed
      setAdminsList(updatedAdmins);

      // close dialog
      removeDialogRef?.current?.close();
    }
  }, [removeState, admins]);

  const tableHeadings = [
    { title: "Name", highlightCol: true },
    { title: "Role" },
    { title: "Edit" },
    { title: "Remove" },
  ];

  function updateAdmin(index: number, remove?: boolean) {
    setAdminToEdit(adminsList[index]);

    if (remove) {
      removeDialogRef?.current?.showModal();
    } else {
      editDialogRef?.current?.showModal();
    }
  }

  return (
    <>
      <Table className="push-l">
        <thead>
          <tr>
            {tableHeadings.map((th) => (
              <th
                key={th.title}
                scope="col"
                data-highlight-col={th.highlightCol}
              >
                {th.title}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {adminsList && adminsList.length > 0 ? (
            adminsList.map((a, i) => (
              <tr key={a.user_id}>
                <th>{nameDisplay(a.first_name, a.last_name, "full", true)}</th>
                <td>{league_roles.get(a.league_role)?.title}</td>
                <td>
                  <Button
                    style={{ position: "relative" }}
                    variant="grey"
                    onClick={() => updateAdmin(i)}
                  >
                    <Icon icon="edit_square" label="Edit admin" hideLabel />
                  </Button>
                </td>
                <td>
                  <Button
                    style={{ position: "relative" }}
                    variant="danger"
                    onClick={() => updateAdmin(i, true)}
                  >
                    <Icon icon="delete" label="Remove admin" hideLabel />
                  </Button>
                </td>
              </tr>
            ))
          ) : (
            <tr>
              <td colSpan={4}>
                <Alert
                  alert="This league does not have any admins!"
                  type="grey"
                />
              </td>
            </tr>
          )}
        </tbody>
      </Table>
      {adminToEdit && (
        <>
          <Dialog ref={editDialogRef}>
            <form action={editAction}>
              <Grid cols={2} gap="base">
                <Col fullSpan>
                  <h3>Update {adminToEdit.first_name}&apos;s admin role.</h3>
                </Col>
                <Col fullSpan>
                  <Select
                    name="league_role"
                    label="League Role"
                    choices={league_roles_options}
                    selected={adminToEdit.league_role}
                    required
                  />
                </Col>
                <input
                  type="hidden"
                  name="league_admin_id"
                  value={adminToEdit.league_admin_id}
                />
                {editState?.message && editState?.status !== 200 && (
                  <Col fullSpan>
                    <Alert alert={editState.message} type="danger" />
                  </Col>
                )}
                <Button type="submit" disabled={editPending}>
                  <Icon icon="save" label="Confirm" />
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
                  <h3>
                    Are you sure you want to remove {adminToEdit.first_name}?
                  </h3>
                </Col>
                <input
                  type="hidden"
                  name="league_admin_id"
                  value={adminToEdit.league_admin_id}
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
      <LeagueAdminsAdd league={league} />
    </>
  );
}
