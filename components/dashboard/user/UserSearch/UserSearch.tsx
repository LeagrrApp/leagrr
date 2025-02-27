"use client";

import { userSearchAction } from "@/actions/users";
import Button from "@/components/ui/Button/Button";
import Input from "@/components/ui/forms/Input";
import Icon from "@/components/ui/Icon/Icon";
import { useActionState, useEffect } from "react";
import css from "./userSearch.module.css";

interface UserSearchProps {
  setSearchResult: (value: {
    users?: UserData[];
    count?: number;
    complete: boolean;
  }) => void;
}

export default function UserSearch({ setSearchResult }: UserSearchProps) {
  const [searchState, searchAction, searchPending] = useActionState(
    userSearchAction,
    undefined,
  );

  useEffect(() => {
    if (searchState?.data?.users)
      setSearchResult({
        users: searchState?.data?.users,
        count: searchState?.data?.users.length,
        complete: true,
      });
  }, [searchState, setSearchResult]);

  return (
    <form className={css.form} action={searchAction}>
      <Input
        className={css.input}
        type="search"
        name="query"
        label="Search Users"
        hideLabel
        required
      />
      <Button type="submit" disabled={searchPending}>
        <Icon icon="search" label="Search" />
      </Button>
    </form>
  );
}
