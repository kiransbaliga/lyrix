// Interactive Hero Preview Controller for Lyrix Website

const sampleLyrics = [
  "I was drowning in the static of the city lights",
  "Looking for a signal in the crowded nights",
  "I can hear the rhythm in the dark",
  "Tracing every outline of your heart",
  "Before the morning comes to pull us apart",
  "We are moving like shadows on the floor",
  "Never wanted anything so much more",
  "Hold the frequency until the break of dawn",
  "Even when the melody is gone"
];

let currentIndex = 3;
let isPlaying = true;
let progressSeconds = 74;
const totalDuration = 178; // 2:58
let playbackTimer = null;

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
const progressFill = document.getElementById("progressFill");
const progressTime = document.getElementById("progressTime");
const themeToggle = document.getElementById("themeToggle");
const interactiveOverlay = document.getElementById("interactiveOverlay");
const desktopStage = document.getElementById("desktopStage");

// Format seconds -> mm:ss
function formatTime(sec) {
  const m = Math.floor(sec / 60);
  const s = Math.floor(sec % 60);
  return `${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")}`;
}

// Update Lyrics View
function updateLyrics(animate = true) {
  const prevText = currentIndex > 0 ? sampleLyrics[currentIndex - 1] : "";
  const currentText = sampleLyrics[currentIndex] || "";
  const nextText = currentIndex < sampleLyrics.length - 1 ? sampleLyrics[currentIndex + 1] : "";

  if (animate) {
    lineCurrent.style.opacity = "0.4";
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

// Update Progress Bar
function updateProgress() {
  const pct = (progressSeconds / totalDuration) * 100;
  progressFill.style.width = `${pct}%`;
  progressTime.textContent = `${formatTime(progressSeconds)} / ${formatTime(totalDuration)}`;
}

// Step timeline forward
function stepForward() {
  if (currentIndex < sampleLyrics.length - 1) {
    currentIndex++;
  } else {
    currentIndex = 0;
    progressSeconds = 10;
  }
  progressSeconds = Math.min(totalDuration, progressSeconds + 18);
  updateLyrics(true);
  updateProgress();
}

// Step timeline backward
function stepBackward() {
  if (currentIndex > 0) {
    currentIndex--;
  }
  progressSeconds = Math.max(0, progressSeconds - 18);
  updateLyrics(true);
  updateProgress();
}

// Toggle Play / Pause
function togglePlayback() {
  isPlaying = !isPlaying;
  if (isPlaying) {
    playIcon.innerHTML = '<rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/>';
    startTimer();
  } else {
    playIcon.innerHTML = '<polygon points="5 3 19 12 5 21 5 3"/>';
    clearInterval(playbackTimer);
  }
}

// Start simulation loop
function startTimer() {
  clearInterval(playbackTimer);
  playbackTimer = setInterval(() => {
    progressSeconds += 1;
    if (progressSeconds >= totalDuration) {
      progressSeconds = 0;
      currentIndex = 0;
      updateLyrics(true);
    } else if (progressSeconds % 12 === 0) {
      stepForward();
    }
    updateProgress();
  }, 1000);
}

// Cycle theme
function cycleTheme() {
  currentThemeIndex = (currentThemeIndex + 1) % glowThemes.length;
  const theme = glowThemes[currentThemeIndex];
  themeToggle.textContent = `Glow: ${theme.name}`;
  document.documentElement.style.setProperty("--glow-color", theme.color);
  document.documentElement.style.setProperty("--accent-cyan", theme.hex);
}

// Interactive Drag Simulation for Demo Card
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
  currentX = Math.max(-100, Math.min(100, e.clientX - startX));
  currentY = Math.max(-40, Math.min(40, e.clientY - startY));
  interactiveOverlay.style.transform = `translate3d(${currentX}px, ${currentY}px, 0)`;
});

window.addEventListener("mouseup", () => {
  if (!isDragging) return;
  isDragging = false;
  interactiveOverlay.style.cursor = "grab";
});

// Event Listeners
playPauseBtn.addEventListener("click", togglePlayback);
nextTrackBtn.addEventListener("click", stepForward);
prevTrackBtn.addEventListener("click", stepBackward);
themeToggle.addEventListener("click", cycleTheme);

// Initialize
updateLyrics(false);
updateProgress();
playIcon.innerHTML = '<rect x="6" y="4" width="4" height="16"/><rect x="14" y="4" width="4" height="16"/>';
startTimer();
