"use client";

import { createLeagueAdmin } from "@/actions/leagueAdmins";
import UserSearch from "@/components/dashboard/user/UserSearch/UserSearch";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Select from "@/components/ui/forms/Select";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import Table from "@/components/ui/Table/Table";
import { league_roles_options } from "@/lib/definitions";
import { createDashboardUrl, nameDisplay } from "@/utils/helpers/formatting";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useActionState, useRef, useState } from "react";

interface LeagueAdminsAddProps {
  league: LeagueData;
}

export default function LeagueAdminsAdd({ league }: LeagueAdminsAddProps) {
  const pathname = usePathname();
  const dialogRef = useRef<HTMLDialogElement>(null);

  const [state, action, pending] = useActionState(createLeagueAdmin, {
    link: pathname,
    data: {},
  });
  const [searchResult, setSearchResult] = useState<{
    users?: UserData[];
    count?: number;
    complete: boolean;
  }>({
    complete: false,
  });
  const [userToAdd, setUserToAdd] = useState<UserData | undefined>(undefined);

  // TODO: filter out existing admins from search results

  function handleAdd(user_id: number) {
    if (searchResult.users) {
      const userSelected = searchResult.users.find(
        (u) => u.user_id === user_id,
      );
      setUserToAdd(userSelected);
      dialogRef?.current?.showModal();
    }
  }

  return (
    <>
      <h3 className="type-scale-h4 push">Add User As Admin</h3>
      <div className="push">
        <UserSearch setSearchResult={setSearchResult} />
      </div>
      {searchResult.complete && (
        <>
          <h4 className="type-scale-h5 push-m">Found Users</h4>
          {searchResult.users && searchResult.count ? (
            <Table>
              <thead>
                <tr>
                  <th scope="col" data-highlight-col>
                    Name
                  </th>
                  <th scope="col" colSpan={3}>
                    Username
                  </th>
                  <th scope="col">Add</th>
                </tr>
              </thead>
              <tbody>
                {searchResult.users.map((u) => (
                  <tr key={`${u.user_id}-${u.username}`}>
                    <th scope="row">
                      {nameDisplay(u.first_name, u.last_name, "full", true)}{" "}
                    </th>
                    <td colSpan={3}>
                      <Link href={createDashboardUrl({ u: u.username })}>
                        @{u.username}
                      </Link>
                    </td>
                    <td>
                      <Button
                        style={{ position: "relative" }}
                        variant="grey"
                        onClick={() => handleAdd(u.user_id)}
                      >
                        <Icon icon="person_add" label="Add" />
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </Table>
          ) : (
            <p>Sorry, no users found.</p>
          )}
        </>
      )}
      {searchResult.users && (
        <Dialog ref={dialogRef}>
          <form action={action}>
            <Grid cols={2} gap="base">
              <Col fullSpan>
                <h2>
                  Are you sure you want to add {userToAdd?.first_name} as a
                  league admin?
                </h2>
              </Col>
              {userToAdd && (
                <input type="hidden" name="user_id" value={userToAdd.user_id} />
              )}
              <input type="hidden" name="league_id" value={league.league_id} />
              <Col fullSpan>
                <Select
                  name="league_role"
                  label="League Role"
                  choices={league_roles_options}
                  selected={2}
                  required
                />
              </Col>
              {state?.message && state?.status !== 200 && (
                <Col fullSpan>
                  <Alert alert={state.message} type="danger" />
                </Col>
              )}
              <Button type="submit" disabled={pending}>
                <Icon icon="person_add" label="Confirm" />
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
      )}
    </>
  );
}
