import { applyClasses } from "@/utils/helpers/html-attributes";
import { ButtonHTMLAttributes, PropsWithChildren } from "react";
import css from "./buttonInvis.module.css";

export default function ButtonInvis(
  props: PropsWithChildren<ButtonHTMLAttributes<HTMLButtonElement>>,
) {
  return (
    <button
      {...props}
      className={applyClasses(css.button_invisible, props.className)}
    >
      {props.children}
    </button>
  );
}
