//the useed types in the contract
type contestant_supply = { id: int; name : string ; occupation : string ; votes : int ; block : bool; }
type contestant_storage = (nat, contestant_supply) map
type return = operation list * property_storage
type contestant_id = nat


//types that are required for property transfer function 
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

//address to recieve money from property sales
let admin_address : address = ("tz1iYZE6TxZ5B4wDjuVzvi8s456h788DbZAv" : address)


let update_item(property_kind_index,property_kind,storage:property_id*property_supply*property_storage): property_storage =

  if (property_kind.sale_status = true) then
    let property_storage: property_storage = Map.update
      property_kind_index
      (Some { property_kind with out_of_stock = true })
      property_storage
    in
    property_storage



// main function
let main (contestant_kind_index, contestant_storage : nat * contestant_storage) : return =
    //checks if the property exist
  let contestant_kind : contestant_supply =
    match Map.find_opt (contestant_kind_index) contestant_storage with
    | Some k -> k
    | None -> (failwith "Sorry, Candidate you are looking for does not exist" : contestant_supply)
  in

  // Check if contestant is block
  let () = if contestant_kind.block = true then
    failwith "Sorry, You can not vote for this contestant currently now!"
  in

 //Update our `contestant_storage` stock levels.
  let contestant_storage = update_item(contestant_kind_index,contestant_kind,contestant_storage)
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
    match ( Tezos.get_entrypoint_opt "%transfer" property_kind.user_address : transfer list contract option ) with
    | None -> ( failwith "Invalid external token contract" : transfer list contract )
    | Some e -> e
  in
 
  let fa2_operation : operation =
    Tezos.transaction [tr] 0tez entrypoint
  in

  // Payout to the Publishers address.
  let receiver : unit contract =
    match (Tezos.get_contract_opt publisher_address : unit contract option) with
    | Some (contract) -> contract
    | None -> (failwith ("Not a contract") : (unit contract))
  in
 
  let payout_operation : operation = 
    Tezos.transaction unit amount receiver 
  in

 ([fa2_operation ; payout_operation], property_storage)
