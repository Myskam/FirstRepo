'use client';
import { motion, AnimatePresence } from 'framer-motion';
import type { Exercise, Answer } from '@/types';
import { MultipleChoice } from './MultipleChoice';
import { FillBlank } from './FillBlank';
import { MatchPairs } from './MatchPairs';
import { ReorderWords } from './ReorderWords';

interface Props {
  exercise: Exercise;
  exerciseIndex: number;
  onAnswer: (answer: Answer) => void;
}

export function QuizCard({ exercise, exerciseIndex, onAnswer }: Props) {
  const startedAt = Date.now();

  function handleAnswer(correct: boolean) {
    const timeSpent = Date.now() - startedAt;
    onAnswer({ exerciseId: exercise.id, topic: exercise.topic, correct, timeSpent });
  }

  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={exerciseIndex}
        initial={{ opacity: 0, x: 40 }}
        animate={{ opacity: 1, x: 0 }}
        exit={{ opacity: 0, x: -40 }}
        transition={{ duration: 0.22 }}
        className="w-full"
      >
        {exercise.type === 'multiple_choice' && (
          <MultipleChoice exercise={exercise} onAnswer={(c) => handleAnswer(c)} />
        )}
        {exercise.type === 'fill_blank' && (
          <FillBlank exercise={exercise} onAnswer={(c) => handleAnswer(c)} />
        )}
        {exercise.type === 'match_pairs' && (
          <MatchPairs exercise={exercise} onAnswer={(c) => handleAnswer(c)} />
        )}
        {exercise.type === 'reorder_words' && (
          <ReorderWords exercise={exercise} onAnswer={(c) => handleAnswer(c)} />
        )}
      </motion.div>
    </AnimatePresence>
  );
}
