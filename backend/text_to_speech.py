import os
import requests

ELEVENLABS_API_KEY = os.getenv('ELEVENLABS_API_KEY')
ELEVENLABS_TTS_URL = "https://api.elevenlabs.io/v1/text-to-speech"

def convert_text_to_speech(text, voice_id):
    headers = {
        'xi-api-key': ELEVENLABS_API_KEY,
        'Content-Type': 'application/json'
    }
    
    data = {
        'text': text,
        'model_id': 'eleven_monolingual_v1',
        'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.5
        }
    }
    
    try:
        response = requests.post(
            f"{ELEVENLABS_TTS_URL}/{voice_id}/stream",
            headers=headers,
            json=data,
            stream=True
        )
        
        if response.status_code == 200:
            return response.iter_content(chunk_size=1024)
        else:
            print(f"Request failed with status code {response.status_code}")
            print(f"Response content: {response.text}")
            raise Exception(f"Failed to convert text to speech: {response.text}")
    except requests.exceptions.RequestException as e:
        print(f"Request exception: {e}")
        raise Exception("Failed to connect to ElevenLabs API")

__all__ = ['convert_text_to_speech']