module filament::task;

use filament::agent::{Agent, AgentCap};
use sui::balance::{Self, Balance};
use sui::clock::Clock;
use sui::coin::Coin;
use sui::derived_object;
use sui::sui::SUI;

const ETaskNotPending: u64 = 0;
const ETaskNotInProgress: u64 = 1;

public enum TaskState has copy, drop, store {
    Pending,
    InProgress,
    Expired,
    Failed,
    Completed,
}

public struct Task has key {
    id: UID,
    expires_at: u64,
    payload: vector<u8>,
    target_agent_id: ID,
    fee_pool: Balance<SUI>,
    failed_at: Option<u64>,
    started_at: Option<u64>,
    completed_at: Option<u64>,
}

public struct TaskKey(u64) has copy, drop, store;

public fun state(task: &Task, clock: &Clock): TaskState {
    if (task.completed_at.is_some()) return TaskState::Completed;
    if (task.failed_at.is_some()) return TaskState::Failed;

    if (clock.timestamp_ms() > task.expires_at) return TaskState::Expired;
    if (task.started_at.is_some()) return TaskState::InProgress;
    TaskState::Pending
}

public fun create(agent: &mut Agent, payload: vector<u8>, fee: Coin<SUI>, expires_at: u64): Task {
    let task_index = agent.num_tasks();

    let task = Task {
        id: derived_object::claim(agent.extend(), TaskKey(task_index)),
        payload,
        expires_at,
        failed_at: option::none(),
        started_at: option::none(),
        target_agent_id: agent.id(),
        completed_at: option::none(),
        fee_pool: fee.into_balance(),
    };

    agent.increment_num_tasks();
    task
}

public fun mark_started(task: &mut Task, agent_cap: &AgentCap, clock: &Clock) {
    assert!(task.state(clock) == TaskState::Pending, ETaskNotPending);
    assert!(agent_cap.agent_id() == task.target_agent_id, ETaskNotInProgress);
    
    task.started_at.fill(clock.timestamp_ms());
}

public fun mark_completed(task: &mut Task, agent_cap: &AgentCap, clock: &Clock) {
    assert!(task.state(clock) == TaskState::InProgress, ETaskNotInProgress);
    assert!(agent_cap.agent_id() == task.target_agent_id, ETaskNotInProgress);

    task.completed_at.fill(clock.timestamp_ms());
}

public fun mark_failed(task: &mut Task, agent_cap: &AgentCap, clock: &Clock) {
    assert!(task.state(clock) == TaskState::InProgress, ETaskNotInProgress);
    assert!(agent_cap.agent_id() == task.target_agent_id, ETaskNotInProgress);
    
    task.failed_at.fill(clock.timestamp_ms());
}

public fun target_agent_id(task: &Task): ID {
    task.target_agent_id
}

public fun payload(task: &Task): &vector<u8> {
    &task.payload
}

public fun fee_pool_value(task: &Task): u64 {
    balance::value(&task.fee_pool)
}

public fun expires_at(task: &Task): u64 {
    task.expires_at
}

public fun started_at(task: &Task): Option<u64> {
    task.started_at
}

// ======== Entry Functions ========

#[allow(lint(share_owned))]
entry fun create_entry(agent: &mut Agent, payload: vector<u8>, fee: Coin<SUI>, expires_at: u64) {
    let task = create(agent, payload, fee, expires_at);

    transfer::share_object(task);
}
