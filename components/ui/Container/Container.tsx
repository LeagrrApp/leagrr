import { apply_classes } from "@/utils/helpers/html-attributes";
import { CSSProperties, PropsWithChildren } from "react";
import css from "./container.module.css";

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
  const classes: string[] = [css.container];

  if (grid) classes.push(css.container_grid);

  if (maxWidth) styles["--container-width"] = maxWidth;

  return (
    <div style={styles} className={apply_classes(classes, className)}>
      {children}
    </div>
  );
}
