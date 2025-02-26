import { apply_classes, paddingString } from "@/utils/helpers/html-attributes";
import Link from "next/link";
import { AnchorHTMLAttributes, CSSProperties } from "react";
import css from "./icon.module.css";

interface IconProps extends AnchorHTMLAttributes<HTMLAnchorElement> {
  icon: string;
  label: string;
  hideLabel?: boolean;
  size?: FontSizeOptions;
  padding?: [SizeOptions, SizeOptions?];
  labelFirst?: boolean;
  gap?: SizeOptions;
  onClick?: (event: React.MouseEvent<HTMLAnchorElement>) => void;
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
    onClick,
  } = props;

  const styles: IconStyles = {};
  const classes: string[] = [css.icon];

  if (hideLabel) {
    classes.push(css.icon_only);
  }

  const finalClasses = apply_classes(classes, className);

  if (size) styles["--icon-size"] = `var(--type-scale-${size})`;
  if (padding) styles["--icon-padding"] = paddingString(padding);
  if (gap) styles["--icon-gap"] = `var(--spacer-${gap})`;

  if (href) {
    return (
      <Link
        style={styles}
        href={href}
        className={finalClasses}
        aria-current={props["aria-current"]}
        onClick={onClick}
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
    <div style={styles} className={finalClasses}>
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
