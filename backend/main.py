import os
from dotenv import load_dotenv  # Import the load_dotenv function
from flask import Flask, jsonify, request, Response, stream_with_context
from flask_cors import CORS
from gemini_ai import get_therapist_response
from text_to_speech import convert_text_to_speech
from sentiment_analysis import analyze_sentiment

load_dotenv()

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

@app.route('/', methods=['GET'])
def home():
    return jsonify({'message': 'Hello World!'}), 200

@app.route('/chat', methods=['POST'])
def chat():
    data = request.get_json()
    user_message = data.get('message')
    voice_id = data.get('voice_id', 'EXAVITQu4vr4xnSDxMaL')  

    try:
        text_response = get_therapist_response(user_message, voice_id)
        return jsonify({'text': text_response}), 200
    except Exception as e: 
        print(f"Error processing message: {user_message}")
        print(f"Exception: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/analyze_sentiment', methods=['POST'])
def analyze_sentiment_endpoint():
    data = request.get_json()
    text = data.get('text')
    
    if not text:
        return jsonify({'error': 'No text provided'}), 400

    try:
        result = analyze_sentiment(text)
        return jsonify(result), 200
    except Exception as e:
        print(f"Error during sentiment analysis: {e}")
        return jsonify({
            'sentiment': 'neutral',
            'score': 0,
            'magnitude': 0
        }), 200

@app.route('/stream_audio', methods=['POST'])
def stream_audio():
    data = request.get_json()
    text = data.get('text')
    voice_id = data.get('voice_id', 'EXAVITQu4vr4xnSDxMaL')

    if not text:
        return jsonify({'error': 'No text provided'}), 400

    try:
        audio_stream = convert_text_to_speech(text, voice_id)
        return Response(
            stream_with_context(audio_stream),
            mimetype='audio/mpeg'
        )
    except Exception as e:
        error_message = str(e)
        if 'quota_exceeded' in error_message:
            return jsonify({
                'error': 'Text-to-speech quota exceeded. Please try again later.',
                'quota_exceeded': True
            }), 429  
        print(f"Error streaming audio: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)