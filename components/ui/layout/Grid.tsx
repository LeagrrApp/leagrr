import { CSSProperties, PropsWithChildren } from "react";
import layout from "./layout.module.css";

// TODO: improve grids so that they are more easily nestable & add subgrid

interface GridProps {
  gap?: SizeOptions;
  cols?: number | ResponsiveColumns;
}

type ResponsiveColumns = {
  xs: number;
  s?: number;
  m?: number;
  l?: number;
  xl?: number;
};

interface GridStyles extends CSSProperties {
  "--gap"?: string;
  "--cols"?: number;
  "--cols-xs"?: number;
  "--cols-s"?: number;
  "--cols-m"?: number;
  "--cols-l"?: number;
  "--cols-xl"?: number;
}

export default function Grid({
  children,
  gap,
  cols,
}: PropsWithChildren<GridProps>) {
  const styles: GridStyles = {};

  if (gap) styles["--gap"] = `var(--spacer-${gap})`;
  if (cols) {
    if (typeof cols === "number") {
      styles["--cols"] = cols;
    }

    if (typeof cols === "object") {
      Object.keys(cols).forEach((size) => {
        styles[`--cols-${size}`] = cols[size as keyof ResponsiveColumns];
      });
    }
  }

  return (
    <div style={styles} className={layout.grid}>
      {children}
    </div>
  );
}
