"use client";

import { addToGameFeed } from "@/actions/games";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Checkbox from "@/components/ui/forms/Checkbox";
import Input from "@/components/ui/forms/Input";
import NumberSelect from "@/components/ui/forms/NumberSelect";
import Select from "@/components/ui/forms/Select";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { nameDisplay } from "@/utils/helpers/formatting";
import { usePathname } from "next/navigation";
import { useActionState, useEffect, useMemo, useState } from "react";
import css from "./gameFeedAdd.module.css";

interface GameFeedAddProps {
  game: GameData;
  canEdit: boolean;
  teamRosters: {
    away_roster: TeamRosterItem[];
    home_roster: TeamRosterItem[];
  };
  currentTime: {
    period: number;
    minutes: number;
    seconds: number;
  };
}

type Choice = { label: string; value: number };

export default function GameFeedAdd({
  game,
  teamRosters,
  currentTime,
}: GameFeedAddProps) {
  const pathname = usePathname();
  const [state, action, pending] = useActionState(addToGameFeed, {
    link: pathname,
    data: {},
  });

  const away_players: Choice[] = useMemo(
    () => [
      ...teamRosters?.away_roster.map((p) => {
        return {
          label: nameDisplay(p.first_name, p.last_name, "first_initial"),
          value: p.user_id,
        };
      }),
    ],
    [teamRosters],
  );

  const home_players: Choice[] = useMemo(
    () => [
      ...teamRosters?.home_roster.map((p) => {
        return {
          label: nameDisplay(p.first_name, p.last_name, "first_initial"),
          value: p.user_id,
        };
      }),
    ],
    [teamRosters],
  );

  const [adding, setAdding] = useState<boolean>(false);
  const [type, setType] = useState<string>("shot");
  const [team, setTeam] = useState<number>(game.away_team_id);
  const [player, setPlayer] = useState<number | undefined>(
    away_players[0]?.value || undefined,
  );
  const [canAssist, setCanAssist] = useState<Choice[]>([]);
  const [goalie, setGoalie] = useState<number>(
    teamRosters.home_roster.find((p) => p.position === "Goalie")?.user_id || 0,
  );

  useEffect(() => {
    setPlayer(
      team === game.home_team_id
        ? home_players[0]?.value
        : away_players[0]?.value,
    );
    setGoalie(
      (team === game.home_team_id
        ? teamRosters.away_roster
        : teamRosters.home_roster
      ).find((p) => p.position === "Goalie")?.user_id || 0,
    );
  }, [team, away_players, home_players, game.home_team_id, teamRosters]);

  useEffect(() => {
    const baseList = team === game.home_team_id ? home_players : away_players;

    const filteredList = baseList.filter((p) => p.value !== player);

    setCanAssist(filteredList);
  }, [player, away_players, game.home_team_id, home_players, team]);

  const team_choices: Choice[] = [
    { label: game.away_team, value: game.away_team_id },
    { label: game.home_team, value: game.home_team_id },
  ];

  if (adding) {
    if (!teamRosters) {
      return (
        <div className={css.game_feed_add}>
          <Alert
            alert="There was an issue loading necessary data to add to game feed!"
            type="danger"
            center
          />
        </div>
      );
    }

    return (
      <form id="game-feed-add" className={css.game_feed_add} action={action}>
        <Col fullSpan>
          <h4>Add to Game Feed</h4>
        </Col>
        <Select
          name="type"
          label="Type"
          choices={["shot", "goal", "penalty"]}
          onChange={(e) => setType(e.target.value)}
          selected={type}
        />
        <Select
          name="team_id"
          label="Team"
          choices={team_choices}
          onChange={(e) => setTeam(parseInt(e.target.value))}
          selected={team}
        />
        <Select
          name="user_id"
          label="Player"
          choices={team === game.home_team_id ? home_players : away_players}
          selected={player}
          onChange={(e) => setPlayer(parseInt(e.target.value))}
        />
        <fieldset className={css.game_feed_add_game_time}>
          <legend className="label">Game Time</legend>
          <NumberSelect
            name="period"
            label="Period"
            min={1}
            max={3}
            labelAfter
            selected={currentTime.period.toString()}
            required
          />
          <NumberSelect
            name="minutes"
            label="Minutes"
            min={0}
            max={19}
            labelAfter
            selected={currentTime.minutes.toString()}
            required
          />
          <NumberSelect
            name="seconds"
            label="Seconds"
            min={0}
            max={59}
            labelAfter
            selected={currentTime.seconds.toString()}
            required
          />
        </fieldset>
        {(type === "goal" || type === "shot") && (
          <fieldset>
            <legend className="label">More Details</legend>
            <Checkbox name="power_play" value="true" label="Power Play" />
            <Checkbox name="shorthanded" value="true" label="Shorthanded" />
            {type === "goal" && (
              <Checkbox name="empty_net" value="true" label="Empty Net" />
            )}
            {type === "shot" && (
              <Checkbox name="rebound" value="true" label="Rebound" />
            )}
          </fieldset>
        )}
        {type === "goal" && (
          <>
            <div>
              <label htmlFor="assists" className="label push-s">
                Assists
              </label>
              <select name="assists" id="assists" multiple title="Assists">
                {canAssist.map((p) => (
                  <option key={p.value} value={p.value}>
                    {p.label}
                  </option>
                ))}
              </select>
            </div>
          </>
        )}
        {type === "penalty" && (
          <>
            <Input
              name="penalty_minutes"
              label="Length"
              type="number"
              defaultValue="2"
              required
            />
            <Input name="infraction" label="Infraction" required />
          </>
        )}
        <input type="hidden" name="game_id" value={game.game_id} />
        <input
          type="hidden"
          name="opposition_id"
          value={
            game.home_team_id === team ? game.away_team_id : game.home_team_id
          }
        />
        <input type="hidden" name="goalie_id" value={goalie} />
        {state?.message && state?.status !== 200 && (
          <Col fullSpan>
            <Alert alert={state.message} type="danger" />
          </Col>
        )}
        <Col fullSpan>
          <Grid cols={2} gap="base">
            <Button type="submit" disabled={pending}>
              <Icon label="Add to feed" icon="dynamic_feed" />
            </Button>
            <Button
              type="button"
              onClick={() => setAdding(false)}
              variant="grey"
              disabled={pending}
            >
              <Icon label="Cancel" icon="cancel" />
            </Button>
          </Grid>
        </Col>
      </form>
    );
  }

  return (
    <Button
      variant="grey"
      size="h5"
      disabled={game.status !== "public" && game.status !== "completed"}
      onClick={() => setAdding(true)}
    >
      <Icon icon="dynamic_feed" label="Add to Game Feed" />
    </Button>
  );
}
