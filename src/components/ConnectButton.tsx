"use client";
import {
  Connector,
  useAccount,
  useConnect,
  useDisconnect,
} from "@starknet-react/core";
import { Button } from "./ui/button";
import { useStarknetkitConnectModal, StarknetkitConnector } from "starknetkit";

export default function ConnectButton() {
  const { disconnect } = useDisconnect();
  const { address } = useAccount();
  const { connect, connectors } = useConnect();
  const { starknetkitConnectModal } = useStarknetkitConnectModal({
    connectors: connectors as StarknetkitConnector[],
  });

  async function connectWallet() {
    const { connector } = await starknetkitConnectModal();
    if (!connector) {
      return;
    }
    await connect({ connector: connector as Connector });
  }

  if (!address) {
    return (
      <div className="relative inline-flex items-center justify-center gap-4 group">
        <div className="absolute w-[230px] h-[50px] duration-1000 opacity-60 transitiona-all bg-gradient-to-r from-indigo-500 via-pink-500 to-yellow-400 rounded-xl blur-lg filter group-hover:opacity-100 group-hover:duration-200" />
        <a
          onClick={connectWallet}
          role="button"
          className="group relative inline-flex items-center justify-center text-base rounded-xl bg-gray-900 px-8 py-3 font-semibold text-white transition-all duration-200 hover:bg-gray-800 hover:shadow-lg hover:-translate-y-0.5 hover:shadow-gray-600/30"
          title="payment"
          href="#"
        >
          Connect Wallet
          <svg
            aria-hidden="true"
            viewBox="0 0 10 10"
            height={10}
            width={10}
            fill="none"
            className="mt-0.5 ml-2 -mr-1 stroke-white stroke-2"
          >
            <path
              d="M0 5h7"
              className="transition opacity-0 group-hover:opacity-100"
            />
            <path
              d="M1 1l4 4-4 4"
              className="transition group-hover:translate-x-[3px]"
            />
          </svg>
        </a>
      </div>
    );
  }

  return (
    <>
      <div className="relative inline-flex items-center justify-center gap-4 group">
        <div className="absolute w-[230px] h-[50px] duration-1000 opacity-60 transitiona-all bg-gradient-to-r from-indigo-500 via-pink-500 to-yellow-400 rounded-xl blur-lg filter group-hover:opacity-100 group-hover:duration-200" />
        <a
          onClick={() => disconnect}
          role="button"
          className="group relative inline-flex items-center justify-center text-base rounded-xl bg-gray-900 px-8 py-3 font-semibold text-white transition-all duration-200 hover:bg-gray-800 hover:shadow-lg hover:-translate-y-0.5 hover:shadow-gray-600/30"
          title="payment"
        >
          Disconnect Wallet
          <svg
            aria-hidden="true"
            viewBox="0 0 10 10"
            height={10}
            width={10}
            fill="none"
            className="mt-0.5 ml-2 -mr-1 stroke-white stroke-2"
          >
            <path
              d="M0 5h7"
              className="transition opacity-0 group-hover:opacity-100"
            />
            <path
              d="M1 1l4 4-4 4"
              className="transition group-hover:translate-x-[3px]"
            />
          </svg>
        </a>
      </div>
      <div className="p-2 bg-gray-700 rounded-lg ">
        Connected: {address?.slice(0, 6)}...{address?.slice(-4)}
      </div>
    </>
  );
}
