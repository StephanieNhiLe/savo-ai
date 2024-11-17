import os
from pathlib import Path
from dotenv import load_dotenv
from google.cloud import language_v1
from google.oauth2 import service_account
import json

class SentimentAnalyzer:
    def __init__(self):
        self.client = None
        self._initialize_client()

    def _initialize_client(self):
        try:
            credentials_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
            
            if credentials_path and Path(credentials_path).exists():
                credentials = service_account.Credentials.from_service_account_file(credentials_path)
            
            
            self.client = language_v1.LanguageServiceClient(credentials=credentials)
            print("Successfully initialized Language client")
            
        except Exception as e:
            print(f"Error initializing Language client: {str(e)}")
            self.client = None

    def analyze_sentiment(self, text):
        if not self.client:
            print("Warning: Client not initialized, returning neutral sentiment")
            return {'sentiment': 'neutral', 'score': 0, 'magnitude': 0}

        try:
            document = language_v1.Document(
                content=text,
                type_=language_v1.Document.Type.PLAIN_TEXT
            )
            sentiment = self.client.analyze_sentiment(
                request={'document': document}
            ).document_sentiment

            sentiment_category = self._map_sentiment_score(sentiment.score)

            return {
                'sentiment': sentiment_category,
                'score': sentiment.score,
                'magnitude': sentiment.magnitude
            }
        except Exception as e:
            print(f"Error analyzing sentiment: {str(e)}")
            return {'sentiment': 'neutral', 'score': 0, 'magnitude': 0}

    def _map_sentiment_score(self, score):
        if score > 0.5:
            return 'very positive'
        elif score > 0.1:
            return 'positive'
        elif score < -0.5:
            return 'very negative'
        elif score < -0.1:
            return 'negative'
        return 'neutral'

analyzer = SentimentAnalyzer()

def analyze_sentiment(text):
    return analyzer.analyze_sentiment(text)