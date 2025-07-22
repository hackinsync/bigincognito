/* eslint-disable @next/next/no-page-custom-font */
import { StarknetAppProvider } from "@context/StarknetKitProvider";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Big Inc's deWhitepaper: Empowering deGens, deFans, & deArtists",
  description: "In this decentralized music revolution, we hope to flip the traditional record label model on its head—putting control in the hands of deGens, deFans, and deInvestors. Through smart contracts, you’re not just backing an artist; you’re buying a tangible stake in their success, and most importantly letting the artist define their record terms in their favor through a smart contract. Welcome to the new way to fund emerging talent—on-chain and fully transparent.",
  keywords: "web3 music, record label onchain, deWhitepaper, decentralized music, blockchain, smart contracts, deGens, deFans, artists, revenue sharing",
  authors: [{ name: "Jedshock", url: "https://www.jedshock.com" }],
  openGraph: {
    images: [{ url: "https://bigincognito.vercel.app/assets/img/big_inc_alt.jpg" }],
    description: "In this decentralized music revolution, we hope to flip the traditional record label model on its head—putting control in the hands of deGens, deFans, and deInvestors. Through smart contracts, you’re not just backing an artist; you’re buying a tangible stake in their success, and most importantly letting the artist define their record terms in their favor through a smart contract. Welcome to the new way to fund emerging talent—on-chain and fully transparent.",
    title: "Big Inc's deWhitepaper: Empowering deGens, deFans, & deArtists",
    url: "https://www.bigincognito.com/dewhitepaper"
  }
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <>
      <StarknetAppProvider>
        {children}
      </StarknetAppProvider>
    </>
  );
}
