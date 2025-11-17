# Traffix-A-Real-time-Traffic-Detection-System
Kathmandu faces chronic traffic congestion due to increasing urbanization and limited infrastructure. Traffix aims to solve this problem using GPS data from commuter’s mobile devices to deliver live traffic updates, alternate route suggestions, and various traffic insights for future.

## Project Structure
- `lib/` - Flutter frontend application code
- `traffix_backend/` - Django backend server
- `assets/` - Static assets including images and PDFs

## Prerequisites
- Flutter SDK (>=3.0.0)
- Python (>=3.8)
- Node.js (for development tools)
- Git

## Backend Setup

1. Navigate to the backend directory:
```bash
cd traffix_backend
```

2. Create and activate a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows use: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Set up environment variables:
```bash
cp env.example .env
# Edit .env with your configuration
```

5. Run migrations:
```bash
python manage.py migrate
```

6. Start the development server:
```bash
python manage.py runserver
```

## Frontend Setup

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Ensure you have all required dependencies:
- Google Maps integration
- Location services
- OpenStreetMap integration

3. Run the app:
```bash
flutter run
```

## Key Features
- Real-time traffic monitoring
- GPS-based location tracking
- Alternative route suggestions
- Traffic pattern analysis (PDF)
- User authentication with Google and Facebook
- Interactive map interface using OpenStreetMap

### Frontend (Flutter)
- Uses Provider for state management
- Implements clean architecture with services, models, and providers
- Integrates with OpenStreetMap for mapping functionality
- Handles real-time location updates and route calculations

### Backend (Django)
- RESTful API architecture
- Real-time traffic data processing
- Route optimization algorithms

## Contributing
1. Fork the repository
2. Create a new branch for your feature
3. Submit a pull request with a clear description of your changes
