use starknet::ContractAddress;

#[starknet::interface]
pub trait IBigIncGenesis<TContractState> {
    // Core functionality
    fn mint_share(ref self: TContractState, token_address: ContractAddress);
    fn transfer_share(ref self: TContractState, to: ContractAddress, share_amount: u256);
    fn donate(ref self: TContractState, token_address: ContractAddress, amount: u256);

    // View functions
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
    fn set_partner_share_cap(ref self: TContractState, token_address: ContractAddress, cap: u256);
    fn remove_partner_share_cap(ref self: TContractState, token_address: ContractAddress);
    fn pause(ref self: TContractState);
    fn unpause(ref self: TContractState);

    // Partner view functions
    fn get_partner_share_cap(self: @TContractState, token_address: ContractAddress) -> u256;
    fn get_shares_minted_by_partner(self: @TContractState, token_address: ContractAddress) -> u256;

    // Ownable functions
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn transfer_owner(ref self: TContractState, new_owner: ContractAddress);
    fn renounce_owner(ref self: TContractState);

    // Partner token functions
    fn mint_partner_share(
        ref self: TContractState, token_address: ContractAddress, token_amount: u256,
    );
    fn set_partner_token_rate(
        ref self: TContractState, token_address: ContractAddress, tokens_per_share: u256,
    );
    fn get_partner_token_rate(self: @TContractState, token_address: ContractAddress) -> u256;
}

#[starknet::contract]
pub mod BigIncGenesis {
    use core::traits::Into;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};
    use super::IBigIncGenesis;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(
        path: ReentrancyGuardComponent, storage: reentrancy_guard, event: ReentrancyGuardEvent,
    );

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;

    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        reentrancy_guard: ReentrancyGuardComponent::Storage,
        // Token addresses
        usdt_address: ContractAddress,
        usdc_address: ContractAddress,
        // Share economics
        total_share_valuation: u256,
        presale_share_valuation: u256,
        presale_shares: u256,
        shares_sold: u256,
        available_shares: u256,
        is_presale_active: bool,
        // Partner token share caps
        partner_share_cap: Map<ContractAddress, u256>,
        shares_minted_by_partner: Map<ContractAddress, u256>,
        // Shareholder management
        shareholders: Map<ContractAddress, u256>,
        is_shareholder_map: Map<ContractAddress, bool>,
        shareholder_addresses: Map<u32, ContractAddress>,
        shareholder_count: u32,
        // Partner token rates (tokens required for 1 full share)
        partner_token_rates: Map<ContractAddress, u256>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
        ShareMinted: ShareMinted,
        PresaleEnded: PresaleEnded,
        TransferShare: TransferShare,
        Donate: Donate,
        SharesSeized: SharesSeized,
        AllSharesSold: AllSharesSold,
        Withdrawn: Withdrawn,
        PartnerShareCapSet: PartnerShareCapSet,
        PartnerShareMinted: PartnerShareMinted,
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
        token_address: ContractAddress,
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
    struct Withdrawn {
        #[key]
        token_address: ContractAddress,
        amount: u256,
        owner: ContractAddress,
        timestamp: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct PartnerShareCapSet {
        #[key]
        token_address: ContractAddress,
        cap: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct PartnerShareMinted {
        #[key]
        token_address: ContractAddress,
        #[key]
        buyer: ContractAddress,
        amount_paid: u256,
        shares_received: u256,
        rate: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        usdt_address: ContractAddress,
        usdc_address: ContractAddress,
        owner: ContractAddress,
    ) {
        // Initialize components
        self.ownable.initializer(owner);

        // Set token addresses
        self.usdt_address.write(usdt_address);
        self.usdc_address.write(usdc_address);

        // Initialize share parameters
        self.total_share_valuation.write(680000000000_u256); // $680k with 6 decimals
        self.presale_share_valuation.write(457143000000_u256); // $457k with 6 decimals
        self.presale_shares.write(21000000_u256); // 21% shares
        self.shares_sold.write(0_u256);
        self.available_shares.write(82000000_u256); // 82% available after 18% to owner
        self.is_presale_active.write(true);

        // Assign 18% shares to owner
        let owner_shares = 18000000_u256;
        self.shareholders.write(owner, owner_shares);
        self.is_shareholder_map.write(owner, true);
        self.shareholder_addresses.write(0, owner);
        self.shareholder_count.write(1);
    }

    #[abi(embed_v0)]
    impl BigIncGenesisImpl of IBigIncGenesis<ContractState> {
        fn mint_share(ref self: ContractState, token_address: ContractAddress) {
            self.pausable.assert_not_paused();
            self.reentrancy_guard.start();

            self._validate_token(token_address);

            let caller = get_caller_address();
            let contract_address = get_contract_address();

            // Check if all shares are sold
            if self.available_shares.read() == 0 {
                self.emit(AllSharesSold {});
                return;
            }

            let token = IERC20Dispatcher { contract_address: token_address };
            let amount = token.allowance(caller, contract_address);

            assert(amount > 0, 'Amount must be > 0');
            assert(token.balance_of(caller) >= amount, 'Insufficient token balance');

            let current_price = if self.is_presale_active.read() {
                self.presale_share_valuation.read()
            } else {
                self.total_share_valuation.read()
            };

            let shares_bought = (amount * 100000000_u256) / current_price;
            let new_shares_sold = self.shares_sold.read() + shares_bought;

            assert(shares_bought <= self.available_shares.read(), 'Exceeds available shares');

            // Check partner share cap if set
            let partner_cap = self.partner_share_cap.read(token_address);
            if partner_cap > 0 {
                let current_partner_shares = self.shares_minted_by_partner.read(token_address);
                assert(
                    current_partner_shares + shares_bought <= partner_cap,
                    'Exceeds partner share cap',
                );
                self
                    .shares_minted_by_partner
                    .write(token_address, current_partner_shares + shares_bought);
            }

            self.shares_sold.write(new_shares_sold);

            if self.is_presale_active.read() && new_shares_sold >= self.presale_shares.read() {
                self.is_presale_active.write(false);
                self.emit(PresaleEnded {});
            }

            // Add to shareholder if new
            if self.shareholders.read(caller) == 0 {
                let current_count = self.shareholder_count.read();
                self.shareholder_addresses.write(current_count, caller);
                self.shareholder_count.write(current_count + 1);
                self.is_shareholder_map.write(caller, true);
            }

            // Update balances
            let current_shares = self.shareholders.read(caller);
            self.shareholders.write(caller, current_shares + shares_bought);

            let available = self.available_shares.read();
            self.available_shares.write(available - shares_bought);

            // Transfer tokens
            token.transfer_from(caller, contract_address, amount);

            self.emit(ShareMinted { buyer: caller, shares_bought, amount });

            self.reentrancy_guard.end();
        }

        fn transfer_share(ref self: ContractState, to: ContractAddress, share_amount: u256) {
            self.pausable.assert_not_paused();

            let caller = get_caller_address();
            assert(to != 0.try_into().unwrap(), 'Cannot transfer to zero address');

            let sender_shares = self.shareholders.read(caller);
            assert(sender_shares >= share_amount, 'Insufficient shares');

            self.shareholders.write(caller, sender_shares - share_amount);

            let recipient_shares = self.shareholders.read(to);
            self.shareholders.write(to, recipient_shares + share_amount);

            if recipient_shares == 0 {
                let current_count = self.shareholder_count.read();
                self.shareholder_addresses.write(current_count, to);
                self.shareholder_count.write(current_count + 1);
                self.is_shareholder_map.write(to, true);
            }

            if sender_shares == share_amount {
                self.is_shareholder_map.write(caller, false);
                self._remove_shareholder(caller);
            }

            self.emit(TransferShare { from: caller, to, share_amount });
        }

        fn donate(ref self: ContractState, token_address: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            let contract_address = get_contract_address();

            assert(amount > 0, 'Amount must be > 0');
            assert(
                token_address == self.usdt_address.read()
                    || token_address == self.usdc_address.read(),
                'USDC/USDT Only',
            );
            let token = IERC20Dispatcher { contract_address: token_address };

            assert(token.balance_of(caller) >= amount, 'Insufficient balance');
            assert(token.allowance(caller, contract_address) >= amount, 'Insufficient allowance');

            token.transfer_from(caller, contract_address, amount);

            self.emit(Donate { donor: caller, token_address, amount });
        }

        fn withdraw(ref self: ContractState, token_address: ContractAddress, amount: u256) {
            self.ownable.assert_only_owner();
            self.reentrancy_guard.start();

            let token = IERC20Dispatcher { contract_address: token_address };
            let contract_address = get_contract_address();

            assert(token.balance_of(contract_address) >= amount, 'Insufficient balance');

            let owner = self.ownable.owner();
            token.transfer(owner, amount);

            //     Emit Withdrawn event
            let ts: u256 = get_block_timestamp().into();
            self.emit(Event::Withdrawn(Withdrawn { token_address, amount, owner, timestamp: ts }));

            self.reentrancy_guard.end();
        }

        fn seize_shares(ref self: ContractState, shareholder: ContractAddress) {
            self.ownable.assert_only_owner();
            self.pausable.assert_not_paused();

            let shares_to_seize = self.shareholders.read(shareholder);
            assert(shares_to_seize > 0, 'No shares to seize');

            // Transfer shares to owner
            let owner = self.ownable.owner();
            let owner_shares = self.shareholders.read(owner);

            self.shareholders.write(shareholder, 0);
            self.shareholders.write(owner, owner_shares + shares_to_seize);

            // Remove from shareholder list
            self.is_shareholder_map.write(shareholder, false);
            self._remove_shareholder(shareholder);

            self.emit(SharesSeized { shareholder, share_amount: shares_to_seize });
        }

        fn pause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.pause();
        }

        fn unpause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.unpause();
        }

        fn set_partner_share_cap(
            ref self: ContractState, token_address: ContractAddress, cap: u256,
        ) {
            self.ownable.assert_only_owner();
            self._validate_token(token_address);

            self.partner_share_cap.write(token_address, cap);
            self.emit(PartnerShareCapSet { token_address, cap });
        }

        fn remove_partner_share_cap(ref self: ContractState, token_address: ContractAddress) {
            self.ownable.assert_only_owner();
            self._validate_token(token_address);

            self.partner_share_cap.write(token_address, 0);
            self.emit(PartnerShareCapSet { token_address, cap: 0 });
        }

        fn mint_partner_share(
            ref self: ContractState, token_address: ContractAddress, token_amount: u256,
        ) {
            self.pausable.assert_not_paused();
            self.reentrancy_guard.start();

            let caller = get_caller_address();
            let contract_address = get_contract_address();

            // check if all shares are sold
            if self.available_shares.read() == 0 {
                self.emit(AllSharesSold {});
                return;
            }

            let tokens_per_share = self.partner_token_rates.read(token_address);
            assert(tokens_per_share > 0, 'Partner token rate not set');

            assert(token_amount > 0, 'Amount must be > 0');

            let token = IERC20Dispatcher { contract_address: token_address };
            assert(token.balance_of(caller) >= token_amount, 'Insufficient token balance');
            assert(
                token.allowance(caller, contract_address) >= token_amount, 'Insufficient allowance',
            );

            // calculate shares: (tokens_sent * share_precision) / tokens_per_share
            let share_precision = 100000000_u256; // same precision as the `mint_share` function
            let shares_received = (token_amount * share_precision) / tokens_per_share;

            assert(shares_received > 0, 'Shares received must be > 0');
            assert(shares_received <= self.available_shares.read(), 'Exceeds available shares');

            let partner_cap = self.partner_share_cap.read(token_address);
            if partner_cap > 0 {
                let current_partner_shares = self.shares_minted_by_partner.read(token_address);
                assert(
                    current_partner_shares + shares_received <= partner_cap,
                    'Exceeds partner share cap',
                );
                self
                    .shares_minted_by_partner
                    .write(token_address, current_partner_shares + shares_received);
            }

            let new_shares_sold = self.shares_sold.read() + shares_received;
            self.shares_sold.write(new_shares_sold);

            if self.is_presale_active.read() && new_shares_sold >= self.presale_shares.read() {
                self.is_presale_active.write(false);
                self.emit(PresaleEnded {});
            }

            // add to shareholder if new
            if self.shareholders.read(caller) == 0 {
                let current_count = self.shareholder_count.read();
                self.shareholder_addresses.write(current_count, caller);
                self.shareholder_count.write(current_count + 1);
                self.is_shareholder_map.write(caller, true);
            }

            let current_shares = self.shareholders.read(caller);
            self.shareholders.write(caller, current_shares + shares_received);

            let available = self.available_shares.read();
            self.available_shares.write(available - shares_received);

            token.transfer_from(caller, contract_address, token_amount);

            self
                .emit(
                    PartnerShareMinted {
                        token_address,
                        buyer: caller,
                        amount_paid: token_amount,
                        shares_received,
                        rate: tokens_per_share,
                    },
                );

            self.reentrancy_guard.end();
        }

        fn set_partner_token_rate(
            ref self: ContractState, token_address: ContractAddress, tokens_per_share: u256,
        ) {
            self.ownable.assert_only_owner();
            assert(tokens_per_share > 0, 'Rate must be > 0');

            self.partner_token_rates.write(token_address, tokens_per_share);
        }

        // View functions
        fn get_partner_token_rate(self: @ContractState, token_address: ContractAddress) -> u256 {
            self.partner_token_rates.read(token_address)
        }

        fn get_available_shares(self: @ContractState) -> u256 {
            self.available_shares.read()
        }

        fn get_shares(self: @ContractState, addr: ContractAddress) -> u256 {
            self.shareholders.read(addr)
        }

        fn get_shareholders(self: @ContractState) -> Array<ContractAddress> {
            let mut shareholders = ArrayTrait::new();
            let count = self.shareholder_count.read();
            let mut i = 0;

            while i < count {
                let shareholder = self.shareholder_addresses.read(i);
                if self.is_shareholder_map.read(shareholder) {
                    shareholders.append(shareholder);
                }
                i += 1;
            }

            shareholders
        }

        fn is_shareholder(self: @ContractState, addr: ContractAddress) -> bool {
            self.is_shareholder_map.read(addr)
        }

        fn get_usdt_address(self: @ContractState) -> ContractAddress {
            self.usdt_address.read()
        }

        fn get_usdc_address(self: @ContractState) -> ContractAddress {
            self.usdc_address.read()
        }

        fn get_total_share_valuation(self: @ContractState) -> u256 {
            self.total_share_valuation.read()
        }

        fn get_presale_share_valuation(self: @ContractState) -> u256 {
            self.presale_share_valuation.read()
        }

        fn get_presale_shares(self: @ContractState) -> u256 {
            self.presale_shares.read()
        }

        fn get_shares_sold(self: @ContractState) -> u256 {
            self.shares_sold.read()
        }

        fn is_presale_active(self: @ContractState) -> bool {
            self.is_presale_active.read()
        }

        fn get_partner_share_cap(self: @ContractState, token_address: ContractAddress) -> u256 {
            self.partner_share_cap.read(token_address)
        }

        fn get_shares_minted_by_partner(
            self: @ContractState, token_address: ContractAddress,
        ) -> u256 {
            self.shares_minted_by_partner.read(token_address)
        }

        fn get_owner(self: @ContractState) -> ContractAddress {
            self.ownable.owner()
        }

        fn transfer_owner(ref self: ContractState, new_owner: ContractAddress) {
            self.ownable.transfer_ownership(new_owner);
        }

        /// Leaves the contract without an owner, prioritize `transfer_owner` for changes in the
        /// access control
        fn renounce_owner(ref self: ContractState) {
            self.ownable.renounce_ownership();
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _validate_token(self: @ContractState, token_address: ContractAddress) {
            let usdt = self.usdt_address.read();
            let usdc = self.usdc_address.read();
            assert(token_address == usdt || token_address == usdc, 'Invalid token address');
        }

        fn _remove_shareholder(ref self: ContractState, shareholder: ContractAddress) {
            let count = self.shareholder_count.read();
            let mut i = 0;

            while i < count {
                if self.shareholder_addresses.read(i) == shareholder {
                    // Move last element to this position
                    let last_shareholder = self.shareholder_addresses.read(count - 1);
                    self.shareholder_addresses.write(i, last_shareholder);
                    self.shareholder_count.write(count - 1);
                    break;
                }
                i += 1;
            };
        }

        fn _validate_partner_token(self: @ContractState, token_address: ContractAddress) {
            let rate = self.partner_token_rates.read(token_address);
            assert(rate > 0, 'Partner token not configured');
        }
    }
}
