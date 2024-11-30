// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.23;
 
 interface IERC721 {
 	function transferFrom (
 		address _from,
 		address _to,
 		uint _nftId
 	) external;
}

contract EnglishAuction{
	event Start();                                      //拍卖开始事件
	event Bid(address indexed sender, uint amount);     //每次出价时触发事件，记录出价人和金额
	event Withdraw(address indexed bidder, uint amount); //当投标人撤回出价金额时触发
	event End(address highestBidder, uint highestBid);  //拍卖结束事件，记录最高出价人和最终金额
	
	IERC721 public immutable nft;
	uint public immutable nftId;
	
	address payable public immutable seller;
	uint32 public endAt;                    //拍卖结束的时间戳
	bool public started;                    //拍卖是否开始和结束
	bool public ended;                      //
	
	address public highestBidder;           //最高出价者
	uint public highestBid;                 //最高出价金额
	mapping(address => uint ) public bids;  //映射每个投标者的出价金额，用于存储每个投标者的待退还金额
	
	constructor(
		address _nft,
		uint _nftId,
		uint _startingBid                   //起拍价
    ){
        nft =IERC721(_nft);
        nftId = _nftId;
        seller = payable (msg.sender);
        highestBid = _startingBid;
    }
    
    function start() external {         //卖家调用此函数启动拍卖
    	require(msg.sender == seller, "not seller");
    	require(!started, "started");
    	
    	started = true;
    	endAt = uint32(block.timestamp + 60);       // 60s
    	nft.transferFrom(seller, address(this), nftId); //把 NFT 从卖家转移到合约地址
    	
    	emit Start();
    }
    
    function bid() external payable {       //出价
    	require(started, "not started");
    	require(block.timestamp < endAt, "ended");
    	require(msg.value > highestBid, "value < highest bid");
    	
    	if(highestBidder != address(0)){
    		bids[highestBidder] += highestBid;
        }
        
        highestBid = msg.value;
        highestBidder = msg.sender;
        
        emit Bid(msg.sender, msg.value);
    }
    
    function withdraw() external {      //撤回出价
    	uint bal = bids[msg.sender];
    	bids[msg.sender] = 0;
    	payable (msg.sender).transfer(bal);
    	emit Withdraw(msg.sender, bal);
    }
    
    function end() external {       //拍卖结束
    	require(started, "not started");
    	require(!ended, "ended");
    	require(block.timestamp >= endAt, "not ended");
    	
    	ended = true;
    	if(highestBidder != address(0)){
    		nft.transferFrom(address(this), highestBidder, nftId);
    		seller.transfer(highestBid);
        }else{
        	nft.transferFrom(address(this), seller, nftId);
        }
        
        emit End(highestBidder, highestBid);
    }
}