"use client";

import Button from "@/components/ui/Button/Button";
import Card from "@/components/ui/Card/Card";
import Input from "@/components/ui/forms/Input";
import Icon from "@/components/ui/Icon/Icon";
import Col from "@/components/ui/layout/Col";
import Grid from "@/components/ui/layout/Grid";
import { createDashboardUrl } from "@/utils/helpers/formatting";
import { useActionState, useEffect, useRef, useState } from "react";
import css from "./divisionInvite.module.css";
import { setDivisionJoinCode } from "@/actions/divisions";

interface DivisionInviteProps {
  division: DivisionData;
}

export default function DivisionInvite({ division }: DivisionInviteProps) {
  const {
    name,
    division_id,
    join_code,
    slug: division_slug,
    season_slug,
    league_slug,
    league_id,
  } = division;

  const dialogRef = useRef<HTMLDialogElement>(null);
  const [state, action, pending] = useActionState(
    setDivisionJoinCode,
    undefined,
  );
  const [joinCodeValue, setJoinCodeValue] = useState<string>(
    state?.data?.join_code || join_code || "",
  );
  const [updating, setUpdating] = useState<boolean>(false);
  const [hasBeenCopied, setHasBeenCopied] = useState<boolean>(false);

  function copyCodeLink() {
    const copyLink = createDashboardUrl(
      { l: league_slug, s: season_slug, d: division_slug },
      `join/?join_code=${joinCodeValue}`,
    );

    navigator.clipboard.writeText(
      encodeURI(`${window.location.origin}${copyLink}`),
    );

    setHasBeenCopied(true);

    setTimeout(() => {
      setHasBeenCopied(false);
    }, 2000);
  }

  useEffect(() => {
    state?.data?.join_code && setJoinCodeValue(state?.data?.join_code);
    setUpdating(false);
  }, [state]);

  if (state?.data?.join_code || (join_code && join_code !== "" && !updating))
    return (
      <>
        <Card padding="l" isContainer>
          <h3 className="push-m">Division Invite</h3>
          <p className="push">
            Invite teams to join <strong>{name}</strong>! This code allows teams
            to easily join <strong>{name}</strong> without needing a league
            administrator to approve a join request.
          </p>
          <dl className={css.join_code_info}>
            <dt>Division:</dt>
            <dd>
              <span className={css.join_code_info_line}>{name}</span>
            </dd>
            <dt>Code:</dt>
            <dd>
              <span className={css.join_code_info_line}>{joinCodeValue}</span>
            </dd>
          </dl>
          <div className={css.button_wrap}>
            <Button
              onClick={copyCodeLink}
              variant={hasBeenCopied ? "success" : "primary"}
            >
              <Icon
                icon={hasBeenCopied ? "check_circle" : "content_copy"}
                label={hasBeenCopied ? "Copied!" : "Copy Invite Link"}
              />
            </Button>
            <Button onClick={() => setUpdating(true)} variant="grey">
              <Icon icon="update" label="Update Join Code" />
            </Button>
          </div>
        </Card>
      </>
    );

  return (
    <>
      <Card padding="l">
        <h3 className="push-m">{updating ? "Update" : "Create a"} Join Code</h3>
        <p className="push-s">
          This code allows teams to easily join this division without needing a
          league administrator to approve a join request.
        </p>
        <small className="push block">
          <strong>Note:</strong> The code needs to be unique, minimum of 6
          characters and url safe, meaning no spaces or special characters. The
          code will automatically be made url safe in the database, so make sure
          to copy the correctly updated code provided after you click the update
          button.
        </small>
        <form action={action}>
          <Grid gap="base">
            <Col fullSpan>
              <Input
                name="join_code"
                label="Join Code"
                value={joinCodeValue}
                onChange={(e) => setJoinCodeValue(e.target.value)}
                placeholder="Ex. j4ts-4-l1f3"
                errors={{ errs: state?.errors?.join_code, type: "danger" }}
                required
                hideLabel
              />
            </Col>
            <input type="hidden" name="division_id" value={division_id} />
            <input type="hidden" name="league_id" value={league_id} />
            <Button
              onClick={() => dialogRef?.current?.showModal()}
              disabled={pending}
              type="submit"
            >
              <Icon
                icon={updating ? "update" : "add_circle"}
                label={updating ? "Update" : "Set Code"}
              />
            </Button>
            {updating && (
              <Button onClick={() => setUpdating(false)} variant="grey">
                <Icon icon="cancel" label="Cancel" />
              </Button>
            )}
          </Grid>
        </form>
        <form action="action"></form>
      </Card>
    </>
  );
}
