pragma solidity ^0.4.24;

/// @title RDDNMarket interface
/// @dev Interface for RDDNMarket
contract IRDDNMarket {

    event CreateMarket(
        address owner,
        uint256 marketId
    );

    event UpdateMarket(
        address owner,
        uint256 marketId
    );

    function createMarket(
        string _name,
        uint256 _marketType,
        address _holder,
        string _mediaId,
        bool _isValid
    ) external returns(bool);

    function updateMarket(
        uint256 _marketId,
        string _name,
        uint256 _marketType,
        string _mediaId,
        bool _isValid
    ) external returns(bool);

    function getMarket(
        uint256 _marketId
    ) public view returns (
        uint256 marketId,
        string  name,
        uint256 marketType,
        address holder,
        string mediaId,
        bool isValid,
        address owner
    );

    function getMarket(
        address _owner,
        uint256 _index
    ) public view returns (
        uint256 marketId,
        string  name,
        uint256 marketType,
        address holder,
        string mediaId,
        bool isValid,
        address owner
    );

    function marketTypeOf(uint256 _marketId) public view returns (uint256);
    function holderOf(uint256 _marketId) public view returns (address);
    function isValid(uint256 _marketId) public view returns (bool);   
}