import { CSSProperties, PropsWithChildren } from "react";
import css from "./card.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";

interface CardProps {
  padding?: SizeOptions;
  className?: string | string[];
}
interface CardStyles extends CSSProperties {
  "--card-padding"?: string;
}

export default function Card({
  children,
  padding,
  className,
}: PropsWithChildren<CardProps>) {
  const styles: CardStyles = {};

  if (padding) styles["--card-padding"] = `var(--spacer-${padding})`;

  return (
    <div style={styles} className={apply_classes(css.card, className)}>
      {children}
    </div>
  );
}
