'use client';

import { Expectation } from '@/types/expectation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import CountdownTimer from './CountdownTimer';
import Link from 'next/link';

interface ExpectationCardProps {
  expectation: Expectation;
}

export default function ExpectationCard({ expectation }: ExpectationCardProps) {
  const getStatusColor = (status: Expectation['status']) => {
    switch (status) {
      case 'ongoing':
        return 'text-yellow-400';
      case 'fulfilled':
        return 'text-green-400';
      case 'rejected':
        return 'text-red-400';
      default:
        return 'text-gray-400';
    }
  };

  const getStatusIcon = (status: Expectation['status']) => {
    switch (status) {
      case 'ongoing':
        return '🟡';
      case 'fulfilled':
        return '🟢';
      case 'rejected':
        return '🔴';
      default:
        return '⚪';
    }
  };

  const totalVotes = expectation.voteCounts.approve + expectation.voteCounts.disapprove;
  const approvalRate = totalVotes > 0 ? (expectation.voteCounts.approve / totalVotes * 100).toFixed(1) : '0';

  return (
    <Card className="bg-transparent text-white border-gray-600 hover:border-gray-500 transition-all duration-200 ease-in-out hover:scale-[1.01]">
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between">
          <CardTitle className="text-lg font-bolden text-ourWhite line-clamp-2">
            {expectation.title}
          </CardTitle>
          <div className="flex items-center gap-2">
            <span className="text-lg">{getStatusIcon(expectation.status)}</span>
            <span className={`text-sm font-medium ${getStatusColor(expectation.status)}`}>
              {expectation.status.toUpperCase()}
            </span>
          </div>
        </div>
      </CardHeader>
      
      <CardContent className="space-y-4">
        <p className="text-sm text-gray-300 line-clamp-3 poppins-regular">
          {expectation.summary}
        </p>
        
        <div className="flex items-center justify-between text-sm">
          <div className="flex items-center gap-4">
            <span className="text-gray-400">
              {totalVotes} votes
            </span>
            <span className="text-green-400">
              {approvalRate}% approval
            </span>
          </div>
          
          {expectation.status === 'ongoing' && (
            <CountdownTimer deadline={expectation.deadline} />
          )}
        </div>
        
        <div className="flex items-center justify-between">
          <div className="flex gap-2 text-xs text-gray-400">
            <span>✅ {expectation.voteCounts.approve}</span>
            <span>❌ {expectation.voteCounts.disapprove}</span>
          </div>
          
          <Link href={`/dewhitepaper/expectation/${encodeURIComponent(expectation.milestoneURI)}`}>
            <Button 
              variant="outline" 
              size="sm"
              className="text-ourWhite px-6 rounded-none bg-[transparent] border-gray-600 font-extralight font-lighten tracking-widest hover:border-gray-500 transition-all duration-200 ease-in-out hover:scale-[1.02]"
            >
              {expectation.status === 'ongoing' ? 'Vote Now' : 'View Details'}
            </Button>
          </Link>
        </div>
      </CardContent>
    </Card>
  );
} 