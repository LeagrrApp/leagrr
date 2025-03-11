"use client";

import Alert from "@/components/ui/Alert/Alert";
import Badge from "@/components/ui/Badge/Badge";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import Icon from "@/components/ui/Icon/Icon";
import Loader from "@/components/ui/Loader/Loader";
import PaginationControls from "@/components/ui/PaginationControls/PaginationControls";
import Table from "@/components/ui/Table/Table";
import { Truncate } from "@/components/ui/Truncate/Truncate";
import { user_roles, user_roles_options } from "@/lib/definitions";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";
import css from "./userList.module.css";

export default function UserList() {
  const searchParams = useSearchParams();

  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | undefined>(undefined);
  const [userList, setUserList] = useState<UserData[]>([]);
  const [count, setCount] = useState<number>(0);
  const [page, setPage] = useState<number>(
    parseInt(searchParams.get("page") || "1"),
  );
  const [perPage, setPerPage] = useState<number>(
    parseInt(searchParams.get("perPage") || "15"),
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
        updateAbleSearchParams.set("perPage", "15");
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

  const tableHeadings = [
    { title: "Username" },
    { title: "First Name" },
    { title: "Last Name" },
    { title: "Email" },
    { title: "Role" },
    { title: "Status" },
    { title: "Edit" },
  ];

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

  return (
    <div className={css.layout}>
      <form className={css.filters}>
        <Input
          type="search"
          name="search"
          label="Search"
          value={searchValue}
          onChange={(e) => setSearchValue(e.target.value)}
        />
        <Select
          name="user_role"
          label="Role"
          choices={[{ label: "All", value: 0 }, ...user_roles_options]}
          selected={userRole}
        />
        <Select
          name="status"
          label="Status"
          choices={["all", "active", "inactive", "suspended", "banned"]}
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
            setPerPage(15);
            setUserRole(0);
          }}
        >
          <Icon icon="cancel" label="Reset" gap="m" />
        </Button>
      </form>
      <div>
        <Table>
          <thead>
            <tr>
              {tableHeadings.map((th) => (
                <th key={th.title} scope="col">
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

                let badgeColor: ColorOptions | undefined;

                switch (status) {
                  case "inactive":
                    badgeColor = "warning";
                    break;
                  case "suspended":
                    badgeColor = "caution";
                    break;
                  case "banned":
                    badgeColor = "danger";
                    break;
                  default:
                    badgeColor = "primary";
                    break;
                }

                return (
                  <tr key={user_id}>
                    <th scope="row">{username}</th>
                    <td>{last_name}</td>
                    <td>{first_name}</td>
                    <td title={email}>
                      <Truncate>{email}</Truncate>
                    </td>
                    <td>{user_roles.get(user_role)?.title}</td>
                    <td>
                      <Badge text={status} type={badgeColor} />
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
  );
}
