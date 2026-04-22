import styles from './AnalyzingScreen.module.css';

export default function AnalyzingScreen({ status }) {
  return (
    <div className={styles.screen}>
      <div className={styles.card}>
        <div className="spinner" />
        <h2 className={styles.title}>Building Your Course</h2>
        <p className={styles.status}>{status}</p>
        <p className={styles.hint}>
          This may take a moment depending on the number of images.
        </p>
      </div>
    </div>
  );
}
