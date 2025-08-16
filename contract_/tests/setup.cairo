use contract_::BigIncGenesis::IBigIncGenesisDispatcher;
use core::result::ResultTrait;
use openzeppelin::token::erc20::interface::IERC20Dispatcher;
use openzeppelin::utils::serde::SerializedAppend;
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::ContractAddress;

pub const OWNER: felt252 = 'owner';
pub const USER1: felt252 = 'user1';
pub const USER2: felt252 = 'user2';
const USDT_INITIAL_SUPPLY: u256 = 1000000000000_u256; // 1M USDT with 6 decimals
const USDC_INITIAL_SUPPLY: u256 = 1000000000000_u256; // 1M USDC with 6 decimals

pub fn owner() -> ContractAddress {
    OWNER.try_into().unwrap()
}

pub fn deploy_mock_erc20(
    name: ByteArray, symbol: ByteArray, initial_supply: u256, recipient: ContractAddress,
) -> ContractAddress {
    let contract = declare("MockERC20").unwrap().contract_class();
    let mut constructor_args = array![];

    constructor_args.append_serde(initial_supply);
    constructor_args.append_serde(recipient);

    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
    contract_address
}

pub fn deploy_big_inc_genesis(
    usdt_address: ContractAddress, usdc_address: ContractAddress,
) -> ContractAddress {
    let contract = declare("BigIncGenesis").unwrap().contract_class();
    let (contract_address, _) = contract
        .deploy(@array![usdt_address.into(), usdc_address.into(), OWNER.try_into().unwrap()])
        .unwrap();
    contract_address
}

pub fn setup() -> (IBigIncGenesisDispatcher, IERC20Dispatcher, IERC20Dispatcher) {
    let usdt_address = deploy_mock_erc20("USDT", "USDT", USDT_INITIAL_SUPPLY, owner());
    let usdc_address = deploy_mock_erc20("USDC", "USDC", USDC_INITIAL_SUPPLY, owner());
    let big_inc_address = deploy_big_inc_genesis(usdt_address, usdc_address);
    let genesis_dispatcher = IBigIncGenesisDispatcher { contract_address: big_inc_address };
    let usdt_dispatcher = IERC20Dispatcher { contract_address: usdt_address };
    let usdc_dispatcher = IERC20Dispatcher { contract_address: usdc_address };

    (genesis_dispatcher, usdt_dispatcher, usdc_dispatcher)
}
