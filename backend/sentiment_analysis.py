import os
from dotenv import load_dotenv
from google.cloud import language_v1
from google.oauth2 import service_account

load_dotenv()

class SentimentAnalyzer:
    def __init__(self):
        self.client = None
        self._initialize_client()

    def _initialize_client(self):
        """Initialize the Google Cloud client using credentials from .env"""
        try:
            credentials_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
            if credentials_path and os.path.exists(credentials_path):
                credentials = service_account.Credentials.from_service_account_file(
                    credentials_path
                )
                self.client = language_v1.LanguageServiceClient(credentials=credentials)
            else:
                raise Exception("GOOGLE_APPLICATION_CREDENTIALS not found or invalid")
        except Exception as e:
            print(f"Error initializing Language client: {str(e)}")
            self.client = None

    def analyze_sentiment(self, text):
        """
        Analyze text sentiment using Google Cloud Natural Language API
        Returns detailed sentiment for Flutter app compatibility
        """
        if not self.client:
            return {'sentiment': 'neutral', 'score': 0, 'magnitude': 0}

        try:
            document = language_v1.Document(
                content=text,
                type_=language_v1.Document.Type.PLAIN_TEXT
            )
            sentiment = self.client.analyze_sentiment(
                request={'document': document}
            ).document_sentiment

            print(f"Sentiment score: {sentiment.score}, Magnitude: {sentiment.magnitude}")

            if sentiment.score > 0.5:
                sentiment_category = 'very positive'
            elif sentiment.score > 0.1:
                sentiment_category = 'positive'
            elif sentiment.score < -0.5:
                sentiment_category = 'very negative'
            elif sentiment.score < -0.1:
                sentiment_category = 'negative'
            else:
                sentiment_category = 'neutral'

            return {
                'sentiment': sentiment_category,
                'score': sentiment.score,
                'magnitude': sentiment.magnitude
            }
        except Exception as e:
            print(f"Error analyzing sentiment: {str(e)}")
            return {'sentiment': 'neutral', 'score': 0, 'magnitude': 0}

analyzer = SentimentAnalyzer()

def analyze_sentiment(text):
    """
    Public function to analyze sentiment, used by main.py
    """
    return analyzer.analyze_sentiment(text)