from flask import Flask, jsonify, request
# from flask_cors import CORS

app = Flask(__name__)
# CORS(app, resources={r"/*": {"origins": "http://localhost:3000", "methods": ["GET", "POST", "OPTIONS"]}})

@app.route('/', methods=['GET'])
def home():
    return jsonify({'message': 'Hello World!'}), 200

if __name__ == '__main__':
    app.run(debug=True)