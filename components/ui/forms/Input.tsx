"use client";

import {
  ChangeEventHandler,
  PropsWithChildren,
  useEffect,
  useState,
} from "react";
import forms from "./forms.module.css";

interface InputWrapProps {
  isPassword: boolean;
}

function InputWrap({
  children,
  isPassword,
}: PropsWithChildren<InputWrapProps>) {
  if (isPassword) return <div className={forms.field_wrap}>{children}</div>;
  return <>{children}</>;
}

interface InputProps extends Partial<HTMLInputElement> {
  label: string;
  labelAfter?: boolean;
  labelAsPlaceholder?: boolean;
  onChange?: ChangeEventHandler;
  errors?: string[];
}

export default function Input({
  label,
  type,
  name,
  labelAfter,
  labelAsPlaceholder,
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
    <div className={forms.unit}>
      {!labelAfter && (
        <label className={forms.label} htmlFor={name}>
          {label}
        </label>
      )}
      <InputWrap isPassword={type === "password"}>
        <input
          className={forms.field}
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
        />
        {type === "password" && (
          <button
            className={
              inputType === "password"
                ? forms.toggle_password
                : `${forms.toggle_password} ${forms.toggle_password_visible}`
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
        <label className={forms.label} htmlFor={name}>
          {label}
        </label>
      )}
      {errors?.length && (
        <ul className={forms.errors}>
          {errors.map((err) => (
            <li key={err}>{err}</li>
          ))}
        </ul>
      )}
    </div>
  );
}
