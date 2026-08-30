// ==========================================================================
// Lyrix Interactive Controller: Sub-Second Audio Sync + Liquid Glass HUD
// ==========================================================================

const sampleTracks = [
  {
    title: "Starboy",
    artist: "The Weeknd, Daft Punk",
    album: "Starboy (2016)",
    duration: 230, // 3:50
    artGradient: "linear-gradient(135deg, #FF0055, #7A00FF)",
    lyrics: [
      { time: 10, text: "I'm tryna put you in the worst mood, ah" },
      { time: 14, text: "P1 cleaner than your church shoes, ah" },
      { time: 18, text: "Milli point two just to hurt you, ah" },
      { time: 22, text: "All red Lamb' just to tease you, ah" },
      { time: 26, text: "None of these toys on lease too, ah" },
      { time: 30, text: "Made your whole year in a week too, yah" },
      { time: 34, text: "Main bitch out your league too, ah" },
      { time: 38, text: "Side bitch out of your league too, ah" },
      { time: 42, text: "Look what you've done" },
      { time: 46, text: "I'm a motherfuckin' starboy" }
    ]
  },
  {
    title: "Viva La Vida",
    artist: "Coldplay",
    album: "Viva La Vida (2008)",
    duration: 242, // 4:02
    artGradient: "linear-gradient(135deg, #E65C00, #F9D423)",
    lyrics: [
      { time: 12, text: "I used to rule the world" },
      { time: 16, text: "Seas would rise when I gave the word" },
      { time: 21, text: "Now in the morning I sleep alone" },
      { time: 26, text: "Sweep the streets I used to own" },
      { time: 31, text: "I used to roll the dice" },
      { time: 36, text: "Feel the fear in my enemy's eyes" },
      { time: 41, text: "Listen as the crowd would sing" },
      { time: 46, text: "Now the old king is dead, long live the king" },
      { time: 52, text: "One minute I held the key" },
      { time: 57, text: "Next the walls were closed on me" }
    ]
  },
  {
    title: "Claw Marks",
    artist: "panicbaby",
    album: "Claw Marks (2024)",
    duration: 178, // 2:58
    artGradient: "linear-gradient(135deg, #00F0FF, #3B82F6)",
    lyrics: [
      { time: 8, text: "I was drowning in the static of the city lights" },
      { time: 14, text: "Looking for a signal in the crowded nights" },
      { time: 20, text: "I can hear the rhythm in the dark" },
      { time: 26, text: "Tracing every outline of your heart" },
      { time: 32, text: "Before the morning comes to pull us apart" },
      { time: 38, text: "We are moving like shadows on the floor" },
      { time: 44, text: "Never wanted anything so much more" }
    ]
  }
];

let trackIndex = 0;
let lyricIndex = 1;
let isPlaying = true;
let currentSeconds = 14;
let timer = null;

// Glow color configurations
const themeMap = {
  cyan: { color: "#00F0FF", shadow: "rgba(0, 240, 255, 0.55)" },
  purple: { color: "#A855F7", shadow: "rgba(168, 85, 247, 0.55)" },
  gold: { color: "#FBBF24", shadow: "rgba(251, 191, 36, 0.55)" },
  green: { color: "#34D399", shadow: "rgba(52, 211, 153, 0.55)" },
  pink: { color: "#F43F5E", shadow: "rgba(244, 63, 94, 0.55)" },
  white: { color: "#FFFFFF", shadow: "rgba(255, 255, 255, 0.60)" }
};

// DOM Elements
const linePrev = document.getElementById("linePrev");
const lineCurrent = document.getElementById("lineCurrent");
const lyricCurrentText = document.getElementById("lyricCurrentText");
const lineNext = document.getElementById("lineNext");
const overlay = document.getElementById("interactiveOverlay");
const overlayDot = document.getElementById("overlayDot");
const overlayTrackBadge = document.getElementById("overlayTrackBadge");
const overlayTime = document.getElementById("overlayTime");

const playPauseBtn = document.getElementById("playPauseBtn");
const playIcon = document.getElementById("playIcon");
const prevTrackBtn = document.getElementById("prevTrackBtn");
const nextTrackBtn = document.getElementById("nextTrackBtn");

const spCurrentTime = document.getElementById("spCurrentTime");
const spTotalTime = document.getElementById("spTotalTime");
const progressFill = document.getElementById("progressFill");
const progressBarTrack = document.getElementById("progressBarTrack");

const stageTrackTitle = document.getElementById("stageTrackTitle");
const stageArtistTitle = document.getElementById("stageArtistTitle");
const miniTrackName = document.getElementById("miniTrackName");
const miniArtistName = document.getElementById("miniArtistName");
const albumArtwork = document.getElementById("albumArtwork");
const miniArtBox = document.getElementById("miniArtBox");
const trackRows = document.querySelectorAll(".sim-track-row");

// Customizer elements
const colorPalette = document.getElementById("colorPalette");
const fontSizeControl = document.getElementById("fontSizeControl");
const opacitySlider = document.getElementById("opacitySlider");
const opacityValueDisplay = document.getElementById("opacityValueDisplay");
const demoCurrentLine = document.getElementById("demoCurrentLine");
const demoHud = document.getElementById("demoHud");

function formatTime(sec) {
  const m = Math.floor(sec / 60);
  const s = Math.floor(sec % 60);
  return `${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")}`;
}

function updateTrackUI() {
  const track = sampleTracks[trackIndex];
  if (stageTrackTitle) stageTrackTitle.textContent = track.title;
  if (stageArtistTitle) stageArtistTitle.textContent = `${track.artist} · ${track.album}`;
  if (miniTrackName) miniTrackName.textContent = track.title;
  if (miniArtistName) miniArtistName.textContent = track.artist.split(",")[0];
  if (overlayTrackBadge) overlayTrackBadge.textContent = `${track.title} · ${track.artist.split(",")[0]}`;
  if (spTotalTime) spTotalTime.textContent = formatTime(track.duration);

  // Update art background gradients
  if (albumArtwork) albumArtwork.style.background = track.artGradient;
  if (miniArtBox) miniArtBox.style.background = track.artGradient;

  // Track row selection
  trackRows.forEach((row, idx) => {
    if (idx === trackIndex) {
      row.classList.add("active");
      const numSpan = row.querySelector(".track-col-num");
      if (numSpan) numSpan.textContent = "▶";
    } else {
      row.classList.remove("active");
      const numSpan = row.querySelector(".track-col-num");
      if (numSpan) numSpan.textContent = `${idx + 1}`;
    }
  });
}

function updateLyricsUI(animate = true) {
  const track = sampleTracks[trackIndex];
  const lyrics = track.lyrics;
  
  const prevText = lyricIndex > 0 ? lyrics[lyricIndex - 1].text : "";
  const currentText = lyrics[lyricIndex] ? lyrics[lyricIndex].text : "";
  const nextText = lyricIndex < lyrics.length - 1 ? lyrics[lyricIndex + 1].text : "";

  if (animate) {
    if (lineCurrent) {
      lineCurrent.style.opacity = "0.3";
      lineCurrent.style.transform = "scale(0.97) translateY(-3px)";
    }
    
    setTimeout(() => {
      if (linePrev) linePrev.textContent = prevText;
      if (lyricCurrentText) lyricCurrentText.textContent = currentText;
      if (lineNext) lineNext.textContent = nextText;
      
      if (lineCurrent) {
        lineCurrent.style.opacity = "1";
        lineCurrent.style.transform = "scale(1.02) translateY(0)";
      }
    }, 100);
  } else {
    if (linePrev) linePrev.textContent = prevText;
    if (lyricCurrentText) lyricCurrentText.textContent = currentText;
    if (lineNext) lineNext.textContent = nextText;
  }
}

function updateProgress() {
  const track = sampleTracks[trackIndex];
  const pct = (currentSeconds / track.duration) * 100;
  if (progressFill) progressFill.style.width = `${pct}%`;
  if (spCurrentTime) spCurrentTime.textContent = formatTime(currentSeconds);
  if (overlayTime) overlayTime.textContent = formatTime(currentSeconds);
}

function stepForward() {
  const track = sampleTracks[trackIndex];
  if (lyricIndex < track.lyrics.length - 1) {
    lyricIndex++;
    currentSeconds = track.lyrics[lyricIndex].time;
  } else {
    trackIndex = (trackIndex + 1) % sampleTracks.length;
    lyricIndex = 0;
    currentSeconds = sampleTracks[trackIndex].lyrics[0].time;
    updateTrackUI();
  }
  updateLyricsUI(true);
  updateProgress();
}

function stepBackward() {
  const track = sampleTracks[trackIndex];
  if (lyricIndex > 0) {
    lyricIndex--;
    currentSeconds = track.lyrics[lyricIndex].time;
  } else {
    currentSeconds = 0;
  }
  updateLyricsUI(true);
  updateProgress();
}

function togglePlayback() {
  isPlaying = !isPlaying;
  if (isPlaying) {
    if (playIcon) playIcon.innerHTML = '<rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/>';
    startLoop();
  } else {
    if (playIcon) playIcon.innerHTML = '<polygon points="6 4 18 12 6 20 6 4"/>';
    clearInterval(timer);
  }
}

function startLoop() {
  clearInterval(timer);
  timer = setInterval(() => {
    currentSeconds += 1;
    const track = sampleTracks[trackIndex];
    
    if (lyricIndex < track.lyrics.length - 1) {
      if (currentSeconds >= track.lyrics[lyricIndex + 1].time) {
        lyricIndex++;
        updateLyricsUI(true);
      }
    } else if (currentSeconds >= track.duration) {
      trackIndex = (trackIndex + 1) % sampleTracks.length;
      lyricIndex = 0;
      currentSeconds = 0;
      updateTrackUI();
      updateLyricsUI(true);
    }
    updateProgress();
  }, 1000);
}

// Track row clicks
trackRows.forEach(row => {
  row.addEventListener("click", () => {
    const tIdx = parseInt(row.getAttribute("data-track"), 10);
    if (!isNaN(tIdx) && tIdx !== trackIndex) {
      trackIndex = tIdx;
      lyricIndex = 0;
      currentSeconds = sampleTracks[trackIndex].lyrics[0].time;
      updateTrackUI();
      updateLyricsUI(true);
      updateProgress();
    }
  });
});

// Audio scrubber track click
if (progressBarTrack) {
  progressBarTrack.addEventListener("click", (e) => {
    const rect = progressBarTrack.getBoundingClientRect();
    const clickX = e.clientX - rect.left;
    const pct = Math.max(0, Math.min(1, clickX / rect.width));
    const track = sampleTracks[trackIndex];
    currentSeconds = Math.floor(pct * track.duration);
    
    // Find closest lyric index
    let closestIdx = 0;
    for (let i = 0; i < track.lyrics.length; i++) {
      if (currentSeconds >= track.lyrics[i].time) {
        closestIdx = i;
      }
    }
    lyricIndex = closestIdx;
    updateLyricsUI(true);
    updateProgress();
  });
}

// =========================================================================
// UNRESTRICTED GLOBAL DRAGGING WITH BOUNDS
// =========================================================================
let isDragging = false;
let startPointerX = 0, startPointerY = 0;
let overlayLeft = 0, overlayTop = 0;

if (overlay) {
  overlay.addEventListener("pointerdown", (e) => {
    if (e.target.closest("button, a, input")) return;

    isDragging = true;
    overlay.setPointerCapture(e.pointerId);

    const rect = overlay.getBoundingClientRect();
    overlayLeft = rect.left;
    overlayTop = rect.top;

    startPointerX = e.clientX;
    startPointerY = e.clientY;

    overlay.style.right = "auto";
    overlay.style.bottom = "auto";
    overlay.style.left = `${overlayLeft}px`;
    overlay.style.top = `${overlayTop}px`;
    overlay.style.cursor = "grabbing";
  });

  overlay.addEventListener("pointermove", (e) => {
    if (!isDragging) return;

    const deltaX = e.clientX - startPointerX;
    const deltaY = e.clientY - startPointerY;

    let newX = overlayLeft + deltaX;
    let newY = overlayTop + deltaY;

    const maxX = window.innerWidth - overlay.offsetWidth - 12;
    const maxY = window.innerHeight - overlay.offsetHeight - 12;

    newX = Math.max(12, Math.min(maxX, newX));
    newY = Math.max(12, Math.min(maxY, newY));

    overlay.style.left = `${newX}px`;
    overlay.style.top = `${newY}px`;
  });

  function stopDrag(e) {
    if (!isDragging) return;
    isDragging = false;
    try {
      overlay.releasePointerCapture(e.pointerId);
    } catch (err) {}
    overlay.style.cursor = "grab";
  }

  overlay.addEventListener("pointerup", stopDrag);
  overlay.addEventListener("pointercancel", stopDrag);
}

// Event Bindings for player buttons
if (playPauseBtn) playPauseBtn.addEventListener("click", togglePlayback);
if (nextTrackBtn) nextTrackBtn.addEventListener("click", stepForward);
if (prevTrackBtn) prevTrackBtn.addEventListener("click", stepBackward);

// =========================================================================
// CUSTOMIZER: THEME GLOW, FONT SCALE, TRANSLUCENCY
// =========================================================================
if (colorPalette) {
  colorPalette.querySelectorAll(".palette-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      colorPalette.querySelectorAll(".palette-btn").forEach(b => b.classList.remove("active"));
      btn.classList.add("active");

      const themeKey = btn.getAttribute("data-theme");
      const theme = themeMap[themeKey];
      if (theme) {
        document.documentElement.style.setProperty("--active-glow-color", theme.color);
        document.documentElement.style.setProperty("--active-glow-shadow", theme.shadow);
        
        // Update ambient aura
        const aura1 = document.getElementById("ambientAura1");
        if (aura1) {
          aura1.style.background = `radial-gradient(circle, ${theme.color} 0%, transparent 70%)`;
        }
      }
    });
  });
}

if (fontSizeControl) {
  fontSizeControl.querySelectorAll(".segment-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      fontSizeControl.querySelectorAll(".segment-btn").forEach(b => b.classList.remove("active"));
      btn.classList.add("active");

      const size = btn.getAttribute("data-size");
      if (overlay) {
        if (size === "small") {
          lineCurrent.style.fontSize = "1.05rem";
          if (linePrev) linePrev.style.fontSize = "0.78rem";
          if (lineNext) lineNext.style.fontSize = "0.78rem";
        } else if (size === "large") {
          lineCurrent.style.fontSize = "1.42rem";
          if (linePrev) linePrev.style.fontSize = "0.96rem";
          if (lineNext) lineNext.style.fontSize = "0.96rem";
        } else {
          lineCurrent.style.fontSize = "1.22rem";
          if (linePrev) linePrev.style.fontSize = "0.88rem";
          if (lineNext) lineNext.style.fontSize = "0.88rem";
        }
      }
    });
  });
}

if (opacitySlider && opacityValueDisplay) {
  opacitySlider.addEventListener("input", (e) => {
    const val = e.target.value;
    opacityValueDisplay.textContent = `${val}%`;
    const alpha = val / 100;
    if (overlay) {
      overlay.style.background = `rgba(18, 20, 26, ${alpha})`;
    }
    if (demoHud) {
      demoHud.style.background = `rgba(18, 20, 26, ${alpha})`;
    }
  });
}

// =========================================================================
// INTERACTIVE KEYBOARD SHORTCUTS LISTENER
// =========================================================================
const activeKeys = new Set();
const keyPills = document.querySelectorAll(".key-pill");

window.addEventListener("keydown", (e) => {
  const code = e.code;
  activeKeys.add(code);

  keyPills.forEach(pill => {
    const targetKey = pill.getAttribute("data-key");
    if (targetKey === code || (targetKey === "Control" && e.ctrlKey) || (targetKey === "Alt" && e.altKey)) {
      pill.classList.add("active");
    }
  });
});

window.addEventListener("keyup", (e) => {
  const code = e.code;
  activeKeys.delete(code);

  keyPills.forEach(pill => {
    const targetKey = pill.getAttribute("data-key");
    if (targetKey === code || (!e.ctrlKey && targetKey === "Control") || (!e.altKey && targetKey === "Alt")) {
      pill.classList.remove("active");
    }
  });
});

// =========================================================================
// Dynamic Hero Typewriter Effect (Apple Minimalist Slogans)
// =========================================================================
const typewriterPhrases = [
  "glance at.",
  "sing along with.",
  "feel effortlessly.",
  "turn into karaoke.",
  "code alongside."
];

let phraseIndex = 0;
let charIndex = typewriterPhrases[0].length;
let isDeleting = true;
const typewriterEl = document.getElementById("typewriterText");

function runTypewriter() {
  if (!typewriterEl) return;
  const currentPhrase = typewriterPhrases[phraseIndex];

  if (isDeleting) {
    charIndex--;
    typewriterEl.textContent = currentPhrase.substring(0, charIndex);

    if (charIndex <= 0) {
      isDeleting = false;
      phraseIndex = (phraseIndex + 1) % typewriterPhrases.length;
      setTimeout(runTypewriter, 300);
      return;
    }
    setTimeout(runTypewriter, 40);
  } else {
    charIndex++;
    typewriterEl.textContent = currentPhrase.substring(0, charIndex);

    if (charIndex >= currentPhrase.length) {
      isDeleting = true;
      setTimeout(runTypewriter, 2600);
      return;
    }
    setTimeout(runTypewriter, 70);
  }
}

// Initial Kickoff
updateTrackUI();
updateLyricsUI(false);
updateProgress();
startLoop();
setTimeout(runTypewriter, 2200);
