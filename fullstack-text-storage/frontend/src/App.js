import React, { useEffect, useState } from 'react';

// The Nginx container that serves this build proxies /api/* to the Flask backend.
const API_BASE = '/api';

function App() {
    const [text, setText] = useState('');
    const [entries, setEntries] = useState([]);
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const loadEntries = async () => {
        try {
            const res = await fetch(`${API_BASE}/list`);
            if (!res.ok) throw new Error(`List failed: ${res.status}`);
            const data = await res.json();
            setEntries(data.entries || []);
        } catch (err) {
            setError(err.message);
        }
    };

    useEffect(() => {
        loadEntries();
    }, []);

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!text.trim()) return;

        setLoading(true);
        setError('');
        try {
            const res = await fetch(`${API_BASE}/insert`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ text }),
            });
            if (!res.ok) throw new Error(`Insert failed: ${res.status}`);
            setText('');
            await loadEntries();
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={styles.container}>
            <h1>Text Storage App</h1>
            <p>React frontend &rarr; Flask API &rarr; PostgreSQL</p>

            <form onSubmit={handleSubmit} style={styles.form}>
                <input
                    type="text"
                    value={text}
                    onChange={(e) => setText(e.target.value)}
                    placeholder="Type something to store..."
                    style={styles.input}
                />
                <button type="submit" disabled={loading} style={styles.button}>
                    {loading ? 'Saving...' : 'Insert'}
                </button>
            </form>

            {error && <p style={styles.error}>Error: {error}</p>}

            <h2>Entries</h2>
            {entries.length === 0 ? (
                <p>No entries yet.</p>
            ) : (
                <ul style={styles.list}>
                    {entries.map((entry) => (
                        <li key={entry.id} style={styles.listItem}>
                            <span>{entry.text}</span>
                            <small style={styles.timestamp}>{new Date(entry.created_at).toLocaleString()}</small>
                        </li>
                    ))}
                </ul>
            )}
        </div>
    );
}

const styles = {
    container: {
        fontFamily: 'Arial, sans-serif',
        maxWidth: 600,
        margin: '40px auto',
        padding: '0 20px',
    },
    form: {
        display: 'flex',
        gap: 8,
        marginBottom: 20,
    },
    input: {
        flex: 1,
        padding: 8,
        fontSize: 16,
    },
    button: {
        padding: '8px 16px',
        fontSize: 16,
        cursor: 'pointer',
    },
    error: {
        color: 'red',
    },
    list: {
        listStyle: 'none',
        padding: 0,
    },
    listItem: {
        display: 'flex',
        justifyContent: 'space-between',
        borderBottom: '1px solid #ddd',
        padding: '8px 0',
    },
    timestamp: {
        color: '#666',
        marginLeft: 12,
        whiteSpace: 'nowrap',
    },
};

export default App;
