pragma solidity ^0.4.24;

/// @title RightsDigitalAssetSpec interface
/// @dev Interface for RightsDigitalAssetSpec
contract IRightsDigitalAssetSpec {

    event Define(
        address owner,
        uint256 specId
    );
    

    function define(
        string _name,
        string _symbol,
        uint256 _assetType,
        string _mediaId, 
        uint256 _totalSupplyLimit, 
        uint256 _referenceValue
    ) public;

    function getDigitalAssetSpec(uint256 _specId) public view returns (
        uint256 specId,
        string name,
        string symbol,
        uint256 assetType,
        string mediaId,
        uint256 totalSupplyLimit,
        uint256 referenceValue,
        address owner
    );

    function getDigitalAssetSpec(address _owner, uint256 _index) public view returns (
        uint256 specId,
        string name,
        string symbol,
        uint256 assetType,
        string mediaId,
        uint256 totalSupplyLimit,
        uint256 referenceValue,
        address owner
    );

    function nameOf(uint256 _specId) public view returns (string);
    function symbolOf(uint256 _specId) public view returns (string);
    function assetTypeOf(uint256 _specId) public view returns (uint256);
    function mediaIdOf(uint256 _specId) public view returns (string);
    function totalSupplyLimitOf(uint256 _specId) public view returns (uint256);
    function referenceValueOf(uint256 _objectId) public view returns (uint256);
}
