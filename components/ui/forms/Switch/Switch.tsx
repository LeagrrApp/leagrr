import { ChangeEventHandler, useEffect, useState } from "react";
import css from "./switch.module.css";
import { apply_classes } from "@/utils/helpers/html-attributes";

interface SwitchProps extends Partial<HTMLInputElement> {
  label: string;
  labelRight?: boolean;
  noSpread?: boolean;
  onChange: ChangeEventHandler;
}

export default function Switch({
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
      checked ? `${css.switch_wrap} ${css.switch_checked}` : css.switch_wrap
    );
  }, [checked]);

  return (
    <div className={apply_classes(css.switch, className)}>
      <label
        className={`${css.switch_label}${
          noSpread ? ` ${css.switch_label_no_spread}` : ""
        }`}
        htmlFor={name}
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
        id={name}
        onChange={onChange}
        checked={checked}
      />
    </div>
  );
}
