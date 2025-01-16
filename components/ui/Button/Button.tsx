import { CSSProperties } from "react";
import button from "./button.module.css";
import Link from "next/link";
import { apply_classes } from "@/utils/helpers/html-attributes";
import { ButtonProps } from "../ui";

interface ButtonStyles extends CSSProperties {
  "--btn-size"?: string;
}

export default function Button({
  children,
  href,
  onClick,
  type = "button",
  style,
  variant,
  outline,
  size,
  fullWidth,
  asSpan,
  className,
}: ButtonProps) {
  const classes = [button.button];

  if (className) classes.push(className);

  const styles: ButtonStyles = {};

  if (variant) {
    classes.push(button[`button_${variant}`]);
  }

  if (outline) {
    classes.push(button.button_outline);
  }

  if (size) {
    styles["--btn-size"] = `var(--type-scale-${size})`;
  }

  if (fullWidth) {
    classes.push(button.button_full_width);
  }

  if (href)
    return (
      <Link style={styles} className={apply_classes(classes)} href={href}>
        {children}
      </Link>
    );

  if (asSpan)
    return (
      <span style={style} className={apply_classes(classes)}>
        {children}
      </span>
    );

  return (
    <button
      style={style}
      className={apply_classes(classes)}
      type={type}
      onClick={onClick}
    >
      {children}
    </button>
  );
}
