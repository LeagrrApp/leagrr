"use client";

import ButtonInvis from "@/components/ui/ButtonInvis/ButtonInvis";
import Card from "@/components/ui/Card/Card";
import Icon from "@/components/ui/Icon/Icon";
import Table from "@/components/ui/Table/Table";
import Switch from "@/components/ui/forms/Switch/Switch";
import { applyClasses } from "@/utils/helpers/html-attributes";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import DashboardUnit from "../../DashboardUnit/DashboardUnit";
import DashboardUnitHeader from "../../DashboardUnitHeader/DashboardUnitHeader";
import css from "./divisionSchedule.module.css";

type DivisionGamesProps = {
  games: GameData[];
  canEdit: boolean;
};

export default function DivisionSchedule({
  games,
  canEdit,
}: DivisionGamesProps) {
  const pathname = usePathname();

  const [showPastGames, setShowPastGames] = useState(false);
  const [gameList, setGameList] = useState<GameData[]>(() => {
    return games
      .filter((g) => {
        const gameTime = new Date(g.date_time);
        const now = new Date(Date.now());

        return gameTime > now;
      })
      .toReversed();
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
    const updatedGamesList = games
      .filter((g) => {
        const gameTime = new Date(g.date_time);
        const now = new Date(Date.now());

        if (showPastGames) return gameTime < now;
        return gameTime > now;
      })
      .toReversed();

    if (showPastGames) {
      updatedGamesList.reverse();
      setGameList(
        updatedGamesList.slice(gameListOffset, gameListOffset + gamesPerPage),
      );
    } else {
      setGameList(updatedGamesList);
    }

    setGameCount(updatedGamesList.length);
  }, [showPastGames, gameListOffset, games]);

  return (
    <DashboardUnit gridArea="schedule">
      <DashboardUnitHeader>
        <h3>
          <Icon icon="calendar_month" label="Schedule" labelFirst />
        </h3>
        {canEdit && (
          <Icon
            className={css.division_schedule_add}
            icon="add_circle"
            label="Add Game"
            hideLabel
            href={`${pathname}/g`}
            size="h2"
          />
        )}
        <Switch
          name="showPastGames"
          label="Show past games"
          checked={showPastGames}
          onChange={() => setShowPastGames(!showPastGames)}
          noSpread
          className={css.division_schedule_switch}
        />
      </DashboardUnitHeader>
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
                title="Away Team"
              >
                <span aria-hidden="true">Away</span>
              </th>
              <th
                className={css.division_schedule_wide}
                scope="col"
                title="Home Team"
              >
                <span aria-hidden="true">Home</span>
              </th>
              <th className={css.division_schedule_narrow}>Location</th>
            </tr>
          </thead>
          <tbody>
            {gameList.map((g) => {
              console.log(g.date_time);
              const gameTime = g.date_time.toLocaleString("en-CA", {
                month: "short",
                day: "2-digit",
                hour: "numeric",
                minute: "2-digit",
                // hour12: false,
              });

              const rowClasses = [];
              if (g.status !== "public" && g.status !== "completed") {
                rowClasses.push(
                  css.game_list_flag,
                  css[`game_list_flag_${g.status}`],
                );
              }

              return (
                <tr key={g.game_id} className={applyClasses(rowClasses)}>
                  <td>
                    {gameTime}
                    <Link href={`${pathname}/g/${g.game_id}`}>
                      <span className="srt">
                        View game between {g.away_team} and
                        {g.home_team} taking place {gameTime}
                      </span>
                    </Link>
                  </td>
                  <td
                    className={
                      g.away_team_score > g.home_team_score &&
                      g.status === "completed"
                        ? css.division_winner
                        : undefined
                    }
                  >
                    {g.away_team}{" "}
                    {g.status === "completed" && (
                      <strong>{g.away_team_score}</strong>
                    )}
                  </td>
                  <td
                    className={
                      g.home_team_score > g.away_team_score &&
                      g.status === "completed"
                        ? css.division_winner
                        : undefined
                    }
                  >
                    {g.status === "completed" && (
                      <strong>{g.home_team_score}</strong>
                    )}{" "}
                    {g.home_team}
                  </td>
                  <td title={`${g.arena} - ${g.venue}`}>
                    {g.arena && g.venue ? (
                      <>
                        {g.arena} - {g.venue}
                      </>
                    ) : (
                      <>
                        <span aria-hidden="true">TBD</span>
                        <span className="srt">Location to be determined</span>
                      </>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </Table>
      </Card>
      {gameCount > gamesPerPage && (
        <div className={css.division_schedule_controls}>
          {gameListOffset !== 0 && (
            <ButtonInvis
              className={css.game_list_prev}
              onClick={() => setGameListOffset(gameListOffset - 10)}
            >
              <Icon icon="chevron_left" label="Prev" gap="xs" />
            </ButtonInvis>
          )}
          <div className={css.game_list_count}>
            {gameListOffset / gamesPerPage + 1} /{" "}
            {Math.ceil(gameCount / gamesPerPage)}
          </div>
          {gameListOffset < gameCount - 10 && (
            <ButtonInvis
              className={css.game_list_next}
              onClick={() => setGameListOffset(gameListOffset + 10)}
            >
              <Icon icon="chevron_right" label="Next" labelFirst gap="xs" />
            </ButtonInvis>
          )}
        </div>
      )}
    </DashboardUnit>
  );
}
