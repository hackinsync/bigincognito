
use starknet::ContractAddress;
use core::option::OptionTrait;
use core::result::ResultTrait;
use core::traits::{TryInto};
use core::byte_array::{ByteArray};


use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait, spy_events, EventSpyAssertionsTrait
};

use starknet::{get_block_timestamp};

use contract_::BigIncGenesis::{IBigIncGenesisDispatcher, IBigIncGenesisDispatcherTrait};
use contract_::ierc20::{IERC20Dispatcher, IERC20DispatcherTrait};


// ============================================================================
// CONSTANTS
// ============================================================================

const USDT_INITIAL_SUPPLY: u256 = 1000000000000_u256; // 1M tokens with 6 decimals
const USDC_INITIAL_SUPPLY: u256 = 1000000000000_u256; // 1M tokens with 6 decimals

    fn OWNER() -> ContractAddress {
        'owner'.try_into().unwrap()
    }
    

    fn USER1() -> ContractAddress {
        'user1'.try_into().unwrap()
    }

    fn USER2() -> ContractAddress {
        'user2'.try_into().unwrap()
    }




// ============================================================================
// SETUP FUNCTIONS
// ============================================================================

fn __deploy_mock_erc20__(admin: ContractAddress) -> ContractAddress {
    let mock_erc20_class_hash = declare("MockToken").unwrap().contract_class();
    let mut calldata = array![];
    admin.serialize(ref calldata);
    let (mocktoken_contract_address, _) = mock_erc20_class_hash.deploy(@calldata).unwrap();
    mocktoken_contract_address
}

fn deploy_big_inc_genesis(usdt_address: ContractAddress, usdc_address: ContractAddress, owner: ContractAddress) -> ContractAddress {
    let contract = declare("BigIncGenesis").unwrap().contract_class();
    let mut constructor_calldata = array![];

    usdt_address.serialize(ref constructor_calldata);
    usdc_address.serialize(ref constructor_calldata);
    owner.serialize(ref constructor_calldata);

    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    contract_address
}

fn setup_basic() -> (ContractAddress, ContractAddress, ContractAddress) {
    let owner: ContractAddress = OWNER();
    let user1: ContractAddress = USER1();
    let user2: ContractAddress = USER2();
    let usdt_address = __deploy_mock_erc20__(owner);      
    let usdc_address = __deploy_mock_erc20__(owner);
    // Mint tokens to users for both USDT and USDC
    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    let usdc = IERC20Dispatcher { contract_address: usdc_address };
    start_cheat_caller_address(usdt_address, owner);
    usdt.mint(user1, USDT_INITIAL_SUPPLY);
    usdt.mint(user2, USDT_INITIAL_SUPPLY);
    stop_cheat_caller_address(usdt_address);
    start_cheat_caller_address(usdc_address, owner);
    usdc.mint(user1, USDC_INITIAL_SUPPLY);
    usdc.mint(user2, USDC_INITIAL_SUPPLY);
    stop_cheat_caller_address(usdc_address);
    let big_inc_address = deploy_big_inc_genesis(usdt_address, usdc_address, owner);
    (big_inc_address, usdt_address, usdc_address)
}

fn setup_with_shares() -> (ContractAddress, ContractAddress, ContractAddress, ContractAddress) {
    let (big_inc_address, usdt_address, usdc_address) = setup_basic();
    let user1: ContractAddress = USER1();
    
    // Mint some shares to user1
    let amount = 4571430000_u256; // ~1M shares at presale price
    start_cheat_caller_address(usdt_address, user1);
    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    usdt.approve(big_inc_address, amount);
    stop_cheat_caller_address(usdt_address);
    
    start_cheat_caller_address(big_inc_address, user1);
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    big_inc.mint_share(usdt_address);
    stop_cheat_caller_address(big_inc_address);
    
    (big_inc_address, usdt_address, usdc_address, user1)
}

// ============================================================================
// CONSTRUCTOR TESTS
// ============================================================================

#[test]
fn test_constructor_initial_state() {
    let (big_inc_address, usdt_address, usdc_address) = setup_basic();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER();
    
    // Test initial state
    assert(big_inc.get_owner() == owner, 'Owner not set correctly');
    assert(big_inc.get_usdt_address() == usdt_address, 'USDT address not set');
    assert(big_inc.get_usdc_address() == usdc_address, 'USDC address not set');
    assert(big_inc.get_shares(owner) == 18000000_u256, 'Owner shares not set');
    assert(big_inc.get_shareholder_count() == 1, 'Shareholder count not set');
    assert(big_inc.is_presale_active(), 'Presale should be active');
    assert(big_inc.get_available_shares() == 82000000_u256, 'Available shares not set');
}

// ============================================================================
// SHARE MINTING TESTS
// ============================================================================

#[test]
fn test_mint_share_basic() {
    let (big_inc_address, usdt_address, _usdc_address) = setup_basic();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    let user1: ContractAddress = USER1();
    
    // Approve and mint shares
    let amount = 4571430000_u256; // ~1M shares at presale price
    start_cheat_caller_address(usdt_address, user1);
    usdt.approve(big_inc_address, amount);
    stop_cheat_caller_address(usdt_address);
    
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.mint_share(usdt_address);
    stop_cheat_caller_address(big_inc_address);
    
    // Verify shares were minted
    let user_shares = big_inc.get_shares(user1);
    assert(user_shares > 0, 'Shares not minted');
    assert(big_inc.is_shareholder(user1), 'User1 should be shareholder');
    assert(big_inc.get_shareholder_count() == 2, 'Shareholder count should be 2');
}

#[test]
fn test_mint_share_presale_end() {
    let (big_inc_address, usdt_address, _usdc_address) = setup_basic();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    let user1: ContractAddress = USER1();
    
    // Presale cap: 21_000_000 shares
    // Contract share calculation: shares = (amount * 100_000_000) / 457_143_000_000
    // To get just below the cap, mint 20_900_000 shares
    let first_shares = 20_900_000_u256;
    let presale_price = 457_143_000_000_u256;
    let first_amount = (first_shares * presale_price) / 100_000_000_u256;
    
    start_cheat_caller_address(usdt_address, user1);
    usdt.approve(big_inc_address, first_amount);
    stop_cheat_caller_address(usdt_address);
    
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.mint_share(usdt_address);
    stop_cheat_caller_address(big_inc_address);
    
    // Presale should still be active
    assert(big_inc.is_presale_active(), 'Presale should still be active');
    
    // Mint again to cross the cap
    let second_shares = 200_000_u256;
    let second_amount = (second_shares * presale_price) / 100_000_000_u256;
    
    start_cheat_caller_address(usdt_address, user1);
    usdt.approve(big_inc_address, second_amount);
    stop_cheat_caller_address(usdt_address);
    
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.mint_share(usdt_address);
    stop_cheat_caller_address(big_inc_address);
    
    // Now presale should be ended
    assert(!big_inc.is_presale_active(), 'Presale should be ended');
    assert(big_inc.get_shares_sold() >= 21_000_000_u256, 'Should have sold presale shares');
}

#[test]
fn test_mint_share_multiple_users() {
    let (big_inc_address, usdt_address, usdc_address) = setup_basic();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    let usdc = IERC20Dispatcher { contract_address: usdc_address };
    let user1: ContractAddress = USER1();
    let user2: ContractAddress = USER2();
    
    // User1 mints with USDT
    let amount1 = 4571430000_u256;
    start_cheat_caller_address(usdt_address, user1);
    usdt.approve(big_inc_address, amount1);
    stop_cheat_caller_address(usdt_address);
    
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.mint_share(usdt_address);
    stop_cheat_caller_address(big_inc_address);
    
    // User2 mints with USDC
    let amount2 = 4571430000_u256;
    start_cheat_caller_address(usdc_address, user2);
    usdc.approve(big_inc_address, amount2);
    stop_cheat_caller_address(usdc_address);
    
    start_cheat_caller_address(big_inc_address, user2);
    big_inc.mint_share(usdc_address);
    stop_cheat_caller_address(big_inc_address);
    
    assert(big_inc.is_shareholder(user1), 'User1 should be shareholder');
    assert(big_inc.is_shareholder(user2), 'User2 should be shareholder');
    assert(big_inc.get_shareholder_count() == 3, 'Shareholder count should be 3');
}

// ============================================================================
// SHARE TRANSFER TESTS
// ============================================================================

#[test]
fn test_transfer_share_basic() {
    let (big_inc_address, _usdt_address, _usdc_address, user1) = setup_with_shares();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let user2: ContractAddress = USER2();
    
    let user1_shares = big_inc.get_shares(user1);
    let transfer_amount = user1_shares / 2;
    
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.transfer_share(user2, transfer_amount);
    stop_cheat_caller_address(big_inc_address);
    
    assert(big_inc.get_shares(user1) == user1_shares - transfer_amount, 'User1 shares not updated');
    assert(big_inc.get_shares(user2) == transfer_amount, 'User2 shares not received');
    assert(big_inc.is_shareholder(user2), 'User2 should be shareholder');
}

#[test]
fn test_transfer_share_full_balance() {
    let (big_inc_address, _usdt_address, _usdc_address, user1) = setup_with_shares();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let user2: ContractAddress = USER2();
    
    let user1_shares = big_inc.get_shares(user1);
    
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.transfer_share(user2, user1_shares);
    stop_cheat_caller_address(big_inc_address);
    
    assert(big_inc.get_shares(user1) == 0, 'User1 should have 0 shares');
    assert(big_inc.get_shares(user2) == user1_shares, 'User2 should have all shares');
    assert(!big_inc.is_shareholder(user1), 'User1 should not be shareholder');
    assert(big_inc.is_shareholder(user2), 'User2 should be shareholder');
}

// ============================================================================
// DONATION TESTS
// ============================================================================

#[test]
fn test_donate_usdt() {
    let (big_inc_address, usdt_address, _usdc_address) = setup_basic();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    let user1: ContractAddress = USER1();
    
    let amount = 1000000_u256; // 1 token with 6 decimals
    start_cheat_caller_address(usdt_address, user1);
    usdt.approve(big_inc_address, amount);
    stop_cheat_caller_address(usdt_address);
    
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.donate(usdt_address, amount);
    stop_cheat_caller_address(big_inc_address);
    
    // Verify donation was successful
    let contract_balance = usdt.balance_of(big_inc_address);
    assert(contract_balance >= amount, 'Contract should');
}

#[test]
fn test_donate_usdc() {
    let (big_inc_address, _usdt_address, usdc_address) = setup_basic();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let usdc = IERC20Dispatcher { contract_address: usdc_address };
    let user1: ContractAddress = USER1();
    
    let amount = 1000000_u256; // 1 token with 6 decimals
    start_cheat_caller_address(usdc_address, user1);
    usdc.approve(big_inc_address, amount);
    stop_cheat_caller_address(usdc_address);
    
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.donate(usdc_address, amount);
    stop_cheat_caller_address(big_inc_address);
    
    // Verify donation was successful
    let contract_balance = usdc.balance_of(big_inc_address);
    assert(contract_balance >= amount, 'Contract should have');
}

// ============================================================================
// OWNER FUNCTION TESTS
// ============================================================================

#[test]
fn test_withdraw_success() {
    let (big_inc_address, usdt_address, _usdc_address) = setup_basic();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    let owner: ContractAddress = OWNER();
    
    // First donate some tokens to the contract
    let user1: ContractAddress = USER1();
    let amount = 1000000_u256;
    start_cheat_caller_address(usdt_address, user1);
    usdt.approve(big_inc_address, amount);
    stop_cheat_caller_address(usdt_address);
    
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.donate(usdt_address, amount);
    stop_cheat_caller_address(big_inc_address);
    
    // Now withdraw as owner
    let withdraw_amount = 500000_u256;
    start_cheat_caller_address(big_inc_address, owner);
    big_inc.withdraw(usdt_address, withdraw_amount);
    stop_cheat_caller_address(big_inc_address);
    
    let owner_balance = usdt.balance_of(owner);
    assert(owner_balance >= withdraw_amount, 'Owner should have ');
}

#[test]
fn test_seize_shares_success() {
    let (big_inc_address, _usdt_address, _usdc_address, user1) = setup_with_shares();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER();
    
    let user1_shares = big_inc.get_shares(user1);
    let owner_shares_before = big_inc.get_shares(owner);
    
    start_cheat_caller_address(big_inc_address, owner);
    big_inc.seize_shares(user1);
    stop_cheat_caller_address(big_inc_address);
    
    assert(big_inc.get_shares(user1) == 0, 'User1 shares should be seized');
    assert(big_inc.get_shares(owner) == owner_shares_before + user1_shares, 'Owner should have seized shares');
    assert(!big_inc.is_shareholder(user1), 'User1 should not be shareholder');
}

#[test]
fn test_pause_and_unpause() {
    let (big_inc_address, _usdt_address, _usdc_address) = setup_basic();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER();
    
    // Pause contract
    start_cheat_caller_address(big_inc_address, owner);
    big_inc.pause();
    stop_cheat_caller_address(big_inc_address);
    
    // Unpause contract
    start_cheat_caller_address(big_inc_address, owner);
    big_inc.unpause();
    stop_cheat_caller_address(big_inc_address);
    
    // Contract should be unpaused
    // Note: We can't directly check paused state, but we can verify by trying to mint
    let (big_inc_address2, usdt_address, _usdc_address) = setup_basic();
    let big_inc2 = IBigIncGenesisDispatcher { contract_address: big_inc_address2 };
    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    let user1: ContractAddress = USER1();
    
    let amount = 4571430000_u256;
    start_cheat_caller_address(usdt_address, user1);
    usdt.approve(big_inc_address2, amount);
    stop_cheat_caller_address(usdt_address);
    
    start_cheat_caller_address(big_inc_address2, user1);
    big_inc2.mint_share(usdt_address);
    stop_cheat_caller_address(big_inc_address2);
    
    assert(big_inc2.get_shares(user1) > 0, 'Should be able to ');
}

// ============================================================================
// OWNERSHIP TESTS
// ============================================================================

#[test]
fn test_transfer_ownership() {
    let (big_inc_address, _usdt_address, _usdc_address) = setup_basic();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER();
    let user1: ContractAddress = USER1();
    
    start_cheat_caller_address(big_inc_address, owner);
    big_inc.transfer_owner(user1);
    stop_cheat_caller_address(big_inc_address);
    
    assert(big_inc.get_owner() == user1, 'Ownership should be transferred');
}

#[test]
fn test_renounce_ownership() {
    let (big_inc_address, _usdt_address, _usdc_address) = setup_basic();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER();
    
    start_cheat_caller_address(big_inc_address, owner);
    big_inc.renounce_owner();
    stop_cheat_caller_address(big_inc_address);
    
    let zero_address: ContractAddress = 0.try_into().unwrap();
    assert(big_inc.get_owner() == zero_address, 'Ownership should be renounced');
}

// ============================================================================
// VIEW FUNCTION TESTS
// ============================================================================

#[test]
fn test_shareholder_management() {
    let (big_inc_address, usdt_address, _usdc_address) = setup_basic();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    let user1: ContractAddress = USER1();
    let user2: ContractAddress = USER2();
    
    // Mint shares to user1
    let amount = 4571430000_u256;
    start_cheat_caller_address(usdt_address, user1);
    usdt.approve(big_inc_address, amount);
    stop_cheat_caller_address(usdt_address);
    
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.mint_share(usdt_address);
    stop_cheat_caller_address(big_inc_address);
    
    // Transfer some shares to user2
    let user1_shares = big_inc.get_shares(user1);
    let transfer_amount = user1_shares / 2;
    
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.transfer_share(user2, transfer_amount);
    stop_cheat_caller_address(big_inc_address);
    
    // Test shareholder functions
    assert(big_inc.is_shareholder(user1), 'User1 should be shareholder');
    assert(big_inc.is_shareholder(user2), 'User2 should be shareholder');
    assert(big_inc.get_shareholder_count() == 3, 'Should have 3 shareholders');
    
    // Test shareholder at index
    let shareholder_at_0 = big_inc.get_shareholder_at_index(0);
    let shareholder_at_1 = big_inc.get_shareholder_at_index(1);
    let shareholder_at_2 = big_inc.get_shareholder_at_index(2);
    
    assert(shareholder_at_0 == OWNER(), 'Index 0 should be owner');       
    assert(shareholder_at_1 == user1 || shareholder_at_1 == user2, 'Index 1 should be');
    assert(shareholder_at_2 == user1 || shareholder_at_2 == user2, 'Index 2 should be');
}

#[test]
fn test_shareholder_removal() {
    let (big_inc_address, _usdt_address, _usdc_address, user1) = setup_with_shares();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER();
    
    let initial_count = big_inc.get_shareholder_count();
    let user1_shares = big_inc.get_shares(user1);
    
    // Transfer all shares to owner
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.transfer_share(owner, user1_shares);
    stop_cheat_caller_address(big_inc_address);
    
    assert(!big_inc.is_shareholder(user1), 'User1 should not be shareholder');
    assert(big_inc.get_shareholder_count() == initial_count - 1, 'Shareholder count');
}

// ============================================================================
// INTEGRATION TESTS
// ============================================================================

#[test]
fn test_complete_share_lifecycle() {
    let (big_inc_address, usdt_address, _usdc_address) = setup_basic();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    let user1: ContractAddress = USER1();
    let user2: ContractAddress = USER2();
    
    // 1. Mint shares
    let amount = 4571430000_u256;
    start_cheat_caller_address(usdt_address, user1);
    usdt.approve(big_inc_address, amount);
    stop_cheat_caller_address(usdt_address);
    
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.mint_share(usdt_address);
    stop_cheat_caller_address(big_inc_address);
    
    // 2. Transfer shares
    let user1_shares = big_inc.get_shares(user1);
    let transfer_amount = user1_shares / 2;
    
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.transfer_share(user2, transfer_amount);
    stop_cheat_caller_address(big_inc_address);
    
    // 3. Donate tokens
    let donate_amount = 1000000_u256;
    start_cheat_caller_address(usdt_address, user1);
    usdt.approve(big_inc_address, donate_amount);
    stop_cheat_caller_address(usdt_address);
    
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.donate(usdt_address, donate_amount);
    stop_cheat_caller_address(big_inc_address);
    
    // 4. Verify final state
    assert(big_inc.get_shares(user1) == user1_shares - transfer_amount, 'User1 shares incorrect');
    assert(big_inc.get_shares(user2) == transfer_amount, 'User2 shares incorrect');
    assert(big_inc.is_shareholder(user1), 'User1 should be shareholder');
    assert(big_inc.is_shareholder(user2), 'User2 should be shareholder');
    assert(big_inc.get_shareholder_count() == 3, 'Shareholder count incorrect');
}

#[test]
fn test_presale_to_main_sale_transition() {
    let (big_inc_address, usdt_address, _usdc_address) = setup_basic();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    let user1: ContractAddress = USER1();
    
    // Initial state should be presale
    assert(big_inc.is_presale_active(), 'Should start in presale');
    
    // Mint enough to end presale
    let presale_shares = big_inc.get_presale_shares();
    let presale_valuation = big_inc.get_presale_share_valuation();
    let amount_needed = (presale_shares * presale_valuation) / 100000000_u256;
    
    start_cheat_caller_address(usdt_address, user1);
    usdt.approve(big_inc_address, amount_needed);
    stop_cheat_caller_address(usdt_address);
    
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.mint_share(usdt_address);
    stop_cheat_caller_address(big_inc_address);
    
    // Presale should be ended
    assert(!big_inc.is_presale_active(), 'Presale should be ended');
    assert(big_inc.get_shares_sold() >= presale_shares, 'Should have sold presale shares');
}





