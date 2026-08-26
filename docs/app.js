// Lyrix Interactive Controller: Spotify Sync + Unrestricted Global Draggable Overlay

const sampleTracks = [
  {
    title: "Starboy",
    artist: "The Weeknd, Daft Punk",
    album: "Starboy",
    duration: 230, // 3:50
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
    album: "Viva La Vida",
    duration: 242,
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
    album: "Claw Marks",
    duration: 178, // 2:58
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

// Glow color themes
const glowThemes = [
  { name: "Cyan", color: "rgba(0, 240, 255, 0.55)", hex: "#00F0FF" },
  { name: "Purple", color: "rgba(157, 78, 221, 0.55)", hex: "#9D4EDD" },
  { name: "Gold", color: "rgba(255, 189, 46, 0.55)", hex: "#FFBD2E" },
  { name: "Green", color: "rgba(39, 201, 63, 0.55)", hex: "#27C93F" }
];
let currentThemeIndex = 0;

// DOM Elements
const linePrev = document.getElementById("linePrev");
const lineCurrent = document.getElementById("lineCurrent");
const lineNext = document.getElementById("lineNext");

const playPauseBtn = document.getElementById("playPauseBtn");
const playIcon = document.getElementById("playIcon");
const prevTrackBtn = document.getElementById("prevTrackBtn");
const nextTrackBtn = document.getElementById("nextTrackBtn");

const spCurrentTime = document.getElementById("spCurrentTime");
const spTotalTime = document.getElementById("spTotalTime");
const progressFill = document.getElementById("progressFill");

const spotifyTitle = document.getElementById("spotifyTitle");
const spotifyArtist = document.getElementById("spotifyArtist");
const miniTitle = document.getElementById("miniTitle");
const miniArtist = document.getElementById("miniArtist");
const rowTrackName = document.getElementById("rowTrackName");
const rowArtistName = document.getElementById("rowArtistName");

const themeToggle = document.getElementById("themeToggle");
const overlay = document.getElementById("interactiveOverlay");

function formatTime(sec) {
  const m = Math.floor(sec / 60);
  const s = Math.floor(sec % 60);
  return `${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")}`;
}

function updateTrackUI() {
  const track = sampleTracks[trackIndex];
  spotifyTitle.textContent = track.title;
  spotifyArtist.textContent = `${track.artist} · ${track.album}`;
  miniTitle.textContent = track.title;
  miniArtist.textContent = track.artist.split(",")[0];
  rowTrackName.textContent = track.title;
  rowArtistName.textContent = track.artist;
  spTotalTime.textContent = formatTime(track.duration);
}

function updateLyricsUI(animate = true) {
  const track = sampleTracks[trackIndex];
  const lyrics = track.lyrics;
  
  const prevText = lyricIndex > 0 ? lyrics[lyricIndex - 1].text : "";
  const currentText = lyrics[lyricIndex] ? lyrics[lyricIndex].text : "";
  const nextText = lyricIndex < lyrics.length - 1 ? lyrics[lyricIndex + 1].text : "";

  if (animate) {
    lineCurrent.style.opacity = "0.35";
    lineCurrent.style.transform = "scale(0.96) translateY(-4px)";
    
    setTimeout(() => {
      linePrev.textContent = prevText;
      lineCurrent.textContent = currentText;
      lineNext.textContent = nextText;
      
      lineCurrent.style.opacity = "1";
      lineCurrent.style.transform = "scale(1.03) translateY(0)";
    }, 120);
  } else {
    linePrev.textContent = prevText;
    lineCurrent.textContent = currentText;
    lineNext.textContent = nextText;
  }
}

function updateProgress() {
  const track = sampleTracks[trackIndex];
  const pct = (currentSeconds / track.duration) * 100;
  progressFill.style.width = `${pct}%`;
  spCurrentTime.textContent = formatTime(currentSeconds);
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
    playIcon.innerHTML = '<rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/>';
    startLoop();
  } else {
    playIcon.innerHTML = '<polygon points="5 3 19 12 5 21 5 3"/>';
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

function cycleTheme() {
  currentThemeIndex = (currentThemeIndex + 1) % glowThemes.length;
  const theme = glowThemes[currentThemeIndex];
  themeToggle.textContent = `Glow: ${theme.name}`;
  document.documentElement.style.setProperty("--glow-color", theme.color);
  document.documentElement.style.setProperty("--accent-cyan", theme.hex);
}

// =========================================================================
// UNRESTRICTED GLOBAL DRAGGING (Anywhere on the entire browser window!)
// =========================================================================
let isDragging = false;
let startPointerX = 0, startPointerY = 0;
let overlayLeft = 0, overlayTop = 0;

overlay.addEventListener("pointerdown", (e) => {
  // Ignore clicks on buttons inside overlay if any
  if (e.target.closest("button, a")) return;

  isDragging = true;
  overlay.setPointerCapture(e.pointerId);

  // Capture current bounding rect
  const rect = overlay.getBoundingClientRect();
  overlayLeft = rect.left;
  overlayTop = rect.top;

  startPointerX = e.clientX;
  startPointerY = e.clientY;

  // Switch overlay to fixed inline coordinates
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

  // Safe viewport bounds clamping
  const maxX = window.innerWidth - overlay.offsetWidth - 10;
  const maxY = window.innerHeight - overlay.offsetHeight - 10;

  newX = Math.max(10, Math.min(maxX, newX));
  newY = Math.max(10, Math.min(maxY, newY));

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

// Event Bindings
playPauseBtn.addEventListener("click", togglePlayback);
nextTrackBtn.addEventListener("click", stepForward);
prevTrackBtn.addEventListener("click", stepBackward);
themeToggle.addEventListener("click", cycleTheme);

// =========================================================================
// Wholesome & Relatable Dynamic Hero Typewriter Effect
// =========================================================================
const typewriterPhrases = [
  "Music you can glance at.",
  "Sing along to every chorus.",
  "Scream your heart out to your favourite song.",
  "Turn late-night focus into karaoke.",
  "Catch every lyric without losing your flow.",
  "Whisper the verses, belt out the bridge.",
  "Feel every word as the music moves."
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
      setTimeout(runTypewriter, 350);
      return;
    }
    setTimeout(runTypewriter, 35);
  } else {
    charIndex++;
    typewriterEl.textContent = currentPhrase.substring(0, charIndex);

    if (charIndex >= currentPhrase.length) {
      isDeleting = true;
      setTimeout(runTypewriter, 2400); // pause when phrase is complete
      return;
    }
    setTimeout(runTypewriter, 65);
  }
}

// Initialize
updateTrackUI();
updateLyricsUI(false);
updateProgress();
startLoop();

// Start deleting the first line after an initial reading pause
setTimeout(runTypewriter, 2000);

