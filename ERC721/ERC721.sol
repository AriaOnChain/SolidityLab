// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC165 {  //IERC165标准检查合约是不是支持了ERC721，ERC1155的接口
    // 输入要查询的interfaceId接口id,如果合约实现了该接口id返回true
    // 规则详见：https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}





interface IERC721 is IERC165 {
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

// 确保目标合约实现了onERC721Received()函数（返回onERC721Received的selector）
function _checkOnERC721Received(
    address operator,
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
) internal {
    if (to.code.length > 0) {
        try IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) returns (bytes4 retval) {
            if (retval != IERC721Receiver.onERC721Received.selector) {
                // Token rejected
                revert IERC721Errors.ERC721InvalidReceiver(to);
            }
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                // non-IERC721Receiver implementer
                revert IERC721Errors.ERC721InvalidReceiver(to);
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }
}

//拓展接口 返回代币名称 返回代币代号 返回链接
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721 is IERC721 ,IERC721Metadata{
    using Strings for uint256;
    string public override name;
    string public override symbol;
    mapping(uint => address) private _owners;
    mapping(address => uint) private _balances;
    mapping(uint => address) private _tokenApprovals;
    _operatorApprovals;
    ;
    constructor(){}
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool){
        return 
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }
    function balanceOf(address owner) external view override returns (uint) {
        require(owner != address(0),"");
        return _balances[owner];
    }
    ;
    ;
    ;
}