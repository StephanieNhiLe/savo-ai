import os
import requests

def analyze_sentiment(input_data, input_type='text'):
    """
    Analyze sentiment from either text or audio input
    
    Args:
        input_data: Either text string or audio file path
        input_type: 'text' or 'audio'
    """
    hume_api_key = os.getenv('HUMEAI_API_KEY')
    
    if input_type == 'audio':
        with open(input_data, 'rb') as audio_file:
            audio_data = audio_file.read()
            
        data = audio_data
        content_type = 'application/octet-stream'
        
    else:  # text
        data = input_data.encode('utf-8')
        content_type = 'text/plain'

    response = requests.post(
        'https://api.hume.ai/sentiment', # double check this hume api endpoint
        headers={
            'Content-Type': content_type,
            'Authorization': f'Bearer {hume_api_key}',
        },
        data=data
    )

    if response.status_code == 200:
        return response.json()
    else:
        raise Exception(f"Failed to perform sentiment analysis: {response.status_code}")
