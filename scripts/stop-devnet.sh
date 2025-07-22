#!/bin/bash

echo "🛑 Stopping Katana devnet..."

if [ -f .katana.pid ]; then
    KATANA_PID=$(cat .katana.pid)
    kill $KATANA_PID 2>/dev/null && echo "✅ Katana devnet stopped (PID: $KATANA_PID)" || echo "⚠️  Process not found"
    rm .katana.pid
else
    echo "⚠️  No .katana.pid file found. Attempting to kill any katana processes..."
    pkill katana && echo "✅ Katana processes killed" || echo "❌ No katana processes found"
fi
