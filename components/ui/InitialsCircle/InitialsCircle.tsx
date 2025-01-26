import { makeAcronym } from "@/utils/helpers/formatting";
import css from "./initialsCircle.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";
import { CSSProperties } from "react";

interface InitialsCircleProps {
  label: string;
  initialsStyle: "first_word" | "all";
  hideLabel?: boolean;
  size?: FontSizeOptions;
  padding?: [SizeOptions, SizeOptions?];
  labelFirst?: boolean;
  gap?: SizeOptions;
  className?: string | string[];
  color?: {
    bg: ColorOptions;
    text: ColorOptions;
  };
}

interface InitialsCircleStyles extends CSSProperties {
  "--icl-gap"?: string;
  "--icl-size"?: string;
  "--icl-font-size"?: string;
  "--icl-bg-color"?: string;
  "--icl-text-color"?: string;
}

export default function InitialsCircle({
  label,
  initialsStyle,
  hideLabel,
  padding,
  labelFirst,
  gap,
  className,
  color,
}: InitialsCircleProps) {
  const styles: InitialsCircleStyles = {};

  if (color) {
    styles["--icl-bg-color"] = `var(--color-${color.bg})`;
    styles["--icl-text-color"] = `var(--color-${color.text})`;
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
