from flask import Flask
from flask import Flask, render_template, request, jsonify
app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello, World!'

@app.route('/health')
def health_check():
    # Liveness probe: simple check to confirm the app is running
    return jsonify(status="healthy"), 200

@app.route('/ready')
def readiness_check():
    # Readiness probe: check if the app is ready to serve traffic (e.g., DB connection)
    # You can extend this to include more comprehensive checks
    return jsonify(status="ready"), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0')
