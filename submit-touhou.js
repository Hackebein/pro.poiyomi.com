(async () => {
  const endpoint = "https://us-central1-poiyomi-pro-site.cloudfunctions.net/submitTouhouScoreV2";

  const getTokenFromIDB = () => new Promise((resolve) => {
    const req = indexedDB.open("firebaseLocalStorageDb");
    req.onerror = () => resolve(null);
    req.onsuccess = () => {
      try {
        const db = req.result;
        const tx = db.transaction("firebaseLocalStorage", "readonly");
        const store = tx.objectStore("firebaseLocalStorage");
        const all = store.getAll();
        all.onsuccess = () => {
          for (const entry of all.result || []) {
            const t = entry?.value?.stsTokenManager?.accessToken;
            if (t) return resolve(t);
          }
          resolve(null);
        };
        all.onerror = () => resolve(null);
      } catch { resolve(null); }
    };
  });

  const token = await getTokenFromIDB();
  if (!token) throw new Error("Not logged in -- no Firebase auth token found.");

  const score = Math.floor(Number(prompt("Score to submit:", "50")) || 50);

  // Real client: ze=0.1 (100 pts/sec), ut=1e3 (1s checkpoint ticks)
  // score = Math.floor(gameTime * 0.1), so gameTime ∈ [score*10, score*10+10)
  const gameTime = score * 10 + 2 + Math.random() * 7;

  // Checkpoints fire when elapsed % 1000 < 16 (once per ~1s rAF window)
  // Values are Math.floor(elapsedAtTick * 0.1) — nearly linear at ~100 pts/tick
  const checkpoints = [0];
  const numFullSeconds = Math.floor(gameTime / 1000);
  for (let k = 1; k <= numFullSeconds; k++) {
    const frameTime = k * 1000 + Math.random() * 15;
    checkpoints.push(Math.floor(frameTime * 0.1));
  }

  // Hash uses last checkpoint score + absolute rAF timestamp (performance.now())
  const lastCpScore = checkpoints[checkpoints.length - 1];
  const lastCpAbsTime = performance.now() - gameTime + numFullSeconds * 1000 + Math.random() * 15;
  const hash = btoa(`${lastCpScore}-${lastCpAbsTime}-touhou-game-2024`).substring(0, 10);

  // mouseMoves: incremented per rAF frame where cursor delta > 2px on either axis
  const framesTotal = Math.floor(gameTime / 16.67);
  const mouseMoves = Math.floor(framesTotal * (0.7 + Math.random() * 0.2));

  const body = { score, validation: { checkpoints, mouseMoves, gameTime, hash } };
  console.log("Payload:", JSON.stringify(body, null, 2));

  const res = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
    body: JSON.stringify(body)
  });

  console.log("HTTP", res.status, await res.json());
})();