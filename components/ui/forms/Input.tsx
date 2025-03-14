"use client";

import { applyClasses } from "@/utils/helpers/html-attributes";
import { ChangeEvent, PropsWithChildren, useEffect, useState } from "react";
import Alert from "../Alert/Alert";
import css from "./forms.module.css";
import Label from "./Label";

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
  id?: string;
  label: string;
  name: string;
  labelAfter?: boolean;
  hideLabel?: boolean;
  noPlaceholder?: boolean;
  onChange?(e: ChangeEvent<HTMLInputElement>): unknown;
  errors?: {
    errs?: string[];
    type?: string;
  };
  optional?: boolean;
}

export default function Input({
  id,
  label,
  type,
  name,
  labelAfter,
  hideLabel,
  placeholder,
  noPlaceholder,
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
  className,
}: InputProps) {
  const [inputValue, setInputValue] = useState(value || defaultValue || "");
  const [inputType, setInputType] = useState(type || "");

  const placeholderText = !placeholder && hideLabel ? label : placeholder;

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
    <div className={applyClasses(css.unit, className)}>
      {!labelAfter && (
        <Label
          label={label}
          htmlFor={id || name}
          hideLabel={hideLabel}
          required={required}
          optional={optional}
        />
      )}
      <InputWrap isPassword={type === "password"}>
        <input
          className={css.field}
          type={inputType || "text"}
          name={name}
          id={id || name}
          onChange={handleChange}
          placeholder={!noPlaceholder ? placeholderText : undefined}
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
