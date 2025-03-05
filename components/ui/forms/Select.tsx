"use client";

import { capitalize } from "@/utils/helpers/formatting";
import { ChangeEvent, useEffect, useState } from "react";
import Alert from "../Alert/Alert";
import forms from "./forms.module.css";
import Label from "./Label";

interface SelectProps extends Partial<HTMLSelectElement> {
  name: string;
  label: string;
  labelAfter?: boolean;
  hideLabel?: boolean;
  onChange?(e: ChangeEvent<HTMLSelectElement>): unknown;
  errors?: {
    errs?: string[];
    type?: string;
  };
  choices: string[] | SelectOption[] | readonly [string, ...string[]];
  selected?: string | number;
  blankFirst?: boolean;
  optional?: boolean;
}

export default function Select({
  name,
  label,
  labelAfter,
  hideLabel,
  choices,
  selected,
  required,
  onChange,
  errors,
  disabled,
  blankFirst,
  optional,
}: SelectProps) {
  const [selectValue, setSelectValue] = useState<string | number | undefined>(
    selected || "",
  );

  useEffect(() => {
    setSelectValue(selected || "");
  }, [selected]);

  function handleChange(e: React.ChangeEvent<HTMLSelectElement>) {
    setSelectValue(e.currentTarget.value);

    if (onChange) onChange(e);
  }

  return (
    <div className={forms.unit}>
      {!labelAfter && (
        <Label
          label={label}
          htmlFor={name}
          hideLabel={hideLabel}
          required={required}
          optional={optional}
        />
      )}
      <select
        className={forms.field}
        name={name}
        id={name}
        onChange={handleChange}
        required={required}
        value={selectValue}
        disabled={disabled}
      >
        {blankFirst && <option value="" disabled={!optional}></option>}
        {choices?.map((choice) => {
          if (typeof choice === "object") {
            return (
              <option
                key={choice.value}
                value={choice.value}
                disabled={choice.value === ""}
              >
                {choice.label}
              </option>
            );
          }
          return (
            <option
              key={`${name}-${choice}`}
              value={choice}
              disabled={choice === ""}
            >
              {capitalize(choice)}
            </option>
          );
        })}
      </select>
      {labelAfter && (
        <Label
          label={label}
          htmlFor={name}
          hideLabel={hideLabel}
          required={required}
          optional={optional}
        />
      )}
      {errors?.errs?.length && <Alert alert={errors.errs} type={errors.type} />}
    </div>
  );
}
