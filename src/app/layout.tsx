/* eslint-disable @next/next/no-page-custom-font */
import type { Metadata } from "next";
import "./globals.css";
import Nav from "@components/Nav";
import { headers } from 'next/headers'
import AppKitProvider from "@context/AppKitProvider";
import { StarknetAppProvider } from "@context/StarknetKitProvider";
import { Toaster } from "@/components/ui/toaster";

export const metadata: Metadata = {
  title: "Big Inc - Artist Onchain",
  description: "Welcome to my body of work",
  openGraph: {
    images: [{ url: "https://bigincognito.vercel.app/assets/img/inc-the-god.jpg" }],
    description: "Big Inc is a multidisciplinary creative artist onchain.",
    title: "Big Inc - Artist Onchain",
    url: "https://www.bigincognito.com"
  }
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const cookies: string = headers().get('cookie')!

  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link
          rel="preconnect"
          href="https://fonts.gstatic.com"
          crossOrigin={"anonymous"}
        />
        <link
          href="https://fonts.googleapis.com/css2?family=Poppins:ital,wght@0,100;0,200;0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,100;1,200;1,300;1,400;1,500;1,600;1,700;1,800;1,900&display=swap"
          rel="stylesheet"
        />
        <link
          rel="preload"
          href="/assets/music/light_years.mp3"
          as="audio"
          type="audio/mpeg"
        />
        <link
          rel="shortcut icon"
          href="/assets/img/big_inc_icon.png"
          type="image/png"
        />
      </head>
      <body className="bg-darkBg bg-[radial-gradient(ellipse_80%_80%_at_50%_-20%,rgba(120,119,198,0.3),rgba(255,255,255,0))] w-vw flex flex-col h-dvh overflow-hidden relative">
        <Nav />
        <main className="grow custom-scrollbar overflow-auto overflow-x-hidden">
          <StarknetAppProvider>
            <AppKitProvider cookies={cookies}>
              {children}
            </AppKitProvider>
          </StarknetAppProvider>
        </main>
        <Toaster />
      </body>
    </html>
  );
}
