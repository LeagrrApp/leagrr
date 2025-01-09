import Menu from "@/components/dashboard/Menu/Menu";
import SkipLinks from "@/components/ui/accessibility/SkipLinks";
import css from "./layout.module.css";

export default function Layout({ children }: { children: React.ReactNode }) {
  const skipLinks: BasicLink[] = [
    {
      href: "#menu",
      text: "Skip to menu",
    },
    {
      href: "#main",
      text: "Skip to main area",
    },
  ];

  return (
    <div className={css.dashboard}>
      <SkipLinks links={skipLinks} />

      <Menu />

      <main id="main" tabIndex={0}>
        {children}
      </main>
    </div>
  );
}
