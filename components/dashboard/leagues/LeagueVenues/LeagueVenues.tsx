"use client";

import { removeLeagueVenue } from "@/actions/venues";
import Alert from "@/components/ui/Alert/Alert";
import Button from "@/components/ui/Button/Button";
import Dialog from "@/components/ui/Dialog/Dialog";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import Table from "@/components/ui/Table/Table";
import { Truncate } from "@/components/ui/Truncate/Truncate";
import { addressAsGoogleMapsLink } from "@/utils/helpers/formatting";
import { usePathname } from "next/navigation";
import { useActionState, useRef, useState } from "react";
import LeagueVenueAdd from "./LeagueVenueAdd/LeagueVenueAdd";

interface LeagueVenuesProps {
  venues?: LeagueVenueData[];
  league: LeagueData;
}

export default function LeagueVenues({ venues, league }: LeagueVenuesProps) {
  const pathname = usePathname();
  const removeDialogRef = useRef<HTMLDialogElement>(null);

  const [removeState, removeAction, removePending] = useActionState(
    removeLeagueVenue,
    {
      link: pathname,
      data: {},
    },
  );

  const [venueToRemove, setVenueToRemove] = useState<
    LeagueVenueData | undefined
  >(() => {
    if (venues) return venues[0];
    return undefined;
  });

  const tableHeadings = [
    { title: "Venue", highlightCol: true },
    { title: "Address" },
    { title: "Arenas" },
    { title: "Remove" },
  ];

  function removeVenue(index: number) {
    if (!venues) return;

    setVenueToRemove(venues[index]);
    removeDialogRef?.current?.showModal();
  }

  return (
    <>
      <Table className="push">
        <thead>
          <tr>
            {tableHeadings.map((th) => (
              <th
                key={th.title}
                scope="col"
                data-highlight-col={th.highlightCol}
              >
                {th.title}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {venues && venues.length > 0 ? (
            venues.map((v, i) => (
              <tr key={v.league_venue_id}>
                <th>{v.venue}</th>
                <td>
                  <a
                    href={addressAsGoogleMapsLink(v.address)}
                    target="_blank"
                    data-no-full-hover
                  >
                    <Truncate text={v.address} />
                  </a>
                </td>
                <td>{v.arenas}</td>
                <td>
                  <Button
                    style={{ position: "relative" }}
                    variant="danger"
                    onClick={() => removeVenue(i)}
                  >
                    <Icon icon="delete" label="Remove venue" hideLabel />
                  </Button>
                </td>
              </tr>
            ))
          ) : (
            <tr>
              <td colSpan={4}>
                <Alert
                  alert="This league does not have any venues!"
                  type="grey"
                />
              </td>
            </tr>
          )}
        </tbody>
      </Table>
      {venueToRemove && (
        <Dialog ref={removeDialogRef}>
          <form action={removeAction}>
            <Grid cols={2} gap="base">
              <Col fullSpan>
                <h3>Are you sure you want to remove {venueToRemove.venue}?</h3>
              </Col>
              <input
                type="hidden"
                name="league_venue_id"
                value={venueToRemove.league_venue_id}
              />
              {removeState?.message && removeState?.status !== 200 && (
                <Col fullSpan>
                  <Alert alert={removeState.message} type="danger" />
                </Col>
              )}
              <Button type="submit" disabled={removePending} variant="danger">
                <Icon icon="delete" label="Confirm" />
              </Button>
              <Button
                onClick={() => removeDialogRef?.current?.close()}
                variant="grey"
              >
                <Icon icon="cancel" label="Cancel" />
              </Button>
            </Grid>
          </form>
        </Dialog>
      )}
      <LeagueVenueAdd league_id={league.league_id} />
    </>
  );
}
