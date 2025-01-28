"use client";

import { ChangeEventHandler, useEffect, useState } from "react";
import css from "./forms.module.css";
import Alert from "../Alert/Alert";

interface TextAreaProps extends Partial<HTMLTextAreaElement> {
  label: string;
  labelAfter?: boolean;
  labelAsPlaceholder?: boolean;
  onChange?: ChangeEventHandler;
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
  labelAsPlaceholder,
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

  const placeholderText = labelAsPlaceholder ? label : placeholder;

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
        <label className={css.label} htmlFor={name}>
          {label}{" "}
          {optional && <span className={css.label_optional}>(Optional)</span>}
        </label>
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
        <label className={css.label} htmlFor={name}>
          {label}{" "}
          {optional && <span className={css.label_optional}>(Optional)</span>}
        </label>
      )}
      {errors?.errs?.length && <Alert alert={errors.errs} type={errors.type} />}
    </div>
  );
}
