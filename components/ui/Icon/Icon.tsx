import { Url } from "next/dist/shared/lib/router/router";
import css from "./icon.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";
import Link from "next/link";

interface IconProps {
  icon: string;
  label: string;
  hideLabel?: boolean;
  href?: Url;
  className?: string;
}

export default function Icon({
  icon,
  label,
  hideLabel,
  href,
  className,
}: IconProps) {
  let classes: string[] = [css.icon];

  if (className) {
    typeof className === "string"
      ? classes.push(className)
      : (classes = [...classes, ...className]);
  }

  if (href) {
    return (
      <Link href={href} className={apply_classes(classes)}>
        <i className="material-symbols-outlined">{icon}</i>
        <span className={hideLabel ? `${css.icon_label} srt` : css.icon_label}>
          {label}
        </span>
      </Link>
    );
  }

  return (
    <div className={apply_classes(classes)}>
      <i className="material-symbols-outlined">{icon}</i>
      <span className={hideLabel ? `${css.icon_label} srt` : css.icon_label}>
        {label}
      </span>
    </div>
  );
}
