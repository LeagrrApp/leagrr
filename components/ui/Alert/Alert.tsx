import { CSSProperties } from "react";
import css from "./alert.module.css";

interface AlertProps {
  alert: string | string[];
  type?: string;
  fontSize?: FontSizeOptions;
  marginStart?: SizeOptions;
  marginEnd?: SizeOptions;
  center?: boolean;
}

interface AlertStyles extends CSSProperties {
  "--alert-color": string;
  "--alert-bg": string;
  "--alert-font-size"?: string;
  "--line-margin-start"?: string;
  "--line-margin-end"?: string;
}

export default function Alert({
  alert,
  type,
  fontSize,
  marginStart,
  marginEnd,
  center,
}: AlertProps) {
  const styles: AlertStyles = {
    "--alert-color": `var(--color-${type || "primary"})`,
    "--alert-bg": `var(--color-${type || "primary"}-lightest)`,
  };

  if (fontSize) {
    styles["--alert-font-size"] = `var(--type-scale-${fontSize})`;
  }

  if (marginStart)
    styles["--line-margin-start"] = `var(--spacer-${marginStart})`;
  if (marginEnd) styles["--line-margin-end"] = `var(--spacer-${marginEnd})`;
  if (center) styles.textAlign = "center";

  if (typeof alert === "string")
    return (
      <div style={styles} className={css.alert}>
        {alert}
      </div>
    );

  if (alert?.length)
    return (
      <ul style={styles} className={css.alert}>
        {alert.map((msg) => (
          <li key={msg}>{msg}</li>
        ))}
      </ul>
    );
}
