pragma solidity ^0.4.24;

import "./interfaces/IRightsDigitalAssetSpec.sol";
import "./modules/MasterDataModule.sol";

/// @title RightsDigitalAssetSpec
/// @dev ERC721 based meta data of RightsDigitalAssetObject contract.
contract RightsDigitalAssetSpec is IRightsDigitalAssetSpec, MasterDataModule {

    /*** DATA TYPES ***/

    struct DigitalAssetSpec {
        string name; // asset name
        string symbol; // asset symbol
        uint256 assetType; // asset type
        string mediaId; // media file id
        uint256 totalSupplyLimit; // object's total supply (0 = no limit)
        uint256 referenceValue; // price to buy asset by
    }


    /*** STORAGE ***/

    DigitalAssetSpec[] public digitalAssetSpecs; //all spec list (this index is specId)


    /*** EXTERNAL FUNCTIONS ***/

    /// @dev Define a DigitalAssetSpec.
    /// @param _name assetName
    /// @param _symbol assetSymbol
    /// @param _mediaId mediaId
    /// @param _totalSupplyLimit totalSupplyLimit
    /// @param _referenceValue referenceValue
    /// @return assetId
    function define(
        string _name,
        string _symbol,
        uint256 _assetType,
        string _mediaId, 
        uint256 _totalSupplyLimit, 
        uint256 _referenceValue
    ) public whenNotPaused {
        DigitalAssetSpec memory digitalAsset = DigitalAssetSpec({
            name : _name,
            symbol: _symbol,
            assetType: _assetType,
            mediaId: _mediaId,
            totalSupplyLimit: _totalSupplyLimit,
            referenceValue: _referenceValue
        });

        uint256 specId = digitalAssetSpecs.push(digitalAsset).sub(1);
        _mint(msg.sender, specId);

        emit Define(
            msg.sender,
            specId,
            digitalAsset.name,
            digitalAsset.symbol,
            digitalAsset.assetType,
            digitalAsset.mediaId,
            digitalAsset.totalSupplyLimit,
            digitalAsset.referenceValue
        );
    }

    /// @dev Get DigitalAssetSpec info.
    /// @param _specId spec identifer
    /// @return spec info
    function getDigitalAssetSpec(uint256 _specId) public view returns (
        uint256 specId,
        string name,
        string symbol,
        uint256 assetType,
        string mediaId,
        uint256 totalSupplyLimit,
        uint256 referenceValue,
        address owner
    ) {
        DigitalAssetSpec storage digitalAssetSpec = digitalAssetSpecs[_specId];
        address specOwner = ownerOf(_specId);

        return (
            _specId,
            digitalAssetSpec.name,
            digitalAssetSpec.symbol,
            digitalAssetSpec.assetType,
            digitalAssetSpec.mediaId,
            digitalAssetSpec.totalSupplyLimit,
            digitalAssetSpec.referenceValue,
            specOwner
        );
    }

    /// @dev Get DigitalAssetSpec info.
    /// @param _owner address owning the tokens list to be accessed
    /// @param _index uint256 representing the index to be accessed of the requested tokens list
    /// @return spec info
    function getDigitalAssetSpec(address _owner, uint256 _index) public view returns (
        uint256 specId,
        string name,
        string symbol,
        uint256 assetType,
        string mediaId,
        uint256 totalSupplyLimit,
        uint256 referenceValue,
        address owner
    ) {
        uint256 id = tokenOfOwnerByIndex(_owner, _index);
        return getDigitalAssetSpec(id);
    }

    /// @dev Get name of DigitalAssetSpec.
    /// @param _specId spec identifer
    /// @return name
    function nameOf(uint256 _specId) public view returns (string) {
        require(_exists(_specId));
        return digitalAssetSpecs[_specId].name;
    }

    /// @dev Get symbol of DigitalAssetSpec.
    /// @param _specId spec identifer
    /// @return symbol
    function symbolOf(uint256 _specId) public view returns (string) {
        require(_exists(_specId));
        return digitalAssetSpecs[_specId].symbol;
    }

    /// @dev Get assetType of DigitalAssetSpec.
    /// @param _specId spec identifer
    /// @return assetType
    function assetTypeOf(uint256 _specId) public view returns (uint256) {
        require(_exists(_specId));
        return digitalAssetSpecs[_specId].assetType;
    }

    /// @dev Get mediaId of DigitalAssetSpec.
    /// @param _specId spec identifer
    /// @return mediaId
    function mediaIdOf(uint256 _specId) public view returns (string) {
        require(_exists(_specId));
        return digitalAssetSpecs[_specId].mediaId;
    }

    /// @dev Get totalSupplyLimit of DigitalAssetSpec.
    /// @param _specId spec identifer
    /// @return totalSupplyLimit
    function totalSupplyLimitOf(uint256 _specId) public view returns (uint256) {
        require(_exists(_specId));
        return digitalAssetSpecs[_specId].totalSupplyLimit;
    }

    /// @dev Get referenceValue of DigitalAssetSpec.
    /// @param _specId spec identifer
    /// @return referenceValue
    function referenceValueOf(uint256 _specId) public view returns (uint256) {
        require(_exists(_specId));
        return digitalAssetSpecs[_specId].referenceValue;
    }
}