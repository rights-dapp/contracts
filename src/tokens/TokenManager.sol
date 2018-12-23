pragma solidity ^0.4.24;

import "./../tokens/RightsBaseToken.sol";
import "./../utils/RDDNControl.sol";
import "./../utils/ManagerRole.sol";
import "./../interfaces/ITokenManager.sol";
import "./../utils/AddressLinkedList.sol";

import "openzeppelin-solidity/math/SafeMath.sol";
import "openzeppelin-solidity/utils/Address.sol";

contract TokenManager is RDDNControl, ITokenManager, MinterRole, ManagerRole {
    using SafeMath for uint256;
    using Address for address;

    /*** STORAGE ***/

    // All token contract addresses
    address[] public contracts;

    // Mapping from contract address to token ID
    mapping(address => uint256) internal contractToTokenId;

    // Mapping from contract address to contract issues
    mapping (address => bool) internal contractIssues;

    // Mapping from token ID to owner
    mapping(uint256 => address) internal tokenOwner;
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) internal ownedTokenIds;

    // Mapping from holder to token Ids
    AddressLinkedList private heldTokenIdList;


    /*** CONSTRUCTOR ***/

    constructor() public {
        heldTokenIdList = new AddressLinkedList();
    }

    /*** EXTERNAL FUNCTIONS ***/

    /// @dev issue the specified token in Rihgts Distributed Digital Network.
    /// @param _contractAddress  token address.
    /// @return A boolean that indicates if the token was issued.
    function issue(
        address _contractAddress
    ) whenNotPaused public returns (bool) {
        require(!_exists(_contractAddress));

        RightsBaseToken token = RightsBaseToken(_contractAddress);
        uint256 tokenId = contracts.push(_contractAddress).sub(1);

        contractToTokenId[_contractAddress] = tokenId;
        contractIssues[_contractAddress] = true;

        _addTokenTo(msg.sender, tokenId);

        emit Issue(
            msg.sender,
            token.name(),
            token.symbol(),
            token.totalSupply(),
            tokenId
        );

        return true;
    }
    
    /// @dev Transfer the specified amount of token to the specified address.
    /// @param _to    Receiver address.
    /// @param _value Amount of tokens that will be transferred.
    /// @param _tokenId  token identifer.
    function transfer(
        address _to,
        uint256 _value,
        uint256 _tokenId
    ) public whenNotPaused returns (bool) {
        require(_exists(_tokenId));
        RightsBaseToken token = RightsBaseToken(contracts[_tokenId]);

        require(_value <= token.balanceOf(msg.sender));
        require(_to != address(0));

        if(!_to.isContract()) {
            token.forceTransferFrom(msg.sender, _to, _value);
            _handleTokenHolder(msg.sender, _to, _tokenId, _value);
        }

        emit Transfer(msg.sender, _to, _value, _tokenId);
        return true;
    }

    /// @dev Transfer the specified amount of token from the specified address
    /// to the specified address.
    /// @param _from  Sender address.
    /// @param _to    Receiver address.
    /// @param _value Amount of tokens that will be transferred.
    /// @param _tokenId  token identifer.
    function transferFrom(
        address _from,
        address _to,
        uint256 _value,
        uint256 _tokenId
    ) public whenNotPaused returns (bool) {
        require(_exists(_tokenId));
        RightsBaseToken token = RightsBaseToken(contracts[_tokenId]);

        require(_value <= token.balanceOf(_from));
        require(_to != address(0));

        if(!_to.isContract()) {
            token.transferFrom(_from, _to, _value);
            _handleTokenHolder(_from, _to, _tokenId, _value);
        }

        emit Transfer(_from, _to, _value, _tokenId);
        return true;
    }

    /// @dev Transfer the specified amount of token from the specified address 
    /// to the specified address by managers.
    /// @param _from  Sender address.
    /// @param _to    Receiver address.
    /// @param _value Amount of tokens that will be transferred.
    /// @param _tokenId  token identifer.
    function forceTransferFrom(
        address _from,
        address _to,
        uint256 _value,
        uint256 _tokenId
    ) public whenNotPaused onlyManager returns (bool) {
        require(_exists(_tokenId));
        RightsBaseToken token = RightsBaseToken(contracts[_tokenId]);

        require(_value <= token.balanceOf(_from));
        require(_to != address(0));

        if(!_to.isContract()) {
            token.forceTransferFrom(_from, _to, _value);
            _handleTokenHolder(_from, _to, _tokenId, _value);
        }

        emit Transfer(_from, _to, _value, _tokenId);
        return true;
    }



    /// @dev Updates the token info of the specified token ID
    /// @param _tokenId tokenId of the token object
    /// @param _name Name of the token object
    /// @param _symbol Symbol of the token object
    function updateTokenInfo(uint256 _tokenId, string _name, string _symbol) public {
        require(_exists(_tokenId));
        require(ownerOf(_tokenId) == msg.sender);

        RightsBaseToken token = RightsBaseToken(contracts[_tokenId]);
        token.update(_name, _symbol);

        emit Update(
            msg.sender,
            _tokenId,
            token.name(),
            token.symbol(),
            token.totalSupply()
        );
    }

    /// @dev Gets contract count.
    /// @return count of contract.
    function getContractCount() public constant returns(uint256) {
        return contracts.length;
    }

    /// @dev Gets the contract address of the specified token ID
    /// @return count of contract.
    function contractOf(uint256 _tokenId) public constant returns(address) {
        return contracts[_tokenId];
    }

    /// @dev get tokenId from contract address.
    /// @param _contractAddress   Contract address.
    /// @return count of contract.
    function getTokenId(address _contractAddress) public constant returns(uint256) {
        require(_exists(_contractAddress));

        return contractToTokenId[_contractAddress];
    }

    /// @dev Total number of tokens in existence
    /// @param _tokenId The token Iidentifer
    function totalSupplyOf(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId));
        RightsBaseToken token = RightsBaseToken(contracts[_tokenId]);

        return token.totalSupply();
    }

    /// @dev Returns balance of the `_owner`.
    /// @param _tokenId The token Iidentifer
    /// @param _owner   The address whose balance will be returned.
    /// @return balance Balance of the `_owner`.
    function balanceOf(uint256 _tokenId, address _owner) public constant returns (uint256) {
        require(_exists(_tokenId));
        RightsBaseToken token = RightsBaseToken(contracts[_tokenId]);

        return token.balanceOf(_owner);
    }

    /// @dev Gets the owner of the specified token ID
    /// @param _tokenId uint256 ID of the token to query the owner of
    /// @return holders address currently marked as the owner of the given token ID
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

    /// @dev Gets the token IDs of the requested owner
    /// @param _owner address owning the objects list to be accessed
    /// @return uint256 token IDs owned by the requested address
    function tokensOfOwner(address _owner) public view returns (uint256[]) {
        return ownedTokenIds[_owner];
    }

    /// @dev Gets the token IDs of the requested owner
    /// @param _holder address holding the objects list to be accessed
    /// @return uint256 token IDs held by the requested address
    function tokensOfHolder(address _holder) public view returns (uint256[]) {
        return heldTokenIdList.valuesOf(_holder);
    }

    /// @dev Decimals of the token
    /// @param _tokenId token id
    /// @return decimals
    function decimalsOf(uint256 _tokenId) public view returns (uint8) {
        // base money info
        address baseTokenAddr = contractOf(_tokenId);
        RightsBaseToken baseToken = RightsBaseToken(baseTokenAddr);
        return baseToken.decimals();
    }

    /// @dev Gets the token object of the specified token ID
    /// @param _tokenId the tokenId of the token object
    /// @return tokenId the tokenId of the token object
    /// @return name the name of the token object
    /// @return symbol the symbol of the token object
    /// @return owner the owner of the token object
    /// @return totalSupply the total supply of the token object
    function getTokenInfo(uint256 _tokenId) public view returns(
        address contractAddress,
        string name,
        string symbol,
        address owner,
        uint256 totalSupply,
        uint8 decimals
    ) {
        require(_exists(_tokenId));
        RightsBaseToken token = RightsBaseToken(contracts[_tokenId]);

        return (
            contracts[_tokenId],
            token.name(),
            token.symbol(),
            ownerOf(_tokenId),
            token.totalSupply(),
            token.decimals()
        );
    }

    /// @dev Calculate relative amount of each tokens
    /// @param _targetTokenId target token id
    /// @param _baseTokenId base token id
    /// @param _amount amount
    function relativeAmountOf(
        uint256 _targetTokenId,
        uint256 _baseTokenId,
        uint256 _amount
    ) public view returns (uint256) {
        if (_targetTokenId == _baseTokenId) {
            return _amount;
        } else {
            // use money info
            uint256 targetDecimals = uint256(decimalsOf(_targetTokenId));
            // base money info
            uint256 baseDecimals = uint256(decimalsOf(_baseTokenId));

            if(targetDecimals >= baseDecimals) {
                return _amount.mul(10 ** (targetDecimals - baseDecimals));
            } else {
                return _amount.div(10 ** (baseDecimals - targetDecimals));
            }
        }
    }


    /*** INTERNAL FUNCTIONS ***/

    /// @dev Check if it is issued contract address
    /// @param _tokenId  token id.
    /// @return A boolean that indicates if the token exists.
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return tokenOwner[_tokenId] != address(0);
    }

    /// @dev Check if it is issued contract address
    /// @param _contractAddress  token address.
    /// @return A boolean that indicates if the token exists.
    function _exists(address _contractAddress) internal view returns (bool) {
        return contractIssues[_contractAddress];
    }

    /// @dev Internal function to add a token ID to the list of a given address
    /// @param _to address representing the new owner of the given token ID
    /// @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
    function _addTokenTo(address _to, uint256 _tokenId) internal {
        require(!_isRegisteredToken(_tokenId));
        ownedTokenIds[_to].push(_tokenId);
        tokenOwner[_tokenId] = _to;
    }

    /// @dev Internal function to add a token ID to the list of a given address
    /// @param _to address representing the new owner of the given token ID
    /// @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
    function _addTokenHolderTo(address _to, uint256 _tokenId) internal {
        require(!_isRegisteredTokenHolder(_to, _tokenId));
        // heldTokensIndex[_to][_tokenId] = holderToTokenIds[_to].push(_tokenId);
        heldTokenIdList.add(_to, _tokenId);
    }

    /// @dev Internal function to remove a token ID from the list of a given address
    /// @param _from address representing the previous owner of the given token ID
    /// @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
    function _removeTokenHolderFrom(address _from, uint256 _tokenId) internal {
        require(_isRegisteredTokenHolder(_from, _tokenId));

        heldTokenIdList.remove(_from, _tokenId);
    }

    /// @dev Internal function to handle token holder list
    /// @param _from address representing the sender 
    /// @param _to address representing the reciever
    /// @param _tokenId uint256 ID of the token to be handled
    /// @param _value uint256 amount of token to be handled
    function _handleTokenHolder(address _from, address _to, uint256 _tokenId, uint256 _value) internal {
        if (_from != address(0) && RightsBaseToken(contracts[_tokenId]).balanceOf(_from) == 0 ) {
            _removeTokenHolderFrom(_from, _tokenId);
        }
        if (_to != address(0) && RightsBaseToken(contracts[_tokenId]).balanceOf(_to) == _value) {
            _addTokenHolderTo(_to, _tokenId);
        }
    }

    /// @dev Returns whether the specified token id registered
    /// @param _tokenId  token identifer.
    /// @return whether the token registered
    function _isRegisteredToken(uint256 _tokenId) internal view returns (bool) {
        return tokenOwner[_tokenId] != address(0);
    }

    /// @dev Returns whether the specified token id registered
    /// @param _to address representing the new owner of the given token ID
    /// @param _tokenId  token identifer.
    /// @return whether the token registered
    function _isRegisteredTokenHolder(address _to, uint256 _tokenId) internal view returns (bool) {
        return heldTokenIdList.exists(_to, _tokenId);
    }
}