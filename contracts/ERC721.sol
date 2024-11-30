// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

interface IERC165 {  //IERC165标准检查合约是不是支持了ERC721，ERC1155的接口
    // 输入要查询的interfaceId接口id,如果合约实现了该接口id返回true
    // 规则详见：https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
 
interface IERC721 is IERC165 {  // ERC721标准接口
    //在转账时被释放，发出地址from，接收地址to
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    // 在授权时被释放，授权地址owner，被授权地址approved
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    // 在批量授权时释放，发出地址owner，被授权地址operator，授权与否approved
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    //返回某地址的NFT持有量balance
    function balanceOf(address owner) external view returns (uint256 balabce);

    //返回某tokenId的主人owner
    function ownerOf(uint256 tokenId) external view returns (address owner);

    //安全转账的重载函数，参数里面包含了data。
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    //安全转账（如果接收方是合约地址，会要求实现ERC721Receiver接口）。参数为转出地址from，接收地址to和tokenId。
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    //普通转账，参数为转出地址from，接收地址to和tokenId
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    //授权另一个地址使用你的NFT。参数为被授权地址approve和tokenId。
    function approve(address to, uint256 tokenId) external;

    //将自己持有的该系列NFT批量授权给某个地址operator。
    function setApprovalForAll(address operator, bool _approved) external;

    //查询tokenId被批准给了哪个地址。
    function getApproved(uint256 tokenId) external view returns (address operator);

    //查询某地址的NFT是否批量授权给了另一个operator地址。
    function isApprovedForAll(address owner,address operator) external view returns (bool);
}

//ERC721接收者接口：合约必须实现这个接口来通过安全转账接受ERC721
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


contract ERC721 is IERC721 {
    // string public override name;    //token名称
    // string public override symbol;  //token代号
    using Address for address;
    mapping(uint => address) private _owners;      // tokenId 到 owner 的持有人映射
    mapping(address => uint) private _balances;    // address 到 持仓数量 的持仓量映射
    mapping(uint => address) private _tokenApprovals;   // tokenID 到 授权地址 的授权映射
    mapping(address => mapping(address => bool)) private _operatorApprovals;   // owner地址 到operator地址 的批量授权映射
    // error ERC721InvalidReceiver(address receiver); // 错误 无效的接收者

    // 实现IERC165接口
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool){
        return 
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    // 实现IERC721接口
    function balanceOf(address owner) external view override returns (uint) {
        require(owner != address(0),"owner = zero address");
        return _balances[owner];
    }
    function ownerOf(uint tokenId) public view override returns (address owner){
        owner = _owners[tokenId];
        require(owner != address(0), "token doesn't exist");
    }
    function isApprovedForAll(address owner,address operator) external view override returns (bool){
        return _operatorApprovals[owner][operator];
    }
    function setApprovalForAll (address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function getApproved(uint tokenId) external view override returns (address) {
        require(_owners[tokenId] != address(0), "token doesn't exist");
        return _tokenApprovals[tokenId];
    }
    // 授权函数。通过调整_tokenApprovals来，授权 to 地址操作 tokenId，同时释放Approval事件。
    function _approve(address owner, address to, uint tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    function approve(address to,uint tokenId) external override {
        address owner = _owners[tokenId];
        require(
            msg.sender == owner || _operatorApprovals[owner][msg.sender],
            "not owner nor approved for all");
            _approve(owner, to , tokenId);
    }
    // 查询 spender地址是否可以使用tokenId（需要是owner或被授权地址）
    function _isApprovedOrOwner(address owner,address spender,uint tokenId)private view returns (bool){
        return (spender == owner || _tokenApprovals[tokenId] == spender || _operatorApprovals[owner][spender]);
    }
    // 转账函数。 释放transfer事件
    // 条件： 1、 tokenid 被 from 拥有 2、to 不是0地址
    function _transfer(address owner, address from, address to,uint tokenId) private {
        require(from == owner ,"not owner");
        require(to != address(0),"transfer to the zero address");
        _approve(owner, address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
    // 实现IERC721接口 非安全转账
    function transferFrom(address from,address to,uint tokenId) external override {
        address owner = ownerOf(tokenId);
        require(_isApprovedOrOwner(owner, msg.sender,tokenId),"not owner nor approved");
        _transfer(owner, from, to, tokenId);
    }
    // 安全转账
    // 条件： 1、from不能是0地址。 2、to不能是0地址。 3、tokenid代币必须存在，并且被from拥有。 
    //       4、如果 to 是智能合约, 他必须支持 IERC721Receiver-onERC721Received。
    function _safeTransfer(
        address owner,address from, address to,
        uint tokenId,bytes memory _data
        )private {
        _transfer(owner, from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, _data);
        }
    //
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) public override {
        address owner = ownerOf(tokenId);
        require(
            _isApprovedOrOwner(owner, msg.sender, tokenId),
            "not owner nor approved"
        );
        _safeTransfer(owner, from, to, tokenId, _data);
    }
    // safeTransferFrom重载函数
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }
    // 铸造函数
    // 条件： 1、tokenid尚不存在。 2、to不是0地址
    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "mint to zero address");
        require(_owners[tokenId] == address(0), "token already minted");
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }
    //销毁函数
    function _burn(uint tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "not owner of token");
        _approve(owner, address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

// 确保目标合约实现了onERC721Received()函数（返回onERC721Received的selector）
    function _checkOnERC721Received(
        address from, 
        address to, 
        uint256 tokenId,
        bytes memory _data
        ) private returns (bool) {
            if (to.isContract()) {
                try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                    return retval == IERC721Receiver.onERC721Received.selector;
                    } catch (bytes memory reason) {
                        if (reason.length == 0) {
                            revert ("ERC721: transfer to non ERC721Receiver implementer");
                        } else {
                            assembly {
                            revert(add(32, reason), mload(reason))
                            }}}} else {return true;}
                            }
    function _msgSender() internal view virtual returns (address){
        return msg.sender;
    }
}
