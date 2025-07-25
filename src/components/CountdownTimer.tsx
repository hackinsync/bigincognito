'use client';

import { useEffect, useState } from 'react';
import { formatDistanceToNow } from 'date-fns';

interface CountdownTimerProps {
  deadline: number; // unix timestamp
  className?: string;
}

export default function CountdownTimer({ deadline, className = '' }: CountdownTimerProps) {
  const [timeLeft, setTimeLeft] = useState<string>('');
  const [isExpired, setIsExpired] = useState(false);

  useEffect(() => {
    const updateTimer = () => {
      const now = Date.now();
      const timeUntilDeadline = deadline - now;

      if (timeUntilDeadline <= 0) {
        setIsExpired(true);
        setTimeLeft('Voting ended');
        return;
      }

      setIsExpired(false);
      setTimeLeft(formatDistanceToNow(deadline, { addSuffix: true }));
    };

    updateTimer();
    const interval = setInterval(updateTimer, 1000);

    return () => clearInterval(interval);
  }, [deadline]);

  return (
    <div className={`flex items-center gap-2 ${className}`}>
      <div className={`w-2 h-2 rounded-full ${isExpired ? 'bg-red-500' : 'bg-green-500'}`} />
      <span className={`text-sm ${isExpired ? 'text-red-400' : 'text-green-400'}`}>
        {timeLeft}
      </span>
    </div>
  );
} 