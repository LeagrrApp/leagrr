import { applyClasses } from "@/utils/html-attributes";
import { CSSProperties, PropsWithChildren } from "react";
import css from "./card.module.css";

interface CardProps {
  padding?: SizeOptions;
  className?: string | string[];
  isContainer?: boolean;
  minHeight?: string;
}
interface CardStyles extends CSSProperties {
  "--card-padding"?: string;
  "--card-min-height"?: string;
}

export default function Card({
  children,
  padding,
  className,
  isContainer,
  minHeight,
}: PropsWithChildren<CardProps>) {
  const classes: string[] = [css.card];
  const styles: CardStyles = {};

  if (padding) styles["--card-padding"] = `var(--spacer-${padding})`;
  if (minHeight) styles["--card-min-height"] = minHeight;

  if (isContainer) classes.push(css.as_container);

  return (
    <div style={styles} className={applyClasses(classes, className)}>
      {children}
    </div>
  );
}
