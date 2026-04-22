import { useState, useEffect, useCallback } from 'react';

let _show = null;

export function useToast() {
  const [msg, setMsg] = useState('');
  const [visible, setVisible] = useState(false);

  const show = useCallback((text) => {
    setMsg(text);
    setVisible(true);
  }, []);

  useEffect(() => { _show = show; }, [show]);

  useEffect(() => {
    if (!visible) return;
    const t = setTimeout(() => setVisible(false), 2800);
    return () => clearTimeout(t);
  }, [visible, msg]);

  return { msg, visible };
}

export function toast(text) {
  _show?.(text);
}

export default function Toast({ msg, visible }) {
  return <div className={`toast ${visible ? 'visible' : ''}`}>{msg}</div>;
}
