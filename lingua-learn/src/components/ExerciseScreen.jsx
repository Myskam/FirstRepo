import { useState, useEffect, useRef } from 'react';
import { generateExercises, isCorrectAnswer, shuffle } from '../utils/exerciseGenerator';
import { speak, isTTSSupported } from '../utils/tts';
import { recordAnswer } from '../utils/wordStats';
import { explainAnswer } from '../utils/claude';
import GrammarTip from './GrammarTip';
import styles from './ExerciseScreen.module.css';

const XP_PER_CORRECT = 10;

export default function ExerciseScreen({ unit, lessonType, language, onComplete, onExit }) {
  const exercises = useRef(generateExercises(unit, lessonType, language));
  const apiKey = localStorage.getItem('ll_apiKey') ?? '';

  const [idx, setIdx]               = useState(0);
  const [answered, setAnswered]     = useState(false);
  const [correct, setCorrect]       = useState(false);
  const [detail, setDetail]         = useState('');
  const [correctCount, setCorrectCount] = useState(0);
  const [wrongCount,   setWrongCount]   = useState(0);
  const [lessonXP,     setLessonXP]     = useState(0);
  const [anim, setAnim]             = useState('');
  const [explanation, setExplanation] = useState('');
  const [loadingExplain, setLoadingExplain] = useState(false);
  const [lastUserAnswer, setLastUserAnswer] = useState('');

  const [selectedOption, setSelectedOption] = useState(null);
  const [typedAnswer,    setTypedAnswer]    = useState('');
  const [matchLeft,  setMatchLeft]  = useState(null);
  const [matchDone,  setMatchDone]  = useState(new Set());
  const [matchWrong, setMatchWrong] = useState(new Set());

  const inputRef = useRef();
  const ex    = exercises.current[idx];
  const total = exercises.current.length;
  const progress = (idx / total) * 100;
  const ttsOk = isTTSSupported();

  // Derive which text is in target language for TTS
  function targetText() {
    if (!ex) return '';
    if (ex.type === 'typeAnswer') return ex.question;
    if (ex.type === 'multiChoice') {
      return ex.prompt === 'What does this mean?' ? ex.question : ex.correct;
    }
    return '';
  }

  // Auto-play target word on each new exercise (typeAnswer / "What does this mean?" only)
  useEffect(() => {
    if (!ex || !ttsOk) return;
    const t = targetText();
    if (t && (ex.type === 'typeAnswer' || ex.prompt === 'What does this mean?')) {
      speak(t, language);
    }
  }, [idx]);

  useEffect(() => {
    if (ex?.type === 'typeAnswer') {
      setTimeout(() => inputRef.current?.focus(), 80);
    }
    setAnswered(false);
    setCorrect(false);
    setDetail('');
    setSelectedOption(null);
    setTypedAnswer('');
    setMatchLeft(null);
    setMatchDone(new Set());
    setMatchWrong(new Set());
    setExplanation('');
    setLastUserAnswer('');
  }, [idx]);

  useEffect(() => {
    function onKey(e) {
      if (answered && e.key === 'Enter') { advance(); return; }
      if (!answered && ex?.type === 'multiChoice') {
        const n = parseInt(e.key);
        if (n >= 1 && n <= 4) {
          const opts = ex.options;
          if (opts[n - 1]) submitMultiChoice(opts[n - 1]);
        }
      }
    }
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  });

  function triggerAnim(name) {
    setAnim('');
    requestAnimationFrame(() => setAnim(name));
  }

  function submitResult(isCorrect, correctAnswer, userAnswer) {
    setAnswered(true);
    setCorrect(isCorrect);
    setDetail(correctAnswer);
    setLastUserAnswer(userAnswer ?? '');
    // Track per-word stats for SRS
    if (ex.type !== 'match') recordAnswer(correctAnswer, isCorrect);
    if (isCorrect) {
      setCorrectCount(c => c + 1);
      setLessonXP(x => x + XP_PER_CORRECT);
      triggerAnim('anim-pop');
    } else {
      setWrongCount(w => w + 1);
      triggerAnim('anim-shake');
    }
  }

  function submitMultiChoice(option) {
    if (answered) return;
    setSelectedOption(option);
    submitResult(option === ex.correct, ex.correct, option);
  }

  function submitTypeAnswer() {
    if (answered || !typedAnswer.trim()) return;
    submitResult(isCorrectAnswer(typedAnswer, ex.correct), ex.correct, typedAnswer);
  }

  function handleMatchTap(side, id) {
    if (matchDone.has(id)) return;
    if (!matchLeft) { setMatchLeft({ side, id }); return; }
    if (matchLeft.side === side) { setMatchLeft({ side, id }); return; }

    const targetId = side === 'target' ? id : matchLeft.id;
    const nativeId = side === 'native' ? id : matchLeft.id;

    if (targetId === nativeId) {
      const nextDone = new Set([...matchDone, targetId]);
      setMatchDone(nextDone);
      setMatchLeft(null);
      if (nextDone.size === ex.pairs.length) {
        setTimeout(() => submitResult(true, '', ''), 300);
      }
    } else {
      const wrongIds = new Set([matchLeft.id, id]);
      setMatchWrong(wrongIds);
      setMatchLeft(null);
      setTimeout(() => setMatchWrong(new Set()), 600);
      setWrongCount(w => w + 1);
    }
  }

  function advance() {
    if (idx + 1 >= total) {
      onComplete({ correctCount, wrongCount, lessonXP });
    } else {
      setIdx(i => i + 1);
    }
  }

  function finish() {
    onComplete({ correctCount, wrongCount, lessonXP });
  }

  async function handleExplain() {
    if (explanation || loadingExplain) return;
    setLoadingExplain(true);
    try {
      const text = await explainAnswer(
        apiKey,
        language,
        ex.question ?? ex.prompt,
        detail,
        lastUserAnswer,
        unit.grammar ?? [],
      );
      setExplanation(text);
    } catch {
      setExplanation('Could not load explanation — check your connection.');
    } finally {
      setLoadingExplain(false);
    }
  }

  function handleExit() {
    if (idx > 0 && !window.confirm('Exit lesson? Progress will not be saved.')) return;
    onExit();
  }

  if (!ex) return null;

  const grammar = unit.grammar ?? [];

  return (
    <div className={styles.screen}>
      {/* Header */}
      <div className={styles.header}>
        <button className={`btn btn-ghost ${styles.exitBtn}`} onClick={handleExit}>✕</button>
        <div className="progress-track">
          <div className="progress-fill" style={{ width: `${progress}%` }} />
        </div>
        <span className={styles.counter}>{idx + 1} / {total}</span>
      </div>

      {/* Body */}
      <div className={`${styles.body} ${anim}`}>
        {ex.type === 'multiChoice' && (
          <MultiChoice
            exercise={ex}
            selected={selectedOption}
            answered={answered}
            onSelect={submitMultiChoice}
            language={language}
            ttsOk={ttsOk}
          />
        )}
        {ex.type === 'typeAnswer' && (
          <TypeAnswer
            exercise={ex}
            value={typedAnswer}
            onChange={setTypedAnswer}
            answered={answered}
            correct={correct}
            inputRef={inputRef}
            onSubmit={submitTypeAnswer}
            language={language}
            ttsOk={ttsOk}
          />
        )}
        {ex.type === 'match' && (
          <MatchPairs
            exercise={ex}
            selected={matchLeft}
            done={matchDone}
            wrong={matchWrong}
            onTap={handleMatchTap}
            language={language}
            ttsOk={ttsOk}
          />
        )}

        {/* Grammar tips — shown above answer area when not yet answered */}
        {!answered && grammar.length > 0 && (
          <GrammarTip grammar={grammar} question={ex.question} correct={ex.correct} />
        )}
      </div>

      {/* Feedback footer */}
      {answered && (
        <div className={`${styles.footer} ${correct ? styles.footerCorrect : styles.footerWrong}`}>
          <p className={`${styles.feedbackMsg} ${correct ? styles.msgCorrect : styles.msgWrong}`}>
            {correct ? '🎉 Correct!' : '❌ Incorrect'}
          </p>
          {!correct && detail && (
            <p className={styles.feedbackDetail}>Correct answer: <strong>{detail}</strong></p>
          )}
          {correct && detail && (
            <p className={styles.feedbackDetail}>{detail}</p>
          )}

          {/* Explain This — shown on wrong answers */}
          {!correct && (
            <div className={styles.explainWrap}>
              {!explanation && !loadingExplain && (
                <button className={styles.explainBtn} onClick={handleExplain}>
                  Explain this →
                </button>
              )}
              {loadingExplain && (
                <span className={styles.explainLoading}>Loading explanation…</span>
              )}
              {explanation && (
                <p className={styles.explanation}>{explanation}</p>
              )}
            </div>
          )}

          <button
            className={`btn ${correct ? 'btn-primary' : 'btn-danger'}`}
            onClick={advance}
          >
            Continue
          </button>
        </div>
      )}

      {/* Check button for type answer before submission */}
      {!answered && ex.type === 'typeAnswer' && (
        <div className={styles.footer}>
          <button
            className="btn btn-primary"
            disabled={!typedAnswer.trim()}
            onClick={submitTypeAnswer}
          >
            Check
          </button>
        </div>
      )}
    </div>
  );
}

/* ── Sub-components ───────────────────────────────────────── */

function SpeakBtn({ text, language, ttsOk }) {
  if (!ttsOk || !text) return null;
  return (
    <button
      className={styles.speakBtn}
      onClick={e => { e.stopPropagation(); speak(text, language); }}
      aria-label="Play pronunciation"
      title="Play pronunciation"
    >
      🔊
    </button>
  );
}

function MultiChoice({ exercise, selected, answered, onSelect, language, ttsOk }) {
  const isTargetQuestion = exercise.prompt === 'What does this mean?';
  const speakText = isTargetQuestion ? exercise.question : exercise.correct;

  return (
    <>
      <p className={styles.prompt}>{exercise.prompt}</p>
      <div className={styles.questionRow}>
        <p className={styles.question}>{exercise.question}</p>
        {ttsOk && <SpeakBtn text={speakText} language={language} ttsOk={ttsOk} />}
      </div>
      <div className={styles.optionsGrid}>
        {exercise.options.map((opt, i) => {
          let cls = styles.option;
          if (answered) {
            if (opt === exercise.correct)  cls += ` ${styles.optCorrect}`;
            else if (opt === selected)     cls += ` ${styles.optWrong}`;
          } else if (opt === selected) {
            cls += ` ${styles.optSelected}`;
          }
          return (
            <button
              key={i}
              className={cls}
              onClick={() => !answered && onSelect(opt)}
              disabled={answered}
            >
              {opt}
            </button>
          );
        })}
      </div>
    </>
  );
}

function TypeAnswer({ exercise, value, onChange, answered, correct, inputRef, onSubmit, language, ttsOk }) {
  return (
    <>
      <p className={styles.prompt}>{exercise.prompt}</p>
      <div className={styles.questionRow}>
        <p className={styles.question}>{exercise.question}</p>
        <SpeakBtn text={exercise.question} language={language} ttsOk={ttsOk} />
      </div>
      <input
        ref={inputRef}
        type="text"
        className={`input-field ${styles.typeInput} ${answered ? (correct ? 'correct' : 'wrong') : ''}`}
        placeholder="Type your answer…"
        value={value}
        onChange={e => !answered && onChange(e.target.value)}
        onKeyDown={e => e.key === 'Enter' && !answered && onSubmit()}
        disabled={answered}
        autoComplete="off"
        autoCorrect="off"
        spellCheck={false}
      />
    </>
  );
}

function MatchPairs({ exercise, selected, done, wrong, onTap, language, ttsOk }) {
  const [leftItems]  = useState(() => shuffle(exercise.pairs));
  const [rightItems] = useState(() => shuffle(exercise.pairs));

  function itemClass(side, id) {
    let cls = styles.matchItem;
    if (done.has(id))  cls += ` ${styles.matchDone}`;
    if (wrong.has(id)) cls += ` ${styles.matchWrong}`;
    if (selected && selected.id === id) cls += ` ${styles.matchSelected}`;
    return cls;
  }

  return (
    <>
      <p className={styles.prompt}>{exercise.prompt}</p>
      <p className={styles.matchHint}>Tap a word, then tap its translation</p>
      <div className={styles.matchGrid}>
        <div className={styles.matchCol}>
          {leftItems.map(p => (
            <button key={p.id} className={itemClass('target', p.id)} onClick={() => !done.has(p.id) && onTap('target', p.id)}>
              <span>{p.target}</span>
              {ttsOk && (
                <span
                  className={styles.matchSpeak}
                  onClick={e => { e.stopPropagation(); speak(p.target, language); }}
                  role="button"
                  aria-label="Play pronunciation"
                >
                  🔊
                </span>
              )}
            </button>
          ))}
        </div>
        <div className={styles.matchCol}>
          {rightItems.map(p => (
            <button key={p.id} className={itemClass('native', p.id)} onClick={() => !done.has(p.id) && onTap('native', p.id)}>
              {p.native}
            </button>
          ))}
        </div>
      </div>
    </>
  );
}
