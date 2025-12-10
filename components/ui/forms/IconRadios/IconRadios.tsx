"use client";
import { capitalize } from "@/utils/formatting";
import { useEffect, useState } from "react";
import Icon from "../../Icon/Icon";
import FauxLabel from "../FauxLabel";
import css from "./iconRadios.module.css";

interface IconRadiosProps {
  label: string;
  name: string;
  value: string;
  updateValue: (value: string) => void;
  choices: {
    value: string;
    icon: string;
    label?: string;
  }[];
}

export default function IconRadios({
  label,
  name,
  value,
  updateValue,
  choices,
}: IconRadiosProps) {
  const [checked, setChecked] = useState<string>(value);

  useEffect(() => {
    updateValue(checked);
  }, [checked, updateValue]);

  return (
    <div className={css.icon_radio_wrap}>
      <FauxLabel label={label} className={css.icon_radios_label} />
      <div className={css.icon_radios}>
        {choices.map((radio) => (
          <label key={radio.value} className={css.icon_radios_option}>
            <input
              type="radio"
              name={name}
              id={`${name}-${radio.value}`}
              value={radio.value}
              checked={radio.value === checked}
              onChange={(e) => setChecked(e.target.value)}
            />
            <Icon
              icon={radio.icon}
              className={css.icon_radios_icon}
              label={radio.label || capitalize(radio.value)}
            />
          </label>
        ))}
      </div>
    </div>
  );
}
