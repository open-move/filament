module filament::protocol;

use enclave::enclave::{Self, Cap as EnclaveCap};
use filament::filament::FILAMENT;
use std::string::String;

public struct ProtocolCap has key {
    id: UID,
    enclave_cap: EnclaveCap<FILAMENT>,
}

public(package) fun create(witness: FILAMENT, ctx: &mut TxContext): ProtocolCap {
    let enclave_cap = enclave::new_cap(witness, ctx);

    ProtocolCap {
        id: object::new(ctx),
        enclave_cap,
    }
}

public fun create_enclave_config(
    protocol_cap: &mut ProtocolCap,
    name: String,
    pcrs: vector<vector<u8>>,
    ctx: &mut TxContext,
) {
    protocol_cap.enclave_cap.create_enclave_config(name, pcrs[0], pcrs[1], pcrs[2], ctx)
}
