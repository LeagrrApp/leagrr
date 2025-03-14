"use client";

import { editTeamAsAdmin } from "@/actions/teams";
import Alert from "@/components/ui/Alert/Alert";
import Badge from "@/components/ui/Badge/Badge";
import Button from "@/components/ui/Button/Button";
import ColorIndicator from "@/components/ui/ColorIndicator/ColorIndicator";
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
import { team_status_options } from "@/lib/definitions";
import {
  applyStatusColor,
  createDashboardUrl,
} from "@/utils/helpers/formatting";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { useActionState, useEffect, useRef, useState } from "react";
import css from "../admin.module.css";

export default function TeamList() {
  const searchParams = useSearchParams();

  const editDialogRef = useRef<HTMLDialogElement>(null);

  const [editState, editAction, editPending] = useActionState(
    editTeamAsAdmin,
    undefined,
  );

  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | undefined>(undefined);
  const [teamList, setTeamList] = useState<TeamData[]>([]);
  const [teamToEdit, setTeamToEdit] = useState<TeamData | undefined>(undefined);
  const [count, setCount] = useState<number>(0);
  const [page, setPage] = useState<number>(
    parseInt(searchParams.get("page") || "1"),
  );
  const [perPage, setPerPage] = useState<number>(
    parseInt(searchParams.get("perPage") || "10"),
  );
  const [teamStatus, setTeamStatus] = useState<string>(
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
        `/api/t?${updateAbleSearchParams.toString()}`,
      );

      const { data, message } = await response.json();

      if (data) {
        setTeamList(data.teams);
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
    if (teamList[0]) {
      setTeamToEdit(teamList[0]);
    } else {
      setTeamToEdit(undefined);
    }
  }, [teamList]);

  useEffect(() => {
    if (!teamToEdit) return;
    if (editState && editState.status === 200) {
      const { team_id, status } = editState.data;

      const teamIndex = teamList.findIndex((u) => u.team_id === team_id);

      const updatedTeamData: TeamData = { ...teamToEdit };

      if (status) updatedTeamData.status = status;

      const teamListClone = [
        ...teamList.slice(0, teamIndex),
        updatedTeamData,
        ...teamList.slice(teamIndex + 1),
      ];

      setTeamList(teamListClone);
      editDialogRef?.current?.close();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [editState]);

  function handleClick(team_id: number) {
    const team = teamList.find((t) => t.team_id === team_id);

    if (!team) return;

    setTeamToEdit(team);

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
    { title: "Color" },
    { title: "Description", highlightCol: true },
    { title: "Status" },
    { title: "Edit" },
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
            id="filter_status"
            name="status"
            label="Status"
            choices={["all", ...team_status_options]}
            selected={teamStatus}
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
            href={createDashboardUrl({ admin: "t" })}
            variant="grey"
            onClick={() => {
              setPerPage(10);
              setTeamStatus("all");
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
              {teamList.length > 0 ? (
                teamList.map((team) => {
                  const { team_id, slug, name, description, color, status } =
                    team;

                  return (
                    <tr key={team_id}>
                      <th scope="row" data-highlight-col>
                        <Link href={createDashboardUrl({ l: slug })}>
                          {name}
                        </Link>
                      </th>
                      <td>
                        <ColorIndicator color={color || "white"} />
                      </td>
                      <td data-highlight-col>
                        <Truncate>{description}</Truncate>
                      </td>
                      <td>
                        {status && (
                          <Badge
                            text={status}
                            type={applyStatusColor(status)}
                          />
                        )}
                      </td>
                      <td>
                        <Button
                          style={{ position: "relative" }}
                          variant="grey"
                          onClick={() => handleClick(team_id)}
                        >
                          <Icon icon="edit_square" label="Remove" hideLabel />
                        </Button>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={tableHeadings.length}>No teams found!</td>
                </tr>
              )}
            </tbody>
          </Table>
        </div>
        <PaginationControls
          page={page}
          perPage={perPage}
          total={count}
          baseUrl={createDashboardUrl({ admin: "t" })}
        />
      </div>
      {teamToEdit && (
        <Dialog ref={editDialogRef}>
          <form action={editAction}>
            <Grid cols={2} gap="base">
              <Col fullSpan>
                <h3>Edit {teamToEdit.name}</h3>
              </Col>
              <Col fullSpan>
                <Select
                  name="status"
                  label="Status"
                  choices={team_status_options}
                  selected={teamToEdit.status}
                />
              </Col>
              <input type="hidden" name="team_id" value={teamToEdit.team_id} />
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
