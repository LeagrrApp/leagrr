"use client";

import Button from "@/components/ui/Button/Button";
import Icon from "@/components/ui/Icon/Icon";
import GameQuickScore from "../GameQuickScore/GameQuickScore";
import css from "./gameControls.module.css";
import { usePathname } from "next/navigation";

interface GameControlsProps {
  game: GameData;
}

export default function GameControls({ game }: GameControlsProps) {
  const pathname = usePathname();

  return (
    <div className={css.game_controls_card}>
      <Button href={`${pathname}/edit`} variant="grey" size="h5">
        <Icon icon="edit_square" label="Edit Game" />
      </Button>
      {/* Add to game feed */}
      <Button
        href="#game-feed"
        variant="grey"
        size="h5"
        disabled={game.status !== "public" && game.status !== "completed"}
      >
        <Icon icon="dynamic_feed" label="Add to Game Feed" />
      </Button>
      <GameQuickScore game={game} buttonClassName={css.game_controls_button} />
    </div>
  );
}
