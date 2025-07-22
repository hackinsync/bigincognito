"use client"
import React from 'react'
import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts'
import { Card, CardContent } from "@/components/ui/card"
import { useShareData } from '@/lib/starknet/hooks'

interface ShareChartStarknetProps {
    className?: string
}

export function ShareChartStarknet({ className = "" }: ShareChartStarknetProps) {
    const { availableShare, userShare, soldShare, teamShare, totalShareholders } = useShareData()

    const data = [
        { name: 'Your Shares', value: userShare },
        { name: 'Available Shares', value: availableShare },
        { name: 'Sold Shares', value: soldShare },
        { name: 'Team Shares', value: teamShare },
    ]

    const COLORS = ['#506AE9', '#9FA4AE', '#7BB274', '#F59E0B']

    // Filter out zero values for cleaner display
    const filteredData = data.filter(item => item.value > 0)

    return (
        <Card className={`w-full poppins-regular max-w-md border-none bg-transparent ${className}`}>
            <CardContent>
                <div className="mb-4 text-center">
                    <h3 className="text-lg font-semibold text-white">BigInc Genesis Shares</h3>
                    <p className="text-sm text-gray-400">Total Shareholders: {totalShareholders}</p>
                </div>

                <ResponsiveContainer className="poppins-regular" width="100%" height={300}>
                    <PieChart>
                        <Pie
                            data={filteredData}
                            cx="50%"
                            cy="50%"
                            labelLine={false}
                            outerRadius={80}
                            fill="#C0C5CC"
                            dataKey="value"
                            label={({ name, value }) => `${name}: ${value.toFixed(2)}%`}
                        >
                            {filteredData.map((entry, index) => (
                                <Cell className='poppins-regular' key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                            ))}
                        </Pie>
                        <Tooltip
                            formatter={(value: number) => [`${value.toFixed(4)}%`, 'Percentage']}
                        />
                        <Legend className='poppins-regular' />
                    </PieChart>
                </ResponsiveContainer>

                <div className="mt-4 space-y-2 text-sm">
                    {filteredData.map((item, index) => (
                        <div key={item.name} className="flex justify-between items-center">
                            <div className="flex items-center gap-2">
                                <div
                                    className="w-3 h-3 rounded-full"
                                    style={{ backgroundColor: COLORS[index % COLORS.length] }}
                                />
                                <span className="text-gray-300">{item.name}</span>
                            </div>
                            <span className="text-white font-medium">{item.value.toFixed(4)}%</span>
                        </div>
                    ))}
                </div>
            </CardContent>
        </Card>
    )
}
