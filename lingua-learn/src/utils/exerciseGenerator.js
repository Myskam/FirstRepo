export function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

function multiChoice(item, pool, lang) {
  const others = pool.filter(p => p.native !== item.native);
  const wrongs = shuffle(others).slice(0, 3).map(p => p.native);
  if (wrongs.length < 3) return null;
  return {
    type: 'multiChoice',
    prompt: 'What does this mean?',
    question: item.target,
    correct: item.native,
    options: shuffle([item.native, ...wrongs]),
    detail: item.example ?? '',
  };
}

function reverseMultiChoice(item, pool, lang) {
  const others = pool.filter(p => p.target !== item.target);
  const wrongs = shuffle(others).slice(0, 3).map(p => p.target);
  if (wrongs.length < 3) return null;
  return {
    type: 'multiChoice',
    prompt: `How do you say this in ${lang}?`,
    question: item.native,
    correct: item.target,
    options: shuffle([item.target, ...wrongs]),
    detail: '',
  };
}

function typeAnswer(item) {
  return {
    type: 'typeAnswer',
    prompt: 'Translate to English:',
    question: item.target,
    correct: item.native,
    detail: item.example ?? '',
  };
}

function matchExercise(items) {
  const pairs = shuffle(items).slice(0, Math.min(6, items.length));
  return {
    type: 'match',
    prompt: 'Match each word with its translation',
    pairs: pairs.map((p, i) => ({ id: i, target: p.target, native: p.native })),
  };
}

import { getTopWeakWords } from './wordStats';

export function generateExercises(unit, lessonType, language) {
  const vocab     = (unit.vocabulary ?? []).filter(v => v.target && v.native);
  const phrases   = (unit.phrases   ?? []).filter(p => p.target && p.native);
  const sentences = (unit.sentences ?? []).filter(s => s.target && s.native);
  const pool = [...vocab, ...phrases];

  let exercises = [];

  switch (lessonType) {
    case 'vocabulary': {
      const items = shuffle(vocab).slice(0, 10);
      items.forEach(item => {
        const mc = multiChoice(item, vocab, language);
        if (mc) exercises.push(mc);
        if (vocab.length >= 5) {
          const rev = reverseMultiChoice(item, vocab, language);
          if (rev) exercises.push(rev);
        }
      });
      break;
    }

    case 'match': {
      if (pool.length >= 3) exercises.push(matchExercise(pool));
      // Follow-up vocab questions
      shuffle(vocab).slice(0, 6).forEach(item => {
        const mc = multiChoice(item, vocab, language);
        if (mc) exercises.push(mc);
      });
      break;
    }

    case 'phrases': {
      const items = shuffle([...phrases, ...sentences]).slice(0, 8);
      items.forEach(item => {
        const mc = multiChoice(item, [...phrases, ...sentences], language);
        exercises.push(mc ?? typeAnswer(item));
      });
      break;
    }

    case 'translate': {
      shuffle(pool).slice(0, 10).forEach(item => exercises.push(typeAnswer(item)));
      break;
    }

    case 'review': {
      const weakWords = getTopWeakWords(unit.vocabulary ?? [], 12);
      const useWeak = weakWords.length >= 4;
      const base = useWeak ? weakWords : shuffle(pool).slice(0, 12);
      base.forEach(item => exercises.push(typeAnswer(item)));
      if (!useWeak) {
        // Mix in some multi-choice for variety
        exercises.forEach((ex, i) => {
          if (i % 3 === 0) {
            const mc = multiChoice(base[i], pool, language);
            if (mc) exercises[i] = mc;
          }
        });
      }
      if (pool.length >= 3) exercises.splice(Math.min(4, exercises.length), 0, matchExercise(pool));
      break;
    }

    default:
      break;
  }

  return shuffle(exercises).slice(0, 15);
}

export function normalizeAnswer(s) {
  return s
    .toLowerCase()
    .trim()
    .replace(/[.,!?;:'"()]/g, '')
    .replace(/\s+/g, ' ')
    .replace(/^(a|an|the|el|la|los|las|le|les|un|une|des)\s+/i, '');
}

export function isCorrectAnswer(userAnswer, correct) {
  return normalizeAnswer(userAnswer) === normalizeAnswer(correct);
}
