import { CSSProperties } from "react";
import css from "./alert.module.css";

interface AlertProps {
  alert: string | string[];
  type?: string;
  fontSize?: FontSizeOptions;
}

interface AlertStyles extends CSSProperties {
  "--alert-color": string;
  "--alert-bg": string;
  "--alert-font-size"?: string;
}

export default function Alert({ alert, type, fontSize }: AlertProps) {
  const styles: AlertStyles = {
    "--alert-color": `var(--color-${type || "primary"})`,
    "--alert-bg": `var(--color-${type || "primary"}-pale)`,
  };

  if (fontSize) {
    styles["--alert-font-size"] = `var(--type-scale-${fontSize})`;
  }

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
