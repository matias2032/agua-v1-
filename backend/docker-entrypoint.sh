#!/bin/sh
set -e

if [ -n "$FIREBASE_SERVICE_ACCOUNT_B64" ]; then
  echo "$FIREBASE_SERVICE_ACCOUNT_B64" | base64 -d \
    > /app/firebase-service-account.json
  echo "✅ firebase-service-account.json reconstituído"
fi

exec java \
  -Dspring.profiles.active=prod \
  -Djava.security.egd=file:/dev/./urandom \
  -Dloader.path=/app \
  -jar /app/app.jar