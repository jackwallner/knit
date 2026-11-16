# @knit.math 14-day readout

Day 1 is the first post: D01 on 2026-11-14. Jack moved to 3 posts a day, so the 9 drawn posts run out on 2026-11-17 and the hands posts follow as they are filmed. The checks stay on calendar days.

## Collected automatically

`stats.py` runs at the start of every daily job on the iMac and appends to `~/.knitmath-social/stats.jsonl`: followers, following, likes, video count (public profile, no login). Posts and skips are in `~/.knitmath-social/status.json` and `~/knitmath-social/done/tiktok.txt`.

Per-post numbers are not public. They are read in the TikTok app on moto-2 (video > ... > Analytics, and Profile > menu > Creator tools > Analytics), only while moto-2 is free (`python3 ~/knitmath-social/tt_app.py check` prints `free`).

## Per post (from the app)

Views, average watch time, watched full video %, likes, comments, shares, saves, new followers from the post, For You share of traffic, and any "not eligible for For You" notice. Tag each post drawn or hands.

## Account (from the app)

Followers, profile views (7 days), total views (7 days).

## When

| Check | Date | What decides it |
|---|---|---|
| Day 3 | 2026-11-16 | Day 1 post past 48 h: under 100 views means look for a For You notice first |
| Day 7 | 2026-11-20 | Any post under 100 views after 48 h: check the For You notice before changing anything |
| Day 14 | 2026-11-27 | Every post read at least 48 h after it went up |

## Day 14 verdict (thresholds from the warm-up plan)

- Continue: one post at 5,000+ views, or median 800+ views with 75+ followers, or saves above 1.5% of views on 3+ posts with 1,000+ views.
- Change format: median 200 to 800, followers 20 to 75, and hands beat drawn (or the reverse). Go heavier on the winner.
- Stop or pause: median under 150, followers under 15, saves near zero, hands no better than drawn.
- Scale: Mahj Tips' best post is 2,667 views and 53 followers.
