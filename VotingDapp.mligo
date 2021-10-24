//the useed types in the contract
type contestant_supply = { id: int; name : string ; occupation : string ; votes : int ; block : bool; amount : tez ; }
type contestant_storage = ( nat, contestant_supply ) map
type return = operation list * contestant_storage
type contestant_id = nat


//types that are required for contestant transfer function 
type transfer_destination =
[@layout:comb]
{
  to_ : address;
  contestant_id : contestant_id;
  amount : nat;
}
 
type transfer =
[@layout:comb]
{
  from_ : address;
  txs : transfer_destination list;
}

//address to recieve money from contestant sales
let admin_address : address = ("tz1Rt5zRn6hU9g3zLvcZYqx6aFTSW8Fg2GJV" : address)


let update_vote( contestant_kind_index, contestant_kind, storage : contestant_id * contestant_supply * contestant_storage): contestant_storage =

  if (contestant_kind.block = false) then
    let contestant_storage: contestant_storage = Map.update
      contestant_kind_index
      (Some { contestant_kind with vote += 1 })
      contestant_storage
    in
    contestant_storage



// main function
let main (contestant_kind_index, contestant_storage : nat * contestant_storage) : return =
    //checks if the contestant exist
  let contestant_kind : contestant_supply =
    match Map.find_opt (contestant_kind_index) contestant_storage with
    | Some k -> k
    | None -> (failwith "Sorry, Candidate you are looking for does not exist" : contestant_supply)
  in

  // Check if contestant is block
  let () = if contestant_kind.block = true then
    failwith "Sorry, You can not vote for this contestant currently now!"
  in

 //Update our vote in `contestant_storage`.
  let contestant_storage = update_vote( contestant_kind_index, contestant_kind, contestant_storage )
  in

  let tr : transfer = {
    from_ = Tezos.self_address;
    txs = [ {
      to_ = Tezos.sender;
      contestant_id = abs( contestant_kind.id );
      amount = 1n;
    } ];
  } 
  in

  // Transfer FA2 functionality
  let entrypoint : transfer list contract = 
    match ( Tezos.get_entrypoint_opt "%transfer" admin_address : transfer list contract option ) with
    | None -> ( failwith "Invalid external token contract" : transfer list contract )
    | Some e -> e
  in
 
  let fa2_operation : operation =
    Tezos.transaction [tr] 0tez entrypoint
  in

  // Payout to the Publishers address.
  let receiver : unit contract =
    match (Tezos.get_contract_opt admin_address : unit contract option) with
    | Some (contract) -> contract
    | None -> (failwith ("Not a contract") : (unit contract))
  in
 
  let payout_operation : operation = 
    Tezos.transaction unit amount receiver 
  in

 ([fa2_operation ; payout_operation], contestant_storage)
