"use client";

import { apply_classes_conditional } from "@/utils/helpers/html-attributes";
import { ChangeEvent, useEffect, useState } from "react";
import Alert from "../Alert/Alert";
import css from "./forms.module.css";

interface TextAreaProps extends Partial<HTMLTextAreaElement> {
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
        <label
          className={apply_classes_conditional(css.label, "srt", hideLabel)}
          htmlFor={name}
        >
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
        <label
          className={apply_classes_conditional(css.label, "srt", hideLabel)}
          htmlFor={name}
        >
          {label}{" "}
          {optional && <span className={css.label_optional}>(Optional)</span>}
        </label>
      )}
      {errors?.errs?.length && <Alert alert={errors.errs} type={errors.type} />}
    </div>
  );
}
