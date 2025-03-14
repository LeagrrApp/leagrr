"use client";

import { editUserAsAdmin } from "@/actions/users";
import Alert from "@/components/ui/Alert/Alert";
import Badge from "@/components/ui/Badge/Badge";
import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import Loader from "@/components/ui/Loader/Loader";
import PaginationControls from "@/components/ui/PaginationControls/PaginationControls";
import Table from "@/components/ui/Table/Table";
import { Truncate } from "@/components/ui/Truncate/Truncate";
import {
  user_roles,
  user_roles_options,
  user_status_options,
} from "@/lib/definitions";
import {
  applyStatusColor,
  createDashboardUrl,
} from "@/utils/helpers/formatting";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { useActionState, useEffect, useRef, useState } from "react";
import css from "../admin.module.css";

export default function UserList() {
  const searchParams = useSearchParams();

  const editDialogRef = useRef<HTMLDialogElement>(null);

  const [editState, editAction, editPending] = useActionState(
    editUserAsAdmin,
    undefined,
  );

  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | undefined>(undefined);
  const [userList, setUserList] = useState<UserData[]>([]);
  const [userToEdit, setUserToEdit] = useState<UserData | undefined>(undefined);
  const [count, setCount] = useState<number>(0);
  const [page, setPage] = useState<number>(
    parseInt(searchParams.get("page") || "1"),
  );
  const [perPage, setPerPage] = useState<number>(
    parseInt(searchParams.get("perPage") || "10"),
  );
  const [userRole, setUserRole] = useState<number>(
    parseInt(searchParams.get("user_role") || "0"),
  );
  const [userStatus, setUserStatus] = useState<string>(
    searchParams.get("status") || "all",
  );
  const [searchValue, setSearchValue] = useState<string>(
    searchParams.get("search") || "",
  );

  useEffect(() => {
    (async () => {
      // clone read only search params to allow updating
      const updateAbleSearchParams = new URLSearchParams(searchParams);

      // update perPage query param
      updateAbleSearchParams.set("page", page.toString());

      // check if a perPage is included
      if (!updateAbleSearchParams.has("perPage")) {
        updateAbleSearchParams.set("perPage", "10");
      }

      const response = await fetch(
        `/api/u?${updateAbleSearchParams.toString()}`,
      );

      const { data, message } = await response.json();

      if (data) {
        setUserList(data.users);
        setCount(data.total);
      } else {
        setError(message);
      }
      setLoading(false);
    })();
  }, [page, searchParams]);

  useEffect(() => {
    setPage(parseInt(searchParams.get("page") || "1"));
  }, [searchParams]);

  useEffect(() => {
    if (userList[0]) {
      setUserToEdit(userList[0]);
    } else {
      setUserToEdit(undefined);
    }
  }, [userList]);

  useEffect(() => {
    if (!userToEdit) return;
    if (editState && editState.status === 200) {
      const { user_id, status, user_role } = editState.data;

      const userIndex = userList.findIndex((u) => u.user_id === user_id);

      const updatedUserData: UserData = { ...userToEdit };

      if (status) updatedUserData.status = status;
      if (user_role) updatedUserData.user_role = user_role;

      const userListClone = [
        ...userList.slice(0, userIndex),
        updatedUserData,
        ...userList.slice(userIndex + 1),
      ];

      setUserList(userListClone);
      editDialogRef?.current?.close();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [editState]);

  function handleClick(user_id: number) {
    const user = userList.find((tm) => tm.user_id === user_id);

    if (!user) return;

    setUserToEdit(user);

    editDialogRef?.current?.showModal();
  }

  if (loading) {
    return <Loader centered />;
  }

  if (error) {
    return (
      <div>
        <Alert alert={error} type="danger" />
      </div>
    );
  }

  const tableHeadings = [
    { title: "Username", highlightCol: true },
    { title: "First Name" },
    { title: "Last Name" },
    { title: "Email" },
    { title: "Role" },
    { title: "Status" },
    { title: "Edit" },
  ];

  const hColWidth = 5;
  const colWidth = `${(100 - hColWidth) / tableHeadings.length - 1}%`;

  return (
    <>
      <div className={css.layout}>
        <form className={css.filters}>
          <Input
            type="search"
            name="search"
            label="Search"
            value={searchValue}
            onChange={(e) => setSearchValue(e.target.value)}
            placeholder="Ex: Jesse Doe"
          />
          <Select
            id="filter_user_role"
            name="user_role"
            label="Role"
            choices={[{ label: "All", value: 0 }, ...user_roles_options]}
            selected={userRole}
          />
          <Select
            id="filter_status"
            name="status"
            label="Status"
            choices={["all", ...user_status_options]}
            selected={userStatus}
          />
          <Select
            name="perPage"
            label="Per Page"
            choices={["10", "15", "20", "25", "50", "100"]}
            selected={perPage}
          />
          <Button type="submit">
            <Icon icon="filter_alt" label="Apply" gap="m" />
          </Button>
          <Button
            href={createDashboardUrl({ admin: "u" })}
            variant="grey"
            onClick={() => {
              setPerPage(10);
              setUserRole(0);
              setUserStatus("all");
              setSearchValue("");
            }}
          >
            <Icon icon="cancel" label="Reset" gap="m" />
          </Button>
        </form>
        <div>
          <Table hColWidth={`${hColWidth}`} colWidth={colWidth}>
            <thead>
              <tr>
                {tableHeadings.map((th) => (
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
              {userList.length > 0 ? (
                userList.map((user) => {
                  const {
                    user_id,
                    username,
                    last_name,
                    first_name,
                    email,
                    user_role,
                    status,
                  } = user;

                  return (
                    <tr key={user_id}>
                      <th scope="row">
                        <Link href={createDashboardUrl({ u: username })}>
                          @{username}
                        </Link>
                      </th>
                      <td>{last_name}</td>
                      <td>{first_name}</td>
                      <td title={email}>
                        <Truncate>{email}</Truncate>
                      </td>
                      <td>{user_roles.get(user_role)?.title}</td>
                      <td>
                        <Badge text={status} type={applyStatusColor(status)} />
                      </td>
                      <td>
                        <Button
                          style={{ position: "relative" }}
                          variant="grey"
                          onClick={() => handleClick(user_id)}
                        >
                          <Icon icon="edit_square" label="Remove" hideLabel />
                        </Button>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={tableHeadings.length}>No users found!</td>
                </tr>
              )}
            </tbody>
          </Table>
        </div>
        <PaginationControls
          page={page}
          perPage={perPage}
          total={count}
          baseUrl={createDashboardUrl({ admin: "u" })}
        />
      </div>
      {userToEdit && (
        <Dialog ref={editDialogRef}>
          <form action={editAction}>
            <Grid cols={2} gap="base">
              <Col fullSpan>
                <h3>
                  Edit {userToEdit.first_name} {userToEdit.last_name}
                </h3>
              </Col>
              <Select
                name="user_role"
                label="Role"
                choices={user_roles_options}
                selected={userToEdit.user_role}
              />
              <Select
                name="status"
                label="Status"
                choices={user_status_options}
                selected={userToEdit.status}
              />
              <input type="hidden" name="user_id" value={userToEdit.user_id} />
              {editState?.message && editState?.status === 400 && (
                <Col fullSpan>
                  <Alert alert={editState.message} type="danger" />
                </Col>
              )}
              <Button type="submit" disabled={editPending}>
                <Icon icon="save" label="Update" />
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
      )}
    </>
  );
}
