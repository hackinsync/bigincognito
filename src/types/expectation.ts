export type ExpectationStatus = 'ongoing' | 'fulfilled' | 'rejected';

export interface Expectation {
  id: string;
  milestoneURI: string;
  title: string;
  summary: string;
  deadline: number; // unix timestamp
  status: ExpectationStatus;
  voteCounts: {
    approve: number;
    disapprove: number;
  };
}

export interface MilestoneContent {
  title: string;
  bipLink: string;
  content: string;
  createdAt: string;
}

export interface UserVote {
  expectationId: string;
  vote: 'approve' | 'disapprove';
  timestamp: number;
  comment?: string;
}

export interface VotingState {
  currentVote?: 'approve' | 'disapprove';
  hasVoted: boolean;
  comment: string;
} 