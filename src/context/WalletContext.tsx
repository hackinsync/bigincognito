import { createContext, useContext } from 'react'
import { useAccount, useConnect, useDisconnect, ConnectVariables, Connector } from '@starknet-react/core'

export interface WalletContextType {
  account: `0x${string}` | undefined;
  isConnected: boolean;
  connect: (args?: ConnectVariables) => void;
  disconnect: () => void;
  connectors: Connector[];
}

const WalletContext = createContext<WalletContextType | undefined>(undefined);

export const WalletProvider = ({ children, connectors }: { children: React.ReactNode; connectors: Connector[] }) => {
  const { address } = useAccount();
  const { connect } = useConnect();
  const { disconnect } = useDisconnect();

  const value: WalletContextType = {
    account: address,
    isConnected: !!address,
    connect,
    disconnect,
    connectors,
  };

  return <WalletContext.Provider value={value}>{children}</WalletContext.Provider>;
};

export const useWallet = () => {
  const context = useContext(WalletContext);
  if (!context) throw new Error("useWallet must be used within a WalletProvider");
  return context;
};