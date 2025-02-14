"use client";

import { apply_classes_conditional } from "@/utils/helpers/html-attributes";
import { ChangeEvent, PropsWithChildren, useEffect, useState } from "react";
import Alert from "../Alert/Alert";
import css from "./forms.module.css";

interface InputWrapProps {
  isPassword: boolean;
}

function InputWrap({
  children,
  isPassword,
}: PropsWithChildren<InputWrapProps>) {
  if (isPassword) return <div className={css.field_wrap}>{children}</div>;
  return <>{children}</>;
}

interface InputProps extends Partial<HTMLInputElement> {
  label?: string;
  labelAfter?: boolean;
  labelAsPlaceholder?: boolean;
  hideLabel?: boolean;
  onChange?(e: ChangeEvent<HTMLInputElement>): unknown;
  errors?: {
    errs?: string[];
    type?: string;
  };
  optional?: boolean;
}

export default function Input({
  label,
  type,
  name,
  labelAfter,
  labelAsPlaceholder,
  hideLabel,
  placeholder,
  value,
  defaultValue,
  required,
  min,
  max,
  step,
  autocapitalize,
  onChange,
  errors,
  optional,
  disabled,
}: InputProps) {
  const [inputValue, setInputValue] = useState(value || defaultValue || "");
  const [inputType, setInputType] = useState(type || "");

  const placeholderText = labelAsPlaceholder ? label : placeholder;

  useEffect(() => {
    setInputValue(value || defaultValue || "");
  }, [value, defaultValue]);

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    setInputValue(e.currentTarget.value);

    if (onChange) onChange(e);
  }

  function togglePassword() {
    if (type !== "password") return;

    if (inputType === "password") {
      setInputType("text");
    } else {
      setInputType("password");
    }
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
      <InputWrap isPassword={type === "password"}>
        <input
          className={css.field}
          type={inputType || "text"}
          name={name}
          id={name}
          onChange={handleChange}
          placeholder={placeholderText}
          value={inputValue}
          min={min}
          max={max}
          step={step}
          required={required}
          autoCapitalize={autocapitalize}
          disabled={disabled}
        />
        {type === "password" && (
          <button
            className={
              inputType === "password"
                ? css.toggle_password
                : `${css.toggle_password} ${css.toggle_password_visible}`
            }
            onClick={togglePassword}
            type="button"
          >
            <i className="material-symbols-outlined">
              {inputType === "password" ? "visibility" : "visibility_off"}
            </i>
          </button>
        )}
      </InputWrap>
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
