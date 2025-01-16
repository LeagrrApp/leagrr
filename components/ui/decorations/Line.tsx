import { CSSProperties } from "react";
import css from "./decorations.module.css";

interface LineProps {
  height?: SizeOptions;
  marginStart?: SizeOptions;
  marginEnd?: SizeOptions;
  color?: ColorOptions;
}

interface LineStyles extends CSSProperties {
  "--line-color"?: string;
  "--line-height"?: string;
  "--line-margin-start"?: string;
  "--line-margin-end"?: string;
}

export default function Line({
  color,
  height,
  marginStart,
  marginEnd,
}: LineProps) {
  const styles: LineStyles = {};

  if (color) styles["--line-color"] = `var(--color-${color})`;
  if (height) styles["--line-height"] = `var(--spacer-${height})`;
  if (marginStart)
    styles["--line-margin-start"] = `var(--spacer-${marginStart})`;
  if (marginEnd) styles["--line-margin-end"] = `var(--spacer-${marginEnd})`;

  return <div style={styles} className={css.line}></div>;
}
