pragma solidity ^0.4.24;

/// @title RightsDigitalAssetObject interface
/// @dev Interface for RightsDigitalAssetObject
contract IRightsDigitalAssetObject {

    event Mint(
        address owner,
        uint256 objectId,
        uint256 specId
    );

    event SetMediaId(
        address owner,
        uint256 objectId,
        string mediaId
    );

    function mint(
        address _to,
        uint256 _specId,
        string _mediaId,
        string _info
    ) public;

    function setMediaId(uint256 _objectId, string _mediaId) public;

    function getDigitalAssetObject(uint256 _objectId) public view returns(
        uint256 objectId,
        uint256 specId,
        string mediaId,
        string info,
        address owner,
        uint256 objectIndex
    );

    function getDigitalAssetObject(address _owner, uint256 _index) public view returns (
        uint256 objectId,
        uint256 specId,
        string mediaId,
        string info,
        address owner,
        uint256 objectIndex
    );

    function getDigitalAssetObject(uint256 _specId, uint256 _index) public view returns (
        uint256 objectId,
        uint256 specId,
        string mediaId,
        string info,
        address owner,
        uint256 objectIndex
    );

    function objectOfSpecByIndex(uint256 _specId, uint256 _index) public view returns (uint256);
    function specIdOf(uint256 _objectId) public view returns (uint256);
    function mediaIdOf(uint256 _objectId) public view returns (string);
    function infoOf(uint256 _objectId) public view returns (string);
    function totalSupplyOf(uint256 _specId) public view returns (uint256);
    function objectIndexOf(uint256 _objectId) public view returns (uint256);
}
