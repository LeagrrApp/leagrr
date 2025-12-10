"use client";

import { createGame } from "@/actions/games";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import FauxLabel from "@/components/ui/forms/FauxLabel";
import Input from "@/components/ui/forms/Input";
import NumberSelect from "@/components/ui/forms/NumberSelect";
import Select from "@/components/ui/forms/Select";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { game_status_options } from "@/lib/definitions";
import { formatDateForInput, numberStringArray } from "@/utils/formatting";
import { useActionState } from "react";
import css from "./createGame.module.css";

interface CreateGameProps {
  division_id: number;
  league_id: number;
  addGameData: AddGameData;
  backLink: string;
}

export default function CreateGame({
  division_id,
  league_id,
  addGameData,
  backLink,
}: CreateGameProps) {
  const [state, action, pending] = useActionState(createGame, {
    link: backLink,
    data: {},
  });

  const team_options: SelectOption[] = [];
  addGameData.teams.forEach((t) => {
    team_options.push({
      label: t.name,
      value: t.team_id,
    });
  });

  const location_options: SelectOption[] = [];
  addGameData.locations.forEach((l) => {
    location_options.push({
      label: `${l.arena} - ${l.venue}`,
      value: l.arena_id,
    });
  });

  const tz_offset = new Date(Date.now()).getTimezoneOffset() / 60;

  return (
    <form action={action}>
      <Grid cols={{ xs: 1, m: 2 }} gap="base">
        <Select
          name="away_team_id"
          label="Away Team"
          choices={team_options}
          errors={{ errs: state?.errors?.away_team_id, type: "danger" }}
          selected={state?.data?.away_team_id}
        />
        <Select
          name="home_team_id"
          label="Home Team"
          choices={team_options}
          errors={{ errs: state?.errors?.home_team_id, type: "danger" }}
          selected={state?.data?.home_team_id}
        />
        <div className={css.date_time_container}>
          <div className={css.date_time_grid}>
            <Input
              type="date"
              name="date"
              label="Date"
              errors={{ errs: state?.errors?.date, type: "danger" }}
              value={
                state?.data?.date ? formatDateForInput(state?.data?.date) : ""
              }
              required
            />
            <div className={css.time_grid}>
              <FauxLabel label="Time" required />
              <NumberSelect
                label="Hour"
                name="hour"
                min={1}
                max={12}
                selected={state?.data?.hour || 1}
                hideLabel
              />
              <Select
                label="Minute"
                name="minute"
                choices={numberStringArray(0, 59, {
                  leading_zeros: true,
                  step: 5,
                })}
                selected={state?.data?.hour || "00"}
                hideLabel
              />
              <Select
                label="AM or PM"
                name="am_pm"
                choices={["AM", "PM"]}
                selected={state?.data?.am_pm || "PM"}
                hideLabel
              />
            </div>
          </div>
        </div>
        <Select
          name="arena_id"
          label="Location"
          choices={location_options}
          errors={{ errs: state?.errors?.arena_id, type: "danger" }}
          selected={state?.data?.arena_id}
        />
        <Col fullSpan>
          <Select
            name="status"
            label="Status"
            choices={game_status_options}
            errors={{ errs: state?.errors?.status, type: "danger" }}
            selected={state?.data?.status}
          />
        </Col>
        <input type="hidden" name="league_id" value={league_id} />
        <input type="hidden" name="division_id" value={division_id} />
        <input type="hidden" name="tz_offset" value={tz_offset} />
        {state?.message && state.status !== 200 && (
          <Col fullSpan>
            <Alert alert={state.message} type="danger" />
          </Col>
        )}
        <Col>
          <Button type="submit" fullWidth disabled={pending}>
            <Icon icon="add_circle" label="Create Game" />
          </Button>
        </Col>
        <Col>
          <Button href={backLink} type="button" variant="grey" fullWidth>
            <Icon icon="cancel" label="Cancel" />
          </Button>
        </Col>
      </Grid>
    </form>
  );
}
