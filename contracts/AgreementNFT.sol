pragma solidity ^0.8.9;

import "./utils/ERC721NoEvents.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract AgreementNFT is ERC721NoEvents {
  address private _owner;
  uint256 private nextTokenId;
  string private _imageCID;
  mapping(address => mapping(string => uint256)) private _ownerTokens;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory imageCID_
  ) ERC721NoEvents(_name, _symbol) {
    nextTokenId = 1;
    _owner = tx.origin;
    _imageCID = imageCID_;
  }

  function getImageCID() public view returns (string memory) {
    return _imageCID;
  }

  function signatureMint(
    address signer,
    string calldata tokenURI
  ) public returns (uint256) {
    require(_owner == tx.origin, "Only owner can mint NFTs");

    _safeMint(signer, nextTokenId);
    _setTokenURI(nextTokenId, tokenURI);
    _ownerTokens[signer][tokenURI] = nextTokenId;
    return nextTokenId++;
  }

  function verifyByTokenURI(
    address signer,
    string calldata tokenURI
  ) public view returns (bool) {
    uint256 tokenId = _ownerTokens[signer][tokenURI];
    return _ownerOf(tokenId) == signer;
  }
}
