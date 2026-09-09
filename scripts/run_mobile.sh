#!/bin/sh
cd "/Users/mac/Downloads/files (1)/apps/mobile" && exec flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0 --dart-define=API_BASE_URL=http://localhost:8000/api/v1
