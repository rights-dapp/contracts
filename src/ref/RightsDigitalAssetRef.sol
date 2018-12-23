pragma solidity ^0.4.24;
import "./../RightsDigitalAssetSpec.sol";
import "./../RightsDigitalAssetObject.sol";

/// @title RightsDigitalAssetRef
/// @dev Contract for Reference of RightsDigitalAssetSpec and RightsDigitalAssetObject
contract RightsDigitalAssetRef {

    /*** STORAGE ***/

    RightsDigitalAssetSpec spec;
    RightsDigitalAssetObject object;


    /*** CONSTRUCTOR ***/

    constructor(address specAddr, address objectAddr) public {
        spec = RightsDigitalAssetSpec(specAddr);
        object = RightsDigitalAssetObject(objectAddr);
    }


    /*** EXTERNAL FUNCTIONS ***/

    /// @dev Get DigitalAsset.
    /// @param _objectId object identifer
    /// @return object info
    function getDigitalAsset(uint256 _objectId) public view returns (
        uint256 objectId,
        uint256 specId,
        string mediaId,
        address owner,
        uint256 objectIndex,
        string name,
        uint256 assetType,
        string specMediaId
    ) {
        require(object.ownerOf(_objectId) != address(0));
        uint256 targetSpecId = object.specIdOf(_objectId);

        return (
            _objectId,
            targetSpecId,
            object.mediaIdOf(_objectId),
            object.ownerOf(_objectId),
            object.objectIndexOf(_objectId),
            spec.nameOf(targetSpecId),
            spec.assetTypeOf(targetSpecId),
            spec.mediaIdOf(targetSpecId)
        );
    }

    /// @dev Get DigitalAsset.
    /// @param _owner address owning the tokens list to be accessed
    /// @param _index uint256 representing the index to be accessed of the requested tokens list
    /// @return object info
    function getDigitalAsset(address _owner, uint256 _index) public view returns (
        uint256 objectId,
        uint256 specId,
        string mediaId,
        address owner,
        uint256 objectIndex,
        string name,
        uint256 assetType,
        string specMediaId
    ) {
        uint256 id = object.tokenOfOwnerByIndex(_owner, _index);
        return getDigitalAsset(id);
    }

    /// @dev Get DigitalAsset.
    /// @param _specId spec identifer
    /// @param _index uint256 representing the index to be accessed of the requested tokens list
    /// @return object info
    function getDigitalAsset(uint256 _specId, uint256 _index) public view returns (
        uint256 objectId,
        uint256 specId,
        string mediaId,
        address owner,
        uint256 objectIndex,
        string name,
        uint256 assetType,
        string specMediaId
    ) {
        require(spec.ownerOf(_specId) != address(0));

        uint256 id = object.objectOfSpecByIndex(_specId, _index);
        return getDigitalAsset(id);
    }
}