import { CSSProperties, PropsWithChildren } from "react";
import layout from "./layout.module.css";

interface FlexProps {
  gap?: SizeOptions;
  justifyContent?: JustifyOptions;
  alignItems?: AlignOptions;
  direction?: AlignOptions;
}

interface FlexStyles extends CSSProperties {
  "--gap"?: string;
  "--justify-content"?: string;
  "--align-items"?: string;
  "--direction"?: string;
}

export default function Flex({
  children,
  gap,
  justifyContent,
  alignItems,
}: PropsWithChildren<FlexProps>) {
  const styles: FlexStyles = {};

  if (gap) styles["--gap"] = `var(--spacer-${gap})`;
  if (justifyContent) styles["--justify-content"] = justifyContent;
  if (alignItems) styles["--align-items"] = alignItems;

  return (
    <div style={styles} className={layout.flex}>
      {children}
    </div>
  );
}
