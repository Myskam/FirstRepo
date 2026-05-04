import { useState } from 'react';
import WelcomeScreen   from './components/WelcomeScreen';
import UploadScreen    from './components/UploadScreen';
import AnalyzingScreen from './components/AnalyzingScreen';
import CourseScreen    from './components/CourseScreen';
import LessonScreen    from './components/LessonScreen';
import ExerciseScreen  from './components/ExerciseScreen';
import CompleteScreen      from './components/CompleteScreen';
import ConversationScreen  from './components/ConversationScreen';
import Toast, { useToast, toast } from './components/Toast';
import { analyzeImage } from './utils/claude';
import { buildCourse }  from './utils/courseBuilder';
import { loadCachedGermanCourse, buildGermanCourse, clearGermanCourseCache } from './utils/germanTutorLoader';

function loadState() {
  return {
    course:   JSON.parse(localStorage.getItem('ll_course')   || 'null'),
    totalXP:  parseInt(localStorage.getItem('ll_xp')        || '0', 10),
    streak:   parseInt(localStorage.getItem('ll_streak')    || '0', 10),
  };
}

export default function App() {
  const saved = loadState();

  const [screen,     setScreen]     = useState('welcome');
  const [apiKey,     setApiKey]     = useState(() => localStorage.getItem('ll_apiKey') ?? '');
  const [course,     setCourse]     = useState(saved.course);
  const [totalXP,    setTotalXP]    = useState(saved.totalXP);
  const [streak,     setStreak]     = useState(saved.streak);
  const [unitIdx,    setUnitIdx]    = useState(0);
  const [lessonType, setLessonType] = useState('vocabulary');
  const [result,     setResult]     = useState(null);
  const [status,     setStatus]     = useState('');

  const toastState = useToast();

  /* ── Welcome ── */
  function handleStart(key) {
    setApiKey(key);
    setScreen(course ? 'course' : 'upload');
  }

  /* ── Upload → Analyze ── */
  async function handleAnalyze(files) {
    setScreen('analyzing');
    const pages = [];

    for (let i = 0; i < files.length; i++) {
      setStatus(`Scanning image ${i + 1} of ${files.length}…`);
      const base64    = files[i].data.split(',')[1];
      const mediaType = files[i].type || 'image/jpeg';
      try {
        const data = await analyzeImage(apiKey, base64, mediaType);
        pages.push(data);
      } catch (err) {
        toast(`Image ${i + 1}: ${err.message}`);
      }
    }

    if (pages.length === 0) {
      toast('Could not extract content — try clearer images');
      setScreen('upload');
      return;
    }

    setStatus('Building your course…');
    const newCourse = buildCourse(pages);
    setCourse(newCourse);
    localStorage.setItem('ll_course', JSON.stringify(newCourse));
    setScreen('course');
  }

  /* ── Course → Lesson ── */
  function handleSelectUnit(i) {
    setUnitIdx(i);
    setScreen('lesson');
  }

  /* ── Lesson → Exercise ── */
  function handleStartLesson(type) {
    setLessonType(type);
    setScreen('exercise');
  }

  /* ── Exercise → Complete ── */
  function handleComplete(res) {
    setResult(res);

    const newXP     = totalXP + res.lessonXP;
    const newStreak = streak + 1;
    setTotalXP(newXP);
    setStreak(newStreak);
    localStorage.setItem('ll_xp',     newXP);
    localStorage.setItem('ll_streak', newStreak);

    // Update unit progress
    setCourse(prev => {
      const next = structuredClone(prev);
      const unit = next.units[unitIdx];
      const acc  = res.correctCount / Math.max(1, res.correctCount + res.wrongCount);
      unit.progress  = Math.min(100, (unit.progress ?? 0) + Math.round(acc * 34));
      unit.xpEarned  = (unit.xpEarned ?? 0) + res.lessonXP;
      unit.completed = unit.progress >= 100;
      localStorage.setItem('ll_course', JSON.stringify(next));
      return next;
    });

    setScreen('complete');
  }

  /* ── Complete → next unit or course ── */
  function handleContinue() {
    const next = unitIdx + 1;
    if (course && next < course.units.length) {
      setUnitIdx(next);
      setScreen('lesson');
    } else {
      toast('🎓 You finished all units!');
      setScreen('course');
    }
  }

  /* ── Load German Tutor preset ── */
  async function handleLoadGermanTutor() {
    const cached = loadCachedGermanCourse();
    if (cached) {
      setCourse(cached);
      localStorage.setItem('ll_course', JSON.stringify(cached));
      setScreen('course');
      return;
    }
    if (!apiKey.trim()) {
      toast('Enter your Claude API key first to scan the course materials');
      return;
    }
    setScreen('analyzing');
    try {
      const newCourse = await buildGermanCourse(apiKey, setStatus);
      setCourse(newCourse);
      localStorage.setItem('ll_course', JSON.stringify(newCourse));
      setScreen('course');
    } catch (err) {
      toast(err.message);
      setScreen('welcome');
    }
  }

  /* ── Reset ── */
  function handleReset() {
    ['ll_course', 'll_xp', 'll_streak'].forEach(k => localStorage.removeItem(k));
    clearGermanCourseCache();
    setCourse(null);
    setTotalXP(0);
    setStreak(0);
    setScreen('upload');
  }

  return (
    <>
      {screen === 'welcome' && (
        <WelcomeScreen
          onStart={handleStart}
          savedCourse={course}
          onLoadGermanTutor={handleLoadGermanTutor}
          hasGermanCache={!!loadCachedGermanCourse()}
        />
      )}
      {screen === 'upload'    && <UploadScreen    onAnalyze={handleAnalyze} />}
      {screen === 'analyzing' && <AnalyzingScreen status={status} />}
      {screen === 'course'    && course && (
        <CourseScreen
          course={course}
          totalXP={totalXP}
          streak={streak}
          onSelectUnit={handleSelectUnit}
          onAddMore={() => setScreen('upload')}
          onReset={handleReset}
        />
      )}
      {screen === 'lesson' && course && (
        <LessonScreen
          unit={course.units[unitIdx]}
          onStart={handleStartLesson}
          onConverse={() => setScreen('conversation')}
          onBack={() => setScreen('course')}
        />
      )}
      {screen === 'conversation' && course && (
        <ConversationScreen
          unit={course.units[unitIdx]}
          language={course.language}
          apiKey={apiKey}
          onExit={() => setScreen('lesson')}
        />
      )}
      {screen === 'exercise' && course && (
        <ExerciseScreen
          unit={course.units[unitIdx]}
          lessonType={lessonType}
          language={course.language}
          onComplete={handleComplete}
          onExit={() => setScreen('course')}
        />
      )}
      {screen === 'complete' && result && (
        <CompleteScreen
          result={result}
          onContinue={handleContinue}
          onBack={() => setScreen('course')}
        />
      )}

      <Toast msg={toastState.msg} visible={toastState.visible} />
    </>
  );
}
