import css from "./truncate.module.css";

interface TruncateProps {
  text: string;
}

export function Truncate({ text }: TruncateProps) {
  return <div className={css.truncate}>{text}</div>;
}
