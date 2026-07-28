import os
import time

import psycopg2
import psycopg2.extras
from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

DB_HOST = os.environ.get("DB_HOST", "db")
DB_PORT = os.environ.get("DB_PORT", "5432")
DB_NAME = os.environ.get("POSTGRES_DB", "textstorage")
DB_USER = os.environ.get("POSTGRES_USER", "postgres")
DB_PASSWORD = os.environ.get("POSTGRES_PASSWORD", "postgres")


def get_connection(retries=5, delay=2):
    """Connect to Postgres, retrying briefly in case the DB is still starting."""
    last_error = None
    for attempt in range(retries):
        try:
            return psycopg2.connect(
                host=DB_HOST,
                port=DB_PORT,
                dbname=DB_NAME,
                user=DB_USER,
                password=DB_PASSWORD,
            )
        except psycopg2.OperationalError as exc:
            last_error = exc
            time.sleep(delay)
    raise last_error


def ensure_schema():
    """Create the entries table if it doesn't exist yet (fresh RDS/Postgres instance)."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS entries (
                    id SERIAL PRIMARY KEY,
                    content VARCHAR(1000) NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
            conn.commit()
    finally:
        conn.close()


ensure_schema()


@app.route("/health")
def health():
    return jsonify(status="ok")


@app.route("/insert", methods=["POST"])
def insert_entry():
    data = request.get_json(silent=True) or {}
    text = (data.get("text") or "").strip()

    if not text:
        return jsonify(error="Field 'text' is required"), 400

    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO entries (content) VALUES (%s) RETURNING id, content, created_at",
                (text,),
            )
            row = cur.fetchone()
            conn.commit()
    finally:
        conn.close()

    return jsonify(id=row[0], text=row[1], created_at=row[2].isoformat()), 201


@app.route("/list", methods=["GET"])
def list_entries():
    conn = get_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT id, content, created_at FROM entries ORDER BY id DESC")
            rows = cur.fetchall()
    finally:
        conn.close()

    entries = [
        {"id": r["id"], "text": r["content"], "created_at": r["created_at"].isoformat()}
        for r in rows
    ]
    return jsonify(entries=entries), 200


if __name__ == "__main__":
    # Only used for local debugging; the container runs this via gunicorn.
    app.run(host="0.0.0.0", port=5000)
