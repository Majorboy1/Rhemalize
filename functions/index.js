const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { onCall } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { tmpdir } = require("os");
const { join } = require("path");
const { writeFileSync, unlinkSync } = require("fs");
const mp3Duration = require("mp3-duration");

// Initialize the Firebase Admin SDK
initializeApp();
const firestore = getFirestore();
const storage = getStorage();

// ─────────────────────────────────────────────
//  1. EXTRACT DURATION ON NEW AUDIO UPLOAD
//     Triggered whenever a file is uploaded to
//     the "audio/" folder in Firebase Storage.
// ─────────────────────────────────────────────
exports.extractAudioDuration = onObjectFinalized(
  async (event) => {
    const { name: filePath, contentType } = event.data;
    if (!filePath || !filePath.startsWith("audio/")) return;
    if (!contentType || !contentType.startsWith("audio/")) return;

    console.log(`Processing audio file: ${filePath}`);

    try {
      // Download the file to a temp dir and parse duration from header
      const bucket = storage.bucket(event.data.bucket);
      const file = bucket.file(filePath);
      const tempPath = join(tmpdir(), `audio_${Date.now()}.mp3`);

      // Only download the first 64KB - enough for MP3 header/Xing frame
      await file.download({ destination: tempPath });
      const durationSeconds = await new Promise((resolve, reject) => {
        mp3Duration(tempPath, (err, duration) => {
          // Clean up temp file
          try { unlinkSync(tempPath); } catch (_) {}
          if (err) reject(err);
          else resolve(duration);
        });
      });

      if (!durationSeconds || durationSeconds <= 0) {
        console.log(`Could not determine duration for ${filePath}`);
        return;
      }

      // Format the duration as HH:MM:SS or MM:SS
      const durStr = formatDuration(durationSeconds);
      console.log(`Duration for ${filePath}: ${durStr}`);

      // Build the download URL so we can find the Firestore doc
      const downloadUrl = `https://firebasestorage.googleapis.com/v0/b/${event.data.bucket}/o/${encodeURIComponent(filePath)}?alt=media`;

      // Find the sermon document that has this audioUrl
      await updateFirestoreDuration(downloadUrl, filePath, durStr);
    } catch (error) {
      console.error(`Error extracting duration for ${filePath}:`, error);
    }
  }
);

// ─────────────────────────────────────────────
//  2. BACKFILL ALL EXISTING SERMONS (Callable)
//     Invoked from the Flutter admin panel to
//     fix durations for all existing sermons.
// ─────────────────────────────────────────────
exports.backfillDurations = onCall(
  { cors: true },
  async (event) => {
    // Only allow admins to trigger this
    if (!event.auth) {
      return { success: false, error: "Authentication required" };
    }

    const results = { total: 0, fixed: 0, failed: 0, errors: [] };

    try {
      // Get all sermons
      const snapshot = await firestore.collection("sermons").get();
      results.total = snapshot.docs.length;

      for (const doc of snapshot.docs) {
        const data = doc.data();
        let updated = false;

        // Fix main sermon duration
        if (data.audioUrl && data.audioUrl.startsWith("http")) {
          if (!data.duration || data.duration === "0:00" || data.duration === "") {
            try {
              const dur = await extractDurationFromUrl(data.audioUrl);
              if (dur) {
                await doc.ref.update({ duration: dur });
                results.fixed++;
                updated = true;
                console.log(`Fixed sermon ${doc.id}: ${dur}`);
              }
            } catch (e) {
              results.failed++;
              results.errors.push(`Sermon ${doc.id}: ${e.message}`);
            }
          }
        }

        // Fix episode durations
        const episodes = data.episodes || [];
        let episodesChanged = false;
        for (let i = 0; i < episodes.length; i++) {
          const ep = episodes[i];
          if (ep.audioUrl && ep.audioUrl.startsWith("http")) {
            if (!ep.duration || ep.duration === "0:00" || ep.duration === "") {
              try {
                const dur = await extractDurationFromUrl(ep.audioUrl);
                if (dur) {
                  episodes[i].duration = dur;
                  episodesChanged = true;
                  results.fixed++;
                  console.log(`Fixed episode ${ep.id} in sermon ${doc.id}: ${dur}`);
                }
              } catch (e) {
                results.failed++;
                results.errors.push(`Episode ${ep.id}: ${e.message}`);
              }
            }
          }
        }
        if (episodesChanged) {
          await doc.ref.update({ episodes });
        }
      }
    } catch (error) {
      console.error("Backfill error:", error);
      return { success: false, error: error.message };
    }

    return {
      success: true,
      total: results.total,
      fixed: results.fixed,
      failed: results.failed,
      errors: results.errors,
    };
  }
);

// ─────────────────────────────────────────────
//  3. PUSH NOTIFICATION on new sermon
// ─────────────────────────────────────────────
exports.sendSermonNotification = onDocumentCreated(
  "sermons/{sermonId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return null;

    const sermonData = snapshot.data();
    const sermonTitle = sermonData.title || "New Sermon Available";

    const message = {
      notification: {
        title: "New Sermon Uploaded! 📖",
        body: `Listen now: ${sermonTitle}`,
      },
      topic: "new_sermons",
      android: {
        notification: {
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
    };

    try {
      const response = await getMessaging().send(message);
      console.log("Successfully sent message:", response);
    } catch (error) {
      console.log("Error sending message:", error);
    }
  }
);

// ─────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────

/** Format seconds into "MM:SS" or "H:MM:SS" */
function formatDuration(totalSeconds) {
  if (!totalSeconds || totalSeconds <= 0) return "0:00";
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const secs = Math.floor(totalSeconds % 60);
  if (hours > 0) {
    return `${hours}:${String(minutes).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
  }
  return `${String(minutes).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
}

/** Extract audio duration from a download URL using mp3-duration */
async function extractDurationFromUrl(downloadUrl) {
  // Convert download URL back to a storage reference
  const urlObj = new URL(downloadUrl);
  const pathParts = urlObj.pathname.split("/o/");
  if (pathParts.length < 2) return null;
  const encodedPath = pathParts[1].split("?")[0];
  const filePath = decodeURIComponent(encodedPath);

  const bucket = storage.bucket();
  const file = bucket.file(filePath);
  const exists = await file.exists();
  if (!exists[0]) {
    console.log(`File not found in storage: ${filePath}`);
    return null;
  }

  const tempPath = join(tmpdir(), `backfill_${Date.now()}_${Math.random().toString(36).slice(2)}.mp3`);
  await file.download({ destination: tempPath });

  const durationSeconds = await new Promise((resolve, reject) => {
    mp3Duration(tempPath, (err, duration) => {
      try { unlinkSync(tempPath); } catch (_) {}
      if (err) reject(err);
      else resolve(duration);
    });
  });

  if (durationSeconds && durationSeconds > 0) return formatDuration(durationSeconds);
  return null;
}

/** Update a Firestore sermon/episode record by matching the audio URL.
 *  Also handles the old bucket name for backward compatibility. */
async function updateFirestoreDuration(downloadUrl, filePath, durStr) {
  // Try to find a sermon with matching audioUrl
  const sermonsSnap = await firestore
    .collection("sermons")
    .where("audioUrl", ">=", downloadUrl)
    .where("audioUrl", "<=", downloadUrl + "\uf8ff")
    .get();

  if (!sermonsSnap.empty) {
    for (const doc of sermonsSnap.docs) {
      await doc.ref.update({ duration: durStr });
      console.log(`Updated sermon ${doc.id} duration: ${durStr}`);
    }
    return;
  }

  // Try to find a sermon whose episodes contain this audioUrl
  const allSermons = await firestore.collection("sermons").get();
  for (const doc of allSermons.docs) {
    const episodes = doc.data().episodes || [];
    let changed = false;
    for (let i = 0; i < episodes.length; i++) {
      if (episodes[i].audioUrl && episodes[i].audioUrl.includes(filePath)) {
        episodes[i].duration = durStr;
        changed = true;
        console.log(`Updated episode ${episodes[i].id} duration: ${durStr}`);
      }
    }
    if (changed) {
      await doc.ref.update({ episodes });
    }
  }
}