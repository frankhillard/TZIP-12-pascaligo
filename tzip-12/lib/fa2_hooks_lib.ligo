// SPDX-FileCopyrightText: 2020 tqtezos
// SPDX-License-Identifier: MIT

#if !FA2_BEHAVIORS
#define FA2_BEHAVIORS

#include "../fa2_interface.ligo"

(* ------------------------------------------------------------- *)

type get_owners is transfer_descriptor -> list(option(address))


type to_hook is address -> option (contract (transfer_descriptor_param))


function get_owners_from_batch (const batch : list(transfer_descriptor); const get_owners : get_owners) : set(address) is block {
  function apply_get_owners(const acc : set(address); const tx : transfer_descriptor) : set(address) is block {
    const owners : list(option(address)) = get_owners (tx);
  } with List.fold( 
      (function (const acc : set(address); const o: option(address)) : set(address) is case o of
        | None -> acc
        | Some (a) -> Set.add (a, acc)
      end
      ),
      owners,
      acc
    )
} with List.fold(apply_get_owners, batch, (Set.empty : set(address)))

(*
 * Helper function that converts `transfer_param` to `transfer_descriptor_param`
 *)
function convert_to_transfer_descriptor
  ( const self_addr      : address
  ; const param_sender_addr : address
  ; const transfer_destination : transfer_destination
  ): transfer_descriptor_param is block
{ const transfer_destination_descriptor_ : transfer_destination_descriptor_ = record
    [ to_      = Some (transfer_destination.0)
    ; token_id = transfer_destination.1.0
    ; amount   = transfer_destination.1.1
    ]
; const transfer_destination_descriptor : transfer_destination_descriptor =
    Layout.convert_to_right_comb ((transfer_destination_descriptor_ : transfer_destination_descriptor_))
; const transfer_descriptor_ : transfer_descriptor_ = record
    [ from_ = Some (param_sender_addr)
    ; txs   = list [ transfer_destination_descriptor ]
    ]
; const transfer_descriptor_batch : list (transfer_descriptor) = list
    [ Layout.convert_to_right_comb ((transfer_descriptor_ : transfer_descriptor_)) ]
; const transfer_descriptor_param : transfer_descriptor_param_ = record
    [ fa2      = self_addr
    ; batch    = transfer_descriptor_batch
    ; operator = Tezos.sender
    ]
} with Layout.convert_to_right_comb ((transfer_descriptor_param : transfer_descriptor_param_))

(*
 * Append a transaction of transfer hook call
 * to a list of operations provided
 *)
function validate_owner_hook( const self_addr : address; const param_sender_addr : address; const is_sender : bool; const ops : list (operation); const transfer_destination : transfer_destination
; const to_hook : to_hook) : list(operation) is block
{ 
  const hook_addr : address = if is_sender then param_sender_addr else transfer_destination.0;
} with case to_hook (hook_addr) of
    Some (hook) ->
      Tezos.transaction (convert_to_transfer_descriptor(self_addr, param_sender_addr, transfer_destination), 0mutez, hook) # ops
  | None -> ops
  end

(*
 * Retrieves contract from `tokens_received` entrypoint
 *)
function to_receiver_hook( const receiving_address : address ) : option (contract (transfer_descriptor_param)) is
    Tezos.get_entrypoint_opt ("%tokens_received", receiving_address)

(*
 * Retrieves contract from `tokens_sent` entrypoint
 *)
function to_sender_hook( const sender_address : address) : option (contract (transfer_descriptor_param)) is
    Tezos.get_entrypoint_opt ("%tokens_sent", sender_address)

(*
 * Make a list of transfer hook calls for each sender or receiver
 *)
function validate_owner_hooks( const params : transfer_param; const self_addr : address; const is_sender : bool) : list (operation) is 
  block { 
    const to_hook : to_hook = if is_sender then to_sender_hook else to_receiver_hook;

    function validate( const ops : list (operation); const td  : transfer_destination) : list (operation) is 
    block { 
      const owner : address = if is_sender then params.0 else td.0
    } with validate_owner_hook (self_addr, params.0, is_sender, ops, td, to_hook)

} with List.fold (validate, params.1, (nil : list (operation)))

function merge_operations
  ( const fst : list (operation)
  ; const snd : list (operation)
  ) : list (operation) is List.fold
    ( function
      ( const operations : list (operation)
      ; const operation  : operation
      ) : list (operation) is operation # operations
    , fst
    , snd
    )

(*
 * Construct a list of transfer hook calls for each sender and
 * receiver if such were specified
 *)
function generic_transfer_hook( const transfer_param : transfer_param) : list (operation) is 
block { 
  const self_addr : address = Tezos.self_address;
  const sender_ops : list (operation) = validate_owner_hooks (transfer_param, self_addr, True);
  const receiver_ops : list (operation) = validate_owner_hooks (transfer_param, self_addr, False);
} with merge_operations (receiver_ops, sender_ops)

#endif