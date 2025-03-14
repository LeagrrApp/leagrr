import { applyClasses } from "@/utils/helpers/html-attributes";
import { CSSProperties, DialogHTMLAttributes, RefObject } from "react";
import css from "./dialog.module.css";

interface DialogProps extends DialogHTMLAttributes<HTMLDialogElement> {
  ref: RefObject<HTMLDialogElement | null>;
  closeButton?: boolean;
  maxWidth?: string;
}

interface DialogStyles extends CSSProperties {
  "--dialog-width"?: string;
}

export default function Dialog({
  children,
  className,
  style,
  maxWidth,
  closeButton,
  ref,
}: DialogProps) {
  // const { className, style, maxWidth, closeButton, ref } = props;

  const classes = [css.dialog];

  if (className) classes.push(className);

  const styles: DialogStyles = style || {};

  if (maxWidth) styles["--dialog-width"] = maxWidth;

  return (
    <dialog style={styles} className={applyClasses(classes)} ref={ref}>
      {closeButton && (
        <button className={css.close} onClick={() => ref?.current?.close()}>
          <i className="material-symbols-outlined">close</i>
          <span className="srt">Close dialog</span>
        </button>
      )}

      {children}
    </dialog>
  );
}
