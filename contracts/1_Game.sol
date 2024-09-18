// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Game {

    struct Ante {
        uint fees; // per game entry fee
        uint max_entries; // max entries per bout
        uint start; // time in minutes from genesis epoch to tournament start
        uint end; // time in minutes from the genesis epoch to tournament end
        bool disbursed; // have the funds been disbursed?
        bool canceled; // was the tourney canceled?
    }


    uint count = 0;
    address ADMIN = 0xD0dC8A261Ad1B75A92C5e502AE10c3Fde042b879;
    uint pending = 0;
   
    mapping (uint => Ante) public tourneys;
    mapping (uint => uint) public prizepools;
    mapping (uint => address[]) public participants;
    
    
    
    


  
    function createTourney(uint fee_val, uint max_val, uint start_val, uint duration) public {
        require(
            msg.sender == ADMIN, 
            "an admin only function"
        );
        require(
            fee_val >= 1,
            "amount sent must be at least 0.01 ETH"
        );
        uint st = (block.timestamp / (60)) + start_val;
        uint ed = st + duration;
        require(
            start_val <= 720,
            "tourney must start within 12 hrs!"
        );
        require(
            start_val >= 15,
            "tourney must start 15 mins or later!"
        );
        require(
            duration >= 15,
            "tourney must run for at least for 15 mins"
        );
        require(
            duration <= 45,
            "tourney can run for at most for 45 mins"
        );


        uint a_id = count + 1;

       
        Ante memory a = Ante({
            fees: fee_val,
            max_entries: max_val,
            start: st,
            end: ed,
            disbursed: false,
            canceled: false
        });
        tourneys[a_id] = a;
        prizepools[a_id] = 0;
        count = a_id;

    }

    function participate(uint a_id) public payable {
        Ante memory a = tourneys[a_id];
        require (a.fees * 0.01 ether <= msg.value, "not enough tokens attached to fulfull entry fee");
        require (a.disbursed == false, "the tourney has already ended");
        require (a.canceled == false, "the tourney has been canceled!");
        uint tnow = (block.timestamp / (60));
        require (tnow < a.start, "the tourney has already started!");
        require (participants[a_id].length < a.max_entries, "the tourney slots are full!");
        participants[a_id].push(msg.sender);
        uint pp = prizepools[a_id];
        prizepools[a_id] = pp + a.fees;
        pending = pending + a.fees;
    }


    function cancel(uint a_id) public {
        Ante memory a = tourneys[a_id];
        uint tnow = (block.timestamp / (60));
        require (msg.sender == ADMIN, "admin only function");
        require (a.disbursed == false, "the prize has already been disbursed");
        require (a.canceled == false, "the tourney has already been canceled");
        require (a.start > tnow, "the tourney has already started!");
        require (a.max_entries >= 2 * participants[a_id].length, "enough participants to continue");

        
        tourneys[a_id] = Ante({
            fees: a.fees,
            max_entries: a.max_entries,
            start: a.start,
            end: a.end,
            disbursed: false,
            canceled: true
        });
        for (uint i = 0; i < participants[a_id].length; i++){
            payable(participants[a_id][i]).transfer(a.fees * 0.01 ether);
        }
        pending = pending - (a.fees * participants[a_id].length);
        


    }

    
    function distribute(uint a_id, address[5] memory winners) public {
        Ante memory a = tourneys[a_id];
        uint tnow = (block.timestamp / (60));
        require (msg.sender == ADMIN, "admin only function");
        require (a.disbursed == false, "the prize has already been disbursed");
        require (a.canceled == false, "the tourney has already been canceled");
        require (a.end < tnow, "the tourney needs to be completed!");
        require (a.max_entries < 2 * participants[a_id].length, "not enough participants to continue");

        uint flag1 = 0;
        uint flag2 = 0;

        for (uint i = 0; i < participants[a_id].length; i++){
            address p = participants[a_id][i];
            if (p == winners[0] || p == winners[1] || p == winners[2] || p == winners[3] || p == winners[4]){
                flag1 = flag1 + 1;
            }
        }

        for (uint j = 0; j < 5; j++){
            if (winners[j] == address(0)){
                flag2 = flag2 + 1;
            }
        }

        require (flag1 + flag2 == 5, "not all winners from participant list");

        uint pp = prizepools[a_id];
        if (flag2 == 0){
            payable(winners[0]).transfer((pp *3 * 0.0099 ether)/8);
            payable(winners[1]).transfer((pp *2 * 0.0099 ether)/8); 
            payable(winners[2]).transfer((pp *1 * 0.0099 ether)/8); 
            payable(winners[3]).transfer((pp *1 * 0.0099 ether)/8); 
            payable(winners[4]).transfer((pp *1 * 0.0099 ether)/8);   
        }
        else if (flag2 == 1){
            payable(winners[0]).transfer((pp *3 * 0.0099 ether)/7);
            payable(winners[1]).transfer((pp *2 * 0.0099 ether)/7); 
            payable(winners[2]).transfer((pp *1 * 0.0099 ether)/7); 
            payable(winners[3]).transfer((pp *1 * 0.0099 ether)/7); 
        }
        else if (flag2 == 2){
            payable(winners[0]).transfer((pp *3 * 0.0099 ether)/6);
            payable(winners[1]).transfer((pp *2 * 0.0099 ether)/6); 
            payable(winners[2]).transfer((pp *1 * 0.0099 ether)/6); 
        }
        else if (flag2 == 3){
            payable(winners[0]).transfer((pp *3 * 0.0099 ether)/5);
            payable(winners[1]).transfer((pp *2 * 0.0099 ether)/5); 
        }
        else if (flag2 == 4){
            payable(winners[0]).transfer((pp * 0.0099 ether));
        }
        else {
            require (false, "must pick at least one winner");
        }

        pending = pending - (prizepools[a_id]);

        
        
        
        
        
    }

    function extract(uint amt) public {
        require (msg.sender == ADMIN, "admin only function");
        require (amt + pending < address(this).balance, "cannot withdraw this much");
        payable(ADMIN).transfer(amt * 0.01 ether);
    } 

   
    
    
}
