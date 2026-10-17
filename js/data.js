/*
  ANNEALER — the one file to edit.

  Every track, date, log entry and line of lore lives here. The site
  rebuilds itself from this on page load.

  Dates are ISO 8601 with a timezone offset, e.g. "2026-12-11T19:00:00-05:00".
*/
window.ANNEALER = {
  site: {
    name: "ANNEALER",
    // The day the project started. Drives "Lehr lit N days ago", the Day numbers
    // in the log, and how hot the first undated chamber has grown.
    litOn: "2026-06-01T00:00:00-05:00",
    ambient: 21, // °C. Where the page, and everything else, ends up.
    // true = show Chamber I open with the example tags below, to see how a release looks.
    // Keep false on the live site.
    showExamples: false,
    // Set to an ISO date to preview the site as if it were that day. null = real time.
    previewDate: null,
  },

  // Landing page: the one line the narrator says first.
  heroLine: "Bring it in hot. I'll cool it slowly. Don't wait up.",

  // Above the three chambers.
  kilnsLede: "Nothing has come out of the lehr yet. Each chamber opens when it has cooled enough. Not before.",

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
  // `ink: true` prints it in invisible ink: it shows only when a reader highlights it.
  workshop: {
    title: "The Workshop",
    lore: [
      { text: "The workshop is at the end of a street that doesn't appear to have an end. You'll find it anyway. Things that run too hot always do." },
      { text: "I take in what has been overheated. Kettles. Fuses. A clock that struck thirteen out of spite. People leave them on the step and go. Nobody knocks." },
      { text: "There's a lehr in the back. It's a long oven, very old and very patient, and I'd ask you not to stare at its door. It doesn't care for that. Neither do I." },
      { text: "I was brought in once, myself.", ink: true },
      { text: "The trick isn't the heat. Anyone can make a thing hot. The trick is holding it there, and then letting it go so slowly it never notices it's being let go." },
      { text: "Glass cooled too fast keeps its temper inside. It looks perfectly well. Then one Tuesday, in an empty room, it shatters. Nobody was near it. Nobody ever is." },
      { text: "Nobody else works here. I tried an apprentice once. The lehr didn't take to him, and that was the end of the apprentice." },
      { text: "I don't repair things. I cool them. The difference is mostly patience, and a little of the other thing." },
      { text: "The lehr has never been switched off. Nobody has asked me to.", ink: true },
    ],
    signoff: "— A.",
  },

  // The Keeper's Log: short dated notes from the bench while the record is being made.
  // Add one whenever there's progress (or none). Newest shows first; `show` caps how many.
  // These four are examples; replace them with your own.
  log: {
    show: 6,
    entries: [
      { date: "2026-06-01", text: "Lit the lehr. It took the match like it had been waiting for one." },
      { date: "2026-07-18", text: "Something came in tonight with its teeth showing. I've put it in the first chamber. It's loud in there." },
      { date: "2026-09-02", text: "Wrote nothing today. Held the temperature. That counts." },
      { date: "2026-10-09", text: "Four objects on the bench now. Two of them are arguing. I'm letting them." },
    ],
  },

  // The three chambers, in process order.
  //   releaseDate: null  → no date yet. The first undated chamber shows "Heating";
  //                        the ones after it show "Cold".
  //   releaseDate set    → countdown gauge; tracks appear when it passes.
  //   sealedOn           → optional; when the countdown starts (gauge at full heat).
  //   tracks: []         → "Objects still arriving". Titles never show until release.
  // Track shape: { title, object, condition, note, duration: "3:41", audio: "audio/file.mp3" }
  // Empty `audio` plays a quiet placeholder hum.
  phases: [
    {
      id: "heat",
      name: "Heat",
      chamberTemp: 565, // °C, top of this chamber's gauge
      sealedOn: null,
      releaseDate: null,
      summary: "Past the critical point. Everything arrives like this.",
      note: "Don't touch the glass. The glass is touching you.",
      tracks: [],
    },
    {
      id: "soak",
      name: "Soak",
      chamberTemp: 548,
      sealedOn: null,
      releaseDate: null,
      summary: "Held there, long enough for the inside to catch up with the outside.",
      note: "It isn't stuck. It's holding. You'll know the difference later.",
      tracks: [],
    },
    {
      id: "cool",
      name: "Slow Cool",
      chamberTemp: 514,
      sealedOn: null,
      releaseDate: null,
      summary: "The part nobody has patience for. The part that works.",
      note: "Don't open the door to check. Checking is how things crack.",
      tracks: [],
    },
  ],

  // Shown in Chamber I only when site.showExamples is true.
  exampleTracks: [
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
  ],

  // The mailing list ("leave your name at the counter").
  counter: {
    title: "Leave your name at the counter",
    intro: "Nothing has come out of the lehr yet. Leave your name and I'll write when the first chamber opens. Once per chamber, and not otherwise.",
    button: "Ring the bell",
    // One is picked at random after someone signs. Write as many as you like.
    replies: [
      "Noted. I'll write when something comes out of the lehr. Don't wait up.",
      "Your name's in the ledger. In ink. That was your decision.",
      "Heard the bell. Didn't come out. I'll write.",
      "Filed under 'patient.' We'll see.",
      "Good. Somebody should know when it's done.",
      "The lehr made a noise when you signed. I'm choosing to take that as approval.",
    ],
    returning: "You again, {name}. Your name's still on the ledger.",
    selfName: "That's my name. Put it back.",
    badEmail: "That address won't take a letter. Check it and ring again.",
    noName: "The ledger needs a name. Any name. Most people lie.",
    failed: "The bell didn't ring. Try again in a moment.",
  },

  // Footer: the colophon line, and the credits line.
  footer: "Cooled at 1 °C per minute. Do not rush the glass.",
  credits: "All work done on the premises. Nobody else works here.",
};
