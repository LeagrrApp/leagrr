import { CSSProperties } from "react";
import css from "./badge.module.css";

interface BadgeProps {
  text: string;
  type?: string;
  fontSize?: FontSizeOptions;
}

interface BadgeStyles extends CSSProperties {
  "--badge-color": string;
  "--badge-bg": string;
  "--badge-font-size"?: string;
}

export default function Badge({ text, type, fontSize }: BadgeProps) {
  const styles: BadgeStyles = {
    "--badge-color": `var(--color-${type || "primary"})`,
    "--badge-bg": `var(--color-${type || "primary"}-pale)`,
  };

  if (fontSize) {
    styles["--badge-font-size"] = `var(--type-scale-${fontSize})`;
  }

  return (
    <span style={styles} className={css.badge}>
      {text}
    </span>
  );
}
