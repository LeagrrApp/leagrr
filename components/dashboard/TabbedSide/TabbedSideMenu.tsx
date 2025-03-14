"use client";

import Icon from "@/components/ui/Icon/Icon";
import { usePathname } from "next/navigation";
import css from "./tabbedSide.module.css";

interface TabbedSideMenuProps {
  menuItems: {
    icon: string;
    label: string;
    url: string;
  }[];
}

export function TabbedSideMenu({ menuItems }: TabbedSideMenuProps) {
  const pathname = usePathname();

  return (
    <nav className={css.menu}>
      <ul>
        {menuItems.map((item) => (
          <li key={item.url}>
            <Icon
              icon={item.icon}
              label={item.label}
              padding={["ml", "base"]}
              href={item.url}
              aria-current={pathname === item.url || undefined}
            />
          </li>
        ))}
      </ul>
    </nav>
  );
}
