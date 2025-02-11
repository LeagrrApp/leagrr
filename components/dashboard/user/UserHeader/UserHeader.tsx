"use client";

import { nameDisplay } from "@/utils/helpers/formatting";
import DHeader from "../../DHeader/DHeader";
import ProfileImg from "@/components/ui/ProfileImg/ProfileImg";
import css from "./userHeader.module.css";
import Badge from "@/components/ui/Badge/Badge";
import Icon from "@/components/ui/Icon/Icon";
import { usePathname } from "next/navigation";

interface UserHeaderProps {
  user: UserData;
  canEdit: boolean;
  editLink: string;
}

// basic details: name, username, pronoun/gender, profile pic/icon
export default function UserHeader({
  canEdit,
  user,
  editLink,
}: UserHeaderProps) {
  const pathname = usePathname();

  const { first_name, last_name, username, gender, pronouns, user_role, img } =
    user;

  const name = nameDisplay(first_name, last_name, "full");

  return (
    <DHeader
      className={css.user_header}
      containerClassName={css.user_header_container}
      color={"primary"}
    >
      <ProfileImg label={name} src={img} size={150} />
      <div>
        <h1 className={css.user_headline}>
          {name}
          {canEdit && pathname !== editLink && (
            <Icon
              icon="edit_square"
              label="Edit Profile"
              hideLabel
              href={editLink}
              size="h3"
            />
          )}
        </h1>
        <p className={css.user_info}>
          <span className={css.user_username}>@{username}</span>
          {gender || pronouns ? " | " : undefined}
          {gender}
          {gender && pronouns ? ", " : undefined}
          {pronouns}{" "}
          {user_role === 1 && (
            <Badge text="Site Admin" fontSize="s" type="secondary" />
          )}
          {user_role === 2 && <Badge text="Commissioner" fontSize="s" />}
        </p>
      </div>
    </DHeader>
  );
}
