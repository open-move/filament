module filament::blueprint;

use enclave::enclave::EnclaveConfig;
use filament::filament::FILAMENT;
use filament::protocol::ProtocolCap;
use std::string::String;
use sui::derived_object;

const EInvalidCapability: u64 = 0;

public struct Blueprint has key, store {
    id: UID,
    name: String,
    base_fee: u64,
    num_agents: u64,
    enclave_config_id: ID,
}

public struct BlueprintCap has key, store {
    id: UID,
    blueprint_id: ID,
}

public struct BlueprintCapKey() has copy, drop, store;

public fun create_blueprint(
    _protocol_cap: &mut ProtocolCap,
    enclave_config: &EnclaveConfig<FILAMENT>,
    name: String,
    base_fee: u64,
    ctx: &mut TxContext,
): (Blueprint, BlueprintCap) {
    let mut blueprint = Blueprint {
        id: object::new(ctx),
        name,
        base_fee,
        num_agents: 0,
        enclave_config_id: object::id(enclave_config),
    };

    let cap = BlueprintCap {
        id: derived_object::claim(&mut blueprint.id, BlueprintCapKey()),
        blueprint_id: blueprint.id.to_inner(),
    };

    (blueprint, cap)
}

public fun name(blueprint: &Blueprint): String {
    blueprint.name
}

public fun enclave_config_id(blueprint: &Blueprint): ID {
    blueprint.enclave_config_id
}

public fun base_fee(blueprint: &Blueprint): u64 {
    blueprint.base_fee
}

public fun num_agents(blueprint: &Blueprint): u64 {
    blueprint.num_agents
}

public fun update_base_fee(blueprint: &mut Blueprint, cap: &BlueprintCap, new_fee: u64) {
    blueprint.assert_valid_cap(cap);
    blueprint.base_fee = new_fee;
}

public fun update_name(blueprint: &mut Blueprint, cap: &BlueprintCap, new_name: String) {
    blueprint.assert_valid_cap(cap);
    blueprint.name = new_name;
}

public fun increment_num_agents(blueprint: &mut Blueprint, cap: &BlueprintCap) {
    blueprint.assert_valid_cap(cap);
    blueprint.num_agents = blueprint.num_agents + 1;
}

public fun assert_valid_cap(blueprint: &Blueprint, cap: &BlueprintCap) {
    assert!(object::id(blueprint) == cap.blueprint_id, EInvalidCapability);
}

public(package) fun extend(blueprint: &mut Blueprint): &mut UID {
    &mut blueprint.id
}

#[allow(lint(share_owned))]
entry fun create_blueprint_entry(
    protocol_cap: &mut ProtocolCap,
    enclave_config: &EnclaveConfig<FILAMENT>,
    name: String,
    base_fee: u64,
    ctx: &mut TxContext,
) {
    let (blueprint, cap) = create_blueprint(
        protocol_cap,
        enclave_config,
        name,
        base_fee,
        ctx,
    );

    transfer::share_object(blueprint);
    transfer::public_transfer(cap, ctx.sender());
}
