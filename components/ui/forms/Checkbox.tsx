"use client";

import { apply_classes } from "@/utils/helpers/html-attributes";
import { ChangeEvent, useState } from "react";
import Alert from "../Alert/Alert";
import css from "./forms.module.css";

interface CheckboxProps extends Partial<HTMLInputElement> {
  name: string;
  label?: string;
  labelFirst?: boolean;
  labelAsPlaceholder?: boolean;
  onChange?(e: ChangeEvent<HTMLInputElement>): unknown;
  errors?: {
    errs?: string[];
    type?: string;
  };
  optional?: boolean;
}

export default function Checkbox({
  id,
  label,
  name,
  labelFirst,
  value,
  required,
  onChange,
  errors,
  checked,
}: CheckboxProps) {
  const [isChecked, setIsChecked] = useState(checked || false);

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    setIsChecked(!isChecked);

    if (onChange) onChange(e);
  }

  return (
    <div className={apply_classes(css.unit, css.unit_checkbox)}>
      {labelFirst && (
        <label className={css.label} htmlFor={name}>
          {label}
        </label>
      )}
      <input
        className={css.checkbox}
        type="checkbox"
        name={name}
        id={id || name}
        onChange={handleChange}
        value={value}
        required={required}
        checked={isChecked}
      />
      {!labelFirst && (
        <label className={css.label} htmlFor={name}>
          {label}
        </label>
      )}
      {errors?.errs?.length && <Alert alert={errors.errs} type={errors.type} />}
    </div>
  );
}
