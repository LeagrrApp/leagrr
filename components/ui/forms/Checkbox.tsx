"use client";

import { ChangeEventHandler, useState } from "react";
import css from "./forms.module.css";
import Alert from "../Alert/Alert";
import { apply_classes } from "@/utils/helpers/html-attributes";

interface CheckboxProps extends Partial<HTMLInputElement> {
  label?: string;
  labelFirst?: boolean;
  labelAsPlaceholder?: boolean;
  onChange?: ChangeEventHandler;
  errors?: {
    errs?: string[];
    type?: string;
  };
  optional?: boolean;
}

export default function Checkbox({
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
        id={name}
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
