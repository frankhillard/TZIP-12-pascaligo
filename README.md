# TZIP-12-pascaligo
Implementation of Financial Asset  2 standard for Tezos blockchain (written in Pascaligo)  

WIP

Based on the exemple of stablecoin of Tqtezos (https://github.com/tqtezos/stablecoin), I added hook part implementation and created a Library packaging like it is done in the repository TZIP gtilab (https://gitlab.com/tzip/tzip).

Addin some exemple soon ... 

## Exemple

### permission 

contract permission.ligo is a custom whitelist with hook exemple

### Non fungible token

Following commands to simulate operator and transfer

scenario: B owns a token , register C as operator for B, C transfer B's token to A 

```
ligo compile-contract non_fungible_token.ligo main
```

```
ligo compile-storage non_fungible_token.ligo main 'record[  ledger=(big_map end: big_map(token_id, address));  operators=(big_map end: big_map ((owner * operator), unit))  ]'
```

```
ligo compile-storage non_fungible_token.ligo main 'record[  ledger=big_map [ 1n->("tz1b7tUupMgCNw2cCLpKTkSD1NZzB5TkP2sv":address) ];  operators=(big_map end: big_map ((owner * operator), unit))  ]'
```

```
ligo dry-run --sender=tz1b7tUupMgCNw2cCLpKTkSD1NZzB5TkP2sv non_fungible_token.ligo main 'Fa2 (Update_operators(list [ (Add_operator(Layout.convert_to_right_comb((record [owner=("tz1b7tUupMgCNw2cCLpKTkSD1NZzB5TkP2sv":address);operator=("tz1faswCTDciRzE4oJ9jn2Vm2dvjeyA9fUzU":address)]: operator_param_))))]))'  'record[  ledger=big_map [ 1n->("tz1b7tUupMgCNw2cCLpKTkSD1NZzB5TkP2sv":address) ];  operators=(big_map end: big_map ((owner * operator), unit))  ]'
```

```
ligo dry-run --sender=tz1faswCTDciRzE4oJ9jn2Vm2dvjeyA9fUzU non_fungible_token.ligo main 'Fa2 (Transfer(list [ Layout.convert_to_right_comb(( record [from_=("tz1b7tUupMgCNw2cCLpKTkSD1NZzB5TkP2sv":address);txs=list [Layout.convert_to_right_comb((record [to_=("tz1gjaF81ZRRvdzjobyfVNsAeSC6PScjfQwN": address); token_id=0n; amount=1n ] : transfer_destination_)) ] ] : transfer_param_))]))' 'record[  ledger=big_map [ 1n->("tz1b7tUupMgCNw2cCLpKTkSD1NZzB5TkP2sv":address) ];  operators=big_map [ (("tz1b7tUupMgCNw2cCLpKTkSD1NZzB5TkP2sv": address), ("tz1faswCTDciRzE4oJ9jn2Vm2dvjeyA9fUzU":address))-> unit ]  ]'
```