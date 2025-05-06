"use client";

import { createGame } from "@/actions/games";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { game_status_options } from "@/lib/definitions";
import { formatDateForInput } from "@/utils/helpers/formatting";
import { useActionState } from "react";

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
        <Input
          type="datetime-local"
          name="date_time"
          label="Date & Time"
          errors={{ errs: state?.errors?.date_time, type: "danger" }}
          value={
            state?.data?.date_time
              ? formatDateForInput(state?.data?.date_time)
              : ""
          }
          required
        />
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
