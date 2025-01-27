import { applyColor, makeAcronym } from "@/utils/helpers/formatting";
import css from "./initialsCircle.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";
import { CSSProperties } from "react";

interface InitialsCircleProps {
  label: string;
  initialsStyle: "first_word" | "all";
  hideLabel?: boolean;
  fontSize?: FontSizeOptions;
  padding?: [SizeOptions, SizeOptions?];
  labelFirst?: boolean;
  gap?: SizeOptions;
  className?: string | string[];
  color?: {
    bg: ColorOptions | string;
    text: ColorOptions | string;
    border?: ColorOptions | string;
  };
}

interface InitialsCircleStyles extends CSSProperties {
  "--icl-gap"?: string;
  "--icl-font-size"?: string;
  "--icl-bg-color"?: string;
  "--icl-border-color"?: string;
  "--icl-text-color"?: string;
}

export default function InitialsCircle({
  label,
  initialsStyle,
  hideLabel,
  labelFirst,
  gap,
  fontSize,
  className,
  color,
}: InitialsCircleProps) {
  const styles: InitialsCircleStyles = {};

  if (fontSize) styles["--icl-font-size"] = `var(--type-scale-${fontSize})`;
  if (gap) styles["--icl-gap"] = `var(--spacer-${gap})`;

  if (color) {
    styles["--icl-bg-color"] = applyColor(color.bg);
    styles["--icl-border-color"] = applyColor(color.border || color.bg);
    styles["--icl-text-color"] = applyColor(color.text);
  }

  return (
    <div
      style={styles}
      className={apply_classes(css.initials_circle, className)}
    >
      {labelFirst && <span className={hideLabel ? "srt" : ""}>{label}</span>}
      <span className={css.initials_circle_letters}>
        {initialsStyle === "first_word"
          ? label.substring(0, 1).toUpperCase()
          : makeAcronym(label)}
      </span>
      {!labelFirst && <span className={hideLabel ? "srt" : ""}>{label}</span>}
    </div>
  );
}
