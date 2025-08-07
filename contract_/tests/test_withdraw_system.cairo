use contract_::BigIncGenesis::{
    IBigIncGenesisDispatcher, IBigIncGenesisDispatcherTrait, VoteStatus, WithdrawalRequest,
};
use contract_::MockERC20::{IMockERC20Dispatcher, IMockERC20DispatcherTrait};
use core::traits::Into;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpy, EventSpyAssertionsTrait, declare,
    get_class_hash, spy_events, start_cheat_block_number, start_cheat_block_timestamp,
    start_cheat_caller_address, stop_cheat_block_number, stop_cheat_block_timestamp,
    stop_cheat_caller_address,
};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};

const INITIAL_SUPPLY: u256 = 1000000_000000; // 1M tokens with 6 decimals
const OWNER: felt252 = 0x1;
const ALICE: felt252 = 0x2;
const BOB: felt252 = 0x3;
const CHARLIE: felt252 = 0x4;
const SECONDS_PER_DAY: u64 = 86400; // 24 * 60 * 60

fn deploy_mock_erc20(initial_supply: u256, recipient: ContractAddress) -> ContractAddress {
    let contract = declare("MockERC20").unwrap().contract_class();
    let constructor_calldata = array![
        initial_supply.low.into(), initial_supply.high.into(), recipient.into(),
    ];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    contract_address
}

fn deploy_contract_with_tokens() -> (IBigIncGenesisDispatcher, ContractAddress, ContractAddress) {
    // Deploy mock tokens first
    let usdt_address = deploy_mock_erc20(INITIAL_SUPPLY, contract_address_const::<OWNER>());
    let usdc_address = deploy_mock_erc20(INITIAL_SUPPLY, contract_address_const::<OWNER>());

    // Deploy BigIncGenesis contract
    let contract = declare("BigIncGenesis").unwrap().contract_class();
    let constructor_calldata = array![
        usdt_address.into(), // usdt_address
        usdc_address.into(), // usdc_address  
        OWNER // owner
    ];

    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    let big_inc = IBigIncGenesisDispatcher { contract_address };

    // Transfer some tokens to the contract for testing withdrawals
    let usdt_token = IERC20Dispatcher { contract_address: usdt_address };
    let usdc_token = IERC20Dispatcher { contract_address: usdc_address };

    start_cheat_caller_address(usdt_address, contract_address_const::<OWNER>());
    start_cheat_caller_address(usdc_address, contract_address_const::<OWNER>());

    usdt_token.transfer(contract_address, 100000_000000); // 100k USDT
    usdc_token.transfer(contract_address, 100000_000000); // 100k USDC

    stop_cheat_caller_address(usdt_address);
    stop_cheat_caller_address(usdc_address);

    // Setup shareholders for voting tests
    setup_shareholders(big_inc, usdt_address);

    (big_inc, usdt_address, usdc_address)
}

fn setup_shareholders(contract: IBigIncGenesisDispatcher, token_address: ContractAddress) {
    let usdt_token = IERC20Dispatcher { contract_address: token_address };
    
    // Give Alice 25 shares (high weight voter)
    start_cheat_caller_address(token_address, contract_address_const::<OWNER>());
    usdt_token.transfer(contract_address_const::<ALICE>(), 25_000000); // 25 USDT
    stop_cheat_caller_address(token_address);
    
    start_cheat_caller_address(token_address, contract_address_const::<ALICE>());
    usdt_token.approve(contract.contract_address, 25_000000);
    stop_cheat_caller_address(token_address);
    
    start_cheat_caller_address(contract.contract_address, contract_address_const::<ALICE>());
    contract.mint_share(token_address);
    stop_cheat_caller_address(contract.contract_address);
    
    // Give Bob 2 shares (low weight voter)
    start_cheat_caller_address(token_address, contract_address_const::<OWNER>());
    usdt_token.transfer(contract_address_const::<BOB>(), 2_000000); // 2 USDT
    stop_cheat_caller_address(token_address);
    
    start_cheat_caller_address(token_address, contract_address_const::<BOB>());
    usdt_token.approve(contract.contract_address, 2_000000);
    stop_cheat_caller_address(token_address);
    
    start_cheat_caller_address(contract.contract_address, contract_address_const::<BOB>());
    contract.mint_share(token_address);
    stop_cheat_caller_address(contract.contract_address);
    
    // Give Charlie 2 shares (low weight voter)
    start_cheat_caller_address(token_address, contract_address_const::<OWNER>());
    usdt_token.transfer(contract_address_const::<CHARLIE>(), 2_000000); // 2 USDT
    stop_cheat_caller_address(token_address);
    
    start_cheat_caller_address(token_address, contract_address_const::<CHARLIE>());
    usdt_token.approve(contract.contract_address, 2_000000);
    stop_cheat_caller_address(token_address);
    
    start_cheat_caller_address(contract.contract_address, contract_address_const::<CHARLIE>());
    contract.mint_share(token_address);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_governance_parameters() {
    let (contract, _, _) = deploy_contract_with_tokens();

    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());

    // Check default governance parameters
    let (quorum, voting_period) = contract.get_governance_parameters();
    assert(quorum == 50, 'Default quorum should be 50%');
    assert(voting_period == 2, 'Default voting period is 2');

    // Update governance parameters
    contract.set_governance_parameters(40, 3);
    let (new_quorum, new_voting_period) = contract.get_governance_parameters();
    assert(new_quorum == 40, 'Quorum should be updated');
    assert(new_voting_period == 3, 'Voting period should be updated');

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_submit_withdrawal_request() {
    let (contract, usdt_address, _) = deploy_contract_with_tokens();

    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    start_cheat_block_timestamp(contract.contract_address, 1000);

    let milestone_uri: ByteArray = "ipfs://QmExample123...";
    let deadline = 2000_u64; // Future timestamp
    let amount = 10000_u256;

    let request_id = contract
        .submit_withdrawal_request(usdt_address, amount, deadline, milestone_uri.clone());

    assert(request_id == 0, 'First request ID should be 0');

    let request = contract.get_withdrawal_request(request_id);
    assert(request.requester == contract_address_const::<OWNER>(), 'Wrong requester');
    assert(request.amount == amount, 'Wrong amount');
    assert(request.deadline_timestamp == deadline, 'Wrong deadline');
    assert(request.voting_deadline == 1000 + (2 * SECONDS_PER_DAY), 'Wrong voting deadline');
    assert(!request.is_executed, 'Should not be executed');
    assert(!request.is_cancelled, 'Should not be cancelled');

    stop_cheat_block_timestamp(contract.contract_address);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Insufficient contract balance',))]
fn test_submit_withdrawal_request_insufficient_balance() {
    let (contract, usdt_address, _) = deploy_contract_with_tokens();

    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    start_cheat_block_timestamp(contract.contract_address, 1000);

    let milestone_uri: ByteArray = "ipfs://QmInsufficientBalance...";
    let deadline = 2000_u64; // Future timestamp
    let amount = 200000_000000_u256; // More than contract balance (100k)

    // This should fail due to insufficient contract balance
    contract.submit_withdrawal_request(usdt_address, amount, deadline, milestone_uri);

    stop_cheat_block_timestamp(contract.contract_address);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
fn test_multiple_withdrawal_requests_tracking() {
    let (contract, usdt_address, usdc_address) = deploy_contract_with_tokens();

    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    start_cheat_block_timestamp(contract.contract_address, 1000);

    let milestone_uri1: ByteArray = "ipfs://QmRequest1...";
    let milestone_uri2: ByteArray = "ipfs://QmRequest2...";
    let deadline = 2000_u64;
    let amount1 = 10000_u256;
    let amount2 = 15000_u256;

    // Submit first request
    let request_id1 = contract
        .submit_withdrawal_request(usdt_address, amount1, deadline, milestone_uri1);

    // Submit second request
    let request_id2 = contract
        .submit_withdrawal_request(usdc_address, amount2, deadline, milestone_uri2);

    assert(request_id1 == 0, 'First request ID should be 0');
    assert(request_id2 == 1, 'Second request ID should be 1');

    let request1 = contract.get_withdrawal_request(request_id1);
    let request2 = contract.get_withdrawal_request(request_id2);

    assert(request1.token_address == usdt_address, 'Wrong token for request 1');
    assert(request2.token_address == usdc_address, 'Wrong token for request 2');
    assert(request1.amount == amount1, 'Wrong amount for request 1');
    assert(request2.amount == amount2, 'Wrong amount for request 2');

    stop_cheat_block_timestamp(contract.contract_address);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Amount must be > 0',))]
fn test_submit_withdrawal_request_zero_amount() {
    let (contract, usdt_address, _) = deploy_contract_with_tokens();

    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    start_cheat_block_timestamp(contract.contract_address, 1000);

    let milestone_uri: ByteArray = "ipfs://QmZeroAmount...";
    let deadline = 2000_u64;
    let amount = 0_u256; // Zero amount should fail

    contract.submit_withdrawal_request(usdt_address, amount, deadline, milestone_uri);

    stop_cheat_block_timestamp(contract.contract_address);
    stop_cheat_caller_address(contract.contract_address);
}
#[test]
fn test_cancel_withdrawal_request() {
    let (contract, usdt_address, _) = deploy_contract_with_tokens();

    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    start_cheat_block_timestamp(contract.contract_address, 1000);

    let amount = 100_000000; // 100 USDT
    let deadline = 2000;
    let milestone_uri: ByteArray = "https://example.com/milestone1";

    // Submit withdrawal request
    let request_id = contract
        .submit_withdrawal_request(usdt_address, amount, deadline, milestone_uri);

    // Verify request is created properly
    let request = contract.get_withdrawal_request(request_id);
    assert(!request.is_cancelled, 'Not cancelled initially');
    assert(!request.is_executed, 'Not executed initially');

    // Cancel the withdrawal request
    contract.cancel_withdrawal_request(request_id);

    // Verify request is cancelled
    let cancelled_request = contract.get_withdrawal_request(request_id);
    assert(cancelled_request.is_cancelled, 'Should be cancelled');
    assert(!cancelled_request.is_executed, 'Still not executed');

    stop_cheat_block_timestamp(contract.contract_address);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Already cancelled',))]
fn test_cancel_already_cancelled_request() {
    let (contract, usdt_address, _) = deploy_contract_with_tokens();

    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    start_cheat_block_timestamp(contract.contract_address, 1000);

    let amount = 100_000000;
    let deadline = 2000;
    let milestone_uri: ByteArray = "https://example.com/milestone1";

    // Submit and cancel withdrawal request
    let request_id = contract
        .submit_withdrawal_request(usdt_address, amount, deadline, milestone_uri);
    contract.cancel_withdrawal_request(request_id);

    // Try to cancel again - should panic
    contract.cancel_withdrawal_request(request_id);
}

#[test]
fn test_expectation_hash() {
    let (contract, usdt_address, _) = deploy_contract_with_tokens();

    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    start_cheat_block_timestamp(contract.contract_address, 1000);

    let amount = 100_000000;
    let deadline = 2000;
    let milestone_uri1: ByteArray = "https://example.com/milestone1";
    let milestone_uri2: ByteArray = "https://example.com/milestone2";

    // Submit two requests with same deadline but different URI content
    let request_id1 = contract
        .submit_withdrawal_request(usdt_address, amount, deadline, milestone_uri1);
    let request_id2 = contract
        .submit_withdrawal_request(usdt_address, amount, deadline, milestone_uri2);

    // Get the requests and verify they have different expectation hashes
    let request1 = contract.get_withdrawal_request(request_id1);
    let request2 = contract.get_withdrawal_request(request_id2);

    assert(request1.expectation_hash != request2.expectation_hash, 'Hashes should differ');

    stop_cheat_block_timestamp(contract.contract_address);
    stop_cheat_caller_address(contract.contract_address);
}
