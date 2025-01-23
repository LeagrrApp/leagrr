"use client"; // Error boundaries must be Client Components

import Button from "@/components/ui/Button/Button";
import Container from "@/components/ui/Container/Container";
import { useEffect } from "react";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // Log the error to an error reporting service
    console.error(error);
  }, [error]);

  return (
    <main
      style={{ minHeight: "100dvh", display: "flex", alignItems: "center" }}
    >
      <Container maxWidth="35rem">
        <strong
          style={{
            fontSize: "var(--type-scale-h3)",
            fontStyle: "italic",
            color: "var(--color-primary)",
          }}
        >
          Leagrr
        </strong>
        <h1 className="push">Yikes, something went wrong!</h1>
        <p className="push">{error.message}</p>
        <Button
          onClick={
            // Attempt to recover by trying to re-render the segment
            () => reset()
          }
        >
          Try again
        </Button>
      </Container>
    </main>
  );
}
