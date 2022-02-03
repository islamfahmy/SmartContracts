# Solidity Smart contracts
* ## Vickrey Blind Auction :
    [Blind auction](https://docs.soliditylang.org/en/v0.5.11/solidity-by-example.html#blind-auction) Implmented in solidity but with [vickrey protocol](https://en.wikipedia.org/wiki/Vickrey_auction) winner pays second highest bid 
* ## Rock-paper-scissor 
    [rock-paper-scissor](https://en.wikipedia.org/wiki/Rock_paper_scissors) game written in solidity the protocol ensures binding and fairness through [commit-reveal](https://en.wikipedia.org/wiki/Commitment_scheme) scheme
* ## Private Media Trading : 
    The idea is to make a fair private media trading system via smart contracts where the seller sells media ex: movie privately to every buyer and ensure that either parties can't cheat here I assume that there is an IPFS in the network where the seller can share the media encrypted with some key the idea is driven from  this [paper](https://dl.acm.org/doi/10.1145/2976749.2978362) the protocol is as follow :
    * every potential buyer provides payment for random samples + g^x encrypted with the sellers public key 
    * the media is divided into parts where every part is encrypted with g^(x+yi) and share the encrypted files on IPFS
    * the seller commits to g^yi for every sample 
    * random samples are  generated
    * seller reveals the random samples 
    * buyer checks the data 
    * buyer buys the data if he is ok with it 
    * seller revealls gyi 
    * seller claims money
    * if the seller didn't reveal samples in pre-specified time the buyer can redeem his money 
    * the buyer have to pay money equivalent  to the amount of data revealed  so the buyer won't generate fake accounts and keep requesting  random reveals till he collects the movie parts


