import css from "./forms.module.css";

interface LabelProps {
  label: string;
  hideLabel?: boolean;
  required?: boolean;
  optional?: boolean;
}

export default function FauxLabel({ label, required, optional }: LabelProps) {
  return (
    <p className={css.label}>
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
