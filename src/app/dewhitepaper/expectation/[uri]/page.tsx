'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { getMockExpectations, getMockMilestoneContent } from '@/lib/mock-api';
import { fetchFromIPFS } from '@/lib/ipfs';
import { Expectation, MilestoneContent } from '@/types/expectation';
import VotingInterface from '@/components/VotingInterface';

import CountdownTimer from '@/components/CountdownTimer';
import Link from 'next/link';
import MarkdownRenderer from '@components/MarkdownRenderer';

export default function ExpectationPage() {
  const params = useParams();
  const uri = decodeURIComponent(params.uri as string);
  
  const [expectation, setExpectation] = useState<Expectation | null>(null);
  const [milestoneContent, setMilestoneContent] = useState<MilestoneContent | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setIsLoading(true);
        setError(null);

        // Find expectation by milestoneURI
        const expectations = await getMockExpectations();
        const foundExpectation = expectations.find(exp => exp.milestoneURI === uri);
        
        if (!foundExpectation) {
          setError('Expectation not found');
          return;
        }

        setExpectation(foundExpectation);

        // Try to fetch from IPFS first, then fallback to mock
        let content: MilestoneContent | null = null;
        
        try {
          content = await fetchFromIPFS(uri);
        } catch (ipfsError) {
          console.warn('IPFS fetch failed, using mock data:', ipfsError);
        }

        if (!content) {
          content = await getMockMilestoneContent(uri);
        }

        if (!content) {
          setError('Failed to load milestone content');
          return;
        }

        setMilestoneContent(content);
      } catch (err) {
        console.error('Error fetching expectation data:', err);
        setError('Failed to load expectation data');
      } finally {
        setIsLoading(false);
      }
    };

    if (uri) {
      fetchData();
    }
  }, [uri]);

  const handleVoteSubmitted = () => {
    // Refresh expectation data after vote
    if (expectation) {
      getMockExpectations().then(expectations => {
        const updatedExpectation = expectations.find(exp => exp.id === expectation.id);
        if (updatedExpectation) {
          setExpectation(updatedExpectation);
        }
      });
    }
  };

  if (isLoading) {
    return (
      <main className="w-full h-full max-w-screen-2xl mx-auto">
        <div className="base:max-md:px-3 py-6 px-10">
          <div className="text-center py-20">
            <div className="text-ourWhite text-xl">Loading expectation...</div>
          </div>
        </div>
      </main>
    );
  }

  if (error || !expectation || !milestoneContent) {
    return (
      <main className="w-full h-full max-w-screen-2xl mx-auto">
        <div className="base:max-md:px-3 py-6 px-10">
          <div className="text-center py-20">
            <div className="text-red-400 text-xl mb-4">
              {error || 'Expectation not found'}
            </div>
            <Link href="/dewhitepaper/expectations">
              <Button variant="outline" className="text-ourWhite px-8 rounded-none bg-[transparent] border-gray-600 font-extralight font-lighten tracking-widest hover:border-gray-500 transition-all duration-200 ease-in-out hover:scale-[1.02]">
                ← Back to Expectations
              </Button>
            </Link>
          </div>
        </div>
      </main>
    );
  }

  const isVotingActive = expectation.status === 'ongoing' && expectation.deadline > Date.now();

  return (
    <main className="w-full h-full max-w-screen-2xl mx-auto">
      {/* Header */}
      <header className="py-2 h-fit base:max-md:px-3 px-10 items-center border-b border-gray-600 max-md:py-4 flex relative top-0 w-full">
        <div className="w-fit">
          <p className="bg-gradient-to-t mt-4 from-gray-400 mb-3 tab:text-8xl tracking-tighter text-4xl to-white bg-clip-text text-transparent font-bolden">
            EXPECTATION<span className="from-gray-400 tracking-tighter text-[10px] tab:text-[20px]">noun</span>
          </p>
          <div className="p-4">
            <div className="mx-auto px-6 relative h-fit min-h-32 border-l-gray-600 border-l-2 border-dashed">
              <div id="timeline-item" className="text-ourWhite flex mb-5">
                <span className="absolute flex items-center justify-center -left-[23px] bg-cover bg-block rounded w-10 h-10">
                  1
                </span>
                <div className="relative top-[8px]">
                  <dd className="poppins-regular">
                    : a <strong className="poppins-extrabold">detailed proposal</strong> for community review and voting
                  </dd>
                </div>
              </div>
              <div id="timeline-item" className="text-ourWhite flex">
                <span className="absolute flex items-center justify-center -left-[23px] bg-block bg-cover rounded w-10 h-10">
                  2
                </span>
                <div className="relative top-[8px]">
                  <dd className="poppins-regular">
                    : a <strong className="poppins-extrabold">milestone commitment</strong> tied to treasury withdrawal requests
                  </dd>
                </div>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Content */}
      <section className="base:max-md:px-3 py-6 px-10">
        <div className="mb-8">
          <div className="flex items-start justify-between mb-4">
            <div>
              <h1 className="tab:text-4xl text-2xl mb-2 tracking-wide font-bolden text-ourWhite">
                {milestoneContent.title}
              </h1>
              <div className="flex items-center gap-4 text-sm text-gray-400">
                <span className={`px-2 py-1 rounded ${
                  expectation.status === 'ongoing' ? 'bg-yellow-900/20 text-yellow-400' :
                  expectation.status === 'fulfilled' ? 'bg-green-900/20 text-green-400' :
                  'bg-red-900/20 text-red-400'
                }`}>
                  {expectation.status.toUpperCase()}
                </span>
                {isVotingActive && (
                  <CountdownTimer deadline={expectation.deadline} />
                )}
              </div>
            </div>
            <Link href="/dewhitepaper/expectations">
              <Button variant="outline" size="sm" className="text-ourWhite px-6 rounded-none bg-[transparent] border-gray-600 font-extralight font-lighten tracking-widest hover:border-gray-500 transition-all duration-200 ease-in-out hover:scale-[1.02]">
                ← Back to Expectations
              </Button>
            </Link>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Main Content */}
          <div className="lg:col-span-2 space-y-6">
            {/* Proposal Content */}
            <Card className="bg-transparent text-white border-gray-600">
              <CardHeader>
                <CardTitle className="text-xl font-bolden text-ourWhite">
                  Proposal Details
                </CardTitle>
              </CardHeader>
              <CardContent>
                <MarkdownRenderer content={milestoneContent.content} />
              </CardContent>
            </Card>

            {/* GitHub Link */}
            <Card className="bg-transparent text-white border-gray-600">
              <CardHeader>
                <CardTitle className="text-lg font-bolden text-ourWhite">
                  Full Proposal
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-gray-300 poppins-regular mb-4">
                  View the complete proposal on GitHub for more detailed information and technical specifications.
                </p>
                <a
                  href={milestoneContent.bipLink}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 text-blue-400 hover:text-blue-300 underline"
                >
                  <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 0C4.477 0 0 4.484 0 10.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0110 4.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.203 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.942.359.31.678.921.678 1.856 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0020 10.017C20 4.484 15.522 0 10 0z" clipRule="evenodd" />
                  </svg>
                  View on GitHub
                </a>
              </CardContent>
            </Card>
          </div>

          {/* Voting Sidebar */}
          <div className="lg:col-span-1">
            <VotingInterface 
              expectation={expectation} 
              onVoteSubmitted={handleVoteSubmitted}
            />
          </div>
        </div>
      </section>
    </main>
  );
} 