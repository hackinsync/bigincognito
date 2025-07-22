# BigInc Starknet Integration Guide

This repository now supports both Ethereum/Polygon (via WAGMI) and Starknet implementations of the BigIncGenesis smart contract.

## Quick Start - Starknet Local Development

### Prerequisites

1. **Install Dojo (includes Katana)**:
   ```bash
   curl -L https://install.dojo.sh | bash
   dojoup
   ```

2. **Install Starkli**:
   ```bash
   curl https://get.starkli.sh | sh
   starkliup
   ```

3. **Install Scarb**:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
   ```

### Development Setup

**Option 1: Full Automated Setup**
```bash
npm run setup:full
```
This will:
- Start Katana devnet
- Deploy contracts (BigIncGenesis, MockUSDT, MockUSDC)  
- Update frontend configuration
- Start Next.js dev server with Starknet enabled

**Option 2: Manual Step-by-Step**

1. **Start Katana devnet**:
   ```bash
   npm run setup:devnet
   ```

2. **Deploy contracts**:
   ```bash
   npm run deploy:contracts
   ```

3. **Start frontend with Starknet**:
   ```bash
   npm run dev:starknet
   ```

### Contract Addresses

After deployment, contract addresses are automatically updated in:
- `src/lib/starknet/config.ts`
- `deployment/contracts.json`

### Test Accounts

The devnet provides prefunded test accounts:

**Account #0:**
- Address: `0xf082b9d66cd3d9e4edc4d9c9450e7b154e88d490a22b214ee41c9d291df876`
- Private Key: `0x53b7668914511a29edc1247c0d2a9a44d0c9c78b4a2d8163c6439a4bde52a98`

**Account #1:**
- Address: `0x175c0552eda5d4b38250a5388d4d11b1a018df0c3081c7fe2ee3478ada43d78`  
- Private Key: `0x7dd2923d111acc143d8e1f1b95850bce0479e19bdd4dc4c83a33da7efeb0fd7`

### Using the dApp

1. Visit `http://localhost:3000/dewhitepaper`
2. Connect your Starknet wallet (Braavos, ArgentX, etc.)
3. The page will automatically detect if Starknet contracts are deployed
4. Use MockUSDT/USDC to buy shares
5. View live share distribution in the pie chart

### Architecture

#### Dual Implementation Support
The app supports both Ethereum and Starknet:
- **Ethereum**: Uses WAGMI + WalletConnect
- **Starknet**: Uses starknet-react + StarknetKit
- Automatically switches based on `NEXT_PUBLIC_USE_STARKNET` or contract availability

#### Key Components

**Starknet-Specific:**
- `ShareChartStarknet.tsx` - Live on-chain share visualization
- `ShareModalStarknet.tsx` - Buy shares using Mock USDT/USDC
- `src/lib/starknet/hooks.ts` - Contract interaction hooks
- `src/lib/starknet/config.ts` - Chain and contract configuration

**Smart Contracts:**
- `BigIncGenesis.cairo` - Main share management contract
- `MockERC20.cairo` - Mock USDT/USDC for testing

### Stopping the Environment

```bash
# Stop Next.js dev server
Ctrl+C

# Stop Katana devnet  
npm run stop:devnet
```

### Contract Functions

The BigIncGenesis contract supports:
- `mint_share()` - Buy shares with USDT/USDC
- `get_shares(address)` - Get user's share balance
- `get_shareholders()` - Get all shareholders
- `get_available_shares()` - Get remaining shares for sale
- `transfer_share()` - Transfer shares between users
- `donate()` - Donate tokens to the contract

### Environment Variables

- `NEXT_PUBLIC_USE_STARKNET=true` - Enables Starknet mode in frontend

## Troubleshooting

**Contract not found errors:**
- Ensure Katana is running on port 5050
- Redeploy contracts with `npm run deploy:contracts`

**Wallet connection issues:**
- Use browser wallets compatible with Starknet devnet
- Check that wallet is connected to the correct network

**Transaction failures:**
- Ensure you have sufficient mock token balance
- Approve tokens before minting shares

**Build errors:**
- Run `scarb build` in the `contract_/` directory
- Check that all dependencies are installed
