import { useState, useEffect, useRef } from 'react';
import styles from './ConversationScreen.module.css';
import { conversationTurn, conversationOpener } from '../utils/claude';
import { toast } from './Toast';

export default function ConversationScreen({ unit, language, apiKey, onExit }) {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(true);
  const endRef = useRef();
  const inputRef = useRef();

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, loading]);

  useEffect(() => {
    conversationOpener(apiKey, language, unit.vocabulary ?? [])
      .then(text => {
        setMessages([{ role: 'assistant', content: text }]);
        setLoading(false);
        setTimeout(() => inputRef.current?.focus(), 100);
      })
      .catch(err => {
        toast(err.message);
        onExit();
      });
  }, []);

  async function send() {
    const text = input.trim();
    if (!text || loading) return;
    setInput('');

    const userMsg = { role: 'user', content: text };
    const nextHistory = [...messages, userMsg];
    setMessages(nextHistory);
    setLoading(true);

    try {
      const reply = await conversationTurn(
        apiKey,
        language,
        messages,
        text,
        unit.vocabulary ?? [],
      );
      setMessages([...nextHistory, { role: 'assistant', content: reply }]);
    } catch (err) {
      toast(err.message);
    } finally {
      setLoading(false);
      setTimeout(() => inputRef.current?.focus(), 80);
    }
  }

  function onKeyDown(e) {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); }
  }

  return (
    <div className={styles.screen}>
      <header className="app-header">
        <button className="btn-ghost btn" onClick={onExit}>←</button>
        <span style={{ fontWeight: 800 }}>Conversation · {language}</span>
        <span />
      </header>

      <div className={styles.messages}>
        {messages.map((m, i) => (
          <div
            key={i}
            className={`${styles.bubble} ${m.role === 'user' ? styles.bubbleUser : styles.bubbleAssistant}`}
          >
            {m.content}
          </div>
        ))}
        {loading && <div className={styles.typing}>…</div>}
        <div ref={endRef} />
      </div>

      <div className={styles.inputRow}>
        <input
          ref={inputRef}
          className={styles.textInput}
          placeholder={`Reply in ${language}…`}
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyDown={onKeyDown}
          disabled={loading}
          autoComplete="off"
          autoCorrect="off"
          spellCheck={false}
        />
        <button
          className={styles.sendBtn}
          onClick={send}
          disabled={!input.trim() || loading}
          aria-label="Send"
        >
          ➤
        </button>
      </div>
    </div>
  );
}
