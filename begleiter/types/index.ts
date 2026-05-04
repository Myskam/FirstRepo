// ── Taxonomy ──────────────────────────────────────────────────────────────────

export type CefrLevel = 'A1' | 'A2' | 'B1' | 'B2+';
export type TopicCategory = 'grammar' | 'vocabulary';

export interface TaxonomyTopic {
  id: string;
  level: CefrLevel;
  category: TopicCategory;
  displayName: string;
  prerequisites: string[];
}

// ── Student Profile ───────────────────────────────────────────────────────────

export type TopicStatus =
  | 'not_covered'
  | 'introduced'
  | 'active'
  | 'struggling'
  | 'mastered';

export interface SessionResult {
  date: string;
  exerciseCount: number;
  correctCount: number;
  errorTopics: string[];
}

export interface TopicState {
  status: TopicStatus;
  correctStreak: number;
  totalAttempts: number;
  correctAttempts: number;
  lastPracticed: string | null;
  sessionHistory: SessionResult[];
}

export type StudyContext = 'class' | 'self_study' | 'app_only';

export interface StudentProfile {
  id: string;
  createdAt: string;
  level: CefrLevel;
  studyContext: StudyContext;
  textbook: string | null;
  onboardingComplete: boolean;
  topics: Record<string, TopicState>;
}

// ── Exercises ─────────────────────────────────────────────────────────────────

export interface MultipleChoiceExercise {
  type: 'multiple_choice';
  id: string;
  topic: string;
  question: string;
  options: string[];
  correct: string;
  hint: string | null;
  explanation: string;
}

export interface FillBlankExercise {
  type: 'fill_blank';
  id: string;
  topic: string;
  sentence: string;
  blank: string;
  correct: string;
  hint: string | null;
  explanation: string;
}

export interface MatchPairsExercise {
  type: 'match_pairs';
  id: string;
  topic: string;
  pairs: { left: string; right: string }[];
  explanation: string;
}

export interface ReorderWordsExercise {
  type: 'reorder_words';
  id: string;
  topic: string;
  question?: string;
  words: string[];
  correct: string;
  hint: string | null;
  explanation: string;
}

export type Exercise =
  | MultipleChoiceExercise
  | FillBlankExercise
  | MatchPairsExercise
  | ReorderWordsExercise;

// ── Session ───────────────────────────────────────────────────────────────────

export interface Answer {
  exerciseId: string;
  topic: string;
  correct: boolean;
  timeSpent: number;
}

export interface ActiveSession {
  id: string;
  exercises: Exercise[];
  currentIndex: number;
  answers: Answer[];
  startedAt: string;
  isLoading: boolean;
  error: string | null;
  summary: SessionSummary | null;
}

export interface SessionSummary {
  strongTopics: string[];
  weakTopics: string[];
  recommendation: string;
}

// ── Diagnostic ────────────────────────────────────────────────────────────────

export interface DiagnosticQuestion {
  id: string;
  topic: string;
  type: 'multiple_choice' | 'fill_blank';
  question: string;
  options: string[] | null;
  correct: string;
  explanation: string;
}

export interface DiagnosticResult {
  questions: DiagnosticQuestion[];
  answers: Record<string, string>;
  score: number;
}
