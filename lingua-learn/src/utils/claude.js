export async function analyzeImage(apiKey, base64Data, mediaType) {
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
      'anthropic-dangerous-direct-browser-access': 'true',
    },
    body: JSON.stringify({
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
    }),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error?.message || `API error ${res.status}`);
  }

  const json = await res.json();
  const text = json.content?.[0]?.text?.trim() ?? '';
  const match = text.match(/\{[\s\S]*\}/);
  if (!match) throw new Error('No JSON found in response');
  return JSON.parse(match[0]);
}
