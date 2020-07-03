#include "tzip-12/lib/fa2_transfer_hook_lib.ligo"
#include "tzip-12/lib/fa2_hooks_lib.ligo"

type storage is record [
  fa2_registry : fa2_registry;
  descriptor : permissions_descriptor;
]

type  entry_points is
  | Tokens_transferred_hook of transfer_descriptor_param
  | Register_with_fa2 of contract(fa2_with_hook_entry_points)

function tokens_transferred_hook(const pm : transfer_descriptor_param; const s : storage) : list(operation) * storage is 
block {
    const p : transfer_descriptor_param_ = Layout.convert_to_right_comb (pm);
    const u : unit = validate_hook_call (Tezos.sender, s.fa2_registry);
    const ops : list(operation) = owners_transfer_hook(record [ligo_param = p; michelson_param = pm], s.descriptor);
} with (ops, s)

function register(const fa2 : contract(fa2_with_hook_entry_points); const s : storage) : list(operation) * storage is 
block {
   const ret : list(operation) * set(address) = register_with_fa2 (fa2, s.descriptor, s.fa2_registry);
    s.fa2_registry := ret.1;
} with (list [ret.0], s)

function main (const param : entry_points; const s : storage) : list(operation) * storage is
 block { skip } with
  case param of
  | Tokens_transferred_hook (pm) -> tokens_transferred_hook(pm, s)
  | Register_with_fa2 (fa2) -> register(fa2, s.descriptor, s.fa2_registry)
end