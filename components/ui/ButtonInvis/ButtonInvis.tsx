import { ButtonHTMLAttributes, PropsWithChildren } from "react";
import css from "./buttonInvis.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";

export default function ButtonInvis(
  props: PropsWithChildren<ButtonHTMLAttributes<HTMLButtonElement>>
) {
  // add custom class name, combine if extra class names are added when using component
  const classes = props.className
    ? [css.button_invisible, props.className]
    : css.button_invisible;

  return (
    <button {...props} className={apply_classes(classes)}>
      {props.children}
    </button>
  );
}
