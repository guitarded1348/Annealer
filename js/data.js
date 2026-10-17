/*
  ANNEALER — the one file to edit.

  Every track, date and line of lore lives here. Change text, add tracks,
  move release dates; the site rebuilds itself from this on page load.

  Dates are ISO 8601 with a timezone offset, e.g. "2026-12-11T19:00:00-05:00".
  A phase unlocks the moment `releaseDate` passes. `sealedOn` is when its
  countdown starts (the gauge reads full heat on that day and ambient on
  release day).

  Audio: set `audio` to a file path or URL (e.g. "audio/kettle.mp3").
  Leave it empty and the player plays a quiet placeholder hum instead.
*/
window.ANNEALER = {
  site: {
    name: "ANNEALER",
    // Set to an ISO date to preview the site as if it were that day,
    // e.g. "2027-04-01T00:00:00Z" to see every chamber open. null = real time.
    previewDate: null,
    ambient: 21, // °C. Where the page, and everything else, ends up.
  },

  // Landing page: the one line the narrator says first.
  heroLine: "Bring it in hot. I'll cool it slowly. Don't wait up.",

  // Spoken when someone pokes the lehr. The last one is for the seventh poke.
  lehrLines: [
    "It's warm. It's always warm.",
    "Don't knock on the door. It knocks back.",
    "It ate a teaspoon once. We don't discuss the teaspoon.",
    "Shh. It's thinking.",
    "That isn't breathing. That's the draft. Mostly.",
    "You're making it glow. Stop that.",
  ],
  lehrSeventh: "Seven. It likes you now. I'd consider that bad news.",

  // The Workshop. Each entry is one paragraph.
  // An entry with `ink: true` is printed in invisible ink: it only shows
  // when a reader selects (highlights) the text around it.
  workshop: {
    title: "The Workshop",
    lore: [
      { text: "The workshop is at the end of a street that doesn't appear to have an end. You'll find it anyway. Things that run too hot always do." },
      { text: "I take in what has been overheated. Kettles. Fuses. A clock that struck thirteen out of spite. People leave them on the step and go. Nobody knocks." },
      { text: "There's a lehr in the back. It's a long oven, very old and very patient, and I'd ask you not to stare at its door. It doesn't care for that. Neither do I." },
      { text: "I was brought in once, myself.", ink: true },
      { text: "The trick isn't the heat. Anyone can make a thing hot. The trick is holding it there, and then letting it go so slowly it never notices it's being let go." },
      { text: "Glass cooled too fast keeps its temper inside. It looks perfectly well. Then one Tuesday, in an empty room, it shatters. Nobody was near it. Nobody ever is." },
      { text: "I don't repair things. I cool them. The difference is mostly patience, and a little of the other thing." },
      { text: "The lehr has never been switched off. Nobody has asked me to.", ink: true },
    ],
    signoff: "— A.",
  },

  // The three chambers. Order matters: it's the order of the process.
  phases: [
    {
      id: "heat",
      name: "Heat",
      chamberTemp: 565, // °C shown on the gauge when the chamber is sealed
      sealedOn: "2026-08-01T00:00:00-05:00",
      releaseDate: "2026-09-19T19:00:00-05:00",
      summary: "Past the critical point. Everything arrives like this.",
      note: "Don't touch the glass. The glass is touching you.",
      tracks: [
        {
          title: "Kettle, Boiled Dry",
          object: "One enamel kettle, boiled dry. Still screaming at intake.",
          condition: "Hot to the eye.",
          note: "Took the whistle out. It kept whistling. We've agreed to disagree.",
          duration: "3:41",
          audio: "",
        },
        {
          title: "Fusebox",
          object: "One fuse box. Three fuses blown, one of them proud of it.",
          condition: "Smells of pennies.",
          note: "Customer says it just went. Things don't just go.",
          duration: "4:12",
          audio: "",
        },
        {
          title: "Red Bulb",
          object: "A light bulb that kept glowing after it was unplugged.",
          condition: "Glowing.",
          note: "Kept it in a drawer overnight. The drawer is warm now. The drawer isn't on the invoice.",
          duration: "3:05",
          audio: "",
        },
        {
          title: "Lamp Glass, Unbroken",
          object: "A lamp chimney with a crack that hasn't happened yet.",
          condition: "Fine. Won't be.",
          note: "It looks perfectly well. That's what worries me.",
          duration: "5:20",
          audio: "",
        },
      ],
    },
    {
      id: "soak",
      name: "Soak",
      chamberTemp: 548,
      sealedOn: "2026-09-19T19:00:00-05:00",
      releaseDate: "2026-12-11T19:00:00-05:00",
      summary: "Held there, long enough for the inside to catch up with the outside.",
      note: "It isn't stuck. It's holding. You'll know the difference later.",
      tracks: [
        {
          title: "Held at Temperature",
          object: "A pocket watch that only runs while you're holding it.",
          condition: "Warm in the hand.",
          note: "I've been holding it for eleven days. It's very punctual.",
          duration: "8:44",
          audio: "",
        },
        {
          title: "Pilot Light",
          object: "A small blue flame in a jar. Nobody remembers lighting it.",
          condition: "Steady.",
          note: "It hums in a key I can't name. I've stopped trying.",
          duration: "7:02",
          audio: "",
        },
        {
          title: "The Long Hold",
          object: "A telephone receiver. Someone is still on the line.",
          condition: "Breathing, faintly.",
          note: "They asked me to wait. So I'm waiting.",
          duration: "11:30",
          audio: "",
        },
      ],
    },
    {
      id: "cool",
      name: "Slow Cool",
      chamberTemp: 514,
      sealedOn: "2026-12-11T19:00:00-05:00",
      releaseDate: "2027-03-20T19:00:00-05:00",
      summary: "The part nobody has patience for. The part that works.",
      note: "Don't open the door to check. Checking is how things crack.",
      tracks: [
        {
          title: "Strain Point",
          object: "A wine glass, ringing at a note no one struck.",
          condition: "Below the strain point. Safe now, probably.",
          note: "It stopped ringing on Thursday. I miss it a little.",
          duration: "4:58",
          audio: "",
        },
        {
          title: "Toaster on the Sill",
          object: "A small toaster that waits by the window for someone.",
          condition: "Cool. Hopeful.",
          note: "I've told it nobody's coming. It keeps the crumb tray tidy anyway.",
          duration: "5:36",
          audio: "",
        },
        {
          title: "Room Temperature",
          object: "Unknown. It arrived in an empty box.",
          condition: "Ambient.",
          note: "The box was the thing. I see that now.",
          duration: "6:15",
          audio: "",
        },
      ],
    },
  ],

  // The mailing list ("leave your name at the counter").
  counter: {
    title: "Leave your name at the counter",
    intro: "Ring if you must. I'll send word when a chamber opens, and not otherwise.",
    button: "Ring the bell",
    thanks: "Noted. I'll write when something comes out of the lehr. Don't wait up.",
    returning: "You again, {name}. Your name's still on the ledger.",
    selfName: "That's my name. Put it back.",
    badEmail: "That address won't take a letter. Check it and ring again.",
    noName: "The ledger needs a name. Any name. Most people lie.",
  },

  // Tiny print at the bottom of every page.
  footer: "Cooled at 1 °C per minute. Do not rush the glass.",
};
