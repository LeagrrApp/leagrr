import { apply_classes, paddingString } from "@/utils/helpers/html-attributes";
import { Url } from "next/dist/shared/lib/router/router";
import Link from "next/link";
import { ButtonHTMLAttributes, CSSProperties } from "react";
import css from "./button.module.css";

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  href?: Url;
  variant?: ColorOptions | "transparent";
  outline?: boolean;
  size?: "h1" | "h2" | "h3" | "h4" | "h5" | "s" | "xs";
  fullWidth?: boolean;
  asSpan?: boolean;
  padding?: [SizeOptions, SizeOptions?];
  ariaLabel?: string | undefined;
}

interface ButtonStyles extends CSSProperties {
  "--btn-size"?: string;
  "--btn-padding"?: string;
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
  padding,
  disabled,
  ariaLabel,
}: ButtonProps) {
  const classes = [css.button];

  if (className) classes.push(className);

  const styles: ButtonStyles = { ...style };

  if (variant) {
    classes.push(css[`button_${variant}`]);
  }

  if (outline) {
    classes.push(css.button_outline);
  }

  if (size) {
    styles["--btn-size"] = `var(--type-scale-${size})`;
  }

  if (fullWidth) {
    classes.push(css.button_full_width);
  }

  if (disabled) {
    classes.push(css.button_disabled);
  }

  if (padding) styles["--btn-padding"] = paddingString(padding);

  if (href)
    return (
      <Link
        style={styles}
        className={apply_classes(classes)}
        href={href}
        aria-label={ariaLabel}
      >
        {children}
      </Link>
    );

  if (asSpan)
    return (
      <span style={styles} className={apply_classes(classes)}>
        {children}
      </span>
    );

  return (
    <button
      style={styles}
      className={apply_classes(classes)}
      type={type}
      onClick={onClick}
      aria-label={ariaLabel}
      disabled={disabled}
    >
      {children}
    </button>
  );
}
