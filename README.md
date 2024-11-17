# SAVO AI 

### Prerequisites

1. **Flutter SDK**: Ensure you have Flutter installed on your machine. You can download it from [Flutter's official website](https://flutter.dev/docs/get-started/install).

2. **Dart SDK**: The Dart SDK is included with Flutter, so installing Flutter will also install Dart.

3. **Python**: Make sure you have Python installed (preferably version 3.6 or higher). You can download it from [Python's official website](https://www.python.org/downloads/).

4. **Pip**: Ensure you have `pip` installed for managing Python packages.

5. **Node.js**: If you are using any Node.js packages, ensure Node.js is installed. You can download it from [Node.js official website](https://nodejs.org/).

### Setting Up the Backend (Flask)

1. **Clone the Backend Repository**:
   ```
   git clone <this-repo-url>
   cd SAVO-AI

2. **Create a Virtual Environment** (optional but recommended):
   ```
   python -m venv venv
   source venv/bin/activate  
   # On Windows use `venv\Scripts\activate`

3. **Install Required Packages**:

   Create a `requirements.txt` file in your backend directory with the following content:
   ```
    Flask
    requests 
    python-dotenv
    flask_cors
    google-generativeai
    pydub
    ```
    
    Then run:
    ```pip install -r requirements.txt```

4. **Set Up Environment Variables**:

   Create a `.env` file in your backend directory and add any necessary environment variables. For example:

    ```   
    FLASK_ENV=development

5. **Run the Flask Application**:

   In the terminal, run:
   ```   python main.py```

   The Flask server should start, and you should see output indicating that it is running, typically at http://127.0.0.1:5000.

### Setting Up the Frontend (Flutter)
1. **Clone the Frontend Repository**:

2. **Get Flutter Packages**:

   Run the following command to get the necessary packages: ```   flutter pub get```

3. **Run the Flutter Application**:

   Make sure you have an emulator running or a physical device connected. Then run: ```   flutter run```

   This will build and launch the Flutter application on the selected device.
   
