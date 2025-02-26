"use client";

import { setGameScore } from "@/actions/games";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { useParams, usePathname } from "next/navigation";
import { useActionState, useRef, useState } from "react";
import css from "./gameQuickScore.module.css";

interface GameQuickScoreProps {
  game: GameData;
  buttonClassName?: string;
}

export default function GameQuickScore({
  game,
  buttonClassName,
}: GameQuickScoreProps) {
  const pathname = usePathname();
  const { league } = useParams();

  const initialState = {
    link: pathname,
    data: { league: typeof league === "string" ? league : "", game },
  };

  const [state, action, pending] = useActionState(setGameScore, initialState);

  const dialogRef = useRef<HTMLDialogElement>(null);

  const [homeTeamScore, setHomeTeamScore] = useState(game.home_team_score);
  const [awayTeamScore, setAwayTeamScore] = useState<number>(
    game.away_team_score,
  );

  return (
    <>
      <Button
        className={buttonClassName}
        onClick={() => dialogRef?.current?.showModal()}
        variant="grey"
        size="h5"
        disabled={game.status !== "public" && game.status !== "completed"}
      >
        <Icon icon="scoreboard" label="Quick Score" />
      </Button>
      <Dialog className={css.game_score_input} ref={dialogRef} maxWidth="40rem">
        <form action={action}>
          <h2>Quick Score</h2>
          <Grid cols={2} gap="base">
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
            {state?.message && state?.status !== 200 && (
              <Col fullSpan>
                <Alert alert={state.message} type="danger" />
              </Col>
            )}
            <Button type="submit" disabled={pending}>
              Confirm Score
            </Button>
            <Button
              type="button"
              onClick={() => dialogRef?.current?.close()}
              variant="grey"
            >
              Cancel
            </Button>
            <Col fullSpan>
              <small>
                Note: updating the quick score overrides goals recorded in the
                Game Feed. To re-activate Game Feed scoring, update the goals in
                the Game Feed.
              </small>
            </Col>
          </Grid>
        </form>
      </Dialog>
    </>
  );
}
