"use client";

import { ChangeEvent, useEffect, useState } from "react";
import Alert from "../Alert/Alert";
import css from "./forms.module.css";
import Label from "./Label";

interface TextAreaProps extends Partial<HTMLTextAreaElement> {
  name: string;
  label: string;
  labelAfter?: boolean;
  hideLabel?: boolean;
  onChange?(e: ChangeEvent<HTMLTextAreaElement>): unknown;
  errors?: {
    errs?: string[];
    type?: string;
  };
  optional?: boolean;
}

export default function TextArea({
  label,
  name,
  labelAfter,
  hideLabel,
  placeholder,
  value,
  defaultValue,
  required,
  autocapitalize,
  onChange,
  errors,
  optional,
}: TextAreaProps) {
  const [textAreaValue, setTextAreaValue] = useState(
    value || defaultValue || "",
  );

  const placeholderText = !placeholder && hideLabel ? label : placeholder;

  useEffect(() => {
    setTextAreaValue(value || defaultValue || "");
  }, [value, defaultValue]);

  function handleChange(e: React.ChangeEvent<HTMLTextAreaElement>) {
    setTextAreaValue(e.currentTarget.value);

    if (onChange) onChange(e);
  }

  return (
    <div className={css.unit}>
      {!labelAfter && (
        <Label
          label={label}
          htmlFor={name}
          hideLabel={hideLabel}
          required={required}
          optional={optional}
        />
      )}
      <textarea
        className={css.field}
        name={name}
        id={name}
        onChange={handleChange}
        placeholder={placeholderText}
        value={textAreaValue}
        required={required}
        autoCapitalize={autocapitalize}
      />
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
