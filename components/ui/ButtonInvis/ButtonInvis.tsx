import { ButtonHTMLAttributes, PropsWithChildren } from "react";
import css from "./buttonInvis.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";

export default function ButtonInvis(
  props: PropsWithChildren<ButtonHTMLAttributes<HTMLButtonElement>>
) {
  return (
    <button
      {...props}
      className={apply_classes(css.button_invisible, props.className)}
    >
      {props.children}
    </button>
  );
}
