# slimbot-buitenmeting

**Outside-in uptime probe for [slimbot.nl](https://slimbot.nl/status), running on GitHub Actions.**

Monitoring that runs on your own servers goes down together with those servers, exactly
when you need it. This repo measures Slimbot from the outside:

- every minute: the login page, the live-chat API and the status page, each with response
  time and a content anchor (an HTTP 200 with the wrong page still counts as **down**)
- one JSON line per measurement in [`data/`](data), one file per UTC day
- the status page fetches this data itself (`git fetch`). **Nothing is pushed from here to
  our servers**, and the probe only reads.

```json
{"t":1795824001,"doel":"login","ok":1,"http":200,"ms":636,"reden":"","run":"46084727875"}
```

## Keeping the measurements running

Scheduled GitHub Actions often start late or get skipped. So each run measures 10 times
with a minute between rounds. At the end it **starts the next run itself** if none is
queued, with the `*/5` schedule as a backup. The chain keeps going even if our whole
platform is down, because nothing here depends on it.

- [`meet.sh`](meet.sh): the probe (curl + timing + anchor check)
- [`.github/workflows/meting.yml`](.github/workflows/meting.yml): schedule, self-restart,
  commit with rebase-retry

The live-chat probe URL is a repository secret.

---

*Meting van buitenaf voor slimbot.nl/status: elke minuut drie adressen, met responstijd. Draait op GitHub, los van ons eigen platform.*
