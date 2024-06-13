pub use agent::Agent;
use cron_schedule::Schedule;
use near_sdk::{
    assert_one_yocto,
    borsh::{self, BorshDeserialize, BorshSerialize},
    collections::{LookupMap, TreeMap, UnorderedMap, Vector},
    env,
    json_types::{Base64VecU8, ValidAccountId, U128, U64},
    log, near_bindgen,
    serde::{Deserialize, Serialize},
    serde_json::json,
    AccountId, Balance, BorshStorageKey, Gas, PanicOnDefault, Promise, PromiseResult, StorageUsage,
};
use std::str::FromStr;
pub use tasks::Task;
pub use tasks::TaskHumanFriendly;
pub use triggers::Trigger;

mod agent;
mod owner;
mod storage_impl;
mod tasks;
mod triggers;
mod utils;
mod views;

near_sdk::setup_alloc!();

// Balance & Fee Definitions
pub const ONE_NEAR: u128 = 1_000_000_000_000_000_000_000_000;
pub const BASE_BALANCE: Balance = ONE_NEAR * 5; // safety overhead
pub const GAS_BASE_PRICE: Balance = 100_000_000;
pub const GAS_BASE_FEE: Gas = 3_000_000_000_000;
// actual is: 13534954161128, higher in case treemap rebalance
pub const GAS_FOR_CALLBACK: Gas = 30_000_000_000_000;
pub const AGENT_BASE_FEE: Balance = 500_000_000_000_000_000_000; // 0.0005 Ⓝ (2000 tasks = 1 Ⓝ)
pub const STAKE_BALANCE_MIN: u128 = 10 * ONE_NEAR;

// Boundary Definitions
pub const MAX_BLOCK_TS_RANGE: u64 = 1_000_000_000_000_000_000;
pub const SLOT_GRANULARITY: u64 = 60_000_000_000; // 60 seconds in nanos
pub const AGENT_EJECT_THRESHOLD: u128 = 600; // how many slots an agent can miss before being ejected. 10 * 60 = 1hr
pub const NANO: u64 = 1_000_000_000;

#[derive(BorshStorageKey, BorshSerialize)]
pub enum StorageKeys {
    Tasks,
    Agents,
    Slots,
    AgentsActive,
    AgentsPending,
    Triggers,
    TaskOwners,
}

#[near_bindgen]
#[derive(BorshDeserialize, BorshSerialize, PanicOnDefault)]
// #[derive(BorshDeserialize, BorshSerialize, Deserialize, Serialize, PanicOnDefault)]
// #[serde(crate = "near_sdk::serde")]
pub struct Contract {
    // Runtime
    paused: bool,
    owner_id: AccountId,
    treasury_id: Option<AccountId>,

    // Agent management
    agents: LookupMap<AccountId, Agent>,
    agent_active_queue: Vector<AccountId>,
    agent_pending_queue: Vector<AccountId>,
    // The ratio of tasks to agents, where index 0 is agents, index 1 is tasks
    // Example: [1, 10]
    // Explanation: For every 1 agent, 10 tasks per slot are available.
    // NOTE: Caveat, when there are odd number of tasks or agents, the overflow will be available to first-come first-serve. This doesnt negate the possibility of a failed txn from race case choosing winner inside a block.
    // NOTE: The overflow will be adjusted to be handled by sweeper in next implementation.
    agent_task_ratio: [u64; 2],
    agent_active_index: u64,
    agents_eject_threshold: u128,

    // Basic management
    slots: TreeMap<u128, Vec<Vec<u8>>>,
    tasks: UnorderedMap<Vec<u8>, Task>,
    task_owners: UnorderedMap<AccountId, Vec<Vec<u8>>>,
    triggers: UnorderedMap<Vec<u8>, Trigger>,

    // Economics
    available_balance: Balance, // tasks + rewards balance
    staked_balance: Balance,
    agent_fee: Balance,
    gas_price: Balance,
    proxy_callback_gas: Gas,
    slot_granularity: u64,

    // Storage
    agent_storage_usage: StorageUsage,
    trigger_storage_usage: StorageUsage,
}

// TODO: Setup state migration for tasks/triggers, including initial storage calculation
#[near_bindgen]
impl Contract {
    /// ```bash
    /// near call manager_v1.croncat.testnet new --accountId manager_v1.croncat.testnet
    /// ```
    #[init]
    pub fn new() -> Self {
        let mut this = Contract {
            paused: false,
            owner_id: env::signer_account_id(),
            treasury_id: None,
            tasks: UnorderedMap::new(StorageKeys::Tasks),
            task_owners: UnorderedMap::new(StorageKeys::TaskOwners),
            triggers: UnorderedMap::new(StorageKeys::Triggers),
            agents: LookupMap::new(StorageKeys::Agents),
            agent_active_queue: Vector::new(StorageKeys::AgentsActive),
            agent_pending_queue: Vector::new(StorageKeys::AgentsPending),
            agent_task_ratio: [1, 2],
            agent_active_index: 0,
            agents_eject_threshold: AGENT_EJECT_THRESHOLD,
            slots: TreeMap::new(StorageKeys::Slots),
            available_balance: 0,
            staked_balance: 0,
            agent_fee: AGENT_BASE_FEE,
            gas_price: GAS_BASE_PRICE,
            proxy_callback_gas: GAS_FOR_CALLBACK,
            slot_granularity: SLOT_GRANULARITY,
            agent_storage_usage: 0,
            trigger_storage_usage: 0,
        };
        this.measure_account_storage_usage();
        this
    }

    /// Measure the storage an agent will take and need to provide
    fn measure_account_storage_usage(&mut self) {
        let initial_storage_usage = env::storage_usage();
        let max_len_string = "a".repeat(64);

        // Create a temporary, dummy entry and measure the storage used.
        let tmp_agent = Agent {
            status: agent::AgentStatus::Pending,
            payable_account_id: max_len_string.clone(),
            balance: U128::from(0),
            total_tasks_executed: U128::from(0),
            last_missed_slot: 0,
        };
        self.agents.insert(&max_len_string, &tmp_agent);
        self.agent_storage_usage = env::storage_usage() - initial_storage_usage;
        // Remove the temporary entry.
        self.agents.remove(&max_len_string);

        // Calc the trigger storage needs
        let tmp_hash = max_len_string.clone().try_to_vec().unwrap();
        let tmp_trigger = Trigger {
            owner_id: max_len_string.clone(),
            contract_id: max_len_string.clone(),
            function_id: max_len_string.clone(),
            task_hash: Base64VecU8::from(tmp_hash.clone()),
            arguments: Base64VecU8::from("a".repeat(1024).try_to_vec().unwrap()),
        };
        self.triggers.insert(&tmp_hash, &tmp_trigger);
        self.trigger_storage_usage = env::storage_usage() - initial_storage_usage;
        // Remove the temporary entry.
        self.triggers.remove(&tmp_hash);
    }

    /// Takes an optional `offset`: the number of seconds to offset from now (current block timestamp)
    /// If no offset, returns current slot based on current block timestamp
    /// If offset, returns next slot based on current block timestamp & seconds offset
    fn get_slot_id(&self, offset: Option<u64>) -> u128 {
        let current_block_ts = env::block_timestamp();

        let slot_id: u64 = if let Some(o) = offset {
            // NOTE: Assumption here is that the offset will be in seconds. (60 seconds per slot)
            let next = current_block_ts + (self.slot_granularity + o);

            // Protect against extreme future block schedules
            u64::min(next, current_block_ts + MAX_BLOCK_TS_RANGE)
        } else {
            current_block_ts
        };

        // rounded to nearest granularity
        let slot_remainder = slot_id % self.slot_granularity;
        let slot_id_round = slot_id.saturating_sub(slot_remainder);

        u128::from(slot_id_round)
    }

    /// Parse cadence into a schedule
    /// Get next approximate block from a schedule
    /// return slot from the difference of upcoming block and current block
    fn get_slot_from_cadence(&self, cadence: String) -> u128 {
        let current_block_ts = env::block_timestamp(); // NANOS

        // Schedule params
        // NOTE: eventually use TryFrom
        let schedule = Schedule::from_str(&cadence).unwrap();
        let next_ts = schedule.next_after(&current_block_ts).unwrap();
        let next_diff = next_ts - current_block_ts;

        // Get the next slot, based on the timestamp differences
        let current = self.get_slot_id(None);
        let next_slot = self.get_slot_id(Some(next_diff));

        if current == next_slot {
            // Add slot granularity to make sure the minimum next slot is a block within next slot granularity range
            current + u128::from(self.slot_granularity)
        } else {
            next_slot
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use near_sdk::json_types::ValidAccountId;
    use near_sdk::test_utils::{accounts, VMContextBuilder};
    use near_sdk::{testing_env, MockedBlockchain};

    const BLOCK_START_BLOCK: u64 = 52_201_040;
    const BLOCK_START_TS: u64 = 1_624_151_503_447_000_000;

    fn get_context(predecessor_account_id: ValidAccountId) -> VMContextBuilder {
        let mut builder = VMContextBuilder::new();
        builder
            .current_account_id(accounts(0))
            .signer_account_id(predecessor_account_id.clone())
            .signer_account_pk(b"ed25519:4ZhGmuKTfQn9ZpHCQVRwEr4JnutL8Uu3kArfxEqksfVM".to_vec())
            .predecessor_account_id(predecessor_account_id)
            .block_index(BLOCK_START_BLOCK)
            .block_timestamp(BLOCK_START_TS);
        builder
    }

    #[test]
    fn test_contract_new() {
        let mut context = get_context(accounts(1));
        testing_env!(context.build());
        let contract = Contract::new();
        testing_env!(context.is_view(true).build());
        assert!(contract.get_tasks(None, None, None).is_empty());
    }
}
