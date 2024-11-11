from flask import Flask, jsonify, request
from flask_cors import CORS
from gemini_ai import get_therapist_response  # Import the function from the new file

app = Flask(__name__)
# CORS(app, resources={r"/*": {"origins": "http://localhost:3000", "methods": ["GET", "POST", "OPTIONS"]}})
CORS(app, resources={r"/*": {"origins": "*"}})

@app.route('/', methods=['GET'])
def home():
    return jsonify({'message': 'Hello World!'}), 200

@app.route('/chat', methods=['POST'])
def chat():
    data = request.get_json()
    user_message = data.get('message')

    try:
        response = get_therapist_response(user_message)  # Call the function to get the response
        return jsonify({'response': response}), 200
    except Exception as e:
        # Log the error details
        print(f"Error processing message: {user_message}")
        print(f"Exception: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)