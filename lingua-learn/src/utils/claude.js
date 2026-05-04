const BASE = 'https://api.anthropic.com/v1/messages';

const HEADERS = (apiKey) => ({
  'x-api-key': apiKey,
  'anthropic-version': '2023-06-01',
  'content-type': 'application/json',
  'anthropic-dangerous-direct-browser-access': 'true',
});

async function callClaude(apiKey, body) {
  const res = await fetch(BASE, {
    method: 'POST',
    headers: HEADERS(apiKey),
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error?.message || `API error ${res.status}`);
  }
  return res.json();
}

export async function analyzeImage(apiKey, base64Data, mediaType) {
  const json = await callClaude(apiKey, {
    model: 'claude-sonnet-4-6',
    max_tokens: 4096,
    messages: [{
      role: 'user',
      content: [
        {
          type: 'image',
          source: { type: 'base64', media_type: mediaType, data: base64Data },
        },
        {
          type: 'text',
          text: `Analyze this language course textbook or workbook page.
Extract ALL learning content and return ONLY a valid JSON object — no markdown, no explanation.

Required structure:
{
  "language": "name of the language being learned (not English)",
  "chapter": "chapter/unit label if visible, otherwise 'Chapter 1'",
  "vocabulary": [
    { "target": "word in target language", "native": "English meaning", "example": "example sentence or empty string" }
  ],
  "phrases": [
    { "target": "phrase in target language", "native": "English meaning" }
  ],
  "grammar": [
    { "rule": "grammar rule description", "example": "example sentence" }
  ],
  "sentences": [
    { "target": "full sentence in target language", "native": "English translation" }
  ]
}

Rules:
- Extract EVERY visible vocabulary word, phrase, and sentence
- "language" = the language being taught (e.g. Spanish, French, Japanese)
- Return empty arrays [] when a section has no content
- Output ONLY the JSON object`,
        },
      ],
    }],
  });

  const text = json.content?.[0]?.text?.trim() ?? '';
  const match = text.match(/\{[\s\S]*\}/);
  if (!match) throw new Error('No JSON found in response');
  return JSON.parse(match[0]);
}

export async function explainAnswer(apiKey, language, question, correct, userAnswer, grammarRules) {
  const grammarContext = grammarRules?.length
    ? `\nRelevant grammar from the lesson:\n${grammarRules.map(g => `- ${g.rule}${g.example ? ` (e.g. "${g.example}")` : ''}`).join('\n')}`
    : '';

  const json = await callClaude(apiKey, {
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 256,
    messages: [{
      role: 'user',
      content: `You are a language tutor. The student is learning ${language}.
Exercise: "${question}"
The correct answer is: "${correct}"
The student answered: "${userAnswer}"
${grammarContext}

In 2–3 sentences max, explain why the correct answer is right and what grammar rule applies. Be encouraging. No markdown, no bullet points.`,
    }],
  });

  return json.content?.[0]?.text?.trim() ?? '';
}

export async function conversationTurn(apiKey, language, history, userMessage, vocab) {
  const vocabList = (vocab ?? []).slice(0, 20).map(v => v.target).join(', ');

  const messages = [
    ...history,
    { role: 'user', content: userMessage },
  ];

  const json = await callClaude(apiKey, {
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 300,
    system: `You are a friendly conversational partner helping a student practise ${language}. Rules:
- Keep replies to 1–3 sentences
- Use vocabulary from this list where natural: ${vocabList}
- If the student makes a grammar or vocabulary error, gently correct it inline (e.g. "Great! Just note: it's X not Y.") then continue
- Stay mostly in ${language} but add English translations in (parentheses) for tricky words
- Be warm, encouraging, and natural — not robotic`,
    messages,
  });

  return json.content?.[0]?.text?.trim() ?? '';
}

export async function conversationOpener(apiKey, language, vocab) {
  const vocabList = (vocab ?? []).slice(0, 10).map(v => `${v.target} (${v.native})`).join(', ');

  const json = await callClaude(apiKey, {
    model: 'claude-haiku-4-5-20251001',
    max_tokens: 120,
    messages: [{
      role: 'user',
      content: `Write a friendly opening line to start a ${language} conversation practice session. Use 1–2 of these vocabulary words naturally: ${vocabList}. Keep it to 1–2 sentences. Use ${language} with English in (parentheses) for key words.`,
    }],
  });

  return json.content?.[0]?.text?.trim() ?? `Let's practise your ${language}! How are you doing today?`;
}
