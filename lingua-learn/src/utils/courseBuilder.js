function dedup(arr, keyFn) {
  const seen = new Set();
  return arr.filter(item => {
    const k = keyFn(item)?.toLowerCase?.();
    if (!k || seen.has(k)) return false;
    seen.add(k);
    return true;
  });
}

const UNIT_ICONS = ['📚', '💬', '🌟', '🎯', '🔤', '📝', '🗣️', '✍️', '🧠', '🎓'];

export function buildCourse(pages) {
  const language =
    pages.find(p => p.language && p.language.length < 40)?.language ?? 'Unknown';

  const allVocab     = pages.flatMap(p => p.vocabulary ?? []).filter(v => v.target && v.native);
  const allPhrases   = pages.flatMap(p => p.phrases   ?? []).filter(p => p.target && p.native);
  const allGrammar   = pages.flatMap(p => p.grammar   ?? []).filter(g => g.rule);
  const allSentences = pages.flatMap(p => p.sentences ?? []).filter(s => s.target && s.native);

  const vocab     = dedup(allVocab,     v => v.target);
  const phrases   = dedup(allPhrases,   p => p.target);
  const grammar   = dedup(allGrammar,   g => g.rule);
  const sentences = dedup(allSentences, s => s.target);

  const CHUNK = 10;
  const unitCount = Math.max(1, Math.ceil(vocab.length / CHUNK));
  const units = [];

  for (let i = 0; i < unitCount; i++) {
    const vocabSlice     = vocab.slice(i * CHUNK, (i + 1) * CHUNK);
    const phrasesSlice   = phrases.slice(i * 3, (i + 1) * 3);
    const sentencesSlice = sentences.slice(i * 3, (i + 1) * 3);
    const grammarSlice   = i === 0 ? grammar : [];

    units.push({
      id: i,
      title: `Unit ${i + 1}`,
      icon: UNIT_ICONS[i % UNIT_ICONS.length],
      vocabulary: vocabSlice,
      phrases: phrasesSlice,
      sentences: sentencesSlice,
      grammar: grammarSlice,
      completed: false,
      progress: 0,
      xpEarned: 0,
    });
  }

  // Bonus phrases unit
  if (phrases.length > unitCount * 3) {
    const extra = phrases.slice(unitCount * 3);
    units.push({
      id: units.length,
      title: `Unit ${units.length + 1}: Phrases`,
      icon: '💬',
      vocabulary: extra.map(p => ({ target: p.target, native: p.native, example: '' })),
      phrases: extra,
      sentences,
      grammar: [],
      completed: false,
      progress: 0,
      xpEarned: 0,
    });
  }

  return {
    language,
    title: `${language} Course`,
    units,
    totalVocab: vocab.length,
    totalPhrases: phrases.length,
    createdAt: new Date().toISOString(),
  };
}
