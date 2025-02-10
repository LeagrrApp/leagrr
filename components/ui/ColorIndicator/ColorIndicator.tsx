import { apply_classes } from "@/utils/helpers/html-attributes";
import css from "./colorIndicator.module.css";
import { CSSProperties } from "react";

interface ColorIndicatorProps {
  color: string;
  size?: string;
}

interface ColorIndicatorStyles extends CSSProperties {
  "--ci-color": string;
  "--ci-size"?: string;
}

export default function ColorIndicator({ color, size }: ColorIndicatorProps) {
  const classes = [css.color_indicator];
  const styles: ColorIndicatorStyles = {
    "--ci-color": color,
  };

  if (size) styles["--ci-size"] = size;

  return <span style={styles} className={apply_classes(classes)}></span>;
}
