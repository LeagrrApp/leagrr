"use client";

import { ChangeEvent, useState } from "react";
import Alert from "../Alert/Alert";
import forms from "./forms.module.css";

interface NumberSelectProps extends Partial<HTMLSelectElement> {
  label: string;
  labelAfter?: boolean;
  min: number;
  max: number;
  onChange?(e: ChangeEvent<HTMLSelectElement>): unknown;
  errors?: {
    errs?: string[];
    type?: string;
  };
  selected?: string | number;
}

export default function NumberSelect({
  label,
  name,
  labelAfter,
  min,
  max,
  selected,
  required,
  autocapitalize,
  onChange,
  errors,
  disabled,
}: NumberSelectProps) {
  const [selectValue, setSelectValue] = useState<string | number | undefined>(
    selected || "",
  );

  function handleChange(e: React.ChangeEvent<HTMLSelectElement>) {
    setSelectValue(e.currentTarget.value);

    if (onChange) onChange(e);
  }

  const choices: string[] = [];

  for (let index = min; index <= max; index++) {
    choices.push(index.toString());
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
        required={required}
        autoCapitalize={autocapitalize}
        value={selectValue}
        disabled={disabled}
      >
        {choices?.map((choice) => {
          return (
            <option key={`${name}-${choice}`} value={choice}>
              {choice}
            </option>
          );
        })}
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
