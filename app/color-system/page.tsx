import Container from "@/components/ui/Container/Container";
import Grid from "@/components/ui/layout/Grid";
import {
  applyColor,
  capitalize,
  color_options,
} from "@/utils/helpers/formatting";

export default function Page() {
  const variants: ("dark" | "darker" | "medium" | "light" | "lightest")[] = [
    "darker",
    "dark",
    "medium",
    "light",
    "lightest",
  ];
  return (
    <Container>
      <div style={{ paddingBlock: "var(--spacer-xl" }}>
        <Grid gap="l">
          {color_options.map((color) => {
            if (color !== "white" && color !== "black") {
              return (
                <div key={color}>
                  <h2 className="push-ml">{capitalize(color)}</h2>
                  <Grid cols={6}>
                    <div
                      style={{
                        aspectRatio: 1,
                        width: "100%",
                        backgroundColor: applyColor(color),
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        boxShadow: "0 0 0.5rem #0002",
                      }}
                    >
                      Base
                    </div>
                    {variants.map((v) => {
                      const colorVar = applyColor(color, v);

                      return (
                        <div
                          key={`${color}-${v}`}
                          style={{
                            aspectRatio: 1,
                            width: "100%",
                            backgroundColor: colorVar,
                            color:
                              v === "dark" || v === "darker"
                                ? "white"
                                : undefined,
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            boxShadow: "0 0 0.5rem #0002",
                          }}
                        >
                          {capitalize(v)}
                        </div>
                      );
                    })}
                  </Grid>
                </div>
              );
            }
          })}
        </Grid>
      </div>
    </Container>
  );
}
