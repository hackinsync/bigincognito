'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { getMockExpectations } from '@/lib/mock-api';
import { Expectation, ExpectationStatus } from '@/types/expectation';
import ExpectationCard from '@/components/ExpectationCard';
import Link from 'next/link';

export default function ExpectationsPage() {
  const [expectations, setExpectations] = useState<Expectation[]>([]);
  const [filteredExpectations, setFilteredExpectations] = useState<Expectation[]>([]);
  const [activeFilter, setActiveFilter] = useState<ExpectationStatus | 'all'>('all');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchExpectations = async () => {
      try {
        const data = await getMockExpectations();
        setExpectations(data);
        setFilteredExpectations(data);
      } catch (error) {
        console.error('Failed to fetch expectations:', error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchExpectations();
  }, []);

  useEffect(() => {
    if (activeFilter === 'all') {
      setFilteredExpectations(expectations);
    } else {
      setFilteredExpectations(expectations.filter(exp => exp.status === activeFilter));
    }
  }, [activeFilter, expectations]);

  const getStatusCount = (status: ExpectationStatus) => {
    return expectations.filter(exp => exp.status === status).length;
  };

  const getStatusColor = (status: ExpectationStatus) => {
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

  const getStatusIcon = (status: ExpectationStatus) => {
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

  if (isLoading) {
    return (
      <main className="w-full h-full max-w-screen-2xl mx-auto">
        <div className="base:max-md:px-3 py-6 px-10">
          <div className="text-center py-20">
            <div className="text-ourWhite text-xl">Loading expectations...</div>
          </div>
        </div>
      </main>
    );
  }

  return (
    <main className="w-full h-full max-w-screen-2xl mx-auto">
      {/* Header */}
      <header className="py-2 h-fit base:max-md:px-3 px-10 items-center border-b border-gray-600 max-md:py-4 flex relative top-0 w-full">
        <div className="w-fit">
          <p className="bg-gradient-to-t mt-4 from-gray-400 mb-3 tab:text-8xl tracking-tighter text-4xl to-white bg-clip-text text-transparent font-bolden">
            EXPECTATIONS<span className="from-gray-400 tracking-tighter text-[10px] tab:text-[20px]">noun</span>
          </p>
          <div className="p-4">
            <div className="mx-auto px-6 relative h-fit min-h-32 border-l-gray-600 border-l-2 border-dashed">
              <div id="timeline-item" className="text-ourWhite flex mb-5">
                <span className="absolute flex items-center justify-center -left-[23px] bg-cover bg-block rounded w-10 h-10">
                  1
                </span>
                <div className="relative top-[8px]">
                  <dd className="poppins-regular">
                    : a <strong className="poppins-extrabold">milestone</strong> attached to a withdrawal request from the treasury
                  </dd>
                </div>
              </div>
              <div id="timeline-item" className="text-ourWhite flex">
                <span className="absolute flex items-center justify-center -left-[23px] bg-block bg-cover rounded w-10 h-10">
                  2
                </span>
                <div className="relative top-[8px]">
                  <dd className="poppins-regular">
                    : a <strong className="poppins-extrabold">voting mechanism</strong> where shareholders determine the final state based on majority approval
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
          <h1 className="tab:text-6xl text-3xl mb-5 pt-5 tracking-wide uppercase font-bolden text-ourWhite">
            Community Expectations
          </h1>
          <p className="text-gray-300 poppins-regular max-w-3xl">
            Review and vote on milestones attached to treasury withdrawal requests. Each expectation represents a commitment 
            that shareholders can approve or reject based on its merit and alignment with the project's goals.
          </p>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <Card className="bg-transparent text-white border-gray-600">
            <CardContent className="p-4 text-center">
              <div className="text-2xl font-bold text-ourWhite">{expectations.length}</div>
              <div className="text-sm text-gray-400">Total</div>
            </CardContent>
          </Card>
          <Card className="bg-transparent text-white border-gray-600">
            <CardContent className="p-4 text-center">
              <div className="text-2xl font-bold text-yellow-400">{getStatusCount('ongoing')}</div>
              <div className="text-sm text-gray-400">Ongoing</div>
            </CardContent>
          </Card>
          <Card className="bg-transparent text-white border-gray-600">
            <CardContent className="p-4 text-center">
              <div className="text-2xl font-bold text-green-400">{getStatusCount('fulfilled')}</div>
              <div className="text-sm text-gray-400">Fulfilled</div>
            </CardContent>
          </Card>
          <Card className="bg-transparent text-white border-gray-600">
            <CardContent className="p-4 text-center">
              <div className="text-2xl font-bold text-red-400">{getStatusCount('rejected')}</div>
              <div className="text-sm text-gray-400">Rejected</div>
            </CardContent>
          </Card>
        </div>

        {/* Filter Buttons */}
        <div className="flex flex-wrap gap-2 mb-8">
                      <Button
              variant="outline"
              size="sm"
              onClick={() => setActiveFilter('all')}
              className={`text-ourWhite px-4 rounded-none bg-[transparent] border-gray-600 font-extralight font-lighten tracking-widest hover:border-gray-500 transition-all duration-200 ease-in-out ${
                activeFilter === 'all' ? 'bg-ourWhite text-darkBg border-ourWhite' : ''
              }`}
            >
            All ({expectations.length})
          </Button>
                      <Button
              variant="outline"
              size="sm"
              onClick={() => setActiveFilter('ongoing')}
              className={`text-ourWhite px-4 rounded-none bg-[transparent] border-gray-600 font-extralight font-lighten tracking-widest hover:border-gray-500 transition-all duration-200 ease-in-out ${
                activeFilter === 'ongoing' ? 'bg-ourWhite text-darkBg border-ourWhite' : ''
              }`}
            >
            🟡 Ongoing ({getStatusCount('ongoing')})
          </Button>
                      <Button
              variant="outline"
              size="sm"
              onClick={() => setActiveFilter('fulfilled')}
              className={`text-ourWhite px-4 rounded-none bg-[transparent] border-gray-600 font-extralight font-lighten tracking-widest hover:border-gray-500 transition-all duration-200 ease-in-out ${
                activeFilter === 'fulfilled' ? 'bg-ourWhite text-darkBg border-ourWhite' : ''
              }`}
            >
            🟢 Fulfilled ({getStatusCount('fulfilled')})
          </Button>
                      <Button
              variant="outline"
              size="sm"
              onClick={() => setActiveFilter('rejected')}
              className={`text-ourWhite px-4 rounded-none bg-[transparent] border-gray-600 font-extralight font-lighten tracking-widest hover:border-gray-500 transition-all duration-200 ease-in-out ${
                activeFilter === 'rejected' ? 'bg-ourWhite text-darkBg border-ourWhite' : ''
              }`}
            >
            🔴 Rejected ({getStatusCount('rejected')})
          </Button>
        </div>

        {/* Expectations Grid */}
        {filteredExpectations.length === 0 ? (
          <div className="text-center py-20">
            <div className="text-gray-400 text-xl mb-4">
              No expectations found for the selected filter
            </div>
            <Button
              variant="outline"
              onClick={() => setActiveFilter('all')}
              className="text-ourWhite px-6 rounded-none bg-[transparent] border-gray-600 font-extralight font-lighten tracking-widest hover:border-gray-500 transition-all duration-200 ease-in-out hover:scale-[1.02]"
            >
              View All Expectations
            </Button>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {filteredExpectations.map((expectation) => (
              <ExpectationCard key={expectation.id} expectation={expectation} />
            ))}
          </div>
        )}

        {/* Back to deWhitepaper */}
        <div className="mt-12 text-center">
          <Link href="/dewhitepaper">
            <Button variant="outline" className="text-ourWhite px-8 rounded-none bg-[transparent] border-gray-600 font-extralight font-lighten tracking-widest hover:border-gray-500 transition-all duration-200 ease-in-out hover:scale-[1.02]">
              ← Back to deWhitepaper
            </Button>
          </Link>
        </div>
      </section>
    </main>
  );
} 