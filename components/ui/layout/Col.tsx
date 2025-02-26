import { apply_classes } from "@/utils/helpers/html-attributes";
import { CSSProperties, PropsWithChildren } from "react";
import css from "./layout.module.css";

interface ColProps {
  colSpan?: number;
  fullSpan?: boolean;
  flexGrow?: string | number;
  flexShrink?: string | number;
  flexBasis?: string;
  alignSelf?: string;
  className?: string;
  gridArea?: string;
}

interface ColStyles extends CSSProperties {
  "--col-span"?: string;
  "--flex-grow"?: string | number;
  "--flex-shrink"?: string | number;
  "--flex-basis"?: string;
  "--align-self"?: string;
  "--grid-area"?: string;
}

export default function Col({
  children,
  colSpan,
  fullSpan,
  flexGrow,
  flexShrink,
  flexBasis,
  alignSelf,
  className,
  gridArea,
}: PropsWithChildren<ColProps>) {
  const classes: string[] = [css.col];
  const styles: ColStyles = {};

  if (fullSpan) {
    styles["--col-span"] = "1 / -1";
  } else if (colSpan) {
    styles["--col-span"] = `span ${colSpan}`;
  }

  if (flexGrow) styles["--flex-grow"] = flexGrow;
  if (flexShrink) styles["--flex-shrink"] = flexShrink;
  if (flexBasis) styles["--flex-basis"] = flexBasis;
  if (alignSelf) styles["--align-self"] = alignSelf;
  if (gridArea) {
    styles["--grid-area"] = gridArea;
    classes.push(css.col_grid_area);
  }

  return (
    <div style={styles} className={apply_classes(classes, className)}>
      {children}
    </div>
  );
}
