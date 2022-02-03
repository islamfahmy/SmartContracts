// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract RockPaperScissor {
    //Rules 
    // Rock : 1, Scissor : 2, Paper :3
    // if there is a tie the reward is splitted
    // values should be between 1 and 3 
    // if one player didn't reveal the other wins
    // if both didn't reveal it will be as a tie     
     struct Player {
        bytes32 commit;
        int  choice;
        address payable  playerAdress;
        uint reward;
    }
  
    Player public player1;
    Player public player2;
    
    uint reward ; 
    uint public commitingEnd;
    uint public revealEnd;
    bool public ended;
    
    /// Address `p.playerAdress` won 
    event GameEnded(Player p);
    /// Draw 
    event Draw();

    // Errors that describe failures.

    /// The function has been called too early.
    /// Try again at `time`.
    error TooEarly(uint time);
    /// The function has been called too late.
    /// It cannot be called after `time`.
    error TooLate(uint time);
    /// The function GameEnd has already been called.
    error GameEndAlreadyCalled();
    /// address isn't for an Authorithed Player
    error NotAuthorizedPlayer();
    /// Wrong Commit 
    error NotRightCommit(); 
    
    // Modifiers are a convenient way to validate inputs to
    // functions. `onlyBefore` is applied to `bid` below:
    // The new function body is the modifier's body where
    // `_` is replaced by the old function body.
    modifier onlyBefore(uint time) {
        if (block.timestamp >= time) revert TooLate(time);
        _;
    }
    modifier onlyAfter(uint time) {
        if (block.timestamp <= time) revert TooEarly(time);
        _;
    }


    constructor(
        uint commitingTime,
        uint revealTime,
        address payable player1Address,
        address payable player2Address,
        uint rewardValue
        
        
    ) payable{
        require(rewardValue == msg.value);
        player1.playerAdress =player1Address;
        player2.playerAdress =player2Address;
        player1.choice=-1;
        player2.choice=-1;
        player1.reward=0;
        player2.reward=0;
        commitingEnd = block.timestamp + commitingTime;
        revealEnd = commitingEnd + revealTime;
        reward=msg.value;
     
        
    }

    function commit(bytes32 commitData)
        external
        payable
        onlyBefore(commitingEnd)
    {
        if(msg.sender == player1.playerAdress)
            player1.commit= commitData ;
        else if(msg.sender== player2.playerAdress)
          player2.commit= commitData;
        else revert NotAuthorizedPlayer();
        
    }
    function reveal(
        int  choice,
        uint rand
    )
        external
        onlyAfter(commitingEnd)
        onlyBefore(revealEnd)
    {
            if(choice<1 || choice >3)
                revert NotRightCommit();
            bytes32 toCheck =keccak256(abi.encodePacked(choice, rand));        
            if(msg.sender==player1.playerAdress && toCheck==player1.commit)
                player1.choice = choice;

            else if(msg.sender==player2.playerAdress && toCheck==player2.commit)
                player2.choice = choice;

            else
                revert NotRightCommit();
    }

    /// End the Game and send the highest bid
    function GameEnd()
        external
        onlyAfter(revealEnd)
    {
        if (ended) revert GameEndAlreadyCalled();
        ended = true;
        // no one revealed draw
        if(player1.choice==-1 && player2.choice==-1)
        {
            emit Draw();
            player1.reward=reward/2;
            player2.reward=reward/2;
            
        } // one only revealled
        else if (player1.choice==-1)
        {
            emit GameEnded(player2);
            player2.reward=reward;

        }
        else if(player2.choice==-1)
        {
            emit GameEnded(player1);
            player1.reward=reward;

        } // both revealed
        else
        {  
            int value = player1.choice-player2.choice;
            //tie 
            if(value == 0)
            {
                emit Draw();
                 player1.reward=reward/2;
                 player2.reward=reward/2;
                 
            }
            else if( value == 1 || value == -1)
            {
                if(player1.choice<player2.choice)
                {
                    emit GameEnded(player1);
                    player1.reward=reward;
                }
                else 
                {  
                    emit GameEnded(player2);
                    player2.reward=reward;
                }
            }
            else 
            {
                if(player1.choice>player2.choice)
                {
                    emit GameEnded(player1);
                    player1.reward=reward;
                }
                else 
                {               
                    emit GameEnded(player2);
                    player2.reward=reward;
                }
            }
        }
        
        
    }
    function withdraw()     
    external
    {   address  refund = msg.sender;
        if(refund==player1.playerAdress && player1.reward!=0)
        {
            player1.reward=0;
            player1.playerAdress.transfer(player1.reward);
        }
        else if(refund==player2.playerAdress && player2.reward!=0)
        {
            player2.reward=0;
            player2.playerAdress.transfer(player2.reward);
        }
        else 
            revert();
    }


}