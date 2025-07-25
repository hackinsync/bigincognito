'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { toast } from '@/components/ui/use-toast';
import { Expectation, VotingState } from '@/types/expectation';
import { submitMockVote } from '@/lib/mock-api';
import ConnectButton from './ConnectButton';
import { useAppKitAccount } from '@reown/appkit/react';

interface VotingInterfaceProps {
  expectation: Expectation;
  onVoteSubmitted?: () => void;
}

export default function VotingInterface({ expectation, onVoteSubmitted }: VotingInterfaceProps) {
  const { isConnected } = useAppKitAccount();
  const [votingState, setVotingState] = useState<VotingState>({
    hasVoted: false,
    comment: ''
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  const isVotingActive = expectation.status === 'ongoing' && expectation.deadline > Date.now();
  const totalVotes = expectation.voteCounts.approve + expectation.voteCounts.disapprove;
  const approvalRate = totalVotes > 0 ? (expectation.voteCounts.approve / totalVotes * 100).toFixed(1) : '0';

  const handleVote = async (vote: 'approve' | 'disapprove') => {
    if (!isConnected) {
      toast({
        variant: "destructive",
        title: "Wallet not connected",
        description: "Please connect your wallet to vote",
      });
      return;
    }

    if (!isVotingActive) {
      toast({
        variant: "destructive",
        title: "Voting closed",
        description: "This expectation is no longer accepting votes",
      });
      return;
    }

    setIsSubmitting(true);
    setVotingState(prev => ({ ...prev, currentVote: vote }));

    try {
      const success = await submitMockVote(expectation.id, vote, votingState.comment);
      
      if (success) {
        setVotingState(prev => ({ ...prev, hasVoted: true }));
        toast({
          title: "Vote submitted successfully!",
          description: `Your ${vote} vote has been recorded.`,
        });
        onVoteSubmitted?.();
      } else {
        throw new Error('Failed to submit vote');
      }
    } catch (error) {
      toast({
        variant: "destructive",
        title: "Vote submission failed",
        description: "Please try again or check your wallet connection.",
      });
      setVotingState(prev => ({ ...prev, currentVote: undefined }));
    } finally {
      setIsSubmitting(false);
    }
  };

  const getStatusMessage = () => {
    if (!isVotingActive) {
      return expectation.status === 'fulfilled' 
        ? 'This expectation was approved by the community' 
        : 'This expectation was not approved by the community';
    }
    return 'Voting is currently active';
  };

  return (
    <Card className="bg-transparent text-white border-gray-600">
      <CardHeader>
        <CardTitle className="text-xl font-bolden text-ourWhite">
          Voting Results
        </CardTitle>
        <p className="text-sm text-gray-400 poppins-regular">
          {getStatusMessage()}
        </p>
      </CardHeader>
      
      <CardContent className="space-y-6">
        {/* Vote Counts */}
        <div className="grid grid-cols-2 gap-4">
          <div className="text-center p-4 bg-green-900/20 border border-green-600/30 rounded-lg">
            <div className="text-2xl font-bold text-green-400">
              {expectation.voteCounts.approve}
            </div>
            <div className="text-sm text-gray-400">Approve</div>
          </div>
          <div className="text-center p-4 bg-red-900/20 border border-red-600/30 rounded-lg">
            <div className="text-2xl font-bold text-red-400">
              {expectation.voteCounts.disapprove}
            </div>
            <div className="text-sm text-gray-400">Disapprove</div>
          </div>
        </div>

        {/* Approval Rate */}
        <div className="text-center">
          <div className="text-3xl font-bold text-ourWhite">
            {approvalRate}%
          </div>
          <div className="text-sm text-gray-400">
            Approval Rate ({totalVotes} total votes)
          </div>
        </div>

        {/* Voting Interface */}
        {isVotingActive && (
          <div className="space-y-4">
            <div className="border-t border-gray-600 pt-4">
              <h3 className="text-lg font-bolden text-ourWhite mb-4">
                Cast Your Vote
              </h3>
              
              {!isConnected ? (
                <div className="text-center space-y-4">
                  <p className="text-gray-400">
                    Connect your wallet to participate in voting
                  </p>
                  <ConnectButton />
                </div>
              ) : (
                <div className="space-y-4">
                  {/* Comment Input */}
                  <div>
                    <Label htmlFor="comment" className="text-sm text-gray-300">
                      Optional Comment
                    </Label>
                    <textarea
                      id="comment"
                      placeholder="Share your thoughts on this expectation..."
                      value={votingState.comment}
                      onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setVotingState(prev => ({ ...prev, comment: e.target.value }))}
                      className="mt-2 bg-gray-800/50 border-gray-600 text-white placeholder-gray-400 flex h-24 w-full rounded-md border px-3 py-2 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
                      rows={3}
                    />
                  </div>

                  {/* Vote Buttons */}
                  <div className="flex gap-4">
                    <Button
                      onClick={() => handleVote('approve')}
                      disabled={isSubmitting || votingState.hasVoted}
                      className="flex-1 bg-green-600 hover:bg-green-700 text-black transition-all duration-200 ease-in-out hover:scale-[1.02]"
                    >
                      {isSubmitting && votingState.currentVote === 'approve' ? 'Submitting...' : '✅ Approve'}
                    </Button>
                    <Button
                      onClick={() => handleVote('disapprove')}
                      disabled={isSubmitting || votingState.hasVoted}
                      className="flex-1 bg-red-600 hover:bg-red-700 text-black transition-all duration-200 ease-in-out hover:scale-[1.02]"
                    >
                      {isSubmitting && votingState.currentVote === 'disapprove' ? 'Submitting...' : '❌ Disapprove'}
                    </Button>
                  </div>

                  {votingState.hasVoted && (
                    <div className="text-center p-3 bg-blue-900/20 border border-blue-600/30 rounded-lg">
                      <p className="text-blue-400 text-sm">
                        ✅ Your vote has been submitted successfully!
                      </p>
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        )}

        {/* Status Display for Closed Votes */}
        {!isVotingActive && (
          <div className={`text-center p-4 rounded-lg ${
            expectation.status === 'fulfilled' 
              ? 'bg-green-900/20 border border-green-600/30' 
              : 'bg-red-900/20 border border-red-600/30'
          }`}>
            <p className={`text-lg font-bold ${
              expectation.status === 'fulfilled' ? 'text-green-400' : 'text-red-400'
            }`}>
              {expectation.status === 'fulfilled' ? '✅ Approved' : '❌ Rejected'}
            </p>
            <p className="text-sm text-gray-400 mt-1">
              Voting period has ended
            </p>
          </div>
        )}
      </CardContent>
    </Card>
  );
} 