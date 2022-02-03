// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;
contract Music {

    /* 
     constructor takes number of parts the media will be divided 
     number of samples to reveal   
    */
    struct Buyer {
        bytes32[] commits;
        uint[] randomIndicies;
        bytes32 EncryptedKey; // g^x encrypted with with seller public key 
        bool RandomRefunded; 
        bool priceRefunded;
        bool exists;
        uint randomPriceRefundTime; // if the seller didn't reveal 
        uint priceRefundTime;
    }
  
    
    uint public sellerBalance = 0;
    
    address payable public seller;

    uint public  parts;
    uint  public samples;   
    uint public price ;
    uint public withdrawAfterTime;
    uint public randomPrice;

    bytes32[] sellerCommits;
    bytes32 public sellerPublicKey;

    mapping(address => Buyer) public buyers;

    
    error TooEarly(uint time);
    error TooLate(uint time);
    /// Not the Seller address 
    error wrongAddress();
    /// Wrong Commitment size from the seller
    error wrongSize();
    // ffunds collected seller may reveal to get money
    event fundsCollected();
    event RevealingIndexes(address userAddress,uint[] array); 
    event SellerRevealedCorrectly(bytes32[] array);
    event MediaRevealed(bytes32[] array);
    /// Try again at `time`.
    
    modifier onlyBefore(uint time) {
        if (block.timestamp >= time) revert TooLate(time);
        _;
    }
    modifier onlyAfter(uint time) {
        if (block.timestamp <= time) revert TooEarly(time);
        _;
    }

    constructor(
    uint partsNo,
    uint samplesNo,
    uint mediaPrice, 
    address payable sellerAddress,
    uint refundTime,
    bytes32 publicKey // seller public key
    )
    {
    seller = sellerAddress;    
    parts=partsNo;
    samples=samplesNo;
    price = mediaPrice;
    withdrawAfterTime=refundTime;
    sellerPublicKey=publicKey;     
    randomPrice= samples*price/partsNo;
    }
    function buyRequest(bytes32 gx) external payable //send g^x encrypted with seller public key  
    {
        require(buyers[msg.sender].exists==false);
        require(msg.value==randomPrice);
        Buyer memory b ; 
        b.EncryptedKey = gx;
        b.randomPriceRefundTime=block.timestamp+withdrawAfterTime;
        b.exists=true;
        buyers[msg.sender]=b;
        
    }
     function commitToBuyer(address buyerAddress, bytes32[] memory data)  external
    {
        Buyer storage b =buyers[buyerAddress]; 
        require(b.exists==true );//check if buyer exists
        require(b.commits.length==0);
        require(data.length==parts);
        b.commits=data;
    }


    function userRandomRefund() external
    {
        Buyer storage b =buyers[msg.sender]; 
        require(b.exists==true );//check if buyer exists
        require(b.randomPriceRefundTime<block.timestamp);
        require(b.RandomRefunded==false);
        b.RandomRefunded=true ;
        payable(msg.sender).transfer(randomPrice);   
    }

    function generateRandom(address userAddress) external   {
        Buyer storage b =buyers[msg.sender];

        require(b.exists==true );//check if buyer exists
        require(b.commits.length==parts );
        require(b.randomIndicies.length==0);
        bytes32 hash= keccak256(abi.encodePacked(block.difficulty, block.timestamp));
        uint curr =  uint(hash)%parts;
        for(uint i =0 ;i<samples;i++)
        {  
            
            while(!check(b.randomIndicies,curr))
            {
                hash=keccak256(abi.encodePacked(hash));
                curr =  uint(hash)%parts;
            }
            b.randomIndicies.push(curr); // to do add random generator
        }
        emit RevealingIndexes(userAddress,b.randomIndicies);
    }
    function check(uint[]storage  arr,uint val) private view returns (bool) {
        for (uint i=0; i<arr.length; i++) {
            if(val==arr[i]) return false;
        }
        return true;
    }
    function revealSampleForBuyer(address userAddress,uint[] memory keys) external{
        Buyer storage b =buyers[userAddress]; 
        require(b.exists==true );//check if buyer exists
        require(b.randomIndicies.length==samples);
        require(keys.length==samples);
        // require(b.randomPriceRefundTime>block.timestamp);
        for(uint i=0 ;i<samples;i++)
        {
            if( keccak256(abi.encodePacked( keys[i]) ) != b.commits[b.randomIndicies[i]])
            {
               revert();
            }
        }
        b.RandomRefunded=true;
        sellerBalance+=randomPrice;    
    }
    
    // todo user pay price-random price
    function payPrice () public payable 
    {
        Buyer storage b =buyers[msg.sender];
        require(b.exists==true );//check if buyer exists
        uint amount = price - randomPrice;
        require(msg.value==amount);
        b.priceRefundTime =block.timestamp+withdrawAfterTime;
        sellerBalance += amount;  

    } 
   
    // todo seller reveal to specific user commit 
    function revealMediaForBuyer(address userAddress,uint[] memory keys) external{
        Buyer storage b =buyers[userAddress]; 
        require(b.exists==true );//check if buyer exists
        require(b.priceRefundTime!=0 );//check if buyer paid
        require(keys.length==parts);
        require(b.priceRefundTime>block.timestamp);
        for(uint i=0 ;i<parts;i++)
        {
            if( keccak256(abi.encodePacked( keys[i]) ) != b.commits[i])
            {
               revert();
            }
        }
        b.priceRefunded=true;
        sellerBalance+=price-randomPrice;    
    }
    
    
    // todo seller redeam 
    function sellerRedeam() external{
        uint temp = sellerBalance;
        sellerBalance=0;
        payable(seller).transfer(temp);
    }

    // todo buyer refund after certain time 
    function userPriceRefund() external
    {
        Buyer storage b =buyers[msg.sender]; 
        require(b.exists==true );//check if buyer exists
        require(b.priceRefundTime<block.timestamp);
        require(b.priceRefunded==false);
        b.priceRefunded=true ;
        payable(msg.sender).transfer(price-randomPrice);   
    }


}

/*
1-every potential buyer provides payment for random samples + g^x encrypted with the sellers public key 
2-the seller commits to gyi for every sample and provides his public_key
3-random samples generated 
4-buyer checks the data 
5-buyer buys the data 
6-seller revealls gyi 
7-seller claims money

*/
