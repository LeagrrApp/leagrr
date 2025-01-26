"use client";

import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Grid from "@/components/ui/layout/Grid";
import { useActionState, useEffect, useRef, useState } from "react";
import css from "./gameScoreInput.module.css";
import { useParams, usePathname } from "next/navigation";
import { setGameScore } from "@/actions/games";

interface GameScoreInputProps {
  game: GameData;
}

export default function GameScoreInput({ game }: GameScoreInputProps) {
  const pathname = usePathname();
  const { league } = useParams();

  const initialState = {
    league: typeof league === "string" ? league : "",
    game,
    link: pathname,
  };

  const [state, action, pending] = useActionState(setGameScore, initialState);

  const dialogRef = useRef<HTMLDialogElement>(null);

  const [homeTeamScore, setHomeTeamScore] = useState(game.home_team_score);
  const [awayTeamScore, setAwayTeamScore] = useState<number>(
    game.away_team_score
  );

  return (
    <>
      <Button
        onClick={() => dialogRef?.current?.showModal()}
        size="s"
        padding={["em-s", "em-m"]}
      >
        {game.status === "completed" ? "Update Score" : "Complete Game"}
      </Button>
      <Dialog ref={dialogRef} maxWidth="40rem">
        <form action={action}>
          <h2>
            {game.status === "completed" ? "Update Score" : "Complete Game"}
          </h2>
          <Grid cols={2} gap="base">
            <div className={css.game_score_input_team}>
              <label htmlFor="home_team_score">{game.home_team}</label>
              <input
                name="home_team_score"
                id="home_team_score"
                type="number"
                min="0"
                value={homeTeamScore}
                onChange={(e) =>
                  setHomeTeamScore(parseInt(e?.currentTarget?.value))
                }
                required
              />
            </div>
            <div className={css.game_score_input_team}>
              <label htmlFor="away_team_score">{game.away_team}</label>
              <input
                name="away_team_score"
                id="away_team_score"
                type="number"
                value={awayTeamScore}
                min="0"
                onChange={(e) =>
                  setAwayTeamScore(parseInt(e?.currentTarget?.value))
                }
                required
              />
            </div>
            <Button type="submit">Confirm Score</Button>
            <Button
              type="button"
              onClick={() => dialogRef?.current?.close()}
              variant="grey"
            >
              Cancel
            </Button>
          </Grid>
        </form>
      </Dialog>
    </>
  );
}
