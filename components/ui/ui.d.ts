type SizeOptions = "s" | "m" | "ml" | "base" | "l" | "xl";

type FontSizeOptions =
  | "h1"
  | "h2"
  | "h3"
  | "h4"
  | "h5"
  | "h6"
  | "base"
  | "s"
  | "xs";

type JustifyOptions =
  | "start"
  | "end"
  | "center"
  | "space-between"
  | "space-around"
  | "space-evenly";

type AlignOptions = "start" | "end" | "center";

type DirectionOptions = "row" | "row-reverse" | "column" | "column-reverse";

type BasicLink = {
  href: string;
  text: string;
};

type ColorOptions =
  | "primary"
  | "secondary"
  | "accent"
  | "success"
  | "warning"
  | "danger"
  | "grey";
