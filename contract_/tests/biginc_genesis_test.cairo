use contract_::BigIncGenesis::{
    BigIncGenesis, IBigIncGenesisDispatcher, IBigIncGenesisDispatcherTrait,
};
use core::num::traits::Zero;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{CheatSpan, EventSpyAssertionsTrait, cheat_caller_address, spy_events};
use starknet::ContractAddress;
use super::setup::{deploy_mock_erc20, owner, setup};

fn alice() -> ContractAddress {
    'alice'.try_into().unwrap()
}

fn charlie() -> ContractAddress {
    'charlie'.try_into().unwrap()
}

fn mint(targets: Array<(ContractAddress, u256)>, dispatcher: IERC20Dispatcher) {
    for i in 0..targets.len() {
        let (recipient, amount) = *targets.at(i);
        cheat_caller_address(dispatcher.contract_address, owner(), CheatSpan::TargetCalls(1));
        dispatcher.transfer(recipient, amount);
    }
}

fn feign_mint_share(genesis: IBigIncGenesisDispatcher, token: IERC20Dispatcher, amount: u256) {
    mint(array![(charlie(), amount)], token);
    cheat_caller_address(token.contract_address, charlie(), CheatSpan::TargetCalls(1));
    token.approve(genesis.contract_address, amount);
    cheat_caller_address(genesis.contract_address, charlie(), CheatSpan::Indefinite);
    genesis.mint_share(token.contract_address);
}

fn default_mint_context() -> (IBigIncGenesisDispatcher, IERC20Dispatcher) {
    let (genesis, usdt, _) = setup();
    let amount = 10000;
    feign_mint_share(genesis, usdt, amount);
    (genesis, usdt)
}

#[test]
fn test_genesis_mint_share_success() {
    let (genesis, usdt, _) = setup();
    let amount = 10000;
    let mut spy = spy_events();
    feign_mint_share(genesis, usdt, amount);

    let presale_share_valuation = genesis.get_presale_share_valuation();
    let shares_bought = (amount * 100000000_u256) / presale_share_valuation;
    let shares_sold = genesis.get_shares_sold();
    assert(shares_bought == shares_sold, 'SHARES VALUATION MISMATCH');
    let is_shareholder = genesis.is_shareholder(charlie());
    assert(is_shareholder, 'CHARLIE NOT SHAREHOLDER');

    let event = BigIncGenesis::Event::ShareMinted(
        BigIncGenesis::ShareMinted { buyer: charlie(), shares_bought, amount },
    );

    spy.assert_emitted(@array![(genesis.contract_address, event)]);
}

#[test]
#[should_panic(expected: 'Invalid token address')]
fn test_genesis_mint_share_should_panic_on_invalid_token() {
    let (genesis, _, _) = setup();
    let amount = 1000;
    let contract_address = deploy_mock_erc20("TOKEN", "TKN", 1000000, owner());
    let token = IERC20Dispatcher { contract_address };
    feign_mint_share(genesis, token, amount);
}

#[test]
fn test_genesis_transfer_share_success() {
    let (genesis, _) = default_mint_context();
    // shares have been minted to charlie
    let shares = genesis.get_shares(charlie());
    let alice_shares = genesis.get_shares(alice());
    assert(alice_shares == 0, 'ALICE SHOULD HAVE NO SHARES');
    cheat_caller_address(genesis.contract_address, charlie(), CheatSpan::TargetCalls(5));

    let amount = shares / 2;
    let remaining_amount = shares - amount;

    let mut spy = spy_events();
    genesis.transfer_share(alice(), amount);
    let alice_shares = genesis.get_shares(alice());
    assert(alice_shares == amount, 'ALICE SHARES MISMATCH');

    let shares = genesis.get_shares(charlie());
    assert(shares == remaining_amount, 'CHARLIE SHARES MISMATCH');

    let share_holders = genesis.get_shareholders();
    println!("Number of share holders: {}", share_holders.len());
    for i in 0..share_holders.len() {
        println!("Share at {} is: {}", i, genesis.get_shares(*share_holders.at(i)));
    }
    assert(share_holders.len() == 3, 'INCORRECT SHARE HOLDERS'); // since the owner holds by default

    let event = BigIncGenesis::Event::TransferShare(
        BigIncGenesis::TransferShare { from: charlie(), to: alice(), share_amount: amount },
    );
    spy.assert_emitted(@array![(genesis.contract_address, event)]);
}

#[test]
#[should_panic(expected: 'Insufficient shares')]
fn test_genesis_transfer_share_should_panic_on_insufficient_shares() {
    let (genesis, _) = default_mint_context();
    let shares = genesis.get_shares(charlie());
    cheat_caller_address(genesis.contract_address, charlie(), CheatSpan::Indefinite);
    genesis.transfer_share(alice(), shares + 1);
}

#[test]
#[should_panic(expected: 'Cannot transfer to zero address')]
fn test_genesis_transfer_share_should_panic_on_zero_address() {
    let (genesis, _) = default_mint_context();
    let shares = genesis.get_shares(charlie());
    cheat_caller_address(genesis.contract_address, charlie(), CheatSpan::Indefinite);
    genesis.transfer_share(Zero::zero(), shares);
}

#[test]
fn test_genesis_donate_success() {
    let (genesis, usdt, _) = setup();
    let amount = 1000;
    mint(array![(charlie(), amount)], usdt);
    let mut spy = spy_events();
    let previous_balance = usdt.balance_of(genesis.contract_address);
    assert(previous_balance == 0, 'PREV BALANCE SHOULD BE ZERO');

    cheat_caller_address(usdt.contract_address, charlie(), CheatSpan::TargetCalls(1));
    usdt.approve(genesis.contract_address, amount);
    cheat_caller_address(genesis.contract_address, charlie(), CheatSpan::TargetCalls(1));
    genesis.donate(usdt.contract_address, amount);

    let new_balance = usdt.balance_of(genesis.contract_address);
    assert(new_balance == amount, 'CONTRACT BALANCE MISMATCH');
    let event = BigIncGenesis::Event::Donate(
        BigIncGenesis::Donate { donor: charlie(), token_address: usdt.contract_address, amount },
    );
    spy.assert_emitted(@array![(genesis.contract_address, event)]);
}

#[test]
#[should_panic(expected: 'Exceeds available shares')]
fn test_genesis_mint_share_should_panic_on_exceeded_available_shares() {
    let (genesis, usdt, _) = setup();
    let shares = genesis.get_available_shares();
    let presale_share_valuation = genesis.get_presale_share_valuation();
    println!("Available shares: {}", shares);
    let amount = (shares * presale_share_valuation) / 100000000;
    feign_mint_share(genesis, usdt, amount + 10000);
}

// #[test]
// #[should_panic(expected: 'Insufficient balance')]
// fn test_genesis_withdraw_success_and_should_panic_on_insufficient_funds() {
//     let (genesis, usdt) = default_mint_context();
//     let balance = usdt.balance_of(genesis.contract_address);
//     let owner_balance = usdt.balance_of(owner());
//     cheat_caller_address(genesis.contract_address, owner(), CheatSpan::TargetCalls(1));
//     let timestamp = 10;
//     cheat_block_timestamp(genesis.contract_address, timestamp, CheatSpan::Indefinite);
//     let mut spy = spy_events();
//     genesis.withdraw(usdt.contract_address, balance);

//     let genesis_balance = usdt.balance_of(genesis.contract_address);
//     assert(genesis_balance == 0, 'WITHDRAWAL FAILED 1.');
//     let new_balance = usdt.balance_of(owner());
//     assert(new_balance == (owner_balance + balance), 'OWNER BALANCE MISMATCH');

//     let event = BigIncGenesis::Event::Withdrawn(
//         BigIncGenesis::Withdrawn {
//             token_address: usdt.contract_address,
//             amount: balance,
//             owner: owner(),
//             timestamp: timestamp.into(),
//         },
//     );
//     spy.assert_emitted(@array![(genesis.contract_address, event)]);

//     cheat_caller_address(genesis.contract_address, owner(), CheatSpan::TargetCalls(1));
//     genesis.withdraw(usdt.contract_address, 1);
// }

// #[test]
// #[should_panic(expected: 'Caller is not the owner')]
// fn test_genesis_withdraw_should_panic_on_non_owner() {
//     let (genesis, usdt) = default_mint_context();
//     cheat_caller_address(genesis.contract_address, charlie(), CheatSpan::TargetCalls(1));
//     genesis.withdraw(usdt.contract_address, 100);
// }

#[test]
#[should_panic(expected: 'Insufficient shares')]
fn test_genesis_seize_shares_success_and_should_panic_on_transfer() {
    let (genesis, _) = default_mint_context();
    let mut spy = spy_events();
    cheat_caller_address(genesis.contract_address, owner(), CheatSpan::TargetCalls(1));

    let shares_sold = genesis.get_shares_sold();
    let shares = genesis.get_shares(charlie());
    assert(shares == shares_sold, 'CHARLIE SHARES MISMATCH');

    cheat_caller_address(genesis.contract_address, owner(), CheatSpan::TargetCalls(1));
    genesis.seize_shares(charlie());

    let event = BigIncGenesis::Event::SharesSeized(
        BigIncGenesis::SharesSeized { shareholder: charlie(), share_amount: shares },
    );
    spy.assert_emitted(@array![(genesis.contract_address, event)]);

    let shares = genesis.get_shares(charlie());
    assert(shares == 0, 'CHARLIE SHARES SHOULD BE ZERO');

    cheat_caller_address(genesis.contract_address, charlie(), CheatSpan::Indefinite);
    genesis.transfer_share(alice(), 1);
}

#[test]
#[should_panic(expected: 'Exceeds partner share cap')]
fn test_genesis_partner_share_cap_operations_success_and_should_panic_on_exceeded_cap() {
    let (genesis, usdt, _) = setup();
    let previous_cap = genesis.get_partner_share_cap(usdt.contract_address);
    assert(previous_cap == 0, 'PREVIOUS CAP SHOULD BE ZERO');
    cheat_caller_address(genesis.contract_address, owner(), CheatSpan::TargetCalls(2));
    let cap = 10000000;
    let mut spy = spy_events();
    genesis.set_partner_share_cap(usdt.contract_address, cap); // 10M shares cap

    let rate = 10000;
    genesis.set_partner_token_rate(usdt.contract_address, rate);

    let cap_ref = genesis.get_partner_share_cap(usdt.contract_address);
    assert(cap == cap_ref, 'PRICE CAP MISMATCH');

    let event1 = BigIncGenesis::Event::PartnerShareCapSet(
        BigIncGenesis::PartnerShareCapSet { token_address: usdt.contract_address, cap },
    );

    // let amount = 10000;
    let share_precision = 100000000_u256;
    // let shares_received = (amount * share_precision) / rate;
    let amount = (cap * rate) / share_precision;
    mint(array![(alice(), amount)], usdt);
    cheat_caller_address(usdt.contract_address, alice(), CheatSpan::TargetCalls(1));
    usdt.approve(genesis.contract_address, amount);

    // Mint partner shares
    cheat_caller_address(genesis.contract_address, alice(), CheatSpan::TargetCalls(1));
    println!("Got here, 1.");
    genesis.mint_partner_share(usdt.contract_address, amount);
    println!("Got here, 2.");
    let shares_received = genesis.get_shares_sold();
    let shares = genesis.get_shares(alice());
    assert(shares == shares_received, 'ALICE SHARES MISMATCH');

    let shares_minted_by_partner = genesis.get_shares_minted_by_partner(usdt.contract_address);
    println!("Shares minted by partner: {}", shares_minted_by_partner);
    println!("Cap: {}", cap);
    feign_mint_share(genesis, usdt, amount);

    let event2 = BigIncGenesis::Event::PartnerShareMinted(
        BigIncGenesis::PartnerShareMinted {
            token_address: usdt.contract_address,
            buyer: alice(),
            amount_paid: amount,
            shares_received,
            rate,
        },
    );

    let events = array![(genesis.contract_address, event1), (genesis.contract_address, event2)];
    spy.assert_emitted(@events);

    // mint. should panic
    println!("End.");
    feign_mint_share(genesis, usdt, amount * amount);
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_genesis_set_partner_share_cap_not_owner() {
    let (genesis, usdt, _) = setup();
    cheat_caller_address(genesis.contract_address, alice(), CheatSpan::TargetCalls(1));
    genesis.set_partner_share_cap(usdt.contract_address, 1000);
}

#[test]
#[should_panic(expected: ('Invalid token address',))]
fn test_genesis_set_partner_share_cap_invalid_token() {
    let (genesis, _, _) = setup();
    cheat_caller_address(genesis.contract_address, owner(), CheatSpan::TargetCalls(1));
    let random_token: ContractAddress = 'random token'.try_into().unwrap();
    genesis.set_partner_share_cap(random_token, 1000);
}

#[test]
fn test_genesis_remove_partner_share_cap_success() {
    let (genesis, _, usdc) = setup();
    cheat_caller_address(genesis.contract_address, owner(), CheatSpan::Indefinite);
    genesis.set_partner_share_cap(usdc.contract_address, 1000);
    let shares = genesis.get_partner_share_cap(usdc.contract_address);
    assert(shares == 1000, 'PARTNER SHARES MISMATCH');

    genesis.remove_partner_share_cap(usdc.contract_address);
    let shares = genesis.get_partner_share_cap(usdc.contract_address);
    assert(shares == 0, 'PARTNER SHARES CAP SHOULD BE 0');
}

#[test]
#[should_panic(expected: 'Pausable: paused')]
fn test_genesis_mint_should_panic_on_pause() {
    let (genesis, usdt, _) = setup();
    cheat_caller_address(genesis.contract_address, owner(), CheatSpan::TargetCalls(1));
    genesis.pause();
    feign_mint_share(genesis, usdt, 1000);
}

#[test]
#[should_panic(expected: 'Pausable: paused')]
fn test_genesis_transfer_should_panic_on_pause() {
    let (genesis, _) = default_mint_context();
    cheat_caller_address(genesis.contract_address, owner(), CheatSpan::TargetCalls(1));
    genesis.pause();
    cheat_caller_address(genesis.contract_address, charlie(), CheatSpan::TargetCalls(1));
    genesis.transfer_share(alice(), 1);
}

#[test]
fn test_genesis_mint_and_transfer_success_on_unpause() {
    let (genesis, usdt, _) = setup();
    cheat_caller_address(genesis.contract_address, owner(), CheatSpan::TargetCalls(2));
    genesis.pause();
    genesis.unpause();
    feign_mint_share(genesis, usdt, 100000);
    cheat_caller_address(genesis.contract_address, charlie(), CheatSpan::TargetCalls(1));
    genesis.transfer_share(alice(), 1);
}
