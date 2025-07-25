import { Expectation, MilestoneContent } from '@/types/expectation';

// Mock expectations data
const mockExpectations: Expectation[] = [
  {
    id: '1',
    milestoneURI: 'ipfs://QmMock1',
    title: 'Add Generative Music NFT Feature',
    summary: 'Implement a feature that allows artists to mint generative audio NFTs using the built-in metadata layer.',
    deadline: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days from now
    status: 'ongoing',
    voteCounts: {
      approve: 45,
      disapprove: 12
    }
  },
  {
    id: '2',
    milestoneURI: 'ipfs://QmMock2',
    title: 'Implement Cross-Chain Revenue Distribution',
    summary: 'Create a system for distributing revenue across multiple blockchain networks.',
    deadline: Date.now() - 2 * 24 * 60 * 60 * 1000, // 2 days ago
    status: 'fulfilled',
    voteCounts: {
      approve: 78,
      disapprove: 15
    }
  },
  {
    id: '3',
    milestoneURI: 'ipfs://QmMock3',
    title: 'Launch Mobile App for Shareholders',
    summary: 'Develop a mobile application for shareholders to track their investments and vote on proposals.',
    deadline: Date.now() - 5 * 24 * 60 * 60 * 1000, // 5 days ago
    status: 'rejected',
    voteCounts: {
      approve: 23,
      disapprove: 67
    }
  },
  {
    id: '4',
    milestoneURI: 'ipfs://QmMock4',
    title: 'Integrate AI-Powered Music Analytics',
    summary: 'Add AI-driven analytics to help artists understand their audience and optimize their music strategy.',
    deadline: Date.now() + 3 * 24 * 60 * 60 * 1000, // 3 days from now
    status: 'ongoing',
    voteCounts: {
      approve: 34,
      disapprove: 8
    }
  }
];

// Mock milestone content
const mockMilestoneContent: Record<string, MilestoneContent> = {
  'QmMock1': {
    title: 'Add Generative Music NFT Feature',
    bipLink: 'https://github.com/hackinsync/bigincognito/proposals/bip1.md',
    content: `### Summary
Add a feature that allows artists to mint generative audio NFTs using the built-in metadata layer.

### Rationale
To improve tooling and automate audio variations for music drops, we propose implementing a generative music NFT system. This will enable artists to create unique variations of their tracks programmatically, increasing the collectibility and value of their NFT releases.

### Technical Implementation
- Smart contract integration for metadata storage
- Audio processing pipeline for variations
- Web3 integration for minting
- Frontend interface for artists

### Benefits
- Increased revenue potential for artists
- Enhanced collector experience
- Automated content generation
- Reduced manual work for artists`,
    createdAt: '2025-01-15T13:00:00Z'
  },
  'QmMock2': {
    title: 'Implement Cross-Chain Revenue Distribution',
    bipLink: 'https://github.com/hackinsync/bigincognito/proposals/bip2.md',
    content: `### Summary
Create a system for distributing revenue across multiple blockchain networks to maximize accessibility and reduce gas fees.

### Rationale
Currently, revenue distribution is limited to a single chain. By implementing cross-chain distribution, we can reach more shareholders and optimize for cost and speed.

### Technical Implementation
- Bridge integration for multiple chains
- Automated distribution scheduling
- Gas optimization strategies
- Multi-chain wallet support`,
    createdAt: '2025-01-10T10:00:00Z'
  },
  'QmMock3': {
    title: 'Launch Mobile App for Shareholders',
    bipLink: 'https://github.com/hackinsync/bigincognito/proposals/bip3.md',
    content: `### Summary
Develop a mobile application for shareholders to track their investments and vote on proposals.

### Rationale
Mobile access is crucial for user engagement. A dedicated app will improve the shareholder experience and increase participation in governance.

### Technical Implementation
- React Native development
- Wallet integration
- Push notifications
- Offline capability`,
    createdAt: '2025-01-05T15:00:00Z'
  },
  'QmMock4': {
    title: 'Integrate AI-Powered Music Analytics',
    bipLink: 'https://github.com/hackinsync/bigincognito/proposals/bip4.md',
    content: `### Summary
Add AI-driven analytics to help artists understand their audience and optimize their music strategy.

### Rationale
Data-driven insights are essential for artist success. AI analytics will provide valuable information about audience behavior and music performance.

### Technical Implementation
- Machine learning models for audience analysis
- Real-time data processing
- Predictive analytics
- Artist dashboard integration`,
    createdAt: '2025-01-12T09:00:00Z'
  }
};

export async function getMockExpectations(): Promise<Expectation[]> {
  // Simulate API delay
  await new Promise(resolve => setTimeout(resolve, 500));
  return mockExpectations;
}

export async function getMockExpectationById(id: string): Promise<Expectation | null> {
  await new Promise(resolve => setTimeout(resolve, 300));
  return mockExpectations.find(exp => exp.id === id) || null;
}

export async function getMockMilestoneContent(uri: string): Promise<MilestoneContent | null> {
  await new Promise(resolve => setTimeout(resolve, 400));
  const hash = uri.replace('ipfs://', '');
  return mockMilestoneContent[hash] || null;
}

export async function submitMockVote(
  expectationId: string, 
  vote: 'approve' | 'disapprove', 
  comment?: string
): Promise<boolean> {
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  // Update mock data
  const expectation = mockExpectations.find(exp => exp.id === expectationId);
  if (expectation) {
    expectation.voteCounts[vote]++;
  }
  
  return true;
} 