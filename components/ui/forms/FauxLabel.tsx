import { applyClasses } from "@/utils/html-attributes";
import css from "./forms.module.css";

interface LabelProps {
  label: string;
  hideLabel?: boolean;
  required?: boolean;
  optional?: boolean;
  className?: string;
}

export default function FauxLabel({
  label,
  required,
  optional,
  className,
}: LabelProps) {
  return (
    <p className={applyClasses(css.label, className)}>
      {label}
      {required && (
        <span className={css.label_required} aria-hidden="true">
          *
        </span>
      )}{" "}
      {optional && <span className={css.label_optional}>(Optional)</span>}
    </p>
  );
}
