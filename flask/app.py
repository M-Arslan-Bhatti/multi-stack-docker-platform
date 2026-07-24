from flask import Flask, jsonify
from datetime import datetime, timezone

app = Flask(__name__)


@app.route("/")
def index():
    return jsonify(
        message="Hello from the Flask container!",
        served_by="gunicorn",
        timestamp=datetime.now(timezone.utc).isoformat(),
    )


@app.route("/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    # Only used for local debugging; the container runs this via gunicorn.
    app.run(host="0.0.0.0", port=5000)
