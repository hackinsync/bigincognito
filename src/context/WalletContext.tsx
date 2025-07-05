"use client";
import {
  Connector,
  ConnectVariables,
  publicProvider,
  StarknetConfig,
  voyager,
} from "@starknet-react/core";
import { InjectedConnector } from "@starknet-react/core";
import { createContext, useContext, useMemo } from "react";
import { mainnet, sepolia } from "@starknet-react/chains";

export interface WalletContextType {
  account: `0x${string}` | undefined;
  isConnected: Boolean;
  connect: (args?: ConnectVariables) => void;
  disconnect: () => void;
  connectors: ConnectVariables["connector"][];
}

const WalletContext = createContext<WalletContextType | undefined>(undefined);

export const WalletProvider = ({ children }: { children: React.ReactNode }) => {
  const connectors = [
    new InjectedConnector({ options: { id: 'braavos', name: 'Braavos' } }),
    new InjectedConnector({ options: { id: 'argentX', name: 'Ready Wallet (formerly Argent)' } }),
    new InjectedConnector({ options: { id: 'metamask', name: 'MetaMask' } }),
    new InjectedConnector({ options: { id: 'okxwallet', name: 'OKX' } }),
  ];

  return (
    <StarknetConfig
      chains={[mainnet, sepolia]}
      provider={publicProvider()}
      connectors={connectors as Connector[]}
      explorer={voyager}
    >
      {children}
    </StarknetConfig>
  );
};

export const useWallet = () => {
  const context = useContext(WalletContext);
  if (!context)
    throw new Error("useWallet must be used within a WalletProvider");
  return context;
};
