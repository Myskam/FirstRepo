const KEY = 'll_word_stats';

function load() {
  try { return JSON.parse(localStorage.getItem(KEY) || '{}'); }
  catch { return {}; }
}

function save(stats) {
  localStorage.setItem(KEY, JSON.stringify(stats));
}

export function recordAnswer(target, isCorrect) {
  if (!target) return;
  const stats = load();
  const entry = stats[target] ?? { correct: 0, wrong: 0, lastWrong: null };
  if (isCorrect) {
    entry.correct += 1;
  } else {
    entry.wrong += 1;
    entry.lastWrong = Date.now();
  }
  stats[target] = entry;
  save(stats);
}

// Returns vocab items with wrong-rate > threshold
export function getWeakWords(vocab, threshold = 0.4) {
  const stats = load();
  return (vocab ?? []).filter(v => {
    const s = stats[v.target];
    if (!s || s.wrong + s.correct === 0) return false;
    return s.wrong / (s.wrong + s.correct) > threshold;
  });
}

// Returns top N weak words sorted by wrong-rate then recency
export function getTopWeakWords(vocab, n = 12) {
  const stats = load();
  return getWeakWords(vocab)
    .sort((a, b) => {
      const sa = stats[a.target], sb = stats[b.target];
      const rateA = sa.wrong / (sa.wrong + sa.correct);
      const rateB = sb.wrong / (sb.wrong + sb.correct);
      if (Math.abs(rateA - rateB) > 0.05) return rateB - rateA;
      return (sb.lastWrong ?? 0) - (sa.lastWrong ?? 0);
    })
    .slice(0, n);
}
