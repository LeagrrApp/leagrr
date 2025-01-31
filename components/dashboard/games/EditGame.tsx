"use client";

import { editGame } from "@/actions/games";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import Select from "@/components/ui/forms/Select";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { game_status_options } from "@/lib/definitions";
import { formatDateForInput } from "@/utils/helpers/formatting";
import { useActionState, useEffect } from "react";

interface EditGameProps {
  game_id: number;
  league_id: number;
  addGameData: AddGameData;
  gameData: GameData;
  backLink: string;
}

export default function EditGame({
  game_id,
  league_id,
  addGameData,
  gameData,
  backLink,
}: EditGameProps) {
  const [state, action, pending] = useActionState(editGame, {
    link: backLink,
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

  return (
    <form action={action}>
      <Grid cols={{ xs: 1, m: 2 }} gap="base">
        <Select
          name={
            gameData.has_been_published ? "away_team_id_facade" : "away_team_id"
          }
          label="Away Team"
          choices={team_options}
          errors={{ errs: state?.errors?.away_team_id, type: "danger" }}
          selected={state?.data?.away_team_id || gameData.away_team_id}
          disabled={gameData.has_been_published}
        />
        <Select
          name={
            gameData.has_been_published ? "home_team_id_facade" : "home_team_id"
          }
          label="Home Team"
          choices={team_options}
          errors={{ errs: state?.errors?.home_team_id, type: "danger" }}
          selected={state?.data?.home_team_id || gameData.home_team_id}
          disabled={gameData.has_been_published}
        />
        {gameData.has_been_published && (
          <>
            <input
              type="hidden"
              name="away_team_id"
              value={gameData.away_team_id}
            />
            <input
              type="hidden"
              name="home_team_id"
              value={gameData.home_team_id}
            />
          </>
        )}
        <Col fullSpan>
          <small>
            Note: once the game has been published, the teams cannot be changed.{" "}
            {gameData.status !== "draft" &&
              'If you need to change the teams, mark this game as "Archived" to remove it from the teams\' schedule and standings then create a new game.'}
          </small>
        </Col>
        <Input
          type="datetime-local"
          name="date_time"
          label="Date & Time"
          errors={{ errs: state?.errors?.date_time, type: "danger" }}
          value={
            state?.data?.date_time || formatDateForInput(gameData.date_time)
          }
          required
        />
        <Select
          name="arena_id"
          label="Location"
          choices={location_options}
          errors={{ errs: state?.errors?.arena_id, type: "danger" }}
          selected={state?.data?.arena_id || gameData.arena_id}
        />
        <Col fullSpan>
          <Select
            name="status"
            label="Status"
            choices={game_status_options}
            errors={{ errs: state?.errors?.status, type: "danger" }}
            selected={state?.data?.status || gameData.status}
          />
        </Col>
        <input type="hidden" name="game_id" value={game_id} />
        <input type="hidden" name="league_id" value={league_id} />
        <Col>
          <Button type="submit" fullWidth disabled={pending}>
            <Icon icon="save" label="Save Game" />
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
