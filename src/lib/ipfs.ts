import { MilestoneContent } from '@/types/expectation';

const IPFS_GATEWAYS = [
  'https://ipfs.io/ipfs/',
  'https://gateway.pinata.cloud/ipfs/',
  'https://cloudflare-ipfs.com/ipfs/',
  'https://dweb.link/ipfs/'
];

export async function fetchFromIPFS(uri: string): Promise<MilestoneContent | null> {
  // Remove ipfs:// prefix if present
  const hash = uri.replace('ipfs://', '');
  
  for (const gateway of IPFS_GATEWAYS) {
    try {
      const response = await fetch(`${gateway}${hash}`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
        },
        // Add timeout
        signal: AbortSignal.timeout(10000) // 10 seconds
      });
      
      if (response.ok) {
        const data = await response.json();
        return data as MilestoneContent;
      }
    } catch (error) {
      console.warn(`Failed to fetch from ${gateway}:`, error);
      continue;
    }
  }
  
  return null;
}

export function getIPFSGatewayUrl(uri: string): string {
  const hash = uri.replace('ipfs://', '');
  return `${IPFS_GATEWAYS[0]}${hash}`;
} 