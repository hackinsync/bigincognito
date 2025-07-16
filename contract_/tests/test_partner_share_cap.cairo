use contract_::BigIncGenesis::{IBigIncGenesisDispatcher, IBigIncGenesisDispatcherTrait};
use core::result::ResultTrait;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::{ContractAddress, contract_address_const};

const OWNER: felt252 = 'owner';
const USER1: felt252 = 'user1';
const USER2: felt252 = 'user2';
const USDT_INITIAL_SUPPLY: u256 = 1000000000000_u256; // 1M USDT with 6 decimals
const USDC_INITIAL_SUPPLY: u256 = 1000000000000_u256; // 1M USDC with 6 decimals

fn deploy_mock_erc20(
    name: felt252, symbol: felt252, initial_supply: u256, recipient: ContractAddress,
) -> ContractAddress {
    let contract = declare("MockERC20").unwrap().contract_class();
    let (contract_address, _) = contract
        .deploy(
            @array![
                initial_supply.low.into(),
                initial_supply.high.into(),
                recipient.into(),
                // ByteArray name - simple felt252 approach
                0, // data length
                name, // pending word
                4, // pending word length
                // ByteArray symbol - simple felt252 approach
                0, // data length
                symbol, // pending word
                4, // pending word length
                6, // decimals
                contract_address_const::<OWNER>().into(),
            ],
        )
        .unwrap();
    contract_address
}

fn deploy_big_inc_genesis(
    usdt_address: ContractAddress, usdc_address: ContractAddress,
) -> ContractAddress {
    let contract = declare("BigIncGenesis").unwrap().contract_class();
    let (contract_address, _) = contract
        .deploy(
            @array![
                usdt_address.into(), usdc_address.into(), contract_address_const::<OWNER>().into(),
            ],
        )
        .unwrap();
    contract_address
}

fn setup() -> (ContractAddress, ContractAddress, ContractAddress) {
    let user1 = contract_address_const::<USER1>();
    let usdt_address = deploy_mock_erc20('USDT', 'USDT', USDT_INITIAL_SUPPLY, user1);
    let usdc_address = deploy_mock_erc20('USDC', 'USDC', USDC_INITIAL_SUPPLY, user1);
    let big_inc_address = deploy_big_inc_genesis(usdt_address, usdc_address);

    (big_inc_address, usdt_address, usdc_address)
}

fn test_set_partner_share_cap_success() {
    let (big_inc_address, usdt_address, _usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner = contract_address_const::<OWNER>();

    // Set partner share cap as owner
    start_cheat_caller_address(big_inc_address, owner);
    big_inc.set_partner_share_cap(usdt_address, 10000000_u256); // 10M shares cap
    stop_cheat_caller_address(big_inc_address);

    // Verify the cap was set
    let cap = big_inc.get_partner_share_cap(usdt_address);
    assert(cap == 10000000_u256, 'Partner cap not set correctly');
}

fn test_set_partner_share_cap_not_owner() {
    let (big_inc_address, usdt_address, _usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let user1 = contract_address_const::<USER1>();

    // Try to set partner share cap as non-owner
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.set_partner_share_cap(usdt_address, 10000000_u256);
    stop_cheat_caller_address(big_inc_address);
}

fn test_set_partner_share_cap_invalid_token() {
    let (big_inc_address, _usdt_address, _usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner = contract_address_const::<OWNER>();
    let invalid_token = contract_address_const::<'invalid_token'>();

    // Try to set partner share cap for invalid token
    start_cheat_caller_address(big_inc_address, owner);
    big_inc.set_partner_share_cap(invalid_token, 10000000_u256);
    stop_cheat_caller_address(big_inc_address);
}

fn test_remove_partner_share_cap_success() {
    let (big_inc_address, usdt_address, _usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner = contract_address_const::<OWNER>();

    // Set partner share cap first
    start_cheat_caller_address(big_inc_address, owner);
    big_inc.set_partner_share_cap(usdt_address, 10000000_u256);
    let cap_before = big_inc.get_partner_share_cap(usdt_address);
    assert(cap_before == 10000000_u256, 'Cap should be set');

    // Remove partner share cap
    big_inc.remove_partner_share_cap(usdt_address);
    stop_cheat_caller_address(big_inc_address);

    // Verify the cap was removed
    let cap_after = big_inc.get_partner_share_cap(usdt_address);
    assert(cap_after == 0_u256, 'Partner cap not removed');
}

fn test_remove_partner_share_cap_not_owner() {
    let (big_inc_address, usdt_address, _usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let user1 = contract_address_const::<USER1>();

    // Try to remove partner share cap as non-owner
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.remove_partner_share_cap(usdt_address);
    stop_cheat_caller_address(big_inc_address);
}

fn test_get_partner_share_cap_default_zero() {
    let (big_inc_address, usdt_address, usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };

    // Check default cap is zero
    let usdt_cap = big_inc.get_partner_share_cap(usdt_address);
    let usdc_cap = big_inc.get_partner_share_cap(usdc_address);

    assert(usdt_cap == 0_u256, 'Default USDT cap should be 0');
    assert(usdc_cap == 0_u256, 'Default USDC cap should be 0');
}

fn test_get_shares_minted_by_partner_default_zero() {
    let (big_inc_address, usdt_address, usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };

    // Check default shares minted is zero
    let usdt_shares = big_inc.get_shares_minted_by_partner(usdt_address);
    let usdc_shares = big_inc.get_shares_minted_by_partner(usdc_address);

    assert(usdt_shares == 0_u256, 'Default USDT shares should be 0');
    assert(usdc_shares == 0_u256, 'Default USDC shares should be 0');
}

fn test_mint_share_respects_partner_cap() {
    let (big_inc_address, usdt_address, _usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    let owner = contract_address_const::<OWNER>();
    let user1 = contract_address_const::<USER1>();

    // Set partner share cap
    start_cheat_caller_address(big_inc_address, owner);
    big_inc.set_partner_share_cap(usdt_address, 5000000_u256); // 5M shares cap
    stop_cheat_caller_address(big_inc_address);

    // Approve and mint shares within cap - small amount for 1M shares
    let amount = 4571430000_u256; // Amount for ~1M shares at presale price (1M * 457143 / 100)
    start_cheat_caller_address(usdt_address, user1);
    usdt.approve(big_inc_address, amount);
    stop_cheat_caller_address(usdt_address);

    start_cheat_caller_address(big_inc_address, user1);
    big_inc.mint_share(usdt_address);
    stop_cheat_caller_address(big_inc_address);

    // Verify shares were minted
    let shares_minted = big_inc.get_shares_minted_by_partner(usdt_address);
    assert(shares_minted > 0, 'Shares should be minted');
    assert(shares_minted <= 5000000_u256, 'Should not exceed cap');
}

fn test_mint_share_exceeds_partner_cap() {
    let (big_inc_address, usdt_address, _usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    let owner = contract_address_const::<OWNER>();
    let user1 = contract_address_const::<USER1>();

    // Set low partner share cap
    start_cheat_caller_address(big_inc_address, owner);
    big_inc.set_partner_share_cap(usdt_address, 500000_u256); // 500K shares cap
    stop_cheat_caller_address(big_inc_address);

    // Try to mint more shares than cap allows - 1M shares
    let amount = 4571430000_u256; // Amount for ~1M shares at presale price  
    start_cheat_caller_address(usdt_address, user1);
    usdt.approve(big_inc_address, amount);
    stop_cheat_caller_address(usdt_address);

    start_cheat_caller_address(big_inc_address, user1);
    big_inc.mint_share(usdt_address);
    stop_cheat_caller_address(big_inc_address);
}

fn test_mint_share_without_partner_cap_works() {
    let (big_inc_address, usdt_address, _usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    let user1 = contract_address_const::<USER1>();

    // No partner cap set (should be 0)
    let cap = big_inc.get_partner_share_cap(usdt_address);
    assert(cap == 0_u256, 'Cap should be 0 by default');

    // Should be able to mint shares without cap restriction - small amount for 1M shares
    let amount = 4571430000_u256; // Amount for ~1M shares at presale price
    start_cheat_caller_address(usdt_address, user1);
    usdt.approve(big_inc_address, amount);
    stop_cheat_caller_address(usdt_address);

    start_cheat_caller_address(big_inc_address, user1);
    big_inc.mint_share(usdt_address);
    stop_cheat_caller_address(big_inc_address);

    // Verify shares were minted
    let user_shares = big_inc.get_shares(user1);
    assert(user_shares > 0, 'Shares should be minted');
}

fn test_partner_cap_separate_for_different_tokens() {
    let (big_inc_address, usdt_address, usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner = contract_address_const::<OWNER>();

    // Set different caps for different tokens
    start_cheat_caller_address(big_inc_address, owner);
    big_inc.set_partner_share_cap(usdt_address, 5000000_u256); // 5M shares cap for USDT
    big_inc.set_partner_share_cap(usdc_address, 7000000_u256); // 7M shares cap for USDC
    stop_cheat_caller_address(big_inc_address);

    // Verify caps are set correctly
    let usdt_cap = big_inc.get_partner_share_cap(usdt_address);
    let usdc_cap = big_inc.get_partner_share_cap(usdc_address);

    assert(usdt_cap == 5000000_u256, 'USDT cap incorrect');
    assert(usdc_cap == 7000000_u256, 'USDC cap incorrect');

    // Verify shares minted are tracked separately
    let usdt_shares = big_inc.get_shares_minted_by_partner(usdt_address);
    let usdc_shares = big_inc.get_shares_minted_by_partner(usdc_address);

    assert(usdt_shares == 0_u256, 'USDT shares should be 0');
    assert(usdc_shares == 0_u256, 'USDC shares should be 0');
}

fn test_partner_cap_update_overrides_previous() {
    let (big_inc_address, usdt_address, _usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner = contract_address_const::<OWNER>();

    // Set initial cap
    start_cheat_caller_address(big_inc_address, owner);
    big_inc.set_partner_share_cap(usdt_address, 5000000_u256);
    let initial_cap = big_inc.get_partner_share_cap(usdt_address);
    assert(initial_cap == 5000000_u256, 'Initial cap not set');

    // Update cap
    big_inc.set_partner_share_cap(usdt_address, 8000000_u256);
    let updated_cap = big_inc.get_partner_share_cap(usdt_address);
    assert(updated_cap == 8000000_u256, 'Cap not updated');

    stop_cheat_caller_address(big_inc_address);
}
