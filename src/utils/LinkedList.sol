
pragma solidity ^0.4.24;

contract LinkedList {

    /*** STORAGE ***/

    // Mapping from key id to the values
    mapping(uint256 => uint256[]) private keyTargetValues;
    // Mapping from key id to index of the token
    mapping(uint256 => mapping(uint256 => uint256)) private keyTargetValuesIndex;
    // Mapping from key id to registration status of token
    mapping(uint256 => mapping(uint256 => bool)) private registrationStatus;


    /*** External Functions ***/

    /// @dev Aadd a id to the list of a given key id
    /// @param _keyId key id of the values list
    /// @param _targetId id of the token to be added to the values list of the given key id
    function add(
        uint256 _keyId,
        uint256 _targetId
    ) public {
        require(!exists(_keyId, _targetId));

        // set id
        keyTargetValuesIndex[_keyId][_targetId] = keyTargetValues[_keyId].push(_targetId) - 1;
        registrationStatus[_keyId][_targetId] = true;
    }

    /// @dev Remove a ID from the list of ths specified key id
    /// @param _keyId key id of the values list
    /// @param _targetId id of the token to be added to the values list of the given key id
    function remove(uint256 _keyId, uint256 _targetId) public {
        require(exists(_keyId, _targetId));

        uint256 targetIndex = keyTargetValuesIndex[_keyId][_targetId];
        uint256 lastIndex = keyTargetValues[_keyId].length - 1;
        uint256 lastTargetId = keyTargetValues[_keyId][lastIndex];

        registrationStatus[_keyId][_targetId] = false;
        keyTargetValues[_keyId][targetIndex] = lastTargetId;
        keyTargetValues[_keyId].length--;

        // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
        // be zero. Then we can make sure that we will remove _tokenId from the ownedvalues list since we are first swapping
        // the lastToken to the first position, and then dropping the element placed in the last position of the list
        keyTargetValuesIndex[_keyId][lastTargetId] = targetIndex;
        keyTargetValuesIndex[_keyId][_targetId] = 0;
    }

    /// @dev Get key target ids of the specified key id
    /// @param _keyId key id of the values list
    /// @param _index index of the token to be added to the values list of the given key id
    /// @return values
    function valueOf(uint256 _keyId, uint256 _index) external view returns (uint256) {
        return keyTargetValues[_keyId][_index];
    }

    /// @dev Get key target ids of the specified key id
    /// @param _keyId key id of the token id list
    /// @return value
    function valuesOf(uint256 _keyId) external view returns (uint256[]) {
        return keyTargetValues[_keyId];
    }

    /// @dev Get ids count of the specified key id
    /// @return total of value
    function totalOf(uint256 _keyId) external view returns (uint256) {
        return keyTargetValues[_keyId].length;
    }

    /// @dev Returns whether the specified key id registered
    /// @param _keyId key id of the token id list
    /// @param _targetId id of the token to be added to the token id list of the given key id
    /// @return whether the token registered
    function exists(uint256 _keyId, uint256 _targetId) public view returns (bool) {
        return registrationStatus[_keyId][_targetId];
    }
}