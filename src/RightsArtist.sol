pragma solidity ^0.4.24;

import "./interfaces/IRightsArtist.sol";
import "./modules/MasterDataModule.sol";

/// @title RightsArtist
/// @dev ERC721 based master data of artists.
contract RightsArtist is IRightsArtist, MasterDataModule {

    /*** DATA TYPES ***/

    struct Artist {
        string name; // artist name
        uint256 index; // wallet index
        address holder; // target artist address
        string mediaId; // media file id
        bool isValid;
    }


    /*** STORAGE ***/

    Artist[] public artists;


    /*** External Functions ***/

    /// @dev Creates the artist
    /// @param _name aritst mname
    /// @param _index wallet index(BIP44)
    /// @param _holder target artist address
    /// @param _mediaId media id
    /// @param _isValid Whether the artist is valid
    function createArtist(
        string _name,
        uint256 _index,
        address _holder,
        string _mediaId,
        bool _isValid
    ) external whenNotPaused {

        // add to artists
        Artist memory artist;
        artist.name = _name;
        artist.index = _index;
        artist.holder = _holder;
        artist.mediaId = _mediaId;
        artist.isValid = _isValid;

        uint256 artistId = artists.push(artist).sub(1);
        _mint(msg.sender, artistId);

        emit CreateArtist(msg.sender, artistId);
    }

    /// @dev Updates the artist of the specified id
    /// @param _artistId artist id
    /// @param _name aritst mname
    /// @param _mediaId media id
    /// @param _isValid Whether the artist is valid
    function updateArtist(
        uint256 _artistId,
        string _name,
        string _mediaId,
        bool _isValid
    ) external whenNotPaused {
        require(ownerOf(_artistId) == msg.sender);

        Artist storage artist = artists[_artistId];
        artist.name = _name;
        artist.mediaId = _mediaId;
        artist.isValid = _isValid;

        emit UpdateArtist(msg.sender, _artistId);
    }

    /// @dev Gets artist info
    /// @param _artistId artist id
    /// @return artist info
    function getArtist(uint256 _artistId) external view returns(
        uint256 artistId,
        string name,
        uint256 index,
        address holder,
        string mediaId,
        bool isValid,
        address owner
    ) {
        require(_exists(_artistId));

        Artist memory artist = artists[_artistId];
        return (
            _artistId,
            artist.name,
            artist.index,
            artist.holder,
            artist.mediaId,
            artist.isValid,
            ownerOf(_artistId)
        );
    }

    /// @dev Gets artist info at a given index of the tokens list of the requested owner
    /// @param _owner address owning the tokens list to be accessed
    /// @param _index uint256 representing the index to be accessed of the requested tokens list
    /// @return artist info
    function getArtist(address _owner, uint256 _index) external view returns(
        uint256 artistId,
        string name,
        uint256 index,
        address holder,
        string mediaId,
        bool isValid,
        address owner
    ) {
        uint256 targetId = tokenOfOwnerByIndex(_owner, _index);

        Artist memory artist = artists[targetId];
        return (
            targetId,
            artist.name,
            artist.index,
            artist.holder,
            artist.mediaId,
            artist.isValid,
            ownerOf(targetId)
        );
    }

    /// @dev Returns index of the specified artist id
    /// @param _artistId artist id
    /// @return index of the specified artist id
    function indexOf(uint256 _artistId) public view returns (uint256) {
        require(_exists(_artistId));
        return artists[_artistId].index;
    }

    /// @dev Returns holder of the specified artist id
    /// @param _artistId artist id
    /// @return holder of the specified artist id
    function holderOf(uint256 _artistId) public view returns (address) {
        require(_exists(_artistId));
        return artists[_artistId].holder;
    }

    /// @dev Returns whether the token is valid
    /// @param _artistId artist id
    /// @return whether the token is valid
    function isValid(uint256 _artistId) public view returns (bool) {
        require(_exists(_artistId));
        return artists[_artistId].isValid;
    }
}