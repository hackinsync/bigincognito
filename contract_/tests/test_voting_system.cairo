use contract_::BigIncGenesis::{IBigIncGenesisDispatcher, IBigIncGenesisDispatcherTrait};
use core::traits::Into;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_block_timestamp,
    start_cheat_caller_address, stop_cheat_block_timestamp, stop_cheat_caller_address,
};
use starknet::{ContractAddress, contract_address_const};

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

// ========== WEALTH-BASED VOTING TESTS ==========

#[test]
fn test_wealth_based_voting_high_weight_wins() {
    let (contract, usdt_address, _) = deploy_contract_with_tokens();

    // Submit withdrawal request
    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    start_cheat_block_timestamp(contract.contract_address, 1000);

    let amount = 10000_u256;
    let deadline = 5000_u64; // Future execution deadline
    let milestone_uri: ByteArray = "ipfs://QmVotingTest...";

    let request_id = contract
        .submit_withdrawal_request(usdt_address, amount, deadline, milestone_uri);

    stop_cheat_caller_address(contract.contract_address);

    // Alice (25 shares) votes FOR
    start_cheat_caller_address(contract.contract_address, contract_address_const::<ALICE>());
    contract.vote_on_withdrawal_request(request_id, true);
    stop_cheat_caller_address(contract.contract_address);

    // Bob (2 shares) votes AGAINST
    start_cheat_caller_address(contract.contract_address, contract_address_const::<BOB>());
    contract.vote_on_withdrawal_request(request_id, false);
    stop_cheat_caller_address(contract.contract_address);

    // Charlie (2 shares) votes AGAINST
    start_cheat_caller_address(contract.contract_address, contract_address_const::<CHARLIE>());
    contract.vote_on_withdrawal_request(request_id, false);
    stop_cheat_caller_address(contract.contract_address);

    // Owner (18M shares) votes FOR - this ensures quorum is reached
    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    contract.vote_on_withdrawal_request(request_id, true);
    stop_cheat_caller_address(contract.contract_address);

    // Fast forward past voting deadline and execution deadline
    let voting_deadline_passed = 1000 + (2 * SECONDS_PER_DAY) + 1;
    start_cheat_block_timestamp(contract.contract_address, voting_deadline_passed);

    // Execute withdrawal - should succeed because Owner + Alice FOR votes > Bob + Charlie AGAINST
    // votes
    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    contract.execute_withdrawal(request_id);

    let request = contract.get_withdrawal_request(request_id);
    assert(request.is_executed, 'High weight wins');

    stop_cheat_block_timestamp(contract.contract_address);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: ('Proposal not approved',))]
fn test_wealth_based_voting_low_weight_loses() {
    let (contract, usdt_address, _) = deploy_contract_with_tokens();

    // Submit withdrawal request
    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    start_cheat_block_timestamp(contract.contract_address, 1000);

    let amount = 10000_u256;
    let deadline = 5000_u64;
    let milestone_uri: ByteArray = "ipfs://QmVotingTest2...";

    let request_id = contract
        .submit_withdrawal_request(usdt_address, amount, deadline, milestone_uri);

    stop_cheat_caller_address(contract.contract_address);

    // Alice (25 shares) votes AGAINST
    start_cheat_caller_address(contract.contract_address, contract_address_const::<ALICE>());
    contract.vote_on_withdrawal_request(request_id, false);
    stop_cheat_caller_address(contract.contract_address);

    // Bob (2 shares) votes FOR
    start_cheat_caller_address(contract.contract_address, contract_address_const::<BOB>());
    contract.vote_on_withdrawal_request(request_id, true);
    stop_cheat_caller_address(contract.contract_address);

    // Charlie (2 shares) votes FOR
    start_cheat_caller_address(contract.contract_address, contract_address_const::<CHARLIE>());
    contract.vote_on_withdrawal_request(request_id, true);
    stop_cheat_caller_address(contract.contract_address);

    // Owner (18M shares) votes AGAINST - this ensures quorum is reached but proposal fails
    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    contract.vote_on_withdrawal_request(request_id, false);
    stop_cheat_caller_address(contract.contract_address);

    // Fast forward past voting deadline and execution deadline
    let voting_deadline_passed = 1000 + (2 * SECONDS_PER_DAY) + 1;
    start_cheat_block_timestamp(contract.contract_address, voting_deadline_passed);

    // Execute withdrawal - should fail because Owner AGAINST votes > Alice + Bob + Charlie FOR
    // votes
    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    contract.execute_withdrawal(request_id); // This should panic
}

#[test]
#[should_panic(expected: ('Voting period ended',))]
fn test_voting_after_deadline_fails() {
    let (contract, usdt_address, _) = deploy_contract_with_tokens();

    // Submit withdrawal request
    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    start_cheat_block_timestamp(contract.contract_address, 1000);

    let amount = 10000_u256;
    let deadline = 5000_u64;
    let milestone_uri: ByteArray = "ipfs://QmVotingDeadlineTest...";

    let request_id = contract
        .submit_withdrawal_request(usdt_address, amount, deadline, milestone_uri);

    stop_cheat_caller_address(contract.contract_address);

    // Fast forward past voting deadline (2 days = 172800 seconds)
    start_cheat_block_timestamp(contract.contract_address, 1000 + (2 * SECONDS_PER_DAY) + 1);

    // Try to vote after deadline - should fail
    start_cheat_caller_address(contract.contract_address, contract_address_const::<ALICE>());
    contract.vote_on_withdrawal_request(request_id, true); // This should panic
}

#[test]
#[should_panic(expected: ('Already voted',))]
fn test_double_voting_fails() {
    let (contract, usdt_address, _) = deploy_contract_with_tokens();

    // Submit withdrawal request
    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    start_cheat_block_timestamp(contract.contract_address, 1000);

    let amount = 10000_u256;
    let deadline = 5000_u64;
    let milestone_uri: ByteArray = "ipfs://QmDoubleVoteTest...";

    let request_id = contract
        .submit_withdrawal_request(usdt_address, amount, deadline, milestone_uri);

    stop_cheat_caller_address(contract.contract_address);

    // Alice votes once
    start_cheat_caller_address(contract.contract_address, contract_address_const::<ALICE>());
    contract.vote_on_withdrawal_request(request_id, true);

    // Alice tries to vote again - should fail
    contract.vote_on_withdrawal_request(request_id, false); // This should panic
}

#[test]
#[should_panic(expected: ('Not a shareholder',))]
fn test_non_shareholder_cannot_vote() {
    let (contract, usdt_address, _) = deploy_contract_with_tokens();

    // Submit withdrawal request
    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    start_cheat_block_timestamp(contract.contract_address, 1000);

    let amount = 10000_u256;
    let deadline = 5000_u64;
    let milestone_uri: ByteArray = "ipfs://QmNonShareholderTest...";

    let request_id = contract
        .submit_withdrawal_request(usdt_address, amount, deadline, milestone_uri);

    stop_cheat_caller_address(contract.contract_address);

    // Try to vote as someone who is not a shareholder
    let non_shareholder = contract_address_const::<0x999>();
    start_cheat_caller_address(contract.contract_address, non_shareholder);
    contract.vote_on_withdrawal_request(request_id, true); // This should panic
}

#[test]
#[should_panic(expected: ('Voting period not ended',))]
fn test_early_execution_fails() {
    let (contract, usdt_address, _) = deploy_contract_with_tokens();

    // Submit withdrawal request
    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    start_cheat_block_timestamp(contract.contract_address, 1000);

    let amount = 10000_u256;
    let deadline = 5000_u64;
    let milestone_uri: ByteArray = "ipfs://QmEarlyExecutionTest...";

    let request_id = contract
        .submit_withdrawal_request(usdt_address, amount, deadline, milestone_uri);

    // Alice votes FOR
    start_cheat_caller_address(contract.contract_address, contract_address_const::<ALICE>());
    contract.vote_on_withdrawal_request(request_id, true);
    stop_cheat_caller_address(contract.contract_address);

    // Try to execute before voting period ends - should fail
    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    contract.execute_withdrawal(request_id); // This should panic
}

#[test]
fn test_voting_deadline_calculation() {
    let (contract, usdt_address, _) = deploy_contract_with_tokens();

    // Submit withdrawal request
    start_cheat_caller_address(contract.contract_address, contract_address_const::<OWNER>());
    start_cheat_block_timestamp(contract.contract_address, 1000);

    let amount = 10000_u256;
    let deadline = 5000_u64;
    let milestone_uri: ByteArray = "ipfs://QmDeadlineTest...";

    let request_id = contract
        .submit_withdrawal_request(usdt_address, amount, deadline, milestone_uri);

    let request = contract.get_withdrawal_request(request_id);

    // Verify voting deadline is correctly calculated (2 days from creation)
    let expected_voting_deadline = 1000 + (2 * SECONDS_PER_DAY);
    assert(request.voting_deadline == expected_voting_deadline, 'Wrong voting deadline');

    stop_cheat_block_timestamp(contract.contract_address);
    stop_cheat_caller_address(contract.contract_address);
}
