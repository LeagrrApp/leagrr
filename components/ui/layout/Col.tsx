import { CSSProperties, PropsWithChildren } from "react";
import layout from "./layout.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";

interface ColProps {
  colSpan?: number;
  fullSpan?: boolean;
  flexGrow?: string | number;
  flexShrink?: string | number;
  flexBasis?: string;
  alignSelf?: string;
  className?: string;
}

interface ColStyles extends CSSProperties {
  "--col-span"?: string;
  "--flex-grow"?: string | number;
  "--flex-shrink"?: string | number;
  "--flex-basis"?: string;
  "--align-self"?: string;
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
}: PropsWithChildren<ColProps>) {
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

  return (
    <div style={styles} className={apply_classes(layout.col, className)}>
      {children}
    </div>
  );
}
