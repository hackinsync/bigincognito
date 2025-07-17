'use client'
import { publicProvider, StarknetConfig, voyager } from "@starknet-react/core"
import { mainnet, sepolia } from "@starknet-react/chains"
import { QueryClient, QueryClientProvider } from "@tanstack/react-query"
import { ReactNode, useMemo } from 'react'
import { InjectedConnector } from "@starknet-react/core"
import { WalletProvider } from "./WalletContext"

const queryClient = new QueryClient();

export function StarknetAppProvider({ children }: { children: ReactNode }) {
    const connectors = useMemo(
        () => [
            new InjectedConnector({ options: { id: 'braavos', name: 'Bravoos' } }),
            new InjectedConnector({ options: { id: 'argentX', name: 'Ready Wallet (formerly Argent)' } }),
            new InjectedConnector({ options: { id: 'metamask', name: 'MetaMask' } }),
            new InjectedConnector({ options: { id: 'okxwallet', name: 'OKX' } }),
        ],
        []
    );

    return (
        <StarknetConfig chains={[mainnet, sepolia]} provider={publicProvider()} connectors={connectors} explorer={voyager}>
            <QueryClientProvider client={queryClient}>
                <WalletProvider connectors={connectors}>
                    {children}
                </WalletProvider>
            </QueryClientProvider>
        </StarknetConfig>
    )
}