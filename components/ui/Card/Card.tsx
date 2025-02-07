import { CSSProperties, PropsWithChildren } from "react";
import css from "./card.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";

interface CardProps {
  padding?: SizeOptions;
  className?: string | string[];
  isContainer?: boolean;
}
interface CardStyles extends CSSProperties {
  "--card-padding"?: string;
}

export default function Card({
  children,
  padding,
  className,
  isContainer,
}: PropsWithChildren<CardProps>) {
  const classes: string[] = [css.card];
  const styles: CardStyles = {};

  if (padding) styles["--card-padding"] = `var(--spacer-${padding})`;

  if (isContainer) classes.push(css.as_container);

  return (
    <div style={styles} className={apply_classes(classes, className)}>
      {children}
    </div>
  );
}
