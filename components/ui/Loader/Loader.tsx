import css from "./loader.module.css";

export default function Loader() {
  return (
    <div className={css.loader}>
      <svg
        className={css.loader_spinner}
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 72 72"
      >
        <circle
          className={css.loader_bg}
          cx="36"
          cy="36"
          r="32"
          strokeMiterlimit="10"
        />
        <circle
          className={css.loader_fg}
          cx="36"
          cy="36"
          r="32"
          strokeMiterlimit="10"
        />
      </svg>
    </div>
  );
}
