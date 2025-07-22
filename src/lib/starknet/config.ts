import { sepolia, mainnet } from '@starknet-react/chains'

// Local Katana devnet configuration
export const katanaLocal = {
    id: BigInt('0x4b4154414e41'), // 'KATANA' in hex - unique chain ID for Katana
    name: 'Katana Local',
    network: 'katana-local',
    nativeCurrency: {
        address: '0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7',
        name: 'Ether',
        symbol: 'ETH',
        decimals: 18,
    },
    rpcUrls: {
        default: {
            http: ['http://localhost:5050'],
        },
        public: {
            http: ['http://localhost:5050'],
        },
    },
    testnet: true,
}

export const starknetChains = [katanaLocal, sepolia, mainnet]

// Contract addresses - deployed on local Katana devnet
export const contractAddresses = {
    BigIncGenesis: '0x0524d0778e535c840b4aeea9958d30c182d0064cdd584ea7c0f9e0cf897b36bc',
    MockUSDT: '0x04d2092d368213a814e384facca6a82a47f753f9c95bd98859374f47bbfb9398',
    MockUSDC: '0x06e37c9a6de30781abc6973101e7a7c5e343ccb906a70223a24407a56cde99ef',
}

// Test account for development
export const testAccount = {
    address: '0xf082b9d66cd3d9e4edc4d9c9450e7b154e88d490a22b214ee41c9d291df876',
    privateKey: '0x53b7668914511a29edc1247c0d2a9a44d0c9c78b4a2d8163c6439a4bde52a98',
}

export const SHARE_PRECISION = BigInt(100000000) // 8 decimal places for share calculations
