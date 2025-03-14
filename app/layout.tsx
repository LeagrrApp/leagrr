import { applyClasses } from "@/utils/helpers/html-attributes";
import "material-symbols";
import type { Metadata } from "next";
import { Noto_Sans, Noto_Sans_Mono, Plus_Jakarta_Sans } from "next/font/google";
import "./globals.css";

const notoSans = Noto_Sans({
  variable: "--font-primary",
  subsets: ["latin"],
});

const plusJakartaSans = Plus_Jakarta_Sans({
  variable: "--font-secondary",
  subsets: ["latin"],
});

const notoSansMono = Noto_Sans_Mono({
  variable: "--font-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Leagrr",
  description: "Connect and Play",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en-CA"
      className={applyClasses([
        notoSans.variable,
        plusJakartaSans.variable,
        notoSansMono.variable,
      ])}
    >
      <body>{children}</body>
    </html>
  );
}
