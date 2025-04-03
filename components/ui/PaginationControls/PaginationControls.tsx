"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";
import Icon from "../Icon/Icon";
import css from "./paginationControls.module.css";

interface PaginationControlsProps {
  page: number;
  perPage: number;
  total: number;
  baseUrl: string;
}

export default function PaginationControls({
  page,
  perPage,
  total,
  baseUrl,
}: PaginationControlsProps) {
  const searchParams = useSearchParams();

  const [maxPageNum, setMaxPageNum] = useState<number>(
    Math.ceil(total / perPage),
  );
  const [prePages, setPrePages] = useState<number[]>([]);
  const [postPages, setPostPages] = useState<number[]>([]);

  useEffect(() => {
    const showCount = 2;

    // set before options
    let i = 0;
    let p = page - 1;

    const newPrePages = [];

    while (p > 1 && p < page && i < showCount) {
      newPrePages.push(p);

      i = i + 1;
      p = p - 1;
    }

    // set after options
    i = 0;
    p = page + 1;

    const newPostPages = [];

    while (p < maxPageNum && p > page && i < showCount) {
      newPostPages.push(p);

      i = i + 1;
      p = p + 1;
    }

    setPrePages(newPrePages.reverse());
    setPostPages(newPostPages);
  }, [page, perPage, maxPageNum]);

  useEffect(() => {
    setMaxPageNum(Math.ceil(total / perPage));
  }, [total, perPage]);

  if (total < perPage) return null;

  const queryParams = new URLSearchParams(searchParams);
  queryParams.delete("page");

  return (
    <nav className={css.pagination}>
      {page > 1 && (
        <Icon
          className={css.prev}
          href={`${baseUrl}?${queryParams}${page !== 2 ? `&page=${page - 1}` : ""}`}
          icon="chevron_left"
          label="Prev"
          gap="m"
          aria-label="Previous page"
        />
      )}
      <ol className={css.pages}>
        {page !== 1 && (
          <li className={css.pre_page}>
            <Link href={`${baseUrl}?${queryParams}`}>1</Link>
          </li>
        )}
        {prePages[0] > 2 && (
          <li className={css.ellipse} aria-hidden="true">
            ...
          </li>
        )}
        {prePages.map((p) => (
          <li className={css.pre_page} key={p}>
            <Link href={`${baseUrl}?${queryParams}&page=${p}`}>{p}</Link>
          </li>
        ))}
        <li aria-current="page">
          <strong>{page}</strong>
        </li>
        {postPages.map((p) => (
          <li className={css.post_page} key={p} style={{ color: "red" }}>
            <Link href={`${baseUrl}?${queryParams}&page=${p}`}>{p}</Link>
          </li>
        ))}
        {postPages[postPages.length - 1] < maxPageNum - 1 && (
          <li className={css.ellipse} aria-hidden="true">
            ...
          </li>
        )}
        {maxPageNum !== page && (
          <>
            <li className={css.slash} aria-hidden="true">
              /
            </li>
            <li>
              <Link href={`${baseUrl}?${queryParams}&page=${maxPageNum}`}>
                {maxPageNum}
              </Link>
            </li>
          </>
        )}
      </ol>
      {page * perPage < total && (
        <Icon
          className={css.next}
          href={`${baseUrl}?${queryParams}&page=${page + 1}`}
          icon="chevron_right"
          label="Next"
          gap="m"
          labelFirst
          aria-label="Next page"
        />
      )}
    </nav>
  );
}
