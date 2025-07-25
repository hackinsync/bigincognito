#!/bin/bash

# BigInc Starknet Devnet Setup Script
echo "🚀 Setting up BigInc Starknet Local Development Environment"

# Check if Katana is installed
if ! command -v katana &> /dev/null; then
    echo "❌ Katana not found. Please install Katana first:"
    echo "curl -L https://install.dojo.sh | bash"
    echo "dojoup"
    exit 1
fi

# Check if Starkli is installed
if ! command -v starkli &> /dev/null; then
    echo "❌ Starkli not found. Please install Starkli first:"
    echo "curl https://get.starkli.sh | sh"
    echo "starkliup"
    exit 1
fi

# Start Katana devnet in background
echo "🏃 Starting Katana devnet..."
katana --dev --dev.accounts 10 --dev.seed 42 --http.addr 0.0.0.0 --http.port 5050 &
KATANA_PID=$!

echo "⏳ Waiting for Katana to start..."
sleep 5

# Save Katana PID for cleanup
echo $KATANA_PID > .katana.pid
echo "✅ Katana devnet started with PID: $KATANA_PID"
echo "📊 Devnet running at: http://localhost:5050"

# Display prefunded accounts
echo ""
echo "💰 Prefunded test accounts:"
echo "Account #0: 0xf082b9d66cd3d9e4edc4d9c9450e7b154e88d490a22b214ee41c9d291df876"
echo "Private Key: 0x53b7668914511a29edc1247c0d2a9a44d0c9c78b4a2d8163c6439a4bde52a98"
echo ""
echo "Account #1: 0x175c0552eda5d4b38250a5388d4d11b1a018df0c3081c7fe2ee3478ada43d78"
echo "Private Key: 0x7dd2923d111acc143d8e1f1b95850bce0479e19bdd4dc4c83a33da7efeb0fd7"
echo ""

echo "🔗 RPC URL: http://localhost:5050"
echo "⛽ Chain ID: KATANA (0x4b4154414e41)"
echo ""
echo "To stop the devnet, run: kill $KATANA_PID"
echo "Or use: ./scripts/stop-devnet.sh"
