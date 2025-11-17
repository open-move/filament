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

public fun update_base_fee(blueprint: &mut Blueprint, cap: &BlueprintCap, new_fee: u64) {
    assert_valid_cap(blueprint, cap);
    blueprint.base_fee = new_fee;
}

public fun update_name(blueprint: &mut Blueprint, cap: &BlueprintCap, new_name: String) {
    assert_valid_cap(blueprint, cap);
    blueprint.name = new_name;
}

fun assert_valid_cap(blueprint: &Blueprint, cap: &BlueprintCap) {
    assert!(object::id(blueprint) == cap.blueprint_id, EInvalidCapability);
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
