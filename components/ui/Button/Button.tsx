import { ButtonHTMLAttributes, CSSProperties } from "react";
import button from "./button.module.css";
import { Url } from "next/dist/shared/lib/router/router";
import Link from "next/link";
import { apply_classes } from "@/utils/helpers/html-attributes";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  href?: Url;
  variant?: "secondary" | "accent";
  outline?: boolean;
  size?: "h1" | "h2" | "h3" | "h4" | "h5";
  fullWidth?: boolean;
  asSpan?: boolean;
}

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
}: ButtonProps) {
  const classes = [button.button];

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
