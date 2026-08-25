// Interactive Live Preview: Spotify Player + Lyrix Floating Overlay

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
const interactiveOverlay = document.getElementById("interactiveOverlay");

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
    
    // Check if next lyric should trigger
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

// Draggable Overlay Simulation inside desktop stage
let isDragging = false;
let startX = 0, startY = 0;
let currentX = 0, currentY = 0;

interactiveOverlay.addEventListener("mousedown", (e) => {
  isDragging = true;
  startX = e.clientX - currentX;
  startY = e.clientY - currentY;
  interactiveOverlay.style.cursor = "grabbing";
});

window.addEventListener("mousemove", (e) => {
  if (!isDragging) return;
  currentX = Math.max(-40, Math.min(220, e.clientX - startX));
  currentY = Math.max(-20, Math.min(180, e.clientY - startY));
  interactiveOverlay.style.transform = `translate3d(${currentX}px, ${currentY}px, 0)`;
});

window.addEventListener("mouseup", () => {
  if (!isDragging) return;
  isDragging = false;
  interactiveOverlay.style.cursor = "grab";
});

// Event Bindings
playPauseBtn.addEventListener("click", togglePlayback);
nextTrackBtn.addEventListener("click", stepForward);
prevTrackBtn.addEventListener("click", stepBackward);
themeToggle.addEventListener("click", cycleTheme);

// Initialize
updateTrackUI();
updateLyricsUI(false);
updateProgress();
startLoop();
