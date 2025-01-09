import { CSSProperties, PropsWithChildren } from "react";
import container from "./container.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";

interface ContainerProps {
  maxWidth?: string;
  flex?: boolean;
  className?: string | string[];
}

interface ContainerStyles extends CSSProperties {
  "--container-width"?: string;
}

export default function Container({
  children,
  maxWidth,
  className,
}: PropsWithChildren<ContainerProps>) {
  const styles: ContainerStyles = {};
  let classes: string[] = [container.container];

  if (className) {
    typeof className === "string"
      ? classes.push(className)
      : (classes = [...classes, ...className]);
  }

  if (maxWidth) styles["--container-width"] = maxWidth;

  return (
    <div style={styles} className={apply_classes(classes)}>
      {children}
    </div>
  );
}
