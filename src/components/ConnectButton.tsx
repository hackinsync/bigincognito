"use client";
import { useWallet } from "@context/WalletContext";
import { useStarknetkitConnectModal, StarknetkitConnector } from "starknetkit";

export default function ConnectButton() {
  const { account, connect, disconnect, connectors, isConnected } = useWallet();

  const { starknetkitConnectModal } = useStarknetkitConnectModal({
    connectors: connectors as StarknetkitConnector[],
  });

  async function connectWallet() {
    const { connector } = await starknetkitConnectModal();
    if (!connector) {
      return;
    }
    await connect({ connector });
  }

  return (
    <div className="relative inline-flex items-center justify-center gap-4 group">
      <a
        onClick={isConnected ? () => disconnect() : connectWallet}
        role="button"
        className="group relative inline-flex items-center justify-center text-base rounded-xl bg-blue-800 px-8 py-3 font-semibold text-white transition-all duration-200 hover:bg-gray-500 hover:shadow-lg hover:-translate-y-0.5 hover:shadow-gray-600/30"
        title="payment"
        href="#"
      >
        {isConnected ? "Disconnect Wallet" : "Connect Wallet"}
        <svg
          aria-hidden="true"
          viewBox="0 0 10 10"
          height={10}
          width={10}
          fill="none"
          className="mt-0.5 ml-2 -mr-1 stroke-white stroke-2"
        >
          <path d="M0 5h7" className="transition opacity-0 group-hover:opacity-100" />
          <path d="M1 1l4 4-4 4" className="transition group-hover:translate-x-[3px]" />
        </svg>
      </a>
      {account && (
        <div className="p-2 bg-gray-700 rounded-lg">
          Connected: {account.slice(0, 6)}...{account.slice(-4)}
        </div>
      )}
    </div>
  );
}
