"use client";
import IconSport from "@/components/ui/Icon/IconSport";
import { sports_options } from "@/lib/definitions";
import { capitalize } from "@/utils/helpers/formatting";
import { useEffect, useState } from "react";
import css from "./sportPicker.module.css";

interface SportPickerProps {
  initialSport: string;
  updateSport: (value: string) => void;
}

export default function SportPicker({
  initialSport,
  updateSport,
}: SportPickerProps) {
  const [sport, setSport] = useState<string>(initialSport);

  useEffect(() => {
    updateSport(sport);
  }, [sport, updateSport]);

  return (
    <fieldset>
      <legend className="label">Sport</legend>
      <div className={css.sport_wrap}>
        {sports_options.map((s) => {
          return (
            <label
              className={css.sport_option}
              key={s}
              htmlFor={`sport-${s}`}
              title={
                s !== "hockey"
                  ? "Sport currently unavailable, coming soon!"
                  : undefined
              }
            >
              <IconSport
                className={css.sport_icon}
                sport={s}
                label={capitalize(s)}
                size="h2"
              />
              <input
                type="radio"
                name="sport"
                id={`sport-${s}`}
                value={s}
                onChange={(e) => setSport(e.target.value)}
                checked={s === sport}
                disabled={s !== "hockey"}
              />
            </label>
          );
        })}
      </div>
    </fieldset>
  );
}
