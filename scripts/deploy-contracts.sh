#!/bin/bash

# BigInc Contract Deployment Script for Katana Devnet
echo "🚀 Deploying BigInc contracts to Katana devnet"

# Configuration
RPC_URL="http://localhost:5050"
ACCOUNT_ADDRESS="0xf082b9d66cd3d9e4edc4d9c9450e7b154e88d490a22b214ee41c9d291df876"
PRIVATE_KEY="0x53b7668914511a29edc1247c0d2a9a44d0c9c78b4a2d8163c6439a4bde52a98"

# Check if Katana is running
if ! curl -s $RPC_URL > /dev/null; then
    echo "❌ Katana devnet not running. Please start it first with ./scripts/setup-devnet.sh"
    exit 1
fi

# Create deployment artifacts directory
mkdir -p deployment

echo "📦 Building contracts..."
cd contract_
scarb build

if [ $? -ne 0 ]; then
    echo "❌ Failed to build contracts"
    exit 1
fi

echo "✅ Contracts built successfully"

# Contract paths
MOCK_ERC20_SIERRA="target/dev/contract__MockERC20.contract_class.json"
BIGINC_SIERRA="target/dev/contract__BigIncGenesis.contract_class.json"

if [ ! -f "$MOCK_ERC20_SIERRA" ] || [ ! -f "$BIGINC_SIERRA" ]; then
    echo "❌ Contract artifacts not found. Please check the build output."
    exit 1
fi

echo "📝 Declaring MockERC20 contract..."
MOCK_ERC20_CLASS_HASH=$(starkli declare --account .starkli-wallets/deployer-account.json --rpc $RPC_URL --private-key $PRIVATE_KEY $MOCK_ERC20_SIERRA 2>&1 | grep "Class hash declared:" | awk '{print $4}' || starkli declare --account .starkli-wallets/deployer-account.json --rpc $RPC_URL --private-key $PRIVATE_KEY $MOCK_ERC20_SIERRA 2>&1 | grep "Not declaring class as it's already declared. Class hash:" | awk '{print $NF}')

if [ -z "$MOCK_ERC20_CLASS_HASH" ]; then
    echo "❌ Failed to declare MockERC20 contract"
    exit 1
fi

echo "✅ MockERC20 class hash: $MOCK_ERC20_CLASS_HASH"

echo "📝 Declaring BigIncGenesis contract..."
BIGINC_CLASS_HASH=$(starkli declare --account .starkli-wallets/deployer-account.json --rpc $RPC_URL --private-key $PRIVATE_KEY $BIGINC_SIERRA 2>&1 | grep "Class hash declared:" | awk '{print $4}' || starkli declare --account .starkli-wallets/deployer-account.json --rpc $RPC_URL --private-key $PRIVATE_KEY $BIGINC_SIERRA 2>&1 | grep "Not declaring class as it's already declared. Class hash:" | awk '{print $NF}')

if [ -z "$BIGINC_CLASS_HASH" ]; then
    echo "❌ Failed to declare BigIncGenesis contract"
    exit 1
fi

echo "✅ BigIncGenesis class hash: $BIGINC_CLASS_HASH"

# Deploy USDT (1M initial supply)
echo "🪙 Deploying Mock USDT..."
USDT_INITIAL_SUPPLY="1000000000000" # 1M tokens with 18 decimals
USDT_ADDRESS=$(starkli deploy --account .starkli-wallets/deployer-account.json --rpc $RPC_URL --private-key $PRIVATE_KEY $MOCK_ERC20_CLASS_HASH \
    u256:$USDT_INITIAL_SUPPLY \
    $ACCOUNT_ADDRESS 2>&1 | grep "Contract deployed:" | awk '{print $3}')

if [ -z "$USDT_ADDRESS" ]; then
    echo "❌ USDT deployment failed"
    exit 1
fi

echo "✅ Mock USDT deployed at: $USDT_ADDRESS"

# Deploy USDC (1M initial supply)
echo "🪙 Deploying Mock USDC..."
USDC_INITIAL_SUPPLY="1000000000000" # 1M tokens with 18 decimals
USDC_ADDRESS=$(starkli deploy --account .starkli-wallets/deployer-account.json --rpc $RPC_URL --private-key $PRIVATE_KEY $MOCK_ERC20_CLASS_HASH \
    u256:$USDC_INITIAL_SUPPLY \
    $ACCOUNT_ADDRESS 2>&1 | grep "Contract deployed:" | awk '{print $3}')

if [ -z "$USDC_ADDRESS" ]; then
    echo "❌ USDC deployment failed"
    exit 1
fi

echo "✅ Mock USDC deployed at: $USDC_ADDRESS"

# Deploy BigIncGenesis
echo "🏢 Deploying BigIncGenesis contract..."
BIGINC_ADDRESS=$(starkli deploy --account .starkli-wallets/deployer-account.json --rpc $RPC_URL --private-key $PRIVATE_KEY $BIGINC_CLASS_HASH \
    $USDT_ADDRESS \
    $USDC_ADDRESS \
    $ACCOUNT_ADDRESS 2>&1 | grep "Contract deployed:" | awk '{print $3}')

if [ -z "$BIGINC_ADDRESS" ]; then
    echo "❌ BigIncGenesis deployment failed"
    exit 1
fi

echo "✅ BigIncGenesis deployed at: $BIGINC_ADDRESS"

# Create deployment config file
cd ..
cat > deployment/contracts.json << EOF
{
  "network": "katana_local",
  "rpc_url": "$RPC_URL",
  "contracts": {
    "BigIncGenesis": {
      "address": "$BIGINC_ADDRESS",
      "class_hash": "$BIGINC_CLASS_HASH"
    },
    "MockUSDT": {
      "address": "$USDT_ADDRESS",
      "class_hash": "$MOCK_ERC20_CLASS_HASH",
      "symbol": "USDT",
      "decimals": 6
    },
    "MockUSDC": {
      "address": "$USDC_ADDRESS", 
      "class_hash": "$MOCK_ERC20_CLASS_HASH",
      "symbol": "USDC",
      "decimals": 6
    }
  },
  "test_accounts": [
    {
      "address": "$ACCOUNT_ADDRESS",
      "private_key": "$PRIVATE_KEY"
    },
    {
      "address": "0x175c0552eda5d4b38250a5388d4d11b1a018df0c3081c7fe2ee3478ada43d78",
      "private_key": "0x7dd2923d111acc143d8e1f1b95850bce0479e19bdd4dc4c83a33da7efeb0fd7"
    }
  ]
}
EOF

echo ""
echo "🎉 Deployment completed successfully!"
echo "📄 Contract addresses saved to: deployment/contracts.json"
echo ""
echo "📋 Summary:"
echo "  • MockUSDT: $USDT_ADDRESS"
echo "  • MockUSDC: $USDC_ADDRESS"
echo "  • BigIncGenesis: $BIGINC_ADDRESS"
echo ""
echo "� Updating frontend configuration..."
cd ..
node scripts/update-addresses.js
echo ""
echo "�🔗 You can now use these addresses in your frontend configuration"
