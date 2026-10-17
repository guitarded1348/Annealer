# ANNEALER

Identity and release site for ANNEALER. Plain HTML, CSS and JS. No build step.

## Edit the content

Everything lives in **`js/data.js`**: the narrator's lines, the Workshop lore, the Keeper's Log,
every track, every release date, and the mailing-list copy.

- **`site.litOn`.** The day the project started. Drives "Lehr lit N days ago", the Day numbers
  in the log, and how hot the first chamber has grown.
- **The Keeper's Log.** Add `{ date, text }` to `log.entries` whenever there's progress (or none).
  Newest shows first. The four entries there now are examples; replace them.
- **Release dates.** Leave `releaseDate: null` until you know. The first undated chamber shows
  "Heating" with a gauge that creeps up over time; later ones show "Cold". Set a date and that
  chamber gets a live countdown; when it passes, the tracks appear as intake tags.
  `sealedOn` (optional) is when the countdown gauge starts at full heat.
- **Tracks.** Add them to a phase's `tracks`. Titles stay hidden until release; a sealed
  chamber only shows how many objects are inside.
- **See how a release looks.** Set `site.showExamples: true` to open Chamber I with example tags.
  Keep it `false` on the live site.
- **Audio.** Put files in an `audio/` folder and set a track's `audio` to `"audio/name.mp3"`.
  Empty `audio` plays a quiet synthesized placeholder hum.
- **Counter replies.** `counter.replies` is a pool; one is picked at random after each signup.
- **Invisible ink.** A lore entry with `ink: true` only shows when a reader highlights it.

## Run locally

```sh
python3 -m http.server 8080
# open http://localhost:8080
```

## Deploy to Netlify

Drag the folder onto app.netlify.com/drop, or connect the repo. `netlify.toml` already sets
the publish directory to the repo root; there's no build command.

**Signups are collected with Netlify Forms.** The counter form already carries
`data-netlify="true"`, so once deployed, names and emails show up under Forms in the Netlify
dashboard (enable form detection there if it's off). Export them as CSV when you send word.
Remove `name` and `data-netlify` from the form to go back to front-end only.

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
