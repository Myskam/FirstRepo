const LANG_MAP = {
  german:     'de-DE',
  french:     'fr-FR',
  spanish:    'es-ES',
  italian:    'it-IT',
  portuguese: 'pt-PT',
  dutch:      'nl-NL',
  swedish:    'sv-SE',
  norwegian:  'nb-NO',
  danish:     'da-DK',
  finnish:    'fi-FI',
  russian:    'ru-RU',
  polish:     'pl-PL',
  czech:      'cs-CZ',
  japanese:   'ja-JP',
  chinese:    'zh-CN',
  mandarin:   'zh-CN',
  cantonese:  'zh-HK',
  korean:     'ko-KR',
  arabic:     'ar-SA',
  turkish:    'tr-TR',
  greek:      'el-GR',
  hindi:      'hi-IN',
  hebrew:     'he-IL',
  latin:      'la',
};

export function isTTSSupported() {
  return typeof window !== 'undefined' && 'speechSynthesis' in window;
}

export function langCode(languageName) {
  if (!languageName) return 'en-US';
  return LANG_MAP[languageName.toLowerCase().trim()] ?? 'en-US';
}

export function speak(text, languageName) {
  if (!isTTSSupported() || !text?.trim()) return;
  window.speechSynthesis.cancel();
  const u = new SpeechSynthesisUtterance(text.trim());
  u.lang = langCode(languageName);
  u.rate = 0.9;
  window.speechSynthesis.speak(u);
}
