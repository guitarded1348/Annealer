/* ANNEALER. All content comes from js/data.js; this file only arranges it. */
(function () {
  "use strict";

  var D = window.ANNEALER;
  var $ = function (sel, root) { return (root || document).querySelector(sel); };
  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
  var AMBIENT = D.site.ambient;
  var TOP_TEMP = 565;

  var timeOffset = D.site.previewDate ? Date.parse(D.site.previewDate) - Date.now() : 0;
  function now() { return Date.now() + timeOffset; }

  function esc(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }
  var ROMAN = ["I", "II", "III", "IV", "V", "VI"];
  var dateFmt = new Intl.DateTimeFormat(undefined, { day: "numeric", month: "long", year: "numeric" });
  var timeFmt = new Intl.DateTimeFormat(undefined, { hour: "numeric", minute: "2-digit" });

  /* ---------- landing ---------- */

  (function wordmark() {
    var el = $("#wordmark");
    var rot = [-2, 1.5, -1, 2.5, -1.5, 1, -2.5, 1.8];
    var dy = [0, 0.04, -0.03, 0.02, -0.02, 0.05, -0.01, 0.03];
    el.innerHTML = D.site.name.split("").map(function (ch, i) {
      var hot = i === 6 ? ' class="hot"' : "";
      return '<span aria-hidden="true"' + hot + ' style="--i:' + i + ";--r:" + (rot[i % 8]) + "deg;--dy:" + dy[i % 8] + 'em">' + esc(ch) + "</span>";
    }).join("");
  })();
  $("#hero-line").textContent = D.heroLine;
  $("#kilns-lede").textContent = D.kilnsLede;
  $("#foot-line").textContent = D.footer;
  $("#foot-solo").textContent = D.credits;
  $("#ambient").textContent = AMBIENT;

  /* ---------- the page cools as you scroll ---------- */

  var STOPS = [
    { p: 0.0, fill: [227, 184, 98], ink: [240, 211, 138] },   // straw
    { p: 0.3, fill: [176, 104, 46], ink: [230, 167, 109] },   // bronze
    { p: 0.55, fill: [122, 69, 150], ink: [195, 154, 224] },  // purple
    { p: 0.8, fill: [58, 91, 171], ink: [152, 176, 239] },    // deep blue
    { p: 1.0, fill: [134, 162, 201], ink: [185, 205, 230] },  // pale blue
  ];
  function mix(a, b, t) { return a.map(function (v, i) { return Math.round(v + (b[i] - v) * t); }); }
  function rgb(c) { return "rgb(" + c.join(",") + ")"; }
  function temperAt(p) {
    for (var i = 1; i < STOPS.length; i++) {
      if (p <= STOPS[i].p) {
        var a = STOPS[i - 1], b = STOPS[i], t = (p - a.p) / (b.p - a.p);
        return { fill: mix(a.fill, b.fill, t), ink: mix(a.ink, b.ink, t) };
      }
    }
    return STOPS[STOPS.length - 1];
  }

  var root = document.documentElement;
  var pyroTemp = $("#pyro-temp"), pyroPhase = $("#pyro-phase"), pyrometer = $("#pyrometer");
  var heroNeedle = $(".pyro-needle");
  var spiking = false;

  function cool() {
    var max = Math.max(1, document.documentElement.scrollHeight - window.innerHeight);
    var p = Math.min(1, Math.max(0, window.scrollY / max));
    var c = temperAt(p);
    root.style.setProperty("--temper", rgb(c.fill));
    root.style.setProperty("--temper-ink", rgb(c.ink));
    // slow through the annealing range, faster once past the strain point
    var t = Math.round(AMBIENT + (TOP_TEMP - AMBIENT) * (1 - Math.pow(p, 2.2)));
    if (!spiking) pyroTemp.textContent = t;
    pyroPhase.textContent = p < 0.18 ? "Heat" : p < 0.42 ? "Soak" : p < 0.97 ? "Slow cool" : "Ambient";
    heroNeedle.style.transform = "rotate(" + ((t / 600) * 110 - 70) + "deg)";
  }
  var ticking = false;
  window.addEventListener("scroll", function () {
    if (!ticking) { ticking = true; requestAnimationFrame(function () { cool(); ticking = false; }); }
  }, { passive: true });
  window.addEventListener("resize", cool);

  /* ---------- the lehr is alive ---------- */

  var lehr = $("#lehr"), says = $("#lehr-says"), pupil = $(".pupil");
  var pokes = 0;
  function retrigger(el, cls) { el.classList.remove(cls); void el.offsetWidth; el.classList.add(cls); }

  lehr.addEventListener("click", function () {
    pokes++;
    retrigger(lehr, "jolt");
    retrigger(lehr, "blink");
    if (pokes === 7) {
      lehr.classList.add("awake");
      says.textContent = D.lehrSeventh;
      spiking = true;
      pyrometer.classList.add("spike");
      pyroTemp.textContent = "999";
      setTimeout(function () { spiking = false; pyrometer.classList.remove("spike"); cool(); }, 1800);
    } else {
      says.textContent = D.lehrLines[(pokes - 1 - (pokes > 7 ? 1 : 0)) % D.lehrLines.length];
    }
  });

  function scheduleBlink() {
    setTimeout(function () {
      if (!reduceMotion.matches && !document.hidden) retrigger(lehr, "blink");
      scheduleBlink();
    }, 2800 + Math.random() * 4200);
  }
  scheduleBlink();

  // the eye follows you around the room
  window.addEventListener("pointermove", function (e) {
    if (reduceMotion.matches) return;
    var eye = $(".eye-glow").getBoundingClientRect();
    if (!eye.width) return;
    var dx = e.clientX - (eye.left + eye.width / 2);
    var dy = e.clientY - (eye.top + eye.height / 2);
    var d = Math.hypot(dx, dy) || 1;
    var k = Math.min(1, d / 300);
    pupil.style.transform = "translate(" + (dx / d) * 6 * k + "px," + (dy / d) * 3 * k + "px)";
  }, { passive: true });

  /* ---------- the workshop ---------- */

  $("#lore").innerHTML = D.workshop.lore.map(function (l) {
    return '<p' + (l.ink ? ' class="ink"' : "") + ">" + esc(l.text) + "</p>";
  }).join("") + '<p class="signoff">' + esc(D.workshop.signoff) + "</p>";

  /* ---------- the keeper's log ---------- */

  function dayOf(iso) { return Math.max(1, Math.floor((Date.parse(iso) - Date.parse(D.site.litOn)) / 86400000) + 1); }
  (function keepersLog() {
    var entries = D.log.entries.slice().sort(function (a, b) { return Date.parse(b.date) - Date.parse(a.date); });
    var shown = entries.slice(0, D.log.show || 6);
    $("#log-entries").innerHTML = shown.map(function (e) {
      return '<li><p class="log-day"><span>Day ' + dayOf(e.date) + '</span><time datetime="' + esc(e.date) + '">' +
        dateFmt.format(Date.parse(e.date)) + "</time></p><p class=\"log-text narrator\">" + esc(e.text) + "</p></li>";
    }).join("");
    var ago = Math.max(0, Math.floor((now() - Date.parse(D.site.litOn)) / 86400000));
    $("#days-lit").textContent = ago === 0 ? "Lehr lit today" : "Lehr lit " + ago + (ago === 1 ? " day" : " days") + " ago";
  })();

  /* ---------- the kilns ---------- */

  var INTAKE_BASE = 273; // intake numbers start at absolute zero, in kelvin
  var STAMPS = { heat: "Received hot", soak: "Holding", cool: "Cooled" };
  var VOICES = { heat: "sawtooth", soak: "sine", cool: "triangle" };
  var ROOTS = [55, 61.74, 65.41, 73.42, 49, 58.27, 82.41, 69.3, 46.25, 51.91];
  var trackIndex = 0;

  function dialPoint(temp, r) {
    var a = Math.PI - (Math.min(600, Math.max(0, temp)) / 600) * Math.PI;
    return [100 + r * Math.cos(a), 104 - r * Math.sin(a)];
  }
  function gaugeSVG(phase) {
    var ticks = "";
    for (var t = 0; t <= 600; t += 50) {
      var major = t % 100 === 0;
      var a = dialPoint(t, major ? 68 : 72), b = dialPoint(t, 80);
      ticks += '<line class="tick" x1="' + a[0].toFixed(1) + '" y1="' + a[1].toFixed(1) + '" x2="' + b[0].toFixed(1) + '" y2="' + b[1].toFixed(1) + '"/>';
      if (major) {
        var l = dialPoint(t, 57);
        ticks += '<text class="tick-label" x="' + l[0].toFixed(1) + '" y="' + (l[1] + (t % 600 === 0 ? -6 : 3.5)).toFixed(1) + '" text-anchor="middle">' + t + "</text>";
      }
    }
    var gid = "dial-" + phase.id;
    var s = dialPoint(0, 88), e = dialPoint(600, 88);
    return (
      '<svg viewBox="0 0 200 124" role="img" aria-label="Chamber temperature gauge">' +
      '<defs><linearGradient id="' + gid + '" x1="1" x2="0" y1="0" y2="0">' +
      '<stop offset="0%" stop-color="#e3b862"/><stop offset="35%" stop-color="#b0682e"/>' +
      '<stop offset="65%" stop-color="#7a4596"/><stop offset="100%" stop-color="#3a5bab"/></linearGradient></defs>' +
      '<path class="dial-face" d="M8 104 A92 92 0 0 1 192 104 Z"/>' +
      '<path class="band" stroke="url(#' + gid + ')" d="M' + s[0] + " " + s[1] + " A88 88 0 0 1 " + e[0] + " " + e[1] + '"/>' +
      ticks +
      '<text class="glyph" x="100" y="86" text-anchor="middle">°C</text>' +
      '<line class="needle" x1="100" y1="104" x2="100" y2="34"/>' +
      '<circle class="hub" cx="100" cy="104" r="5"/>' +
      "</svg>"
    );
  }

  function playerHTML(track, label) {
    var hasTape = !!track.audio;
    return (
      '<div class="player" data-src="' + esc(track.audio || "") + '">' +
      '<button type="button" aria-label="Play ' + esc(track.title) + '">' + ICON_PLAY + "</button>" +
      '<input type="range" min="0" max="1000" value="0" aria-label="Position in ' + esc(track.title) + '"' + (hasTape ? "" : " disabled") + ">" +
      "<time>0:00 / " + esc(track.duration || "—") + "</time>" +
      (hasTape ? "" : '<p class="player-caption">No tape threaded yet. This is the lehr humming.</p>') +
      "</div>"
    );
  }

  function tagHTML(track, phase, chamberNo) {
    var n = INTAKE_BASE + trackIndex;
    var root = ROOTS[trackIndex % ROOTS.length];
    trackIndex++;
    return (
      '<li class="tag" data-phase="' + phase.id + '" data-root="' + root + '" data-voice="' + VOICES[phase.id] + '">' +
      '<p class="tag-meta"><span>Intake No. ' + String(n).padStart(4, "0") + "</span></p>" +
      '<span class="stamp" aria-hidden="true">' + STAMPS[phase.id] + "</span>" +
      "<h4>" + esc(track.title) + "</h4>" +
      "<dl><dt>Object received</dt><dd>" + esc(track.object) + "</dd>" +
      (track.condition ? "<dt>Condition</dt><dd>" + esc(track.condition) + "</dd>" : "") + "</dl>" +
      '<blockquote class="tag-note narrator">' + esc(track.note) + "<cite>— A.</cite></blockquote>" +
      playerHTML(track) +
      "</li>"
    );
  }

  var gauges = [];
  var LIT = Date.parse(D.site.litOn);
  var DAY = 86400000;

  /*
    A chamber is in one of four states:
      open     its release date has passed: intake tags and players
      dated    sealed with a release date: cooling gauge and countdown
      heating  the first chamber with no date yet: gauge climbs slowly from the day the lehr was lit
      cold     any later chamber with no date: waits its turn at ambient
  */
  function renderChambers() {
    trackIndex = 0;
    gauges = [];
    var t = now();
    var undatedSeen = false;
    $("#chambers").innerHTML = D.phases.map(function (phase, i) {
      var example = D.site.showExamples && i === 0;
      var tracks = example ? D.exampleTracks : phase.tracks;
      var release = phase.releaseDate ? Date.parse(phase.releaseDate) : null;
      var state = example || (release !== null && t >= release) ? "open"
        : release !== null ? "dated"
        : undatedSeen ? "cold" : "heating";
      if (release === null && !example) undatedSeen = true;
      var no = ROMAN[i] || String(i + 1);
      var status = {
        open: example ? "Example &nbsp;·&nbsp; not real yet" : "Open &nbsp;·&nbsp; since " + (release !== null ? dateFmt.format(release) : ""),
        dated: "Sealed",
        heating: "Heating &nbsp;·&nbsp; no date yet",
        cold: "Cold &nbsp;·&nbsp; not yet loaded",
      }[state];
      var head =
        '<header class="chamber-head">' +
        '<p class="chamber-no">Chamber ' + no + " &nbsp;·&nbsp; " + phase.chamberTemp + " °C</p>" +
        "<h3>" + esc(phase.name) + "</h3>" +
        '<p class="chamber-status">' + status + "</p>" +
        '<p class="chamber-summary narrator">' + esc(phase.summary) + "</p>" +
        "</header>";
      var body;
      if (state === "open") {
        body = '<ul class="tags">' + tracks.map(function (tr) { return tagHTML(tr, phase, no); }).join("") + "</ul>";
      } else {
        trackIndex += tracks.length; // keep intake numbers stable when chambers open
        var count = tracks.length;
        var when = {
          dated: release !== null ? "Opens " + dateFmt.format(release) + ", " + timeFmt.format(release) : "",
          heating: "No date yet. It opens when it's ready, and not before.",
          cold: "Waits for the chamber before it.",
        }[state];
        body =
          '<div class="gauge" data-gauge="' + i + '">' + gaugeSVG(phase) +
          '<p class="gauge-temp"><span data-temp>—</span><small>°C</small></p>' +
          (state === "dated"
            ? '<ul class="countdown" aria-hidden="true">' +
              "<li><b data-d>0</b><span>days</span></li><li><b data-h>0</b><span>hrs</span></li>" +
              "<li><b data-m>0</b><span>min</span></li><li><b data-s>0</b><span>sec</span></li></ul>"
            : "") +
          '<p class="gauge-date">' + when + '<span data-wait></span></p>' +
          "</div>" +
          '<p class="sealed-count">' +
          (count ? count + (count === 1 ? " object" : " objects") + " inside &nbsp;·&nbsp; contents withheld" : "Objects still arriving") +
          "</p>";
        gauges.push({ i: i, phase: phase, state: state, release: release, sealed: phase.sealedOn ? Date.parse(phase.sealedOn) : null });
      }
      return (
        '<article class="chamber is-' + (state === "open" ? "open" : "sealed") + '" data-phase="' + phase.id + '" data-state="' + state + '" id="kiln-' + phase.id + '" aria-labelledby="kiln-' + phase.id + '-name">' +
        head.replace("<h3>", '<h3 id="kiln-' + phase.id + '-name">') + body +
        '<p class="gauge-note narrator">“' + esc(phase.note) + "”</p>" +
        "</article>"
      );
    }).join("");
    bindPlayers();
    tickGauges();
  }

  function pad(n) { return String(n).padStart(2, "0"); }
  function tickGauges() {
    var t = now();
    var reload = false;
    gauges.forEach(function (g) {
      var el = document.querySelector('[data-gauge="' + g.i + '"]');
      if (!el) return;
      var temp, label;
      if (g.state === "dated") {
        var left = g.release - t;
        if (left <= 0) { reload = true; return; }
        var frac = g.sealed === null ? 1 : Math.min(1, Math.max(0, left / Math.max(1, g.release - g.sealed)));
        temp = AMBIENT + frac * (g.phase.chamberTemp - AMBIENT);
        var s = Math.floor(left / 1000);
        $("[data-d]", el).textContent = Math.floor(s / 86400);
        $("[data-h]", el).textContent = pad(Math.floor(s / 3600) % 24);
        $("[data-m]", el).textContent = pad(Math.floor(s / 60) % 60);
        $("[data-s]", el).textContent = pad(s % 60);
        $("[data-wait]", el).textContent = g.sealed !== null && t < g.sealed ? ". Waits for the chamber before it." : "";
        label = "cooling. Opens in " + Math.ceil(s / 86400) + " days.";
      } else if (g.state === "heating") {
        // creeps toward full heat the longer the lehr has been lit
        temp = AMBIENT + (g.phase.chamberTemp - AMBIENT) * (1 - Math.exp(-(t - LIT) / DAY / 90));
        label = "heating. No release date yet.";
      } else {
        temp = AMBIENT;
        label = "cold. Not yet loaded.";
      }
      $("[data-temp]", el).textContent = Math.round(temp);
      $(".needle", el).style.transform = "rotate(" + ((temp / 600) * 180 - 90) + "deg)";
      $("svg", el).setAttribute("aria-label", "Chamber at " + Math.round(temp) + " degrees Celsius, " + label);
    });
    if (reload) renderChambers();
  }
  setInterval(tickGauges, 1000);

  /* ---------- players ---------- */

  var ICON_PLAY = '<svg viewBox="0 0 16 16" aria-hidden="true"><path d="M4 2 L14 8 L4 14 Z" fill="currentColor"/></svg>';
  var ICON_PAUSE = '<svg viewBox="0 0 16 16" aria-hidden="true"><path d="M3 2h4v12H3zM9 2h4v12H9z" fill="currentColor"/></svg>';
  var HUM_SECONDS = 24;
  var audioCtx = null;
  var current = null;

  function fmt(sec) {
    if (!isFinite(sec)) return "—";
    sec = Math.max(0, Math.floor(sec));
    return Math.floor(sec / 60) + ":" + pad(sec % 60);
  }

  function makeHum(rootHz, voice) {
    audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)();
    var ctx = audioCtx, t0 = ctx.currentTime;
    var master = ctx.createGain();
    master.gain.setValueAtTime(0.0001, t0);
    master.gain.exponentialRampToValueAtTime(0.09, t0 + 2.5);
    var lp = ctx.createBiquadFilter();
    lp.type = "lowpass";
    lp.frequency.value = voice === "sawtooth" ? 700 : 420;
    lp.Q.value = 6;
    var lfo = ctx.createOscillator(), lfoGain = ctx.createGain();
    lfo.frequency.value = voice === "sine" ? 0.07 : 0.18;
    lfoGain.gain.value = voice === "sawtooth" ? 380 : 220;
    lfo.connect(lfoGain).connect(lp.frequency);
    var oscs = [[rootHz, voice, 0], [rootHz * 1.5, "sine", 7], [rootHz / 2, "triangle", -5], [rootHz * 2.01, voice, 3]].map(function (o, i) {
      var osc = ctx.createOscillator(), g = ctx.createGain();
      osc.type = o[1];
      osc.frequency.value = o[0];
      osc.detune.value = o[2];
      g.gain.value = [0.5, 0.25, 0.6, 0.12][i];
      osc.connect(g).connect(lp);
      return osc;
    });
    lp.connect(master).connect(ctx.destination);
    oscs.concat(lfo).forEach(function (o) { o.start(); });
    return {
      started: t0,
      elapsed: function () { return ctx.currentTime - t0; },
      stop: function () {
        var t = ctx.currentTime;
        master.gain.cancelScheduledValues(t);
        master.gain.setValueAtTime(master.gain.value, t);
        master.gain.exponentialRampToValueAtTime(0.0001, t + 0.6);
        oscs.concat(lfo).forEach(function (o) { o.stop(t + 0.7); });
      },
    };
  }

  function bindPlayers() {
    Array.prototype.forEach.call(document.querySelectorAll(".player"), function (el) {
      var tag = el.closest(".tag");
      var btn = $("button", el), range = $("input", el), time = $("time", el);
      var title = $("h4", tag).textContent;
      var src = el.dataset.src;
      var listed = time.textContent.split(" / ")[1];
      var audio = null, hum = null, raf = 0;

      function setPlaying(on) {
        btn.innerHTML = on ? ICON_PAUSE : ICON_PLAY;
        btn.setAttribute("aria-label", (on ? "Pause " : "Play ") + title);
      }
      function stop() {
        if (audio) audio.pause();
        if (hum) { hum.stop(); hum = null; range.value = 0; time.textContent = "0:00 / " + listed; }
        cancelAnimationFrame(raf);
        setPlaying(false);
        if (current === api) current = null;
      }
      function loopHum() {
        if (!hum) return;
        var e = hum.elapsed();
        if (e >= HUM_SECONDS) { stop(); return; }
        range.value = Math.round((e / HUM_SECONDS) * 1000);
        time.textContent = fmt(e) + " / " + listed;
        raf = requestAnimationFrame(loopHum);
      }
      var api = { stop: stop };

      btn.addEventListener("click", function () {
        var playing = audio ? !audio.paused : !!hum;
        if (playing) { stop(); return; }
        if (current && current !== api) current.stop();
        current = api;
        if (src) {
          if (!audio) {
            audio = new Audio(src);
            audio.preload = "metadata";
            audio.addEventListener("timeupdate", function () {
              if (audio.duration) range.value = Math.round((audio.currentTime / audio.duration) * 1000);
              time.textContent = fmt(audio.currentTime) + " / " + (audio.duration ? fmt(audio.duration) : listed);
            });
            audio.addEventListener("ended", stop);
            range.addEventListener("input", function () {
              if (audio.duration) audio.currentTime = (range.value / 1000) * audio.duration;
            });
          }
          audio.play().catch(stop);
        } else {
          try {
            hum = makeHum(parseFloat(tag.dataset.root), tag.dataset.voice);
            if (audioCtx.state === "suspended") audioCtx.resume();
          } catch (err) { hum = null; return; }
          loopHum();
        }
        setPlaying(true);
      });
    });
  }

  /* ---------- the counter ---------- */

  var C = D.counter;
  var form = $("#ledger"), nameIn = $("#ledger-name"), mailIn = $("#ledger-email"), reply = $("#ledger-reply");
  $("#counter-title").textContent = C.title;
  $("#ledger-button-label").textContent = C.button;
  var stored = null;
  try { stored = localStorage.getItem("annealer.name"); } catch (e) {}
  $("#counter-intro").textContent = stored ? C.returning.replace("{name}", stored) : C.intro;

  form.addEventListener("submit", function (e) {
    e.preventDefault();
    var name = nameIn.value.trim(), mail = mailIn.value.trim();
    nameIn.removeAttribute("aria-invalid");
    mailIn.removeAttribute("aria-invalid");
    if (!name) { nameIn.setAttribute("aria-invalid", "true"); reply.textContent = C.noName; nameIn.focus(); return; }
    if (name.toLowerCase().replace(/^the\s+/, "") === "annealer") { reply.textContent = C.selfName; nameIn.value = ""; nameIn.focus(); return; }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(mail)) { mailIn.setAttribute("aria-invalid", "true"); reply.textContent = C.badEmail; mailIn.focus(); return; }

    if (form.elements["bot-field"] && form.elements["bot-field"].value) return; // a bot filled the hidden field

    retrigger($("#ledger-submit"), "rung");
    var submit = $("#ledger-submit");
    function received() {
      try { localStorage.setItem("annealer.name", name); } catch (err) {}
      reply.textContent = C.replies[Math.floor(Math.random() * C.replies.length)];
      form.reset();
    }

    // On Netlify the form posts to Netlify Forms (see data-netlify on the <form>).
    // Inside a framed preview there is nowhere to post, so it only answers.
    var live = form.dataset.netlify === "true" && window.self === window.top && location.protocol !== "file:";
    if (!live) { received(); return; }
    submit.disabled = true;
    var body = new URLSearchParams({ "form-name": form.getAttribute("name"), name: name, email: mail });
    fetch("/", { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body: body.toString() })
      .then(function (res) { if (!res.ok) throw new Error(res.status); received(); })
      .catch(function () { reply.textContent = C.failed; })
      .then(function () { submit.disabled = false; });
  });

  /* ---------- the tangled note (simulated annealing, for real) ---------- */

  var TARGET = "COOL IT SLOWLY AND IT FORGETS IT WAS EVER ANGRY";
  var tangle = $("#tangle"), lettersEl = $("#tangle-letters"), readout = $("#tangle-readout");
  var runBtn = $("#tangle-run"), after = $("#tangle-after"), opener = $("#boltzmann");
  var state = null, slots = [], running = 0;

  for (var i = 0; i < TARGET.length; i++) if (TARGET[i] !== " ") slots.push(i);

  function scramble() {
    state = TARGET.split("");
    for (var k = slots.length - 1; k > 0; k--) {
      var j = Math.floor(Math.random() * (k + 1));
      var a = slots[k], b = slots[j], t = state[a]; state[a] = state[b]; state[b] = t;
    }
  }
  function energy() { var e = 0; slots.forEach(function (i) { if (state[i] !== TARGET[i]) e++; }); return e; }
  function drawTangle(T, kept) {
    lettersEl.innerHTML = state.map(function (ch, i) {
      return ch === " " ? " " : '<span' + (ch === TARGET[i] ? ' class="ok"' : "") + ">" + ch + "</span>";
    }).join("");
    readout.innerHTML = "T = " + T.toFixed(2) + " &nbsp;·&nbsp; wrong letters: " + energy() + (kept != null ? " &nbsp;·&nbsp; kept worse: " + kept : "");
  }
  function step(T) {
    var a = slots[Math.floor(Math.random() * slots.length)], b = slots[Math.floor(Math.random() * slots.length)];
    if (a === b || state[a] === state[b]) return 0;
    var before = (state[a] !== TARGET[a]) + (state[b] !== TARGET[b]);
    var afterE = (state[b] !== TARGET[a]) + (state[a] !== TARGET[b]);
    var dE = afterE - before;
    if (dE <= 0 || Math.random() < Math.exp(-dE / T)) {
      var t = state[a]; state[a] = state[b]; state[b] = t;
      return dE > 0 ? 1 : 0;
    }
    return 0;
  }
  function anneal() {
    cancelAnimationFrame(running);
    scramble();
    after.hidden = true;
    runBtn.disabled = true;
    var T = 4, kept = 0, frames = 0;
    function finish() {
      state = TARGET.split("");
      drawTangle(Math.max(T, 0), kept);
      after.hidden = false;
      runBtn.disabled = false;
      runBtn.textContent = "Heat it again";
    }
    if (reduceMotion.matches) {
      while (T > 0.02 && energy() > 0) { for (var n = 0; n < 40; n++) kept += step(T); T *= 0.985; }
      finish();
      return;
    }
    (function frame() {
      for (var n = 0; n < 30; n++) kept += step(Math.max(T, 0.01));
      T *= 0.985;
      frames++;
      drawTangle(T, kept);
      if (energy() === 0 || frames > 900) { finish(); return; }
      running = requestAnimationFrame(frame);
    })();
  }

  function openTangle() {
    scramble();
    drawTangle(4, null);
    after.hidden = true;
    runBtn.textContent = "Lower the temperature";
    tangle.hidden = false;
    runBtn.focus();
  }
  function closeTangle() {
    cancelAnimationFrame(running);
    runBtn.disabled = false;
    tangle.hidden = true;
    opener.focus();
  }
  opener.addEventListener("click", openTangle);
  runBtn.addEventListener("click", anneal);
  $("#tangle-close").addEventListener("click", closeTangle);
  tangle.addEventListener("click", function (e) { if (e.target === tangle) closeTangle(); });
  document.addEventListener("keydown", function (e) { if (e.key === "Escape" && !tangle.hidden) closeTangle(); });

  /* ---------- go ---------- */

  renderChambers();
  cool();

  try {
    console.log(
      "%cANNEALER%c\nYou looked behind the counter. Most people don't.\nThere's a constant at the bottom of the page. Press it.\nAnd if you poke the lehr seven times, don't say I didn't warn you.\n— A.",
      "font: 900 28px 'Big Shoulders Display', Impact, sans-serif; color: #e3b862;",
      "font: italic 14px 'IM Fell English', Georgia, serif; color: #a99d8a;"
    );
  } catch (e) {}
})();
