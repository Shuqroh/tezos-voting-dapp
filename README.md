# VotingDapp
1. With CameLIGO
2. A smart contract for users to vote for their contestant
## Storage example

    Map.literal [ 
     (0n, {
       id: 1;
       amount = 12mutez;
       name = "Ryan Dahl";
       occupation = "Software Developer";
       block = false;
       votes = 0;
     }); 
     (1n, {
       id: 2;
       amount = 12mutez;
       name = "Mark Zuckerberg";
       occupation = "Software Developer";
       block = false;
       votes = 0;
     });
     ...
    ]
