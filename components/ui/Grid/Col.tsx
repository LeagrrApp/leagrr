import { CSSProperties, PropsWithChildren } from "react";
import grid from "./grid.module.css";

interface ColProps {
  colSpan?: number;
  fullSpan?: boolean;
}

interface ColStyles extends CSSProperties {
  "--colSpan"?: string;
}

export default function Col({
  children,
  colSpan,
  fullSpan,
}: PropsWithChildren<ColProps>) {
  const styles: ColStyles = {};

  if (fullSpan) {
    styles["--colSpan"] = "1 / -1";
  } else if (colSpan) {
    styles["--colSpan"] = `span ${colSpan}`;
  }

  return (
    <div style={styles} className={grid.col}>
      {children}
    </div>
  );
}
