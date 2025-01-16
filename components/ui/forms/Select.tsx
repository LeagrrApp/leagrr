"use client";

import { ChangeEventHandler, useEffect, useState } from "react";
import forms from "./forms.module.css";
import Alert from "../Alert/Alert";

interface SelectProps extends Partial<HTMLSelectElement> {
  label: string;
  labelAfter?: boolean;
  labelAsPlaceholder?: boolean;
  onChange?: ChangeEventHandler;
  errors?: {
    errs?: string[];
    type?: string;
  };
  choices: { label: string; value: string | number }[];
}

export default function Select({
  label,
  name,
  labelAfter,
  choices,
  value,
  required,
  autocapitalize,
  onChange,
  errors,
}: SelectProps) {
  const [selectValue, setSelectValue] = useState(value || "");

  useEffect(() => {
    setSelectValue(value || "");
  }, [value]);

  function handleChange(e: React.ChangeEvent<HTMLSelectElement>) {
    setSelectValue(e.currentTarget.value);

    if (onChange) onChange(e);
  }

  return (
    <div className={forms.unit}>
      {!labelAfter && (
        <label className={forms.label} htmlFor={name}>
          {label}
        </label>
      )}
      <select
        className={forms.field}
        name={name}
        id={name}
        onChange={handleChange}
        value={selectValue}
        required={required}
        autoCapitalize={autocapitalize}
      >
        {choices?.map((choice) => (
          <option key={choice.value} value={choice.value}>
            {choice.label}
          </option>
        ))}
      </select>
      {labelAfter && (
        <label className={forms.label} htmlFor={name}>
          {label}
        </label>
      )}
      {errors?.errs?.length && <Alert alert={errors.errs} type={errors.type} />}
    </div>
  );
}
