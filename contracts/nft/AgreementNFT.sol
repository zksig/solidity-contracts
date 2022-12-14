// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../types/DigitalSignatureTypes.sol";
import "../callbacks/signatures/ISignatureCallback.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract AgreementNFT is ISignatureCallback, ERC721URIStorage {
  address private _owner;
  uint256 private nextTokenId;
  string private _imageCID;
  mapping(address => mapping(string => uint256)) private _ownerTokens;

  constructor(
    address owner_,
    string memory _name,
    string memory _symbol,
    string memory imageCID_
  ) ERC721(_name, _symbol) {
    nextTokenId = 1;
    _owner = owner_;
    _imageCID = imageCID_;
  }

  function getImageCID() public view returns (string memory) {
    return _imageCID;
  }

  function signatureCallback(
    DigitalSignatureTypes.SignaturePacket memory packet,
    bytes memory extraInfo
  ) public {
    require(_owner == msg.sender, "Only owner can mint NFTs");

    string memory tokenURI = string(extraInfo);

    _mint(packet.signer, nextTokenId);
    _setTokenURI(nextTokenId, tokenURI);
    _ownerTokens[packet.signer][tokenURI] = nextTokenId;
    nextTokenId++;
  }

  function verifyByTokenURI(
    address signer,
    string calldata tokenURI
  ) public view returns (bool) {
    uint256 tokenId = _ownerTokens[signer][tokenURI];
    return _ownerOf(tokenId) == signer;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual override {
    require(from == address(0), "token transfer not allowed");
  }
}
