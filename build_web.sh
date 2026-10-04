#!/usr/bin/env bash
set -euo pipefail

export PATH="$PATH:$HOME/flutter/bin"

if [ ! -d "$HOME/flutter" ]; then
  git clone --depth 1 -b 3.38.9 https://github.com/flutter/flutter.git "$HOME/flutter"
fi

flutter config --no-analytics || true
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://api.tvrfy.co.ke
