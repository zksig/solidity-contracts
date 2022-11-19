pragma solidity ^0.8.9;

import "./ERC721NoEvents.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract AgreementNFT is ERC721NoEvents {
  string private _imageCID;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory imageCID_
  ) ERC721NoEvents(_name, _symbol) {
    _imageCID = imageCID_;
  }

  function getImageCID() public view returns (string memory) {
    return _imageCID;
  }

  function signatureMint(
    address signer,
    uint256 tokenId,
    string calldata tokenURI
  ) public {
    _setTokenURI(tokenId, tokenURI);
    _safeMint(signer, tokenId);
  }
}
