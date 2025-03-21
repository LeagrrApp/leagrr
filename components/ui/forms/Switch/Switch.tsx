import { applyClasses } from "@/utils/helpers/html-attributes";
import { ChangeEventHandler, useEffect, useState } from "react";
import css from "./switch.module.css";

interface SwitchProps extends Partial<HTMLInputElement> {
  label: string;
  labelRight?: boolean;
  noSpread?: boolean;
  onChange: ChangeEventHandler;
}

export default function Switch({
  id,
  label,
  name,
  labelRight,
  noSpread,
  onChange,
  checked,
  className,
}: SwitchProps) {
  const [classNames, setClassNames] = useState(css.switch_wrap);

  useEffect(() => {
    setClassNames(
      checked ? `${css.switch_wrap} ${css.switch_checked}` : css.switch_wrap,
    );
  }, [checked]);

  return (
    <div className={applyClasses(css.switch, className)}>
      <label
        className={`${css.switch_label}${
          noSpread ? ` ${css.switch_label_no_spread}` : ""
        }`}
        htmlFor={id || name}
      >
        {!labelRight && label}
        <div className={classNames}>
          <span className={css.switch_toggle}></span>
        </div>
        {labelRight && label}
      </label>
      <input
        type="checkbox"
        name={name}
        id={id || name}
        onChange={onChange}
        checked={checked}
      />
    </div>
  );
}
