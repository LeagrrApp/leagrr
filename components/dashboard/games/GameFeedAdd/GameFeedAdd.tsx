"use client";

import Button from "@/components/ui/Button/Button";
import Icon from "@/components/ui/Icon/Icon";
import { useActionState, useEffect, useRef, useState } from "react";
import css from "./gameFeedAdd.module.css";
import Select from "@/components/ui/forms/Select";
import Alert from "@/components/ui/Alert/Alert";
import { nameDisplay } from "@/utils/helpers/formatting";
import Col from "@/components/ui/layout/Col";
import NumberSelect from "@/components/ui/forms/NumberSelect";
import Switch from "@/components/ui/forms/Switch/Switch";
import { addToGameFeed } from "@/actions/games";
import Input from "@/components/ui/forms/Input";

interface GameFeedAddProps {
  game: GameData;
  canEdit: boolean;
  teamRosters: {
    away_roster: TeamRosterItem[];
    home_roster: TeamRosterItem[];
  };
}

type Choice = { label: string; value: number };

export default function GameFeedAdd({
  game,
  canEdit,
  teamRosters,
}: GameFeedAddProps) {
  const assistRef = useRef<HTMLSelectElement>(null);
  const [state, action, pending] = useActionState(addToGameFeed, undefined);

  useEffect(() => {
    console.log(state);
  }, [state]);

  const away_players: Choice[] = [
    ...teamRosters?.away_roster.map((p) => {
      return {
        label: nameDisplay(p.first_name, p.last_name, "first_initial"),
        value: p.user_id,
      };
    }),
  ];

  const home_players: Choice[] = [
    ...teamRosters?.home_roster.map((p) => {
      return {
        label: nameDisplay(p.first_name, p.last_name, "first_initial"),
        value: p.user_id,
      };
    }),
  ];

  const [adding, setAdding] = useState<boolean>(true);
  const [type, setType] = useState<string>("goal");
  const [team, setTeam] = useState<number>(game.away_team_id);
  const [player, setPlayer] = useState<number>(
    team === game.home_team_id ? home_players[0].value : away_players[0].value
  );
  const [canAssist, setCanAssist] = useState<Choice[]>([]);

  useEffect(() => {
    setPlayer(
      team === game.home_team_id ? home_players[0].value : away_players[0].value
    );
  }, [team]);

  useEffect(() => {
    console.log("updating assist options");
    const baseList = team === game.home_team_id ? home_players : away_players;

    const filteredList = baseList.filter((p) => p.value !== player);

    setCanAssist(filteredList);
  }, [player]);

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
      <form className={css.game_feed_add} action={action}>
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
            required
          />
          <NumberSelect
            name="minutes"
            label="Minutes"
            min={0}
            max={19}
            labelAfter
            required
          />
          <NumberSelect
            name="seconds"
            label="Seconds"
            min={0}
            max={59}
            labelAfter
            required
          />
        </fieldset>
        {type === "goal" && (
          <>
            <div>
              <label htmlFor="assists" className="label push-s">
                Assists
              </label>
              <select
                name="assists"
                id="assists"
                multiple
                title="Assists"
                onChange={(e) => console.log(e.target.value)}
              >
                {canAssist.map((p) => (
                  <option key={p.value} value={p.value}>
                    {p.label}
                  </option>
                ))}
              </select>
            </div>
          </>
        )}
        {(type === "goal" || type === "shot") && (
          <fieldset>
            <legend className="label">More Details</legend>
            <div>
              <input
                type="checkbox"
                name="power_play"
                id="power_play"
                value="true"
              />
              <label htmlFor="power_play">Power Player</label>
            </div>
            <div>
              <input
                type="checkbox"
                name="shorthanded"
                id="shorthanded"
                value="true"
              />
              <label htmlFor="shorthanded">Shorthanded</label>
            </div>
            {type === "goal" && (
              <div>
                <input
                  type="checkbox"
                  name="empty_net"
                  id="empty_net"
                  value="true"
                />
                <label htmlFor="empty_net">Empty Net</label>
              </div>
            )}
            {type === "shot" && (
              <div>
                <input
                  type="checkbox"
                  name="rebound"
                  id="rebound"
                  value="true"
                />
                <label htmlFor="rebound">Rebound</label>
              </div>
            )}
          </fieldset>
        )}
        {type === "penalty" && (
          <>
            <Input
              name="penalty_minutes"
              label="Length"
              type="number"
              required
            />
            <Input name="infraction" label="Infraction" required />
          </>
        )}
        <input type="hidden" name="game_id" value={game.game_id} />
        <Col fullSpan>
          <Button type="submit">Add to feed</Button>
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
