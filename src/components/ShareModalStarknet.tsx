"use client"
import React, { useState, useEffect } from 'react'
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Button } from "@/components/ui/button"
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Slider } from "@/components/ui/slider"
import { useToast } from '@/components/ui/use-toast'
import { useAccount } from '@starknet-react/core'
import { useUSDTAddress, useUSDCAddress, useMintShare, useShareValuations, usePresaleActive } from '@/lib/starknet/hooks'
import { contractAddresses } from '@/lib/starknet/config'
import { Contract, Provider } from 'starknet'

interface ShareModalStarknetProps {
    totalShare: number
    yourShare?: number
    crypto: string
    onCryptoChange?: (crypto: string) => void
}

const ERC20_ABI = [
    {
        "type": "function",
        "name": "balance_of",
        "inputs": [
            {
                "name": "account",
                "type": "core::starknet::contract_address::ContractAddress"
            }
        ],
        "outputs": [
            {
                "type": "core::integer::u256"
            }
        ],
        "state_mutability": "view"
    },
    {
        "type": "function",
        "name": "allowance",
        "inputs": [
            {
                "name": "owner",
                "type": "core::starknet::contract_address::ContractAddress"
            },
            {
                "name": "spender",
                "type": "core::starknet::contract_address::ContractAddress"
            }
        ],
        "outputs": [
            {
                "type": "core::integer::u256"
            }
        ],
        "state_mutability": "view"
    },
    {
        "type": "function",
        "name": "approve",
        "inputs": [
            {
                "name": "spender",
                "type": "core::starknet::contract_address::ContractAddress"
            },
            {
                "name": "amount",
                "type": "core::integer::u256"
            }
        ],
        "outputs": [
            {
                "type": "core::bool"
            }
        ],
        "state_mutability": "external"
    }
]

export function ShareModalStarknet({ totalShare, yourShare, crypto, onCryptoChange }: ShareModalStarknetProps) {
    const [openModal, setOpenModal] = useState(false)
    const { toast } = useToast()
    const [shareValue, setShareValue] = useState(0)
    const [balance, setBalance] = useState(BigInt(0))
    const [allowance, setAllowance] = useState(BigInt(0))
    const [isApproving, setIsApproving] = useState(false)

    const { address, account } = useAccount()
    const { data: usdtAddress } = useUSDTAddress()
    const { data: usdcAddress } = useUSDCAddress()
    const { data: presaleActive } = usePresaleActive()
    const { presaleValuation, totalValuation } = useShareValuations()
    const { mintShare, isLoading: isMinting } = useMintShare()

    const currentTokenAddress = crypto === "usdt" ? usdtAddress : usdcAddress
    const currentPrice = presaleActive ? presaleValuation.data : totalValuation.data

    // Fetch token balance and allowance
    useEffect(() => {
        if (!address || !currentTokenAddress || currentTokenAddress === '0x0') return

        const fetchTokenData = async () => {
            try {
                const provider = new Provider({ nodeUrl: 'http://localhost:5050' })
                const tokenContract = new Contract(ERC20_ABI, currentTokenAddress, provider)

                const [balanceResult, allowanceResult] = await Promise.all([
                    tokenContract.balance_of(address),
                    tokenContract.allowance(address, contractAddresses.BigIncGenesis)
                ])

                setBalance(BigInt(balanceResult.toString()))
                setAllowance(BigInt(allowanceResult.toString()))
            } catch (error) {
                console.error('Error fetching token data:', error)
            }
        }

        fetchTokenData()
    }, [address, currentTokenAddress])

    const handleApprove = async () => {
        if (!account || !currentTokenAddress || currentTokenAddress === '0x0') {
            toast({
                title: "Error",
                description: "Please connect your wallet and ensure tokens are deployed",
                variant: "destructive"
            })
            return
        }

        try {
            setIsApproving(true)
            const tokenContract = new Contract(ERC20_ABI, currentTokenAddress, account)

            // Approve a large amount (effectively unlimited)
            const maxAmount = BigInt('0xffffffffffffffffffffffffffffffff')

            await tokenContract.invoke('approve', [contractAddresses.BigIncGenesis, maxAmount])

            toast({
                title: "Success",
                description: "Token approval successful! You can now mint shares.",
            })

            // Refresh allowance
            const newAllowance = await tokenContract.allowance(address!, contractAddresses.BigIncGenesis)
            setAllowance(BigInt(newAllowance.toString()))

        } catch (error) {
            console.error('Approval error:', error)
            toast({
                title: "Error",
                description: "Failed to approve tokens. Please try again.",
                variant: "destructive"
            })
        } finally {
            setIsApproving(false)
        }
    }

    const handleMintShares = async () => {
        if (!currentTokenAddress || currentTokenAddress === '0x0') {
            toast({
                title: "Error",
                description: "Please ensure contracts are deployed",
                variant: "destructive"
            })
            return
        }

        if (allowance === BigInt(0)) {
            toast({
                title: "Error",
                description: "Please approve tokens first",
                variant: "destructive"
            })
            return
        }

        try {
            await mintShare(currentTokenAddress)
            toast({
                title: "Success",
                description: "Shares minted successfully!",
            })
            setOpenModal(false)
        } catch (error) {
            console.error('Mint error:', error)
            toast({
                title: "Error",
                description: "Failed to mint shares. Please try again.",
                variant: "destructive"
            })
        }
    }

    const formatBalance = (amount: bigint) => {
        return (Number(amount) / 1000000).toFixed(2) // Assuming 6 decimals
    }

    if (!address) {
        return (
            <Dialog open={openModal} onOpenChange={setOpenModal}>
                <DialogTrigger asChild>
                    <Button variant="outline" className="bg-transparent border-white text-white hover:bg-white hover:text-black">
                        Buy Shares
                    </Button>
                </DialogTrigger>
                <DialogContent className="sm:max-w-[500px] bg-black border-gray-800">
                    <DialogHeader>
                        <DialogTitle className="text-white">Connect Wallet</DialogTitle>
                        <DialogDescription className="text-gray-400">
                            Please connect your Starknet wallet to buy shares.
                        </DialogDescription>
                    </DialogHeader>
                </DialogContent>
            </Dialog>
        )
    }

    return (
        <Dialog open={openModal} onOpenChange={setOpenModal}>
            <DialogTrigger asChild>
                <Button variant="outline" className="bg-transparent border-white text-white hover:bg-white hover:text-black">
                    Buy Shares
                </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-[500px] bg-black border-gray-800">
                <DialogHeader>
                    <DialogTitle className="text-white">Buy BigInc Genesis Shares</DialogTitle>
                    <DialogDescription className="text-gray-400">
                        Purchase shares using USDT or USDC on Starknet
                        {presaleActive && " (Presale Active - Discounted Price!)"}
                    </DialogDescription>
                </DialogHeader>

                <div className="space-y-6 py-4">
                    {/* Token Selection */}
                    <div className="space-y-2">
                        <Label className="text-white">Select Token</Label>
                        <RadioGroup
                            value={crypto}
                            onValueChange={onCryptoChange}
                            className="flex space-x-6"
                        >
                            <div className="flex items-center space-x-2">
                                <RadioGroupItem value="usdt" id="usdt" />
                                <Label htmlFor="usdt" className="text-white">USDT</Label>
                            </div>
                            <div className="flex items-center space-x-2">
                                <RadioGroupItem value="usdc" id="usdc" />
                                <Label htmlFor="usdc" className="text-white">USDC</Label>
                            </div>
                        </RadioGroup>
                    </div>

                    {/* Balance Display */}
                    <div className="space-y-2">
                        <Label className="text-white">Your Balance</Label>
                        <div className="text-gray-300">
                            {formatBalance(balance)} {crypto.toUpperCase()}
                        </div>
                    </div>

                    {/* Share Value Input */}
                    <div className="space-y-2">
                        <Label htmlFor="shareValue" className="text-white">
                            Share Amount (%)
                        </Label>
                        <Input
                            id="shareValue"
                            type="number"
                            value={shareValue}
                            onChange={(e) => setShareValue(Number(e.target.value))}
                            className="bg-gray-900 border-gray-700 text-white"
                            placeholder="Enter share percentage"
                            min="0"
                            max="100"
                            step="0.01"
                        />
                        <Slider
                            value={[shareValue]}
                            onValueChange={(value) => setShareValue(value[0])}
                            max={100}
                            step={0.01}
                            className="w-full"
                        />
                    </div>

                    {/* Price Calculation */}
                    {currentPrice && shareValue > 0 && (
                        <div className="space-y-2">
                            <Label className="text-white">Cost</Label>
                            <div className="text-gray-300">
                                {((Number(currentPrice) * shareValue) / 100000000 / 1000000).toFixed(2)} {crypto.toUpperCase()}
                            </div>
                        </div>
                    )}

                    {/* Action Buttons */}
                    <div className="flex flex-col space-y-3">
                        {allowance === BigInt(0) ? (
                            <Button
                                onClick={handleApprove}
                                disabled={isApproving}
                                className="w-full bg-blue-600 hover:bg-blue-700"
                            >
                                {isApproving ? 'Approving...' : `Approve ${crypto.toUpperCase()}`}
                            </Button>
                        ) : (
                            <Button
                                onClick={handleMintShares}
                                disabled={isMinting || shareValue <= 0}
                                className="w-full bg-green-600 hover:bg-green-700"
                            >
                                {isMinting ? 'Minting...' : 'Buy Shares'}
                            </Button>
                        )}
                    </div>

                    {/* Contract Status */}
                    <div className="text-xs text-gray-500 space-y-1">
                        <div>BigInc Contract: {contractAddresses.BigIncGenesis.slice(0, 10)}...</div>
                        <div>{crypto.toUpperCase()} Token: {currentTokenAddress?.slice(0, 10)}...</div>
                        <div>Presale: {presaleActive ? 'Active' : 'Inactive'}</div>
                    </div>
                </div>
            </DialogContent>
        </Dialog>
    )
}
