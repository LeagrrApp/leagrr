import { applyClasses } from "@/utils/helpers/html-attributes";
import { CSSProperties, PropsWithChildren } from "react";
import css from "./container.module.css";

interface ContainerProps {
  maxWidth?: string;
  flex?: boolean;
  className?: string | string[];
  grid?: boolean;
  noPadding?: boolean;
}

interface ContainerStyles extends CSSProperties {
  "--container-width"?: string;
}

export default function Container({
  children,
  maxWidth,
  className,
  grid,
  noPadding,
}: PropsWithChildren<ContainerProps>) {
  const styles: ContainerStyles = {};
  const classes: string[] = [css.container];

  if (grid) classes.push(css.container_grid);

  if (maxWidth) styles["--container-width"] = maxWidth;

  if (noPadding) classes.push(css.container_no_padding);

  return (
    <div style={styles} className={applyClasses(classes, className)}>
      {children}
    </div>
  );
}
