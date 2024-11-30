// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint _nftId
    ) external ;
}
contract DutchAuction {
    uint private constant DURATION = 7 days;
    IERC721 public immutable nft; //nft地址
    uint public immutable nftId; 
    
    address public immutable seller; //卖家地址
    uint public immutable startingPrice; //开始售卖价格
    uint public immutable startAt; //开始售卖时间
    uint public immutable expiresAt; //售卖结束时间
    uint public immutable discountRate; //折扣倍率
    constructor(
        uint _startingPrice,
        uint _discountRate,
        address _nft,
        uint _nftId
    ){
        seller = payable (msg.sender);
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        startAt = block.timestamp;
        expiresAt = block.timestamp + DURATION;
        require(_startingPrice >= _discountRate * DURATION,
        "starting price < discount");
        nft = IERC721(_nft);
        nftId = _nftId;
    }
    function getPrice() public view returns(uint){
        uint timeElaosed = block.timestamp - startAt;
        uint discount = discountRate * timeElaosed;
        return startingPrice - discount;
    }
    function buy() external payable { //时间未过期，支付价格不少于当前价格，多支付退还
        require(block.timestamp < expiresAt,"aution expired");
        uint price = getPrice();
        require(msg.value >= price, "ETH < price");
        nft.transferFrom(seller, msg.sender, nftId);
        uint refund = msg.value - price;
        if(refund > 0){
            payable (msg.sender).transfer(refund);
        }
    }
}