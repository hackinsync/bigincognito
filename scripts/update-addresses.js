import fs from 'fs'
import path from 'path'

// Utility to update contract addresses from deployment
export async function updateContractAddresses() {
    try {
        const deploymentPath = path.join(process.cwd(), 'deployment', 'contracts.json')

        if (!fs.existsSync(deploymentPath)) {
            console.warn('Deployment contracts.json not found. Using default addresses.')
            return
        }

        const deploymentData = JSON.parse(fs.readFileSync(deploymentPath, 'utf8'))

        const configPath = path.join(process.cwd(), 'src', 'lib', 'starknet', 'config.ts')
        let configContent = fs.readFileSync(configPath, 'utf8')

        // Update BigIncGenesis address
        if (deploymentData.contracts?.BigIncGenesis?.address) {
            configContent = configContent.replace(
                /BigIncGenesis: '[^']*'/,
                `BigIncGenesis: '${deploymentData.contracts.BigIncGenesis.address}'`
            )
        }

        // Update MockUSDT address
        if (deploymentData.contracts?.MockUSDT?.address) {
            configContent = configContent.replace(
                /MockUSDT: '[^']*'/,
                `MockUSDT: '${deploymentData.contracts.MockUSDT.address}'`
            )
        }

        // Update MockUSDC address
        if (deploymentData.contracts?.MockUSDC?.address) {
            configContent = configContent.replace(
                /MockUSDC: '[^']*'/,
                `MockUSDC: '${deploymentData.contracts.MockUSDC.address}'`
            )
        }

        fs.writeFileSync(configPath, configContent)
        console.log('✅ Contract addresses updated successfully!')

    } catch (error) {
        console.error('❌ Error updating contract addresses:', error)
    }
}

// Run this when called directly
if (import.meta.url === `file://${process.argv[1]}`) {
    updateContractAddresses()
}
