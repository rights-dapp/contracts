pragma solidity ^0.4.24;

/// @title TokenManager interface
/// @dev Interface for TokenManager
contract ITokenManager {

    event Issue(
        address owner,
        uint256 tokenId
    );

    event Mint(
      address owner,
      address to,
      uint256 value,
      uint256 tokenId
    );

    event Burn(
      address owner,
      address to,
      uint256 value,
      uint256 tokenId
    );

    event Transfer(
        address from,
        address to,
        uint256 value,
        uint256 tokenId
    );

    event Update(
        address owner,
        uint256 tokenId
    );


    function getContractCount() public constant returns(uint);
    function issue(address _contractAddress) public returns (bool);

    function transfer(
        address _to,
        uint256 _value,
        uint256 _tokenId
    ) public returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value,
        uint256 _tokenId
    ) public returns (bool);

    function updateTokenInfo(uint256 _tokenId, string _name, string _symbol) public;
    function totalSupplyOf(uint256 _tokenId) public view returns (uint256);
    function balanceOf(uint256 _tokenId, address _owner) public constant returns (uint256);
    function ownerOf(uint256 _tokenId) public view returns (address);
    function tokensOfOwner(address _owner) public view returns (uint256[]);
    function tokensOfHolder(address _holder) public view returns (uint256[]);
    function decimalsOf(uint256 _tokenId) public view returns (uint8);

    function getTokenInfo(uint256 _tokenId) public view returns(
        uint256 tokenId,
        address contractAddress,
        string name,
        string symbol,
        address owner,
        uint256 totalSupply,
        uint8 decimals
    );

    function relativeAmountOf(
        uint256 _targetTokenId,
        uint256 _baseTokenId,
        uint256 _amout
    ) public view returns (uint256);

}