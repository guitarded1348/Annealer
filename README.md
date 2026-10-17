# ANNEALER

Identity and release site for ANNEALER. Plain HTML, CSS and JS. No build step.

## Edit the content

Everything lives in **`js/data.js`**: the narrator's lines, the Workshop lore,
every track, every release date, and the mailing-list copy.

- **Release dates.** Each phase has `sealedOn` (the countdown starts here, gauge at full heat)
  and `releaseDate` (the chamber opens, tracks appear). Use ISO dates with an offset:
  `"2026-12-11T19:00:00-05:00"`.
- **Preview a future date.** Set `site.previewDate` to e.g. `"2027-04-01T00:00:00Z"` to see every
  chamber open. Set it back to `null` before you deploy.
- **Audio.** Put files in an `audio/` folder and set a track's `audio` to `"audio/name.mp3"`.
  Empty `audio` plays a quiet synthesized placeholder hum.
- **Invisible ink.** A lore entry with `ink: true` only shows when a reader highlights it.

## Run locally

```sh
python3 -m http.server 8080
# open http://localhost:8080
```

## Deploy to Netlify

Drag the folder onto app.netlify.com/drop, or connect the repo. `netlify.toml` already sets
the publish directory to the repo root; there's no build command.

**Collect real signups:** add `name="counter" data-netlify="true"` to the `<form id="ledger">`
in `index.html`. The script notices the attribute and posts to Netlify Forms; entries show up
under Forms in the Netlify dashboard.

## Files

```
index.html     page structure and the hand-drawn SVGs
css/site.css   the look; temper colours are tokens at the top
js/data.js     all content and dates (edit this)
js/main.js     behaviour: scroll cooling, kilns, players, counter, easter eggs
404.html       for things that were never brought in
netlify.toml   deploy config
```

## For close readers

Spoilers. Don't read this if you're the audience.

1. **The constant.** The Boltzmann constant in the footer opens a tangled note that untangles
   itself with a real simulated-annealing run (Metropolis acceptance, geometric cooling).
2. **Seven pokes.** Tap the lehr seven times. Its door lifts and the pyrometer spikes.
3. **Invisible ink.** Two lines of Workshop lore are printed in soot. Highlight the gaps.
4. **Small print.** Intake numbers start at 273 (0 °C, in kelvin). There's a note in the page
   source and the browser console. Leave the name "Annealer" at the counter.
