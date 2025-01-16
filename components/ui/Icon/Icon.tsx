import { Url } from "next/dist/shared/lib/router/router";
import css from "./icon.module.css";
import { apply_classes, paddingString } from "@/utils/helpers/html-attributes";
import Link from "next/link";
import { CSSProperties } from "react";
// TODO: fix how to no longer need these imports?
import { FontSizeOptions, SizeOptions } from "../ui";

interface IconProps {
  icon: string;
  label: string;
  hideLabel?: boolean;
  href?: Url;
  className?: string;
  size?: FontSizeOptions;
  padding?: SizeOptions[];
}

interface IconStyles extends CSSProperties {
  "--icon-size"?: string;
  "--icon-padding"?: string;
}

export default function Icon({
  icon,
  label,
  hideLabel,
  href,
  className,
  size,
  padding,
}: IconProps) {
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

  if (href) {
    return (
      <Link style={styles} href={href} className={apply_classes(classes)}>
        <i className="material-symbols-outlined">{icon}</i>
        <span className={hideLabel ? `${css.icon_label} srt` : css.icon_label}>
          {label}
        </span>
      </Link>
    );
  }

  return (
    <div style={styles} className={apply_classes(classes)}>
      <i className="material-symbols-outlined">{icon}</i>
      <span className={hideLabel ? `${css.icon_label} srt` : css.icon_label}>
        {label}
      </span>
    </div>
  );
}
