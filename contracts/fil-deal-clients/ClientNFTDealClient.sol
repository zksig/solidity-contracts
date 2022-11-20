// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { bytesToAddress } from "../utils/helpers.sol";
import "./NFTDealClient.sol";
import "../utils/ERC721NoEvents.sol";

contract ClientNFTDealClient is NFTDealClient {
  function authorizeData(
    bytes calldata cidraw,
    bytes calldata client,
    uint size
  ) internal virtual {
    ERC721NoEvents nftContract = ERC721NoEvents(nftAddress);

    require(
      nftContract.balanceOf(bytesToAddress(client)) > 0,
      "Client is missing required NFT"
    );
  }
}
