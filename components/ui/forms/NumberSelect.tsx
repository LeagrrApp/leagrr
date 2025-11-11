"use client";

import { ChangeEvent, useState } from "react";
import Alert from "../Alert/Alert";
import forms from "./forms.module.css";
import Label from "./Label";

interface NumberSelectProps extends Partial<HTMLSelectElement> {
  name: string;
  label: string;
  labelAfter?: boolean;
  hideLabel?: boolean;
  min: number;
  max: number;
  onChange?(e: ChangeEvent<HTMLSelectElement>): unknown;
  errors?: {
    errs?: string[];
    type?: string;
  };
  selected?: string | number;
  optional?: boolean;
}

export default function NumberSelect({
  id,
  label,
  name,
  labelAfter,
  hideLabel,
  min,
  max,
  selected,
  required,
  autocapitalize,
  onChange,
  errors,
  disabled,
  optional,
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
        <Label
          label={label}
          htmlFor={id || name}
          hideLabel={hideLabel}
          required={required}
          optional={optional}
        />
      )}
      <select
        className={forms.field}
        name={name}
        id={id || name}
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
        <Label
          label={label}
          htmlFor={id || name}
          hideLabel={hideLabel}
          required={required}
          optional={optional}
        />
      )}
      {errors?.errs?.length && <Alert alert={errors.errs} type={errors.type} />}
    </div>
  );
}
