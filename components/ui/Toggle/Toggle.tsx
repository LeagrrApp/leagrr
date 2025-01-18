import { ButtonHTMLAttributes } from "react";
import css from "./toggle.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";

interface ToggleProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  active: boolean;
}

export default function Toggle({
  active,
  className,
  onClick,
  "aria-label": ariaLabel,
}: ToggleProps) {
  const classes = [css.toggle];

  if (className) classes.push(className);

  if (active) classes.push(css.toggle_active);

  return (
    <button
      type="button"
      className={apply_classes(classes)}
      aria-label={ariaLabel}
      onClick={onClick}
    >
      <span className={css.tog_top}></span>
      <span className={css.tog_middle}></span>
      <span className={css.tog_bottom}></span>
    </button>
  );
}
