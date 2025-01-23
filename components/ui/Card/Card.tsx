import { CSSProperties, PropsWithChildren } from "react";
import css from "./card.module.css";

interface CardProps {
  padding?: SizeOptions;
}
interface CardStyles extends CSSProperties {
  "--card-padding"?: string;
}

export default function Card({
  children,
  padding,
}: PropsWithChildren<CardProps>) {
  const styles: CardStyles = {};

  if (padding) styles["--card-padding"] = `var(--spacer-${padding})`;

  return (
    <div style={styles} className={css.card}>
      {children}
    </div>
  );
}
