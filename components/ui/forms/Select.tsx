"use client";

import { ChangeEvent, ChangeEventHandler, useEffect, useState } from "react";
import forms from "./forms.module.css";
import Alert from "../Alert/Alert";
import { capitalize } from "@/utils/helpers/formatting";

interface SelectProps extends Partial<HTMLSelectElement> {
  label: string;
  labelAfter?: boolean;
  onChange?(e: ChangeEvent<HTMLSelectElement>): any;
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
  label,
  name,
  labelAfter,
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
        <label className={forms.label} htmlFor={name}>
          {label}
        </label>
      )}
      {errors?.errs?.length && <Alert alert={errors.errs} type={errors.type} />}
    </div>
  );
}
