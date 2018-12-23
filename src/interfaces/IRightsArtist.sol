pragma solidity ^0.4.24;

contract IRightsArtist {

    event CreateArtist(
        address owner,
        uint256 artistId,
        string name,
        uint256 index,
        address holder,
        string mediaId,
        bool isValid
    );

    event UpdateArtist(
        address owner,
        uint256 artistId,
        string name,
        string mediaId,
        bool isValid
    );

    function createArtist(
        string _name,
        uint256 _walletIndex,
        address _holder,
        string _mediaId,
        bool _isValid
    ) external;

    function updateArtist(
        uint256 _artistId,
        string _name,
        string _mediaId,
        bool _isValid
    ) external;

    function getArtist(uint256 _artistId) external view returns(
        uint256 artistId,
        string name,
        uint256 index,
        address holder,
        string mediaId,
        bool isValid,
        address owner
    );

    function getArtist(address _owner, uint256 _index) external view returns(
        uint256 artistId,
        string name,
        uint256 index,
        address holder,
        string mediaId,
        bool isValid,
        address owner
    );

    function indexOf(uint256 _artistId) public view returns (uint256);
    function holderOf(uint256 _artistId) public view returns (address);
    function isValid(uint256 _artistId) public view returns (bool);
}