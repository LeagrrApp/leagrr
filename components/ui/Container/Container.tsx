import { CSSProperties, PropsWithChildren } from "react";
import container from "./container.module.css";

interface ContainerProps {
  maxWidth?: string;
}

interface ContainerStyles extends CSSProperties {
  "--container-width"?: string;
}

export default function Container({
  children,
  maxWidth,
}: PropsWithChildren<ContainerProps>) {
  const styles: ContainerStyles = {};

  if (maxWidth) styles["--container-width"] = maxWidth;

  return (
    <div style={styles} className={container.container}>
      {children}
    </div>
  );
}
