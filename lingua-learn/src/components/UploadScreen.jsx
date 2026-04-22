import { useRef, useState } from 'react';
import styles from './UploadScreen.module.css';
import { toast } from './Toast';

export default function UploadScreen({ onAnalyze }) {
  const [files, setFiles] = useState([]);
  const [dragging, setDragging] = useState(false);
  const inputRef = useRef();

  function addFiles(newFiles) {
    const images = newFiles.filter(f => f.type.startsWith('image/'));
    images.forEach(file => {
      const reader = new FileReader();
      reader.onload = e =>
        setFiles(prev => [...prev, { name: file.name, type: file.type, data: e.target.result }]);
      reader.readAsDataURL(file);
    });
  }

  function remove(i) {
    setFiles(prev => prev.filter((_, idx) => idx !== i));
  }

  function handleDrop(e) {
    e.preventDefault();
    setDragging(false);
    addFiles(Array.from(e.dataTransfer.files));
  }

  function handleAnalyze() {
    if (files.length === 0) { toast('Upload at least one image'); return; }
    onAnalyze(files);
  }

  return (
    <div className={styles.screen}>
      <header className="app-header">
        <span className="logo">🦉 LinguaLearn</span>
      </header>

      <div className={styles.content}>
        <h2 className={styles.heading}>Upload Course Materials</h2>
        <p className={styles.sub}>
          Add photos of your textbook pages and workbook exercises.
          The more pages you add, the richer your course will be.
        </p>

        {/* Drop zone */}
        <div
          className={`${styles.dropZone} ${dragging ? styles.dragOver : ''}`}
          onClick={() => inputRef.current.click()}
          onDragOver={e => { e.preventDefault(); setDragging(true); }}
          onDragLeave={() => setDragging(false)}
          onDrop={handleDrop}
        >
          <span className={styles.dropIcon}>📚</span>
          <strong>Drop images here or click to browse</strong>
          <span className={styles.dropHint}>JPG · PNG · WebP — multiple files allowed</span>
          <input
            ref={inputRef}
            type="file"
            accept="image/*"
            multiple
            hidden
            onChange={e => { addFiles(Array.from(e.target.files)); e.target.value = ''; }}
          />
        </div>

        {/* Thumbnails */}
        {files.length > 0 && (
          <div className={styles.grid}>
            {files.map((f, i) => (
              <div key={i} className={styles.thumb}>
                <button className={styles.removeBtn} onClick={() => remove(i)}>✕</button>
                <img src={f.data} alt={f.name} />
                <p className={styles.fileName}>{f.name}</p>
              </div>
            ))}
          </div>
        )}

        {files.length > 0 && (
          <button className="btn btn-primary" onClick={handleAnalyze}>
            🔍 Analyse &amp; Build Course
          </button>
        )}
      </div>
    </div>
  );
}
