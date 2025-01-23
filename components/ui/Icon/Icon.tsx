import { Url } from "next/dist/shared/lib/router/router";
import css from "./icon.module.css";
import { apply_classes, paddingString } from "@/utils/helpers/html-attributes";
import Link from "next/link";
import { AnchorHTMLAttributes, CSSProperties } from "react";

interface IconProps extends AnchorHTMLAttributes<HTMLAnchorElement> {
  icon: string;
  label: string;
  hideLabel?: boolean;
  size?: FontSizeOptions;
  padding?: [SizeOptions, SizeOptions?];
  labelFirst?: boolean;
  gap?: SizeOptions;
}

interface IconStyles extends CSSProperties {
  "--icon-size"?: string;
  "--icon-padding"?: string;
  "--icon-gap"?: string;
}

export default function Icon(props: IconProps) {
  const {
    icon,
    label,
    hideLabel,
    href,
    className,
    size,
    padding,
    labelFirst,
    gap,
  } = props;

  const styles: IconStyles = {};
  let classes: string[] = [css.icon];

  if (className) {
    typeof className === "string"
      ? classes.push(className)
      : (classes = [...classes, ...className]);
  }

  if (hideLabel) {
    classes.push(css.icon_only);
  }

  if (size) styles["--icon-size"] = `var(--type-scale-${size})`;
  if (padding) styles["--icon-padding"] = paddingString(padding);
  if (gap) styles["--icon-gap"] = `var(--spacer-${gap})`;

  if (href) {
    return (
      <Link
        style={styles}
        href={href}
        className={apply_classes(classes)}
        aria-current={props["aria-current"]}
      >
        {labelFirst && (
          <span
            className={hideLabel ? `${css.icon_label} srt` : css.icon_label}
          >
            {label}
          </span>
        )}
        <i className="material-symbols-outlined" aria-hidden="true">
          {icon}
        </i>
        {!labelFirst && (
          <span
            className={hideLabel ? `${css.icon_label} srt` : css.icon_label}
          >
            {label}
          </span>
        )}
      </Link>
    );
  }

  return (
    <div style={styles} className={apply_classes(classes)}>
      {labelFirst && (
        <span className={hideLabel ? `${css.icon_label} srt` : css.icon_label}>
          {label}
        </span>
      )}
      <i className="material-symbols-outlined">{icon}</i>
      {!labelFirst && (
        <span className={hideLabel ? `${css.icon_label} srt` : css.icon_label}>
          {label}
        </span>
      )}
    </div>
  );
}
