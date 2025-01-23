"use client";

import Card from "@/components/ui/Card/Card";
import Table from "@/components/ui/Table/Table";
import css from "./divisionSchedule.module.css";
import { useEffect, useState } from "react";
import Button from "@/components/ui/Button/Button";
import ButtonInvis from "@/components/ui/ButtonInvis/ButtonInvis";
import Icon from "@/components/ui/Icon/Icon";

type DivisionGamesProps = {
  games: GameData[];
};

export default function DivisionSchedule({ games }: DivisionGamesProps) {
  const [showCompleted, setShowComplete] = useState(false);
  const [gameList, setGameList] = useState<GameData[]>(() => {
    return games.filter((g) => {
      const gameTime = new Date(g.date_time);
      const now = new Date(Date.now());

      return gameTime > now;
    });
  });
  const [gameListOffset, setGameListOffset] = useState<number>(0);
  const [gameCount, setGameCount] = useState<number>(() => {
    return games.filter((g) => {
      const gameTime = new Date(g.date_time);
      const now = new Date(Date.now());

      return gameTime > now;
    }).length;
  });

  const gamesPerPage = 10;

  useEffect(() => {
    const updatedGamesList = games.filter((g) => {
      const gameTime = new Date(g.date_time);
      const now = new Date(Date.now());

      if (showCompleted) return gameTime < now;
      return gameTime > now;
    });

    if (showCompleted) {
      updatedGamesList.reverse();
      setGameList(
        updatedGamesList.slice(gameListOffset, gameListOffset + gamesPerPage)
      );
    } else {
      setGameList(updatedGamesList);
    }

    setGameCount(updatedGamesList.length);
  }, [showCompleted, gameListOffset]);

  return (
    <>
      <Card className="push-m" padding="ml">
        <Table className={css.division_schedule}>
          <thead>
            <tr>
              <th className={css.division_schedule_narrow} scope="col">
                Date
              </th>
              <th
                className={css.division_schedule_wide}
                scope="col"
                title="Home Team"
              >
                <span aria-hidden="true">Home</span>
              </th>
              <th
                className={css.division_schedule_wide}
                scope="col"
                title="Away Team"
              >
                <span aria-hidden="true">Away</span>
              </th>
              <th className={css.division_schedule_narrow}>Location</th>
            </tr>
          </thead>
          <tbody>
            {gameList.map((g) => {
              const gameTime = new Date(g.date_time).toLocaleString("en-CA", {
                month: "short",
                day: "2-digit",
                hour: "numeric",
                minute: "2-digit",
                hour12: false,
              });

              return (
                <tr key={g.game_id}>
                  <td>{gameTime}</td>
                  <td
                    className={
                      g.home_team_score > g.away_team_score
                        ? css.division_winner
                        : undefined
                    }
                  >
                    {g.home_team}{" "}
                    {showCompleted && <strong>{g.home_team_score}</strong>}
                  </td>
                  <td
                    className={
                      g.away_team_score > g.home_team_score
                        ? css.division_winner
                        : undefined
                    }
                  >
                    {showCompleted && <strong>{g.away_team_score}</strong>}{" "}
                    {g.away_team}
                  </td>
                  <td>
                    {g.arena} - {g.venue}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </Table>
      </Card>
      <div className={css.division_schedule_controls}>
        {gameListOffset !== 0 && (
          <ButtonInvis
            className={css.game_list_prev}
            onClick={() => setGameListOffset(gameListOffset - 10)}
          >
            <Icon icon="chevron_left" label="Prev" gap="xs" />
          </ButtonInvis>
        )}
        <Button
          className={css.game_list_toggle}
          onClick={() => setShowComplete(!showCompleted)}
          padding={["s", "m"]}
        >
          {!showCompleted ? "Show Complete Games" : "Show Upcoming Games"}
        </Button>
        {gameListOffset < gameCount - 10 && (
          <ButtonInvis
            className={css.game_list_next}
            onClick={() => setGameListOffset(gameListOffset + 10)}
          >
            <Icon icon="chevron_right" label="Next" labelFirst gap="xs" />
          </ButtonInvis>
        )}
      </div>
    </>
  );
}
