pragma solidity ^0.4.24;

import "./../utils/RDDNControl.sol";

import 'openzeppelin-solidity/token/ERC721/ERC721Enumerable.sol';

/**
 * @title Data token
 * @dev ERC721 based contract for master data management
 */
contract MasterDataModule is RDDNControl, ERC721Enumerable {
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
    onlyOwner
  {
    super.transferFrom(from, to, tokenId);
  }
}