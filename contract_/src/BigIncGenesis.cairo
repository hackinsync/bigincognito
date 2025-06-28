use starknet::ContractAddress;


#[starknet::interface]
trait IBigIncGenesis<TContractState> {
    fn mint_share(ref self: TContractState, token_address: ContractAddress);
    fn transfer_share(ref self: TContractState, to: ContractAddress, share_amount: u256);
    fn donate(ref self: TContractState);
    fn get_available_shares(self: @TContractState) -> u256;
    fn get_shares(self: @TContractState, addr: ContractAddress) -> u256;
    fn get_shareholders(self: @TContractState) -> Array<ContractAddress>;
    fn is_shareholder(self: @TContractState, addr: ContractAddress) -> bool;
    fn get_usdt_address(self: @TContractState) -> ContractAddress;
    fn get_usdc_address(self: @TContractState) -> ContractAddress;
    fn get_total_share_valuation(self: @TContractState) -> u256;
    fn get_presale_share_valuation(self: @TContractState) -> u256;
    fn get_presale_shares(self: @TContractState) -> u256;
    fn get_shares_sold(self: @TContractState) -> u256;
    fn is_presale_active(self: @TContractState) -> bool;

    // Owner functions
    fn withdraw(ref self: TContractState, token_address: ContractAddress, amount: u256);
    fn seize_shares(ref self: TContractState, shareholder: ContractAddress);
    fn pause(ref self: TContractState);
    fn unpause(ref self: TContractState);

    // Ownable functions
    fn owner(self: @TContractState) -> ContractAddress;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress);
    fn renounce_ownership(ref self: TContractState);
}

#[starknet::contract]
mod BigIncGenesis {
    use super::IBigIncGenesis;
    use starknet::{
        ContractAddress, get_caller_address, get_contract_address,
        contract_address_const //call_contract_syscall, CallContractSyscall
    };
    use core::array::ArrayTrait;
    use core::traits::{Into, TryInto};
    use core::option::OptionTrait;
    //use core::integer::BoundedInt;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerWriteAccess,
        StoragePointerReadAccess,
    };
    use openzeppelin_access::ownable::OwnableComponent;

    // use openzeppelin::access::ownable::OwnableComponent;
    // use openzeppelin::security::pausable::PausableComponent;
    // use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    // use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};


    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: ReentrancyGuardComponent, storage: reentrancy_guard, event: ReentrancyGuardEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl OwnableTwoStepMixinImpl = OwnableComponent::OwnableTwoStepMixinImpl<ContractState>;

    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;

    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;



    // #[storage]
    // struct Storage {
    //     owner: ContractAddress,
    //     paused: bool,
    //     // Reentrancy guard
    //     entered: bool,
    //     // Core contract state
    //     is_shareholder_map: Map<ContractAddress, bool>,
    //     usdt_address: ContractAddress,
    //     usdc_address: ContractAddress,
    //     total_share_valuation: u256,
    //     presale_share_valuation: u256,
    //     presale_shares: u256,
    //     shares_sold: u256,
    //     available_shares: u256,
    //     is_presale_active: bool,
    //     // Shareholder data
    //     shareholders: Map<ContractAddress, u256>,
    //     shareholder_addresses: Array<ContractAddress>,
    //     shareholder_count: u32,
    // }

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        reentrancy_guard: ReentrancyGuardComponent::Storage,

        // Core contract state
        is_shareholder_map: LegacyMap<ContractAddress, bool>,
        usdt_address: ContractAddress,
        usdc_address: ContractAddress,
        total_share_valuation: u256,
        presale_share_valuation: u256,
        presale_shares: u256,
        shares_sold: u256,
        available_shares: u256,
        is_presale_active: bool,
        
        // Shareholder data
        shareholders: LegacyMap<ContractAddress, u256>,
        shareholder_addresses: LegacyMap<u32, ContractAddress>,
        shareholder_count: u32,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ShareMinted: ShareMinted,
        PresaleEnded: PresaleEnded,
        TransferShare: TransferShare,
        Donate: Donate,
        SharesSeized: SharesSeized,
        AllSharesSold: AllSharesSold,
        OwnershipTransferred: OwnershipTransferred,
        Paused: Paused,
        Unpaused: Unpaused,
    }

    #[derive(Drop, starknet::Event)]
    struct ShareMinted {
        #[key]
        buyer: ContractAddress,
        shares_bought: u256,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct PresaleEnded {}

    #[derive(Drop, starknet::Event)]
    struct TransferShare {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        share_amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Donate {
        #[key]
        donor: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct SharesSeized {
        #[key]
        shareholder: ContractAddress,
        share_amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct AllSharesSold {}

    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred {
        #[key]
        previous_owner: ContractAddress,
        #[key]
        new_owner: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct Paused {
        account: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct Unpaused {
        account: ContractAddress,
    }


    #[constructor]
    fn constructor(
        ref self: ContractState, usdt_address: ContractAddress, usdc_address: ContractAddress,
    ) {
        let caller = get_caller_address();

        // Initialize ownership
        self.owner.write(caller);

        // Initialize pausable state
        self.paused.write(false);

        // Initialize reentrancy guard
        self.entered.write(false);

        // Set token addresses
        self.usdt_address.write(usdt_address);
        self.usdc_address.write(usdc_address);

        // Initialize share parameters
        self.total_share_valuation.write(680000000000_u256); // 680k with 6 decimals
        self.presale_share_valuation.write(457143000000_u256); // 457k with 6 decimals
        self.presale_shares.write(21000000_u256); // 21% shares
        self.shares_sold.write(0_u256);
        self.available_shares.write(82000000_u256); // 82% available
        self.is_presale_active.write(true);

        // Assign 18% shares to owner
        let owner_shares = 18000000_u256;
        self.shareholders.write(caller, owner_shares);
        self.is_shareholder_map.write(caller, true);

        // Initialize shareholder array with owner
        let mut shareholders_array = ArrayTrait::new();
        shareholders_array.append(caller);
        self.shareholder_addresses.write(shareholders_array);
        self.shareholder_count.write(1);
    }

    // Modifiers implementation
    // impl ModifierHelpers of ModifierHelpersTrait<ContractState> {
    //     fn assert_only_owner(self: @ContractState) {
    //         let caller = get_caller_address();
    //         let owner = self.owner.read();
    //         assert!(caller == owner, "Caller is not the owner");
    //     }

    //     fn assert_not_paused(self: @ContractState) {
    //         let paused = self.paused.read();
    //         assert!(!paused, "Contract is paused");
    //     }

    //     fn assert_valid_token(self: @ContractState, token_address: ContractAddress) {
    //         let usdt = self.usdt_address.read();
    //         let usdc = self.usdc_address.read();
    //         assert!(token_address == usdt || token_address == usdc, "Invalid token address");
    //     }

    //     fn assert_nonreentrant_before(ref self: ContractState) {
    //         let entered = self.entered.read();
    //         assert!(!entered, "ReentrancyGuard: reentrant call");
    //         self.entered.write(true);
    //     }

    //     fn assert_nonreentrant_after(ref self: ContractState) {
    //         self.entered.write(false);
    //     }
    // }
}

