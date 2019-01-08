pragma solidity ^0.4.24;

import "./interfaces/IRDDNMarket.sol";
import "./modules/MasterDataModule.sol";

/// @title RDDNMarket
/// @dev ERC721 based master data of markets.
contract RDDNMarket is IRDDNMarket, MasterDataModule {

    /*** DATA TYPES ***/

    // Represents an market on an digitalAsset Object
    struct Market {
        string name;
        uint256 marketType;
        address holder;
        string mediaId;
        bool isValid;
    }


    /*** STORAGE ***/

    // all market list
    Market[] public markets;

    
    /*** External Functions ***/

    /// @dev Create a new market.
    /// @param _name name
    /// @param _marketType market type
    /// @param _holder market holder address
    /// @param _mediaId mediaId
    /// @param _isValid isValid
    function createMarket(
        string _name,
        uint256 _marketType,
        address _holder,
        string _mediaId,
        bool _isValid
    ) external whenNotPaused returns(bool) {
        Market memory m;

        m.name = _name;
        m.marketType = _marketType;
        m.holder = _holder;
        m.mediaId = _mediaId;
        m.isValid = _isValid;

        // set ids
        uint256 marketId = markets.push(m) - 1;
        _mint(msg.sender, marketId);

        emit CreateMarket(msg.sender, marketId);
        return true;
    }

    /// @dev Update market info
    /// @param _marketId market id
    /// @param _name name
    /// @param _marketType marketType
    /// @param _mediaId mediaId
    /// @param _isValid isValid
    function updateMarket(
        uint256 _marketId,
        string _name,
        uint256 _marketType,
        string _mediaId,
        bool _isValid
    ) external whenNotPaused returns(bool) {
        // check market owner
        require(ownerOf(_marketId) == msg.sender);

        markets[_marketId].name = _name;
        markets[_marketId].marketType = _marketType;
        markets[_marketId].mediaId = _mediaId;
        markets[_marketId].isValid = _isValid;

        emit UpdateMarket(msg.sender, _marketId);
        return true;
    }
    
    /// @dev Get market info
    /// @param _marketId market id
    /// @return market info
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
    ) {
        require(_exists(_marketId));
        Market memory m = markets[_marketId];

        return(
            _marketId,
            m.name,
            m.marketType,
            m.holder,
            m.mediaId,
            m.isValid,
            ownerOf(_marketId)
        );
    }

    /// @dev Get market info
    /// @param _owner address owning the tokens list to be accessed
    /// @param _index uint256 representing the index to be accessed of the requested tokens list
    /// @return market info
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
    ) {
        uint256 targetId = tokenOfOwnerByIndex(_owner, _index);
        return getMarket(targetId);
    }

    /// @dev Returns market holder of the specified market id
    /// @param _marketId market id
    /// @return market holder address of the specified market id
    function holderOf(uint256 _marketId) public view returns (address) {
        require(_exists(_marketId));
        return markets[_marketId].holder;
    }

    /// @dev Returns market type of the specified market id
    /// @param _marketId market id
    /// @return market type of the specified market id
    function marketTypeOf(uint256 _marketId) public view returns (uint256) {
        require(_exists(_marketId));
        return markets[_marketId].marketType;
    }

    /// @dev Returns whether the market is valid
    /// @param _marketId market id
    /// @return whether the market is valid
    function isValid(uint256 _marketId) public view returns (bool) {
        require(_exists(_marketId));
        return markets[_marketId].isValid;
    }


}