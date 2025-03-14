import { applyClassesConditional } from "@/utils/helpers/html-attributes";
import css from "./forms.module.css";

interface LabelProps {
  label: string;
  htmlFor: string;
  hideLabel?: boolean;
  required?: boolean;
  optional?: boolean;
}

export default function Label({
  label,
  htmlFor,
  hideLabel,
  required,
  optional,
}: LabelProps) {
  return (
    <label
      className={applyClassesConditional(css.label, "srt", hideLabel)}
      htmlFor={htmlFor}
    >
      {label}
      {required && (
        <span className={css.label_required} aria-hidden="true">
          *
        </span>
      )}{" "}
      {optional && <span className={css.label_optional}>(Optional)</span>}
    </label>
  );
}
