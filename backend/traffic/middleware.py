from django.contrib.auth.models import User
from django.contrib.auth import login
import firebase_admin
from firebase_admin import auth, credentials
from .models import FirebaseUser
from django.utils import timezone
import os

class FirebaseAuthMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
        self._initialize_firebase()

    def _initialize_firebase(self):
        """Initialize Firebase Admin SDK if not already initialized"""
        if not len(firebase_admin._apps):
            cred = credentials.Certificate({
                "type": "service_account",
                "project_id": os.getenv('FIREBASE_PROJECT_ID'),
                "private_key_id": os.getenv('FIREBASE_PRIVATE_KEY_ID'),
                "private_key": os.getenv('FIREBASE_PRIVATE_KEY', '').replace('\\n', '\n'),
                "client_email": os.getenv('FIREBASE_CLIENT_EMAIL'),
                "client_id": os.getenv('FIREBASE_CLIENT_ID'),
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
                "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
                "client_x509_cert_url": os.getenv('FIREBASE_CLIENT_CERT_URL')
            })
            try:
                firebase_admin.initialize_app(cred)
            except ValueError as e:
                print(f"Firebase initialization error: {str(e)}")

    def __call__(self, request):
        return self.get_response(request) 