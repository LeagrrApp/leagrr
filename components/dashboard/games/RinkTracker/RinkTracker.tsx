"use client";

import Icon from "@/components/ui/Icon/Icon";
import { CSSProperties, useRef } from "react";
import css from "./rinkTracker.module.css";

interface RinkTrackerProps {
  rinkItems: RinkItem[];
  linkPrefix?: string;
  handleAdd?: (coordinates: string) => void;
}

interface FeedItemStyles extends CSSProperties {
  "--rm-top": string;
  "--rm-left": string;
  "--rm-color": string;
}

export default function RinkTracker({
  rinkItems,
  linkPrefix,
  handleAdd,
}: RinkTrackerProps) {
  const iceRef = useRef<SVGPathElement>(null);

  function handleClick(e: React.MouseEvent<SVGPathElement>) {
    // cancel if no handleAdd function provided
    if (!handleAdd) return;

    const rinkWidth = iceRef?.current?.getBoundingClientRect()?.width;
    const rinkHeight = iceRef?.current?.getBoundingClientRect()?.height;

    const { offsetX, offsetY } = e.nativeEvent;

    if (!rinkWidth || !rinkHeight || !offsetX || !offsetY) return;

    const xPercent = Math.round((offsetX / rinkWidth) * 10000) / 100;
    const yPercent = Math.round((offsetY / rinkHeight) * 10000) / 100;

    handleAdd(`${xPercent}% ${yPercent}%`);
  }

  if (!rinkItems || rinkItems.length < 1) return null;

  return (
    <div className={css.rink_wrap}>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1001.08 432">
        <path
          className={css.fill_ice}
          d="M1000.5,337.96c0,51.66-41.88,93.54-93.54,93.54H94.04c-51.66,0-93.54-41.88-93.54-93.54V94.04C.5,42.38,42.38.5,94.04.5h812.91c51.66,0,93.54,41.88,93.54,93.54v243.91Z"
        />
        <rect
          className={css.fill_blue}
          x={363.33}
          y={0.5}
          width={6}
          height={431}
        />
        <rect
          className={css.fill_blue}
          x={636.67}
          y={0.5}
          width={6}
          height={431}
        />
        <path
          className={css.fill_blue}
          d="M503.83,290c-41.82,0-75.83-34.02-75.83-75.83s34.02-75.83,75.83-75.83,75.83,34.02,75.83,75.83-34.02,75.83-75.83,75.83ZM503.83,139.33c-41.26,0-74.83,33.57-74.83,74.83s33.57,74.83,74.83,74.83,74.83-33.57,74.83-74.83-33.57-74.83-74.83-74.83Z"
        />
        <path
          className={css.fill_crease}
          d="M93.17,195.92h-22v39.08h21.58s7.58-6.83,7.58-18.75-7.17-20.33-7.17-20.33Z"
        />
        <path
          className={css.fill_crease}
          d="M912.71,195.92h22v39.08h-21.58s-7.58-6.83-7.58-18.75,7.17-20.33,7.17-20.33Z"
        />
        <g>
          <circle className={css.fill_red} cx={391} cy={105.5} r={4.25} />
          <circle className={css.fill_red} cx={614.5} cy={105.5} r={4.25} />
          <circle className={css.fill_red} cx={391} cy={322.5} r={4.25} />
          <circle className={css.fill_red} cx={614.5} cy={322.5} r={4.25} />
          <path
            className={css.fill_red}
            d="M182.12,30.3v-9.3h-1v9.17c-2.83-.32-5.71-.5-8.62-.5s-5.79.18-8.62.5v-9.17h-1v9.3c-37.28,4.75-66.21,36.65-66.21,75.2s28.92,70.45,66.21,75.2v9.42h1v-9.3c2.83.32,5.71.5,8.62.5s5.79-.18,8.62-.5v9.3h1v-9.42c37.28-4.75,66.21-36.65,66.21-75.2s-28.93-70.45-66.21-75.2ZM172.5,180.33c-41.26,0-74.83-33.57-74.83-74.83S131.24,30.67,172.5,30.67s74.83,33.57,74.83,74.83-33.57,74.83-74.83,74.83Z"
          />
          <circle className={css.fill_red} cx={172.42} cy={105.5} r={4.25} />
          <polygon
            className={css.fill_red}
            points="162.67 100.67 144.5 100.67 144.5 101.67 163.67 101.67 163.67 90.17 162.67 90.17 162.67 100.67"
          />
          <polygon
            className={css.fill_red}
            points="182.33 90.17 181.33 90.17 181.33 101.67 200.5 101.67 200.5 100.67 182.33 100.67 182.33 90.17"
          />
          <polygon
            className={css.fill_red}
            points="144.5 110.27 162.67 110.27 162.67 120.77 163.67 120.77 163.67 109.27 144.5 109.27 144.5 110.27"
          />
          <polygon
            className={css.fill_red}
            points="181.33 120.77 182.33 120.77 182.33 110.27 200.5 110.27 200.5 109.27 181.33 109.27 181.33 120.77"
          />
          <path
            className={css.fill_red}
            d="M182.12,246.3v-9.3h-1v9.17c-2.83-.32-5.71-.5-8.62-.5s-5.79.18-8.62.5v-9.17h-1v9.3c-37.28,4.75-66.21,36.65-66.21,75.2s28.92,70.45,66.21,75.2v9.42h1v-9.3c2.83.32,5.71.5,8.62.5s5.79-.18,8.62-.5v9.3h1v-9.42c37.28-4.75,66.21-36.65,66.21-75.2,0-38.55-28.92-70.45-66.21-75.2ZM172.5,396.33c-41.26,0-74.83-33.57-74.83-74.83s33.57-74.83,74.83-74.83,74.83,33.57,74.83,74.83c0,41.26-33.57,74.83-74.83,74.83Z"
          />
          <circle className={css.fill_red} cx={172.42} cy={321.5} r={4.25} />
          <polygon
            className={css.fill_red}
            points="162.67 316.67 144.5 316.67 144.5 317.67 163.67 317.67 163.67 306.17 162.67 306.17 162.67 316.67"
          />
          <polygon
            className={css.fill_red}
            points="182.33 306.17 181.33 306.17 181.33 317.67 200.5 317.67 200.5 316.67 182.33 316.67 182.33 306.17"
          />
          <polygon
            className={css.fill_red}
            points="144.5 326.27 162.67 326.27 162.67 336.77 163.67 336.77 163.67 325.27 144.5 325.27 144.5 326.27"
          />
          <polygon
            className={css.fill_red}
            points="181.33 336.77 182.33 336.77 182.33 326.27 200.5 326.27 200.5 325.27 181.33 325.27 181.33 336.77"
          />
          <path
            className={css.fill_red}
            d="M822.88,180.7v9.42h1v-9.3c2.83.32,5.71.5,8.62.5s5.79-.18,8.62-.5v9.3h1v-9.42c37.28-4.75,66.21-36.65,66.21-75.2s-28.93-70.45-66.21-75.2v-9.3h-1v9.17c-2.83-.32-5.71-.5-8.62-.5s-5.79.18-8.62.5v-9.17h-1v9.3c-37.28,4.75-66.21,36.65-66.21,75.2s28.92,70.45,66.21,75.2ZM832.5,30.67c41.26,0,74.83,33.57,74.83,74.83s-33.57,74.83-74.83,74.83-74.83-33.57-74.83-74.83,33.57-74.83,74.83-74.83Z"
          />
          <circle className={css.fill_red} cx={832.42} cy={105.5} r={4.25} />
          <polygon
            className={css.fill_red}
            points="823.67 90.17 822.67 90.17 822.67 100.67 804.5 100.67 804.5 101.67 823.67 101.67 823.67 90.17"
          />
          <polygon
            className={css.fill_red}
            points="860.5 100.67 842.33 100.67 842.33 90.17 841.33 90.17 841.33 101.67 860.5 101.67 860.5 100.67"
          />
          <polygon
            className={css.fill_red}
            points="822.67 120.77 823.67 120.77 823.67 109.27 804.5 109.27 804.5 110.27 822.67 110.27 822.67 120.77"
          />
          <polygon
            className={css.fill_red}
            points="842.33 110.27 860.5 110.27 860.5 109.27 841.33 109.27 841.33 120.77 842.33 120.77 842.33 110.27"
          />
          <path
            className={css.fill_red}
            d="M842.12,246.3v-9.3h-1v9.17c-2.83-.32-5.71-.5-8.62-.5s-5.79.18-8.62.5v-9.17h-1v9.3c-37.28,4.75-66.21,36.65-66.21,75.2s28.92,70.45,66.21,75.2v9.42h1v-9.3c2.83.32,5.71.5,8.62.5s5.79-.18,8.62-.5v9.3h1v-9.42c37.28-4.75,66.21-36.65,66.21-75.2s-28.93-70.45-66.21-75.2ZM832.5,396.33c-41.26,0-74.83-33.57-74.83-74.83s33.57-74.83,74.83-74.83,74.83,33.57,74.83,74.83-33.57,74.83-74.83,74.83Z"
          />
          <circle className={css.fill_red} cx={832.42} cy={321.5} r={4.25} />
          <polygon
            className={css.fill_red}
            points="822.67 316.67 804.5 316.67 804.5 317.67 823.67 317.67 823.67 306.17 822.67 306.17 822.67 316.67"
          />
          <polygon
            className={css.fill_red}
            points="842.33 306.17 841.33 306.17 841.33 317.67 860.5 317.67 860.5 316.67 842.33 316.67 842.33 306.17"
          />
          <polygon
            className={css.fill_red}
            points="804.5 326.27 822.67 326.27 822.67 336.77 823.67 336.77 823.67 325.27 804.5 325.27 804.5 326.27"
          />
          <polygon
            className={css.fill_red}
            points="841.33 336.77 842.33 336.77 842.33 326.27 860.5 326.27 860.5 325.27 841.33 325.27 841.33 336.77"
          />
          <path
            className={css.fill_red}
            d="M1001.08,321.47l-.08-.04V94.04c0-51.86-42.19-94.04-94.04-94.04H94.04C42.19,0,0,42.19,0,94.04v243.91c0,51.86,42.19,94.04,94.04,94.04h812.91c51.86,0,94.04-42.19,94.04-94.04v-16.31l.08-.17ZM935.21,136.5l64.79-30.68v215.14l-64.79-30.44v-154.02ZM1000,94.04v10.67l-64.79,30.68V5.39c37.53,11.99,64.79,47.2,64.79,88.65ZM500,42.92c-22.11-1.29-39.73-19.55-39.99-41.92h39.99v41.92ZM506,1h38.99c-.26,22.03-17.35,40.07-38.99,41.84V1ZM70.67,290.51L1,323.39V103.62l69.67,32.86v154.03ZM70.67,3.98v131.4L1,102.51v-8.47C1,50.81,30.64,14.37,70.67,3.98ZM1,337.96v-13.47l69.67-32.88v136.41C30.64,417.63,1,381.19,1,337.96ZM71.67,428.27v-192.77h21.28l.14-.13c.32-.29,7.75-7.12,7.75-19.12s-7.21-20.57-7.29-20.66l-.15-.18h-21.73V3.73c7.17-1.78,14.66-2.73,22.38-2.73h364.97c.26,22.92,18.33,41.63,40.99,42.92v387.08H94.04c-7.71,0-15.21-.95-22.38-2.73ZM71.67,234.5v-38.08h21.26c1,1.26,6.9,9.18,6.9,19.83s-6.28,17.26-7.28,18.25h-20.88ZM506,431V43.85c22.19-1.78,39.73-20.27,39.99-42.85h360.97c9.48,0,18.63,1.43,27.25,4.08v190.34h-21.73l-.15.18c-.07.09-7.29,8.7-7.29,20.66s7.43,18.84,7.75,19.12l.14.13h21.28v191.42c-8.62,2.65-17.77,4.08-27.25,4.08h-400.96ZM934.21,196.42v38.08h-20.88c-1.01-.99-7.28-7.58-7.28-18.25,0-10.66,5.91-18.57,6.91-19.83h21.26ZM935.21,426.61v-134.98l64.79,30.44v15.89c0,41.46-27.26,76.66-64.79,88.65Z"
          />
        </g>
        <circle className={css.fill_blue} cx={503} cy={214} r={3} />
        <path
          onClick={handleClick}
          ref={iceRef}
          className={css.fill_none}
          d="M1000.5,337.96c0,51.66-41.88,93.54-93.54,93.54H94.04c-51.66,0-93.54-41.88-93.54-93.54V94.04C.5,42.38,42.38.5,94.04.5h812.91c51.66,0,93.54,41.88,93.54,93.54v243.91Z"
        />
      </svg>
      {rinkItems.map((item, i) => {
        const styles: FeedItemStyles = {
          "--rm-top": item.coordinates.split(" ")[1],
          "--rm-left": item.coordinates.split(" ")[0],
          "--rm-color": item.color,
        };

        if (linkPrefix && item.item_id && item.type)
          return (
            <a
              href={`#${linkPrefix}-${item.type}-${item.item_id}`}
              style={styles}
              key={i}
              className={css.rink_marker}
            >
              <Icon icon={item.icon} label="Example" hideLabel />
            </a>
          );

        return (
          <span style={styles} key={i} className={css.rink_marker}>
            <Icon icon={item.icon} label="Example" hideLabel />
          </span>
        );
      })}
    </div>
  );
}
