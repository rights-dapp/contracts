pragma solidity ^0.4.24;

/// @title RDDNMarketSales interface
/// @dev Interface for RDDNMarketSales
contract IRDDNMarketSales {

    event AddSpec(address owner, uint256 marketId, uint256 specId);
    event AddObject(address owner, uint256 marketId, uint256 specId, uint256 objectId);

    event RemoveSpec(address owner, uint256 marketId, uint256 specId);
    event RemoveObject(address owner, uint256 marketId, uint256 specId, uint256 objectId);

    event Purchase(
        address from,
        uint256 marketId,
        uint256 objectId,
        uint256 moneyId,
        uint256 pointId,
        uint256 pointValue
    );

    function addObject(
        uint256 _marketId,
        uint256 _objectId
    ) public returns (bool);

    function removeObject(
        uint256 _marketId,
        uint256 _objectId
    ) public returns (bool);

    function purchase(
        uint256 _marketId,
        uint256 _specId,
        uint256 _moneyId,
        uint256 _pointId,
        uint256 _pointValue
    ) public returns (bool);

    function specIdsOf(uint256 _marketId) public view returns (uint256[]);
    function objectIdsOf(uint256 _marketId, uint256 _specId) public view returns (uint256[]);
    function isOnSale(uint256 _objectId) public view returns(bool);
    function marketIdOf(uint256 _objectId) public view returns (uint256);

}