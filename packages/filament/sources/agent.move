module filament::agent;

use enclave::enclave::Enclave;
use filament::blueprint::{Blueprint, BlueprintCap};
use filament::filament::FILAMENT;
use sui::derived_object;

const EInvalidCapability: u64 = 0;

public struct Agent has key {
    id: UID,
    enclave_id: ID,
    blueprint_id: ID,
}

public struct AgentCap has key, store {
    id: UID,
    agent_id: ID,
}

public struct AgentKey(u64) has copy, drop, store;
public struct AgentCapKey() has copy, drop, store;

public fun create_agent(
    blueprint: &mut Blueprint,
    blueprint_cap: &BlueprintCap,
    enclave: &Enclave<FILAMENT>,
): (Agent, AgentCap) {
    blueprint.assert_valid_cap(blueprint_cap);

    let agent_index = blueprint.num_agents();
    let mut agent = Agent {
        id: derived_object::claim(blueprint.extend(), AgentKey(agent_index)),
        blueprint_id: object::id(blueprint),
        enclave_id: object::id(enclave),
    };

    let cap = AgentCap {
        id: derived_object::claim(&mut agent.id, AgentCapKey()),
        agent_id: agent.id.to_inner(),
    };

    blueprint.increment_num_agents(blueprint_cap);
    (agent, cap)
}

public fun blueprint_id(agent: &Agent): ID {
    agent.blueprint_id
}

public fun enclave_id(agent: &Agent): ID {
    agent.enclave_id
}

public fun assert_valid_cap(agent: &Agent, cap: &AgentCap) {
    assert!(object::id(agent) == cap.agent_id, EInvalidCapability);
}

#[allow(lint(share_owned))]
entry fun create_agent_entry(
    blueprint: &mut Blueprint,
    blueprint_cap: &BlueprintCap,
    enclave: &Enclave<FILAMENT>,
    ctx: &TxContext,
) {
    let (agent, cap) = create_agent(blueprint, blueprint_cap, enclave);

    transfer::share_object(agent);
    transfer::public_transfer(cap, ctx.sender());
}
