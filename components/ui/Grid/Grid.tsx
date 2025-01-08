import { CSSProperties, PropsWithChildren } from "react";
import grid from "./grid.module.css";

interface GridProps {
  gap?: SizeOptions;
  cols?: number;
}

interface GridStyles extends CSSProperties {
  "--gap"?: string;
  "--cols"?: number;
}

export default function Grid({
  children,
  gap,
  cols,
}: PropsWithChildren<GridProps>) {
  const styles: GridStyles = {};

  if (gap) styles["--gap"] = `var(--spacer-${gap})`;
  if (cols) styles["--cols"] = cols;

  return (
    <div style={styles} className={grid.grid}>
      {children}
    </div>
  );
}
