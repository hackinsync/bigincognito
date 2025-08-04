use contract_::BigIncGenesis::{
    BigIncGenesis, IBigIncGenesisDispatcher, IBigIncGenesisDispatcherTrait,
};
use core::result::ResultTrait;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin::utils::serde::SerializedAppend;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, spy_events,
    start_cheat_block_timestamp, start_cheat_caller_address, stop_cheat_block_timestamp,
    stop_cheat_caller_address,
};
use starknet::ContractAddress;

const OWNER: felt252 = 'owner';
const USER1: felt252 = 'user1';
const USER2: felt252 = 'user2';
const USER3: felt252 = 'user3';
const USDT_INITIAL_SUPPLY: u256 = 1000000000000_u256; // 1M USDT with 6 decimals
const USDC_INITIAL_SUPPLY: u256 = 1000000000000_u256; // 1M USDC with 6 decimals

fn deploy_mock_erc20(
    name: ByteArray, symbol: ByteArray, initial_supply: u256, recipient: ContractAddress,
) -> ContractAddress {
    let contract = declare("MockERC20").unwrap().contract_class();
    let mut constructor_args = array![];
    constructor_args.append_serde(name);
    constructor_args.append_serde(symbol);
    constructor_args.append_serde(initial_supply);
    constructor_args.append_serde(recipient);

    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
    contract_address
}

fn deploy_big_inc_genesis(
    usdt_address: ContractAddress, usdc_address: ContractAddress,
) -> ContractAddress {
    let contract = declare("BigIncGenesis").unwrap().contract_class();
    let (contract_address, _) = contract
        .deploy(@array![usdt_address.into(), usdc_address.into(), OWNER.try_into().unwrap()])
        .unwrap();
    contract_address
}

fn setup() -> (ContractAddress, ContractAddress, ContractAddress) {
    let owner: ContractAddress = OWNER.try_into().unwrap();
    let usdt_address = deploy_mock_erc20("USDT", "USDT", USDT_INITIAL_SUPPLY, owner);
    let usdc_address = deploy_mock_erc20("USDC", "USDC", USDC_INITIAL_SUPPLY, owner);
    let big_inc_address = deploy_big_inc_genesis(usdt_address, usdc_address);

    // Distribute tokens to users for testing
    let user1: ContractAddress = USER1.try_into().unwrap();
    let user2: ContractAddress = USER2.try_into().unwrap();
    let user3: ContractAddress = USER3.try_into().unwrap();

    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    start_cheat_caller_address(usdt_address, owner);
    usdt.transfer(user1, 1100000000_u256); // 1100 USDT
    usdt.transfer(user2, 1100000000_u256); // 1100 USDT  
    usdt.transfer(user3, 600000000_u256); // 600 USDT
    stop_cheat_caller_address(usdt_address);

    start_cheat_caller_address(usdc_address, owner);
    usdc.transfer(user1, 1100000000_u256); // 1100 USDC
    usdc.transfer(user2, 1100000000_u256); // 1100 USDC
    usdc.transfer(user3, 600000000_u256); // 600 USDC
    stop_cheat_caller_address(usdc_address);

    (big_inc_address, usdt_address, usdc_address)
}


fn create_shareholders(
    big_inc: IBigIncGenesisDispatcher, usdt_address: ContractAddress, usdc_address: ContractAddress,
) {
    let user1: ContractAddress = USER1.try_into().unwrap();
    let user2: ContractAddress = USER2.try_into().unwrap();
    let user3: ContractAddress = USER3.try_into().unwrap();

    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    let usdc = IERC20Dispatcher { contract_address: usdc_address };

    // User1 buys shares with USDT
    start_cheat_caller_address(usdt_address, user1);
    usdt.approve(big_inc.contract_address, 1000000000_u256); // 1000 USDT
    stop_cheat_caller_address(usdt_address);

    start_cheat_caller_address(big_inc.contract_address, user1);
    big_inc.mint_share(usdt_address);
    stop_cheat_caller_address(big_inc.contract_address);

    // User2 buys shares with USDC
    start_cheat_caller_address(usdc_address, user2);
    usdc.approve(big_inc.contract_address, 1000000000_u256); // 1000 USDC
    stop_cheat_caller_address(usdc_address);

    start_cheat_caller_address(big_inc.contract_address, user2);
    big_inc.mint_share(usdc_address);
    stop_cheat_caller_address(big_inc.contract_address);

    // User3 buys shares with USDT
    start_cheat_caller_address(usdt_address, user3);
    usdt.approve(big_inc.contract_address, 500000000_u256); // 500 USDT
    stop_cheat_caller_address(usdt_address);

    start_cheat_caller_address(big_inc.contract_address, user3);
    big_inc.mint_share(usdt_address);
    stop_cheat_caller_address(big_inc.contract_address);
}


#[test]
fn test_request_withdrawal_success() {
    let (big_inc_address, usdt_address, _usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER.try_into().unwrap();

    start_cheat_caller_address(big_inc_address, owner);

    let current_timestamp = 1000000_u64;
    let deadline_timestamp = current_timestamp + 86400; // 1 day from now
    start_cheat_block_timestamp(big_inc_address, current_timestamp);

    let withdrawal_hash = big_inc
        .request_withdrawal(
            usdt_address, 100000000_u256, // 100 USDT
            "ipfs://milestone1", deadline_timestamp,
        );

    let request = big_inc.get_withdrawal_request(withdrawal_hash);
    assert(request.requester == owner, 'Wrong requester');
    assert(request.token_address == usdt_address, 'Wrong token address');
    assert(request.amount == 100000000_u256, 'Wrong amount');
    assert(request.deadline_timestamp == deadline_timestamp, 'Wrong deadline');
    assert(!request.is_executed, 'Should not be executed');

    stop_cheat_caller_address(big_inc_address);
    stop_cheat_block_timestamp(big_inc_address);
}


#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_request_withdrawal_not_owner() {
    let (big_inc_address, usdt_address, _usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let user1: ContractAddress = USER1.try_into().unwrap();

    start_cheat_caller_address(big_inc_address, user1);

    let current_timestamp = 1000000_u64;
    let deadline_timestamp = current_timestamp + 86400;
    start_cheat_block_timestamp(big_inc_address, current_timestamp);

    big_inc
        .request_withdrawal(usdt_address, 100000000_u256, "ipfs://milestone1", deadline_timestamp);

    stop_cheat_caller_address(big_inc_address);
    stop_cheat_block_timestamp(big_inc_address);
}


#[test]
#[should_panic(expected: ('Deadline must be in future',))]
fn test_request_withdrawal_past_deadline() {
    let (big_inc_address, usdt_address, _usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER.try_into().unwrap();

    start_cheat_caller_address(big_inc_address, owner);

    let current_timestamp = 1000000_u64;
    let deadline_timestamp = 913600_u64;
    start_cheat_block_timestamp(big_inc_address, current_timestamp);

    big_inc
        .request_withdrawal(usdt_address, 100000000_u256, "ipfs://milestone1", deadline_timestamp);

    stop_cheat_caller_address(big_inc_address);
    stop_cheat_block_timestamp(big_inc_address);
}


#[test]
fn test_trigger_vote_on_expectation_success() {
    let (big_inc_address, usdt_address, _usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER.try_into().unwrap();

    // Create withdrawal request
    start_cheat_caller_address(big_inc_address, owner);
    let current_timestamp = 1000000_u64;
    let deadline_timestamp = current_timestamp + 86400;
    start_cheat_block_timestamp(big_inc_address, current_timestamp);

    let withdrawal_hash = big_inc
        .request_withdrawal(usdt_address, 100000000_u256, "ipfs://milestone1", deadline_timestamp);

    start_cheat_block_timestamp(big_inc_address, deadline_timestamp + 1);

    big_inc.trigger_vote_on_expectation(withdrawal_hash);

    let vote_result = big_inc.get_vote_result(withdrawal_hash);
    assert(vote_result.vote_state.is_active, 'Vote should be active');
    assert(vote_result.vote_state.total_votes_for == 0, 'No votes yet');
    assert(vote_result.vote_state.total_votes_against == 0, 'No votes yet');

    stop_cheat_caller_address(big_inc_address);
    stop_cheat_block_timestamp(big_inc_address);
}


#[test]
#[should_panic(expected: ('Withdrawal request not found',))]
fn test_trigger_vote_nonexistent_request() {
    let (big_inc_address, _usdt_address, _usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };

    let fake_hash = 999999;
    big_inc.trigger_vote_on_expectation(fake_hash);
}


#[test]
#[should_panic(expected: ('Deadline not reached',))]
fn test_trigger_vote_before_deadline() {
    let (big_inc_address, usdt_address, _usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER.try_into().unwrap();

    start_cheat_caller_address(big_inc_address, owner);
    let current_timestamp = 1000000_u64;
    let deadline_timestamp = current_timestamp + 86400;
    start_cheat_block_timestamp(big_inc_address, current_timestamp);

    let withdrawal_hash = big_inc
        .request_withdrawal(usdt_address, 100000000_u256, "ipfs://milestone1", deadline_timestamp);

    big_inc.trigger_vote_on_expectation(withdrawal_hash);

    stop_cheat_caller_address(big_inc_address);
    stop_cheat_block_timestamp(big_inc_address);
}


#[test]
fn test_vote_on_milestone_success() {
    let (big_inc_address, usdt_address, usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER.try_into().unwrap();
    let user1: ContractAddress = USER1.try_into().unwrap();

    create_shareholders(big_inc, usdt_address, usdc_address);

    start_cheat_caller_address(big_inc_address, owner);
    let current_timestamp = 1000000_u64;
    let deadline_timestamp = current_timestamp + 86400;
    start_cheat_block_timestamp(big_inc_address, current_timestamp);

    let withdrawal_hash = big_inc
        .request_withdrawal(usdt_address, 100000000_u256, "ipfs://milestone1", deadline_timestamp);

    start_cheat_block_timestamp(big_inc_address, deadline_timestamp + 1);
    big_inc.trigger_vote_on_expectation(withdrawal_hash);

    start_cheat_caller_address(big_inc_address, user1);
    big_inc.vote_on_milestone(withdrawal_hash, true);

    let has_voted = big_inc.has_voted(withdrawal_hash, user1);
    assert(has_voted, 'User should have voted');

    let vote_result = big_inc.get_vote_result(withdrawal_hash);
    assert(vote_result.vote_state.total_votes_for > 0, 'Should have votes');

    stop_cheat_caller_address(big_inc_address);
    stop_cheat_block_timestamp(big_inc_address);
}


#[test]
#[should_panic(expected: ('Already voted',))]
fn test_vote_on_milestone_double_vote() {
    let (big_inc_address, usdt_address, usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER.try_into().unwrap();
    let user1: ContractAddress = USER1.try_into().unwrap();

    create_shareholders(big_inc, usdt_address, usdc_address);

    start_cheat_caller_address(big_inc_address, owner);
    let current_timestamp = 1000000_u64;
    let deadline_timestamp = current_timestamp + 86400;
    start_cheat_block_timestamp(big_inc_address, current_timestamp);

    let withdrawal_hash = big_inc
        .request_withdrawal(usdt_address, 100000000_u256, "ipfs://milestone1", deadline_timestamp);

    start_cheat_block_timestamp(big_inc_address, deadline_timestamp + 1);
    big_inc.trigger_vote_on_expectation(withdrawal_hash);

    // User1 votes twice
    start_cheat_caller_address(big_inc_address, user1);
    big_inc.vote_on_milestone(withdrawal_hash, true);
    big_inc.vote_on_milestone(withdrawal_hash, false); // Should fail

    stop_cheat_caller_address(big_inc_address);
    stop_cheat_block_timestamp(big_inc_address);
}


#[test]
fn test_execute_withdrawal_after_vote_success() {
    let (big_inc_address, usdt_address, usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER.try_into().unwrap();
    let user1: ContractAddress = USER1.try_into().unwrap();
    let user2: ContractAddress = USER2.try_into().unwrap();

    let mut spy = spy_events();

    create_shareholders(big_inc, usdt_address, usdc_address);

    start_cheat_caller_address(big_inc_address, owner);
    let current_timestamp = 1000000_u64;
    let deadline_timestamp = current_timestamp + 86400;
    start_cheat_block_timestamp(big_inc_address, current_timestamp);

    let withdrawal_hash = big_inc
        .request_withdrawal(usdt_address, 100000000_u256, "ipfs://milestone1", deadline_timestamp);

    start_cheat_block_timestamp(big_inc_address, deadline_timestamp + 1);
    big_inc.trigger_vote_on_expectation(withdrawal_hash);

    start_cheat_caller_address(big_inc_address, user1);
    big_inc.vote_on_milestone(withdrawal_hash, true);
    stop_cheat_caller_address(big_inc_address);

    start_cheat_caller_address(big_inc_address, user2);
    big_inc.vote_on_milestone(withdrawal_hash, true);
    stop_cheat_caller_address(big_inc_address);

    let user3: ContractAddress = USER3.try_into().unwrap();
    start_cheat_caller_address(big_inc_address, user3);
    big_inc.vote_on_milestone(withdrawal_hash, true);
    stop_cheat_caller_address(big_inc_address);

    start_cheat_caller_address(big_inc_address, owner);
    big_inc.vote_on_milestone(withdrawal_hash, true);
    stop_cheat_caller_address(big_inc_address);

    // Move time past voting period (voting started at deadline_timestamp + 1)
    start_cheat_block_timestamp(
        big_inc_address, (deadline_timestamp + 1) + 604800 + 1,
    ); // 7 days after voting started + 1 second

    // Execute withdrawal
    start_cheat_caller_address(big_inc_address, owner);
    big_inc.execute_withdrawal_after_vote(withdrawal_hash);

    // Verify withdrawal was executed
    let request = big_inc.get_withdrawal_request(withdrawal_hash);
    assert(request.is_executed, 'Should be executed');

    stop_cheat_caller_address(big_inc_address);
    stop_cheat_block_timestamp(big_inc_address);
}


#[test]
#[should_panic(expected: ('Vote did not pass',))]
fn test_execute_withdrawal_vote_failed() {
    let (big_inc_address, usdt_address, usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER.try_into().unwrap();
    let user1: ContractAddress = USER1.try_into().unwrap();
    let user2: ContractAddress = USER2.try_into().unwrap();

    create_shareholders(big_inc, usdt_address, usdc_address);

    start_cheat_caller_address(big_inc_address, owner);
    let current_timestamp = 1000000_u64;
    let deadline_timestamp = current_timestamp + 86400;
    start_cheat_block_timestamp(big_inc_address, current_timestamp);

    let withdrawal_hash = big_inc
        .request_withdrawal(usdt_address, 100000000_u256, "ipfs://milestone1", deadline_timestamp);

    start_cheat_block_timestamp(big_inc_address, deadline_timestamp + 1);
    big_inc.trigger_vote_on_expectation(withdrawal_hash);

    start_cheat_caller_address(big_inc_address, user1);
    big_inc.vote_on_milestone(withdrawal_hash, false);
    stop_cheat_caller_address(big_inc_address);

    start_cheat_caller_address(big_inc_address, user2);
    big_inc.vote_on_milestone(withdrawal_hash, false);
    stop_cheat_caller_address(big_inc_address);

    // Move time past voting period (voting started at deadline_timestamp + 1)
    start_cheat_block_timestamp(big_inc_address, (deadline_timestamp + 1) + 604800 + 1);

    // Try to execute withdrawal (should fail)
    start_cheat_caller_address(big_inc_address, owner);
    big_inc.execute_withdrawal_after_vote(withdrawal_hash);

    stop_cheat_caller_address(big_inc_address);
    stop_cheat_block_timestamp(big_inc_address);
}


#[test]
#[should_panic(expected: ('No voting power',))]
fn test_vote_on_milestone_no_shares() {
    let (big_inc_address, usdt_address, usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER.try_into().unwrap();
    let user1: ContractAddress = USER1.try_into().unwrap();

    start_cheat_caller_address(big_inc_address, owner);
    let current_timestamp = 1000000_u64;
    let deadline_timestamp = current_timestamp + 86400;
    start_cheat_block_timestamp(big_inc_address, current_timestamp);

    let withdrawal_hash = big_inc
        .request_withdrawal(usdt_address, 100000000_u256, "ipfs://milestone1", deadline_timestamp);

    start_cheat_block_timestamp(big_inc_address, deadline_timestamp + 1);
    big_inc.trigger_vote_on_expectation(withdrawal_hash);

    start_cheat_caller_address(big_inc_address, user1);
    big_inc.vote_on_milestone(withdrawal_hash, true);

    stop_cheat_caller_address(big_inc_address);
    stop_cheat_block_timestamp(big_inc_address);
}


#[test]
fn test_has_voted_function() {
    let (big_inc_address, usdt_address, usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER.try_into().unwrap();
    let user1: ContractAddress = USER1.try_into().unwrap();

    create_shareholders(big_inc, usdt_address, usdc_address);

    start_cheat_caller_address(big_inc_address, owner);
    let current_timestamp = 1000000_u64;
    let deadline_timestamp = current_timestamp + 86400;
    start_cheat_block_timestamp(big_inc_address, current_timestamp);

    let withdrawal_hash = big_inc
        .request_withdrawal(usdt_address, 100000000_u256, "ipfs://milestone1", deadline_timestamp);

    start_cheat_block_timestamp(big_inc_address, deadline_timestamp + 1);
    big_inc.trigger_vote_on_expectation(withdrawal_hash);

    let has_voted_before = big_inc.has_voted(withdrawal_hash, user1);
    assert(!has_voted_before, 'Should not have voted yet');

    start_cheat_caller_address(big_inc_address, user1);
    big_inc.vote_on_milestone(withdrawal_hash, true);

    let has_voted_after = big_inc.has_voted(withdrawal_hash, user1);
    assert(has_voted_after, 'Should have voted');

    stop_cheat_caller_address(big_inc_address);
    stop_cheat_block_timestamp(big_inc_address);
}


#[test]
fn test_vote_participation_rate() {
    let (big_inc_address, usdt_address, usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER.try_into().unwrap();
    let user1: ContractAddress = USER1.try_into().unwrap();
    let user2: ContractAddress = USER2.try_into().unwrap();

    create_shareholders(big_inc, usdt_address, usdc_address);

    start_cheat_caller_address(big_inc_address, owner);
    let current_timestamp = 1000000_u64;
    let deadline_timestamp = current_timestamp + 86400;
    start_cheat_block_timestamp(big_inc_address, current_timestamp);

    let withdrawal_hash = big_inc
        .request_withdrawal(usdt_address, 100000000_u256, "ipfs://milestone1", deadline_timestamp);

    start_cheat_block_timestamp(big_inc_address, deadline_timestamp + 1);
    big_inc.trigger_vote_on_expectation(withdrawal_hash);

    start_cheat_caller_address(big_inc_address, user1);
    big_inc.vote_on_milestone(withdrawal_hash, true);
    stop_cheat_caller_address(big_inc_address);

    let vote_result = big_inc.get_vote_result(withdrawal_hash);

    assert(vote_result.vote_state.total_votes_for > 0, 'Should have some votes');
    assert(vote_result.vote_state.total_voting_power > 0, 'Should have voting power');

    stop_cheat_caller_address(big_inc_address);
    stop_cheat_block_timestamp(big_inc_address);
}

#[test]
fn test_events_emission() {
    let (big_inc_address, usdt_address, _usdc_address) = setup();
    let big_inc = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let owner: ContractAddress = OWNER.try_into().unwrap();
    let user1: ContractAddress = USER1.try_into().unwrap();

    let mut spy = spy_events();

    let usdt = IERC20Dispatcher { contract_address: usdt_address };
    start_cheat_caller_address(usdt_address, user1);
    usdt.approve(big_inc.contract_address, 1000000000_u256); // 1000 USDT
    stop_cheat_caller_address(usdt_address);

    start_cheat_caller_address(big_inc.contract_address, user1);
    big_inc.mint_share(usdt_address);
    stop_cheat_caller_address(big_inc.contract_address);

    let expected_shares = (1000000000_u256 * 100000000_u256) / 457143000000_u256; // ~218750 shares
    spy
        .assert_emitted(
            @array![
                (
                    big_inc_address,
                    BigIncGenesis::Event::ShareMinted(
                        BigIncGenesis::ShareMinted {
                            buyer: user1, shares_bought: expected_shares, amount: 1000000000_u256,
                        },
                    ),
                ),
            ],
        );

    start_cheat_caller_address(big_inc_address, owner);
    let current_timestamp = 1000000_u64;
    let deadline_timestamp = current_timestamp + 86400;
    start_cheat_block_timestamp(big_inc_address, current_timestamp);

    let withdrawal_hash = big_inc
        .request_withdrawal(usdt_address, 100000000_u256, "ipfs://milestone1", deadline_timestamp);

    start_cheat_block_timestamp(big_inc_address, deadline_timestamp + 1);
    big_inc.trigger_vote_on_expectation(withdrawal_hash);

    spy
        .assert_emitted(
            @array![
                (
                    big_inc_address,
                    BigIncGenesis::Event::VoteTriggered(
                        BigIncGenesis::VoteTriggered { withdrawal_hash },
                    ),
                ),
            ],
        );

    start_cheat_caller_address(big_inc_address, user1);
    big_inc.vote_on_milestone(withdrawal_hash, true);
    stop_cheat_caller_address(big_inc_address);

    spy
        .assert_emitted(
            @array![
                (
                    big_inc_address,
                    BigIncGenesis::Event::VoteVoted(
                        BigIncGenesis::VoteVoted {
                            withdrawal_hash, voter: user1, met_expectation: true,
                        },
                    ),
                ),
            ],
        );

    stop_cheat_caller_address(big_inc_address);
    stop_cheat_block_timestamp(big_inc_address);
}
