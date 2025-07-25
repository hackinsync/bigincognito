'use client'
import { useAccount } from '@starknet-react/core'
import { useMemo, useCallback, useState, useEffect } from 'react'
import { Contract, Provider, Account, cairo } from 'starknet'
import BigIncGenesisABI from '../../abi/BigIncGenesisStarknet.json'
import { contractAddresses, SHARE_PRECISION } from './config'

// Hook to get the BigIncGenesis contract instance
export function useBigIncContract() {
    const { address, account } = useAccount()

    return useMemo(() => {
        if (!contractAddresses.BigIncGenesis || contractAddresses.BigIncGenesis === '0x0') {
            return null
        }

        const provider = new Provider({
            nodeUrl: 'http://localhost:5050'
        })

        if (account) {
            return new Contract(BigIncGenesisABI, contractAddresses.BigIncGenesis, account)
        } else {
            return new Contract(BigIncGenesisABI, contractAddresses.BigIncGenesis, provider)
        }
    }, [address, account, contractAddresses.BigIncGenesis])
}

// Hook to read contract data with auto-refresh
function useContractCall<T>(
    functionName: string,
    args: any[] = [],
    defaultValue: T,
    enabled: boolean = true
) {
    const contract = useBigIncContract()
    const [data, setData] = useState<T>(defaultValue)
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)

    const fetchData = useCallback(async () => {
        if (!contract || !enabled) return

        try {
            setLoading(true)
            setError(null)
            const result = await contract[functionName](...args)
            setData(result)
        } catch (err) {
            console.error(`Error calling ${functionName}:`, err)
            setError(err instanceof Error ? err.message : 'Unknown error')
        } finally {
            setLoading(false)
        }
    }, [contract, functionName, JSON.stringify(args), enabled])

    useEffect(() => {
        fetchData()

        // Poll every 5 seconds for live updates
        const interval = setInterval(fetchData, 5000)
        return () => clearInterval(interval)
    }, [fetchData])

    return { data, loading, error, refetch: fetchData }
}

// Hook to read total available shares
export function useAvailableShares() {
    return useContractCall('get_available_shares', [], BigInt(0))
}

// Hook to read user's shares
export function useUserShares() {
    const { address } = useAccount()

    return useContractCall(
        'get_shares',
        address ? [address] : [],
        BigInt(0),
        !!address
    )
}

// Hook to read shares sold
export function useSharesSold() {
    return useContractCall('get_shares_sold', [], BigInt(0))
}

// Hook to read all shareholders
export function useShareholders() {
    return useContractCall('get_shareholders', [], [])
}

// Hook to read presale status
export function usePresaleActive() {
    return useContractCall('is_presale_active', [], false)
}

// Hook to read USDT address
export function useUSDTAddress() {
    return useContractCall('get_usdt_address', [], '0x0')
}

// Hook to read USDC address  
export function useUSDCAddress() {
    return useContractCall('get_usdc_address', [], '0x0')
}

// Hook to mint shares
export function useMintShare() {
    const contract = useBigIncContract()
    const [isLoading, setIsLoading] = useState(false)

    const mintShare = useCallback(async (tokenAddress: string) => {
        if (!contract) throw new Error('Contract not available')

        try {
            setIsLoading(true)
            const result = await contract.invoke('mint_share', [tokenAddress])
            return result
        } catch (error) {
            console.error('Mint share error:', error)
            throw error
        } finally {
            setIsLoading(false)
        }
    }, [contract])

    return { mintShare, isLoading }
}

// Hook to get presale and total share valuations
export function useShareValuations() {
    const presaleValuation = useContractCall('get_presale_share_valuation', [], BigInt(0))
    const totalValuation = useContractCall('get_total_share_valuation', [], BigInt(0))

    return { presaleValuation, totalValuation }
}

// Hook to calculate share data for the pie chart
export function useShareData() {
    const { data: availableShares } = useAvailableShares()
    const { data: userShares } = useUserShares()
    const { data: sharesSold } = useSharesSold()
    const { data: shareholders } = useShareholders()

    const totalShares = BigInt(100000000) // 100% in 8 decimal precision
    const teamShares = totalShares - BigInt(availableShares.toString()) - BigInt(sharesSold.toString())

    return useMemo(() => {
        const formatShare = (shares: bigint) => Number(shares) / Number(SHARE_PRECISION)

        return {
            availableShare: formatShare(BigInt(availableShares.toString())),
            userShare: formatShare(BigInt(userShares.toString())),
            soldShare: formatShare(BigInt(sharesSold.toString())),
            teamShare: formatShare(teamShares),
            totalShareholders: Array.isArray(shareholders) ? shareholders.length : 0,
            shareholders: Array.isArray(shareholders) ? shareholders : []
        }
    }, [availableShares, userShares, sharesSold, teamShares, shareholders])
}
