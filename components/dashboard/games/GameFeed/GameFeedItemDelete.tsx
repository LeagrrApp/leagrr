"use client";

import { deleteFeedItem } from "@/actions/games";
import Button from "@/components/ui/Button/Button";
import { useActionState } from "react";
import css from "./gameFeed.module.css";

interface GameFeedItemDeleteProps {
  type: string;
  id: number;
}

export default function GameFeedItemDelete({
  type,
  id,
}: GameFeedItemDeleteProps) {
  const [state, action, pending] = useActionState(deleteFeedItem, {
    id,
    type,
  });

  return (
    <form className={css.game_feed_item_delete} action={action}>
      <p>Delete this feed item</p>
      <Button type="submit">Delete Item</Button>
    </form>
  );
}
