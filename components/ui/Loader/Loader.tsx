import { apply_classes } from "@/utils/helpers/html-attributes";
import css from "./loader.module.css";

interface LoaderProps {
  className?: string | string[];
  centered?: boolean;
}

export default function Loader({ className, centered }: LoaderProps) {
  const classes: string[] = [css.loader];

  if (centered) classes.push(css.loader_centered);

  return (
    <div className={apply_classes(classes, className)}>
      <svg
        className={css.loader_spinner}
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 72 72"
      >
        <circle
          className={css.loader_bg}
          cx="36"
          cy="36"
          r="32"
          strokeMiterlimit="10"
        />
        <circle
          className={css.loader_fg}
          cx="36"
          cy="36"
          r="32"
          strokeMiterlimit="10"
        />
      </svg>
    </div>
  );
}
