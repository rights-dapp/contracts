pragma solidity ^0.4.24;
import "./RightsDigitalAssetSpec.sol";

import "./interfaces/IRightsDigitalAssetObject.sol";
import "./utils/RDDNControl.sol";

import "openzeppelin-solidity/math/SafeMath.sol";
import "openzeppelin-solidity/token/ERC721/ERC721Full.sol";

/// @title RightsDigitalAssetObject
/// @dev ERC721 based token.
contract RightsDigitalAssetObject is IRightsDigitalAssetObject, RDDNControl, ERC721Full {
    using SafeMath for uint256;

    string internal constant name_ = "RithtsDigitalAssets";
    string internal constant symbol_ = "RDA";

    /*** DATA TYPES ***/

    struct DigitalAssetObject {
        uint256 specId; // asset spec id
        string mediaId; // media file id
        string info; //asset's additional information
    }


    /*** STORAGE ***/

    DigitalAssetObject[] public digitalAssetObjects; // all object list (this index is objectId)

    // Mapping from spec ID to index of the minted objects list
    mapping(uint256 => uint256[]) private mintedObjects;
    // Mapping from object id to position in the minted objects array
    mapping(uint256 => uint256) private mintedObjectsIndex;
    // // Mapping from spec id to count of owned objects
    // mapping(uint256 => mapping(address => uint256)) private ownedObjectCount;

    RightsDigitalAssetSpec spec;


    /*** CONSTRUCTOR ***/

    constructor(address specAddr) ERC721Full(name_, symbol_) public {
        spec = RightsDigitalAssetSpec(specAddr);
    }


    /*** EXTERNAL FUNCTIONS ***/

    /// @dev Mint a DigitalAsset.
    /// @param _to The address that will own the minted token
    /// @param _specId spec identifer
    /// @param _mediaId mediaId
    /// @param _info info
    /// @return objectId
    function mint(
        address _to,
        uint256 _specId,
        string _mediaId,
        string _info
    ) public whenNotPaused {
        require(spec.ownerOf(_specId) == msg.sender);

        // check total supply count
        require(
            spec.totalSupplyLimitOf(_specId) >= mintedObjects[_specId].length
            || spec.totalSupplyLimitOf(_specId) == 0
        );

        require(
            keccak256(abi.encodePacked(_mediaId)) == keccak256(abi.encodePacked(spec.mediaIdOf(_specId)))
            || keccak256(abi.encodePacked(_mediaId)) == keccak256(abi.encodePacked(""))
        );

        DigitalAssetObject memory digitalAssetObject = DigitalAssetObject({
            specId : _specId,
            mediaId: _mediaId,
            info: _info
        });

        uint256 objectId = digitalAssetObjects.push(digitalAssetObject).sub(1);
        _mint(_to, objectId);
        _addObjectTo(_specId, objectId);
        
        emit Mint(
            msg.sender,
            objectId,
            digitalAssetObject.specId,
            digitalAssetObject.mediaId,
            digitalAssetObject.info
        );
    }

    /// @dev Set MediaId
    /// @param _objectId object identifer
    /// @param _mediaId mediaId
    function setMediaId(uint256 _objectId, string _mediaId) public whenNotPaused {
        require(_exists(_objectId));
        DigitalAssetObject storage digitalAsset = digitalAssetObjects[_objectId];

        require(spec.ownerOf(digitalAsset.specId) == msg.sender);
        require(keccak256(abi.encodePacked(digitalAsset.mediaId)) == keccak256(abi.encodePacked("")));

        // set mediaId
        digitalAsset.mediaId = _mediaId;

        emit SetMediaId(
            msg.sender,
            _objectId,
            digitalAsset.mediaId
        );
    }

    /// @dev Get DigitalAsset.
    /// @param _objectId object identifer
    /// @return object info
    function getDigitalAssetObject(uint256 _objectId) public view returns (
        uint256 objectId,
        uint256 specId,
        string mediaId,
        string info,
        address owner,
        uint256 objectIndex
    ) {
        require(_exists(_objectId));
        DigitalAssetObject storage digitalAsset = digitalAssetObjects[_objectId];
        address objectOwner = ownerOf(_objectId);

        return (
            _objectId,
            digitalAsset.specId,
            digitalAsset.mediaId,
            digitalAsset.info,
            objectOwner,
            mintedObjectsIndex[_objectId]
        );
    }

    /// @dev Get DigitalAsset.
    /// @param _owner address owning the tokens list to be accessed
    /// @param _index uint256 representing the index to be accessed of the requested tokens list
    /// @return object info
    function getDigitalAssetObject(address _owner, uint256 _index) public view returns (
        uint256 objectId,
        uint256 specId,
        string mediaId,
        string info,
        address owner,
        uint256 objectIndex
    ) {
        uint256 id = tokenOfOwnerByIndex(_owner, _index);
        return getDigitalAssetObject(id);
    }

    /// @dev Get DigitalAsset.
    /// @param _specId spec identifer
    /// @param _index uint256 representing the index to be accessed of the requested tokens list
    /// @return object info
    function getDigitalAssetObject(uint256 _specId, uint256 _index) public view returns (
        uint256 objectId,
        uint256 specId,
        string mediaId,
        string info,
        address owner,
        uint256 objectIndex
    ) {
        require(spec.ownerOf(_specId) != address(0));

        uint256 id = objectOfSpecByIndex(_specId, _index);
        return getDigitalAssetObject(id);
    }
    
    /// @dev Gets the token ID at a given index of the tokens list of the requested owner
    /// @param _specId spec identifer
    /// @param _index uint256 representing the index to be accessed of the requested tokens list
    /// @return uint256 token ID at the given index of the tokens list owned by the requested address
    function objectOfSpecByIndex(uint256 _specId, uint256 _index) public view returns (uint256) {
        require(spec.ownerOf(_specId) != address(0));
        return mintedObjects[_specId][_index];
    }

    /// @dev Get specId of DigitalAsset.
    /// @param _objectId object identifer
    /// @return specId
    function specIdOf(uint256 _objectId) public view returns (uint256) {
        require(_exists(_objectId));
        return digitalAssetObjects[_objectId].specId;
    }

    /// @dev Get mediaId of DigitalAsset.
    /// @param _objectId object identifer
    /// @return mediaId
    function mediaIdOf(uint256 _objectId) public view returns (string) {
        require(_exists(_objectId));
        return digitalAssetObjects[_objectId].mediaId;
    }

    /// @dev Get info of DigitalAsset.
    /// @param _objectId object identifer
    /// @return info
    function infoOf(uint256 _objectId) public view returns (string) {
        require(_exists(_objectId));
        return digitalAssetObjects[_objectId].info;
    }

    /// @dev Gets the total amount of objects stored by the contract per spec
    /// @param _specId spec identifer
    /// @return uint256 representing the total amount of objects per spec
    function totalSupplyOf(uint256 _specId) public view returns (uint256) {
        require(spec.ownerOf(_specId) != address(0));
        return mintedObjects[_specId].length;
    }

    /// @dev Get objectIndex of DigitalAsset.
    /// @param _objectId object identifer
    /// @return objectIndex
    function objectIndexOf(uint256 _objectId) public view returns (uint256) {
        require(_exists(_objectId));
        return mintedObjectsIndex[_objectId];
    }


    /*** INTERNAL FUNCTIONS ***/

    /// @dev Internal function to add a object ID to the list of the spec
    /// @param _specId uint256 ID of the spec
    /// @param _objectId uint256 ID of the token to be added to the tokens list of the given address
    function _addObjectTo(uint256 _specId, uint256 _objectId) internal {
        mintedObjectsIndex[_objectId] = mintedObjects[_specId].push(_objectId);
    }
}