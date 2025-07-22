#!/bin/bash

echo "🚀 BigInc Full Development Environment Setup"
echo "This script will:"
echo "1. Start Katana devnet"
echo "2. Build and deploy contracts"
echo "3. Update frontend configuration" 
echo "4. Start the Next.js development server"
echo ""

# Check dependencies
missing_deps=false

if ! command -v katana &> /dev/null; then
    echo "❌ Katana not found. Please install with: curl -L https://install.dojo.sh | bash && dojoup"
    missing_deps=true
fi

if ! command -v starkli &> /dev/null; then
    echo "❌ Starkli not found. Please install with: curl https://get.starkli.sh | sh && starkliup"
    missing_deps=true
fi

if ! command -v scarb &> /dev/null; then
    echo "❌ Scarb not found. Please install with: curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh"
    missing_deps=true
fi

if [ "$missing_deps" = true ]; then
    echo ""
    echo "❌ Missing dependencies. Please install them and run this script again."
    exit 1
fi

# Start Katana devnet
echo "🏃 Starting Katana devnet..."
./scripts/setup-devnet.sh

# Wait for devnet to be ready
sleep 10

# Deploy contracts
echo "📦 Deploying contracts..."
./scripts/deploy-contracts.sh

if [ $? -ne 0 ]; then
    echo "❌ Contract deployment failed"
    exit 1
fi

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
npm install

# Start development server
echo "🌐 Starting Next.js development server..."
echo "Frontend will be available at: http://localhost:3000"
echo "Katana devnet RPC: http://localhost:5050"
echo ""
echo "To stop everything:"
echo "  - Ctrl+C to stop Next.js"
echo "  - ./scripts/stop-devnet.sh to stop Katana"
echo ""

NEXT_PUBLIC_USE_STARKNET=true npm run dev
