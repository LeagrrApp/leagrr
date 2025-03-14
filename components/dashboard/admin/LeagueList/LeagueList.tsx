"use client";

import { editLeagueAsAdmin } from "@/actions/leagues";
import Alert from "@/components/ui/Alert/Alert";
import Badge from "@/components/ui/Badge/Badge";
import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import Icon from "@/components/ui/Icon/Icon";
import IconSport from "@/components/ui/Icon/IconSport";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import Loader from "@/components/ui/Loader/Loader";
import PaginationControls from "@/components/ui/PaginationControls/PaginationControls";
import Table from "@/components/ui/Table/Table";
import { Truncate } from "@/components/ui/Truncate/Truncate";
import { sports_options, status_options } from "@/lib/definitions";
import {
  applyStatusColor,
  capitalize,
  createDashboardUrl,
} from "@/utils/helpers/formatting";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { useActionState, useEffect, useRef, useState } from "react";
import css from "../admin.module.css";

export default function LeagueList() {
  const searchParams = useSearchParams();

  const editDialogRef = useRef<HTMLDialogElement>(null);

  const [editState, editAction, editPending] = useActionState(
    editLeagueAsAdmin,
    undefined,
  );

  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | undefined>(undefined);
  const [leagueList, setLeagueList] = useState<LeagueData[]>([]);
  const [leagueToEdit, setLeagueToEdit] = useState<LeagueData | undefined>(
    undefined,
  );
  const [count, setCount] = useState<number>(0);
  const [page, setPage] = useState<number>(
    parseInt(searchParams.get("page") || "1"),
  );
  const [perPage, setPerPage] = useState<number>(
    parseInt(searchParams.get("perPage") || "10"),
  );
  const [sport, setSport] = useState<string>(
    searchParams.get("sport") || "all",
  );
  const [leagueStatus, setLeagueStatus] = useState<string>(
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
        `/api/l?${updateAbleSearchParams.toString()}`,
      );

      const { data, message } = await response.json();

      if (data) {
        setLeagueList(data.leagues);
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
    if (leagueList[0]) {
      setLeagueToEdit(leagueList[0]);
    } else {
      setLeagueToEdit(undefined);
    }
  }, [leagueList]);

  useEffect(() => {
    console.log(editState);
    if (!leagueToEdit) return;
    if (editState && editState.status === 200) {
      const { league_id, status } = editState.data;

      const leagueIndex = leagueList.findIndex(
        (u) => u.league_id === league_id,
      );

      const updatedLeagueData: LeagueData = { ...leagueToEdit };

      if (status) updatedLeagueData.status = status;

      const leagueListClone = [
        ...leagueList.slice(0, leagueIndex),
        updatedLeagueData,
        ...leagueList.slice(leagueIndex + 1),
      ];

      setLeagueList(leagueListClone);
      editDialogRef?.current?.close();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [editState]);

  function handleClick(league_id: number) {
    const league = leagueList.find((l) => l.league_id === league_id);

    if (!league) return;

    setLeagueToEdit(league);

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
    { title: "Name" },
    { title: "Sport" },
    { title: "Description", highlightCol: true },
    { title: "Status" },
    { title: "edit" },
  ];

  const hColWidth = 20;
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
            id="filter_sport"
            name="sport"
            label="Sport"
            choices={["all", ...sports_options]}
            selected={sport}
          />
          <Select
            id="filter_status"
            name="status"
            label="Status"
            choices={["all", ...status_options, "locked"]}
            selected={leagueStatus}
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
            href={createDashboardUrl({ admin: "l" })}
            variant="grey"
            onClick={() => {
              setPerPage(10);
              setSport("all");
              setLeagueStatus("all");
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
              {leagueList.length > 0 ? (
                leagueList.map((league) => {
                  const { league_id, slug, name, description, sport, status } =
                    league;

                  return (
                    <tr key={league_id}>
                      <th scope="row" data-highlight-col>
                        <Link href={createDashboardUrl({ l: slug })}>
                          {name}
                        </Link>
                      </th>
                      <td>
                        <IconSport label={capitalize(sport)} sport={sport} />
                      </td>
                      <td data-highlight-col>
                        <Truncate>{description}</Truncate>
                      </td>
                      <td>
                        <Badge text={status} type={applyStatusColor(status)} />
                      </td>
                      <td>
                        <Button
                          style={{ position: "relative" }}
                          variant="grey"
                          onClick={() => handleClick(league_id)}
                        >
                          <Icon icon="edit_square" label="Remove" hideLabel />
                        </Button>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={tableHeadings.length}>No leagues found!</td>
                </tr>
              )}
            </tbody>
          </Table>
        </div>
        <PaginationControls
          page={page}
          perPage={perPage}
          total={count}
          baseUrl={createDashboardUrl({ admin: "l" })}
        />
      </div>
      {leagueToEdit && (
        <Dialog ref={editDialogRef}>
          <form action={editAction}>
            <Grid cols={2} gap="base">
              <Col fullSpan>
                <h3>Edit {leagueToEdit.name}</h3>
              </Col>
              <Col fullSpan>
                <Select
                  name="status"
                  label="Status"
                  choices={[...status_options, "locked"]}
                  selected={leagueToEdit.status}
                />
              </Col>
              <input
                type="hidden"
                name="league_id"
                value={leagueToEdit.league_id}
              />
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
