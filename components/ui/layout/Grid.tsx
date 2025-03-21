import { applyClasses } from "@/utils/helpers/html-attributes";
import { CSSProperties, PropsWithChildren } from "react";
import layout from "./layout.module.css";

// TODO: improve grids so that they are more easily nestable & add subgrid

interface GridProps {
  gap?: SizeOptions;
  cols?: number | ResponsiveColumns;
  className?: string | string[];
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
  "--g-cols"?: number;
  "--g-cols-xs"?: number;
  "--g-cols-s"?: number;
  "--g-cols-m"?: number;
  "--g-cols-l"?: number;
  "--g-cols-xl"?: number;
  [key: string]: unknown;
}

export default function Grid({
  children,
  gap,
  cols,
  className,
}: PropsWithChildren<GridProps>) {
  const styles: GridStyles = {};

  if (gap) styles["--gap"] = `var(--spacer-${gap})`;
  if (cols) {
    if (typeof cols === "number") {
      styles["--g-cols"] = cols;
    }

    if (typeof cols === "object") {
      Object.keys(cols).forEach((size) => {
        styles[`--g-cols-${size}`] = cols[size as keyof ResponsiveColumns];
      });
    }
  }

  return (
    <div style={styles} className={applyClasses(layout.grid, className)}>
      {children}
    </div>
  );
}
