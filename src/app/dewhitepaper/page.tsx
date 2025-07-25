/* eslint-disable jsx-a11y/alt-text */
'use client';
/* eslint-disable react-hooks/exhaustive-deps */
/* eslint-disable react/no-unescaped-entities */
/* eslint-disable @next/next/no-img-element */
import { readContracts, http, createConfig, writeContract } from '@wagmi/core'
import { polygon } from 'wagmi/chains'
import { ShareChart } from "@components/ShareChart";
import { ShareModal } from "@components/ShareModal";
import { Card, CardHeader, CardTitle, CardContent } from "@components/ui/card";
import { useAppKitAccount, useDisconnect } from "@reown/appkit/react";
import { useEffect, useState } from "react";
import { useReadContracts } from 'wagmi'
import { abi } from '../../abi/BigIncGenesis.json';
import { contractAddress } from "@lib/wallet/config";
import { formatUnits, parseUnits } from "viem";
import { Button } from '@components/ui/button';
import { toast } from '@components/ui/use-toast';
import { useAppKit } from '@reown/appkit/react'
import { WalletProvider } from '@context/WalletContext';
import ConnectButton from '@components/ConnectButton';
import Link from 'next/link';

const config = createConfig({
  chains: [polygon],
  transports: {
    [polygon.id]: http()
  }
});


export default function Page() {
  const { open, close } = useAppKit()
  const { disconnect } = useDisconnect()
  const totalShare = 100
  const { address, isConnected } = useAppKitAccount();
  const [yourShare, setYourShare] = useState(0)
  const [availableShare, setAvailableShare] = useState(0)
  const [soldShare, setSoldShare] = useState(0)
  const [teamShare, setTeamShare] = useState(0)
  const [crypto, setCrypto] = useState("usdt")
  const getShares = {
    abi,
    address: contractAddress as `0x${string}`,
    functionName: 'getShares',
    args: [address as `0x${string}`],
  }
  const availableShares = {
    abi,
    address: contractAddress as `0x${string}`,
    functionName: 'availableShares',
    args: [],
  }
  const soldShares = {
    abi,
    address: contractAddress as `0x${string}`,
    functionName: 'sharesSold',
    args: [],
  }
  const teamShares = {
    abi,
    address: contractAddress as `0x${string}`,
    functionName: 'getShares',
    args: ['0xdB7295B36236D766200D5382F26170b8DB7bf9Df'],
  }

  const { data, isSuccess } = useReadContracts({
    contracts: [getShares, availableShares, soldShares, teamShares],
  });

  const fallbackOnchainFetch = async () => {
    try {
      const data = await readContracts(config, {
        // @ts-ignore
        contracts: [availableShares, soldShares, teamShares]
      });
      setAvailableShare(Number(formatUnits(data?.[0]?.result as bigint, 6)));
      setSoldShare(Number(formatUnits(data?.[1]?.result as bigint, 6)));
      setTeamShare(Number(formatUnits(data?.[2]?.result as bigint, 6)));
    } catch (error) {
      console.log(error, "Fallback error");
    }
  }

  async function donate() {
    let amount: string | null = prompt("How much POL would you like to donate? \n(number)");
    console.log(amount);
    try {
      if (amount !== null && Number(amount) > 0) {
        let bigIntAmount = parseUnits(amount, 18);
        let hash = await writeContract(config, {
          abi,
          address: contractAddress,
          functionName: "donate",
          value: bigIntAmount
        });
        toast({
          title: "Thank you for donating!",
          description: "This is truly invaluable to us 💜",
        });
        console.log(hash, "TX Hash");
      }
    } catch (error: any) {
      console.log(error.message);
      if (error.message.includes("Connector not connected.")) {
        toast({
          variant: "destructive",
          title: "Connect your wallet",
          description: "Your wallet isn't connected",
        });
        open();
      } else if (error.message.includes("connection.connector.getChainId")) {
        await disconnect();
        open();
      } else if (error.message.includes("User rejected the request.")) {
        toast({
          title: "Looks like might be testing 🤓",
        });
      } else {
        toast({
          variant: "destructive",
          title: "Something went wrong",
          description: "Hope the figure you inputted is a number?",
        });
      }
    }
  }

  useEffect(() => {
    fallbackOnchainFetch();
  }, []);

  useEffect(() => {
    try {
      if (isConnected) {
        setYourShare(Number(formatUnits(data?.[0]?.result as bigint, 6)));
        setAvailableShare(Number(formatUnits(data?.[1]?.result as bigint, 6)));
        setSoldShare(Number(formatUnits(data?.[2]?.result as bigint, 6)));
        setTeamShare(Number(formatUnits(data?.[3]?.result as bigint, 6)));
      } else {
        fallbackOnchainFetch();
      }
    } catch (error) {
      console.log(error)
    }
  }, [isConnected, isSuccess]);
  return (
    <>
      <main className="w-full h-full max-w-screen-2xl mx-auto">
        <header className="py-2 h-fit base:max-md:px-3 px-10 items-center border-b border-gray-600 max-md:py-4 flex relative top-0 w-full">
          <div className="w-fit">
            <p className="bg-gradient-to-t mt-4 from-gray-400 mb-3 tab:text-8xl tracking-tighter text-4xl to-white bg-clip-text text-transparent font-bolden">
              deWHITEPAPER<span className="from-gray-400 tracking-tighter text-[10px] tab:text-[20px]">noun</span>
            </p>
            <div className="p-4">
              <div className="mx-auto px-6 relative h-fit min-h-32 border-l-gray-600 border-l-2 border-dashed">
                <div id="timeline-item" className="text-ourWhite flex  mb-5">
                  <span className="absolute flex items-center justify-center -left-[23px] bg-cover bg-block rounded w-10 h-10">
                    1
                  </span>
                  <div className="relative top-[8px]">
                    <dd className="poppins-regular">
                      : a{" "}
                      <span className="poppins-regular line-through">
                        government
                      </span>{" "}
                      report on any subject/a detailed or{" "}
                      <span className="poppins-regular line-through">
                        authoritative
                      </span>{" "}
                      report
                    </dd>
                    <dd className="poppins-regular pl-3 line-through">
                      <i className="italic poppins-regular-italic">
                        especially :{" "}
                      </i>
                      a British publication that is usually less extensive than a
                      blue book
                    </dd>
                  </div>
                </div>
                <div id="timeline-item" className="text-ourWhite flex">
                  <span className="absolute flex items-center justify-center -left-[23px] bg-block bg-cover rounded w-10 h-10">
                    2
                  </span>
                  <div className="relative top-[8px]">
                    <dd className="poppins-regular">
                      : a detailed description with reports from{" "}
                      <strong className="poppins-extrabold">deBlockchain{" "}</strong>through the project's smart contract targeted at
                      <strong className="poppins-extrabold"> deGens</strong>,{" "}
                      <strong className="poppins-extrabold">deFans</strong>, and <strong className="poppins-extrabold">deInvestors</strong> from a decentralized whitepaper.
                    </dd>
                    <dd className="poppins-regular pl-3">
                      For example: I just snagged the whale's share of Big Inc's <strong className="poppins-extrabold">deWhitepaper</strong>—no FUD here, I'm straight-up bullish on this. The dude's got <i className="italic poppins-light-italic">sick</i> bars 🔥—he might just be the next big thing in the music game.
                    </dd>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </header>
        <section
          id="issue-1"
          className="base:max-md:px-3 min-h-[600px] text-ourWhite py-6 px-10 h-fit w-full lg:w-[1000px]"
        >
          <h1 className="tab:text-6xl text-3xl mb-5 pt-5 tracking-wide uppercase font-bolden">
            ISSUE #1.1: The Genesis & Presale (Launchpad)
          </h1>
          <h2 className="text-2xl font-bolden py-4">
            deWhitepaper: Empowering deGens, deFans, & deArtists
          </h2>
          <div className="w-full lg:w-[880px]">
            <em className="poppins-regular-italic">
              It’s so apropos when a smart contract function name carries meaning,
              like{" "}
              <code className="inline-block not-italic font-light text-sm rounded bg-slate-600">
                mintShare
              </code>
              .
            </em>
            <p className="poppins-regular my-3">
              In this decentralized music revolution, we hope to flip the
              traditional record label model on its head—putting control in the
              hands of <strong className="poppins-extrabold">deGens</strong>,{" "}
              <strong className="poppins-extrabold">deFans</strong>, and{" "}
              <strong className="poppins-extrabold">deInvestors</strong>. Through
              smart contracts, you’re not just backing an artist; you’re buying a
              tangible stake in their success, and most importantly letting the artist define their record terms in their favor through a smart contract. Welcome to the new way to fund
              emerging talent—on-chain and fully transparent.
            </p>
          </div>
          <h2 className="text-2xl font-bolden py-4">
            On-chain Shareholders Get Real Stakes
          </h2>
          <div className="w-full lg:w-[880px]">
            <p className="poppins-regular  my-3">
              In the inaugural presale of shares,{" "}
              <strong className="poppins-extrabold">deGens</strong>, fans, and
              investors will have the opportunity to mint shares, recorded
              transparently on the blockchain. This isn’t your typical NFT or
              token sale.{" "}
              <strong className="poppins-extrabold">
                When you sign the{" "}
                <code className="inline-block text-sm font-light rounded bg-slate-600">
                  mintShare
                </code>{" "}
                function on the smart contract
              </strong>
              , you’re buying{" "}
              <strong className="poppins-extrabold">shares on-chain</strong>{" "}
              connected to actual revenue streams, all based on the artist’s
              performance.
            </p>
            <div className="poppins-regular">
              Shareholders own
              <strong className="poppins-extrabold">
                <span> 82%</span> of the total revenue pool</strong>{" "}
              on contract creation which is based on the artist's performance while the team (and the artist) <strong className="poppins-extrabold">own <span>18%</span></strong> of shares on contract creation which is all subject to change if the artist decides to buy shares. After these initial percentages the rest are the current percentages coming from the <strong className="poppins-extrabold" >deBlockchain</strong>.
              <p className='poppins-regular mt-4'>This means:</p>
              <ul className="list-disc px-8 pb-4">
                <li className="poppins-regular my-4">
                  <strong className="poppins-extrabold">
                    Streaming revenue:
                  </strong>{" "}
                  Every stream the artist earns from the album will flow back to
                  the revenue pool <strong className="poppins-extrabold">
                    <span>{availableShare}%</span>
                  </strong>{" "}
                  goes to shareholders,{" "}
                  <strong className="poppins-extrabold">
                    <span>{teamShare}%</span>
                  </strong> to the team (and artist).
                </li>
                <li className="poppins-regular my-4">
                  <strong className="poppins-extrabold">Merchandise:</strong> Sales from tour t-shirts, vinyl, and other related
                  merchandise will flow back to
                  the revenue pool <strong className="poppins-extrabold">
                    <span>{availableShare}%</span>
                  </strong>{" "}
                  goes to shareholders,{" "}
                  <strong className="poppins-extrabold">
                    <span>{teamShare}%</span>
                  </strong> to the team (and artist).
                </li>
                <li className="poppins-regular my-4">
                  <strong className="poppins-extrabold">
                    Promotions & endorsements:
                  </strong>{" "}
                  If the artist secures brand deals or partnerships during this
                  album's lifecycle, shareholders will benefit from the revenue pool <strong className="poppins-extrabold">
                    <span>{availableShare}%</span>
                  </strong>{" "}
                  goes to shareholders,{" "}
                  <strong className="poppins-extrabold">
                    <span>{teamShare}%</span>
                  </strong> to the team (and artist).
                </li>
                <li className="poppins-regular my-4">
                  <strong className="poppins-extrabold">Tour revenue:</strong>{" "}
                  Every ticket sold for performances during this album's lifecycle will
                  contribute to the pool <strong className="poppins-extrabold">
                    <span>{availableShare}%</span>
                  </strong>{" "}
                  goes to shareholders,{" "}
                  <strong className="poppins-extrabold">
                    <span>{teamShare}%</span>
                  </strong> to the team (and artist).
                </li>
                <li className="poppins-regular my-4">
                  <strong className="poppins-extrabold">
                    Master recordings & sync license:
                  </strong>{" "}
                  Shareholders will own a piece of the artist’s master & sync license fee per their shares—
                  <strong className="poppins-extrabold">
                    <span>{availableShare}%</span>
                  </strong>{" "}
                  goes to shareholders,{" "}
                  <strong className="poppins-extrabold">
                    <span>{teamShare}%</span>
                  </strong>{" "}to the team (and artist).
                  And if a shareholder wants to utilize the master license or sync license, they will pay a fee, but it will be a discounted fee per share (like their share percentage slash the original master/sync fee), if they fail to comply with these terms it may result in the seizure of the shareholder’s shares, along with potential legal action for intellectual property abuse.
                </li>
              </ul>
              We are aiming to raise {" "}
              <strong className="poppins-extrabold">
                <span>$457,143</span> - <span>$680,000</span> in total share valuation
              </strong>
              , with{" "}
              <strong className="poppins-extrabold">
                <span>21%</span> of the shares
              </strong>{" "}
              (<strong className="poppins-extrabold"><span>$142,800</span></strong> in shares valuation when the total valuation is <strong>$680,000</strong>) being sold for{" "}
              <strong>$96,000</strong> when the total valuation is <strong>$457,143</strong>. This offers a
              <strong className="poppins-extrabold">
                {" "}
                <span>≈ 48.75%</span> profit
              </strong>{" "}
              for early backers upon resale. Once the presale target is met, the
              smart contract will automatically adjust to the normal pricing tier (where the total valuation is <strong>$680,000</strong>).
            </div>
            <p className="poppins-regular">
              Proceeds from the presale will be allocated as follows:
            </p>
            <ul className="list-disc px-8 py-4">
              <li className="poppins-regular my-4">
                <strong className="poppins-extrabold">
                  Development and infrastructure fees:
                </strong>{" "}
                Development cost for a porfolio management interface for shareholders & other smart contracts, gamification campaigns, server hosting, API quotas, and other essential
                operational costs.
              </li>
              <li className="poppins-regular my-4">
                <strong className="poppins-extrabold">Studio production:</strong>{" "}
                Crafting high-quality singles before the album completion
                (longer than an EP).
              </li>
              <li className="poppins-regular my-4">
                <strong className="poppins-extrabold">Legal fees:</strong>{" "}
                Covering intellectual property protection to ensure the artist's
                master recordings & licensings, and other assets are safeguarded.
              </li>
              <li className="poppins-regular my-4">
                <strong className="poppins-extrabold">
                  Promotion and logistics:
                </strong>{" "}
                Ensuring the artist reaches a wider audience.
              </li>
              <li className="poppins-regular my-4">
                <strong className="poppins-extrabold">Miscellaneous costs</strong>
                .
              </li>
            </ul>
          </div>
          <h2 className="text-2xl font-bolden py-4">
            On-Chain Transparency Itself Doesn't Suffice
          </h2>
          <div className="w-full lg:w-[880px]">
            <p className="poppins-regular my-3">
              While on-chain transparency is a fundamental pillar of this project,
              we believe it alone is not enough. True transparency requires
              accountability not just in the blockchain operations but also in how
              we handle everyday communication and transactions outside the
              blockchain. To ensure shareholders are kept in the loop and no deals
              bypass their scrutiny, we are going to implement several measures
              after/before the presale to bolster transparency and trust:
            </p>
            <ul className="list-disc px-8 py-4">
              <li className="poppins-regular my-4">
                <strong className="poppins-extrabold">
                  Programmatic Monitoring of Communication:
                </strong>{" "}
                Every message sent via/to our contact form and domain email will
                be programmatically monitored. Through IMAP/SMTP integration, all
                correspondence will be broadcasted in real-time to a dedicated
                "contact dump" channel on our official Discord server. This way,
                stakeholders can observe all communication channels and be assured
                that no deals or critical updates are happening behind closed
                doors.
              </li>
              <li className="poppins-regular my-4">
                <strong className="poppins-extrabold">
                  Private Source Code Repository (GitHub Invite-Only):
                </strong>{" "}
                The source code of our website—including the merch store, contact
                form, whitepaper, and other critical pages—will be made available
                through a private GitHub repository, accessible via invite-only to
                shareholders. This way, shareholders can review, audit, and
                monitor the codebase for any changes that could affect
                transparency or integrity. While it won't be publicly available,
                this ensures that all stakeholders can track developments and
                verify that the platform's backend aligns with the project’s
                promises.
              </li>
              <li className="poppins-regular my-4">
                <strong className="poppins-extrabold">
                  Built-In Merch Store & Ticketing Platform:
                </strong>{" "}
                We will not rely on third-party platforms for merchandise sales or
                ticketing. Both the merch store and ticketing system will be built
                directly on our website, ensuring that every transaction is
                broadcasted to a dedicated "cha-ching" channel on our Discord
                server. Shareholders will be able to view sales data in real-time,
                ensuring transparency and accountability for all transactions
                without the need for external platforms.
              </li>
              <li className="poppins-regular my-4">
                <strong className="poppins-extrabold">
                  Monthly Stream Revenue Audits:
                </strong>{" "}
                To maintain transparency with streaming revenue, we will conduct
                monthly audits, showing exactly how much revenue has been
                generated and how it is being distributed to shareholders. These
                audits will be shared openly with all stakeholders, so they can
                verify that the revenue pools are being handled appropriately,
                with no hidden fees or undisclosed deductions.
              </li>
            </ul>
            <p className="poppins-regular my-3">
              Shares revenue will be distributed annually, or earlier in stablecoins (USDC/USDT/STRK on the Starknet chain) to the mapped addresses of our shareholders. Here's the body of work & a testament of talent: <a className='poppins-regular text-blue-400' href="https://www.instagram.com/big_inc_/" target="_blank" rel="noopener noreferrer">Big Inc's Instagram</a>. And any further questions you can <a className='poppins-regular text-blue-400' href="https://x.com/jedshock" target="_blank" rel="noopener noreferrer">DM MGMT on X</a>
            </p>
          </div>
          <h2 className="text-2xl font-bolden py-4">Outro</h2>
          <div className="w-full lg:w-[880px]">
            <p className="poppins-regular my-3">
              We want to show the world what we've been listening to; the
              countless artists who have shaped our psyche with their
              soul-throbbing sounds. Now, we’re giving it back—through the
              unbridled artistry pulsing in our veins and soul. We're carving a
              path, and template for indie artists, who create in the shadows, to break free
              from the chains of obscurity & conformity to find empowerment on-chain, through
              our collective success story.
            </p>
            <p className="poppins-regular flex items-center gap-1">
              Thanks for reading, you can own a piece of pie below.
            </p>
          </div>
        </section>
        <section className="poppins-regular my-5 flex justify-center">
          <Card className="w-full max-w-2xl bg-transparent text-white border-none">
            <CardHeader>
              <CardTitle className="text-center text-2xl">Share Distribution</CardTitle>
            </CardHeader>
            <p className="text-center poppins-regular">
              You own <span>{yourShare}%</span> of the total shares.
            </p>
            <CardContent className="flex flex-col items-center gap-4">
              <ShareChart yourShare={yourShare} soldShare={soldShare} availableShare={availableShare} />
              <ConnectButton />
            </CardContent>
          </Card>
        </section>
        <p className="w-full text-center poppins-regular text-sm text-[#A8AEB9] my-3 p-5"><strong className="poppins-extrabold text-[#A8AEB9]">Disclosure:</strong> Not Financial Advice (NFA). But we are a community-driven project, and we are building this as a template to setup a proven rebel label on-chain with our integrity & reputation which we hold dearly to this becoming a successful story. We are not selling shares to the public, but to our community, and anyone who is willing to join our community. Feel free to join our community and be part of this trailblazing journey.</p>
        
        {/* Expectations Link */}
        <div className="w-full text-center py-8">
          <Link href="/dewhitepaper/expectations">
            <Button variant="outline" className="text-ourWhite px-10 rounded-none bg-[transparent] border-gray-600 font-extralight font-lighten tracking-widest hover:border-gray-500 transition-all duration-200 ease-in-out hover:scale-[1.02]">
              🗳️ View Community Expectations
            </Button>
          </Link>
        </div>
      </main>
    </>
  );
}
