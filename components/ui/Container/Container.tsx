import { CSSProperties, PropsWithChildren } from "react";
import css from "./container.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";

interface ContainerProps {
  maxWidth?: string;
  flex?: boolean;
  className?: string | string[];
  grid?: boolean;
}

interface ContainerStyles extends CSSProperties {
  "--container-width"?: string;
}

export default function Container({
  children,
  maxWidth,
  className,
  grid,
}: PropsWithChildren<ContainerProps>) {
  const styles: ContainerStyles = {};
  let classes: string[] = [css.container];

  if (className) {
    typeof className === "string"
      ? classes.push(className)
      : (classes = [...classes, ...className]);
  }

  if (grid) classes.push(css.container_grid);

  if (maxWidth) styles["--container-width"] = maxWidth;

  return (
    <div style={styles} className={apply_classes(classes)}>
      {children}
    </div>
  );
}
