import type { Metadata } from "next";
import { Plus_Jakarta_Sans, Noto_Sans, Noto_Sans_Mono } from "next/font/google";
import "./globals.css";
import "material-symbols";
import TempNav from "@/components/ui/TempNav/TempNav";
import { apply_classes } from "@/utils/helpers/html-attributes";

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
      className={apply_classes([
        notoSans.variable,
        plusJakartaSans.variable,
        notoSansMono.variable,
      ])}
    >
      <body>{children}</body>
    </html>
  );
}
