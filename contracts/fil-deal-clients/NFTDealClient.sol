// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { specific_authenticate_message_params_parse, specific_deal_proposal_cbor_parse } from "../utils/CBORParse.sol";

abstract contract NFTDealClient {
  uint64 public constant AUTHORIZE_MESSAGE_METHOD_NUM = 2643134072;
  address public nftAddress;

  constructor(address _nftAddress) {
    nftAddress = _nftAddress;
  }

  function authorizeData(
    bytes calldata cidraw,
    bytes calldata client,
    bytes calldata provider,
    uint size
  ) internal virtual;

  function handle_filecoin_method(
    uint64,
    uint64 method,
    bytes calldata params
  ) public {
    if (method != AUTHORIZE_MESSAGE_METHOD_NUM) {
      revert("the filecoin method that was called is not handled");
    }

    bytes
      calldata deal_proposal_cbor_bytes = specific_authenticate_message_params_parse(
        params
      );
    (
      bytes calldata cidraw,
      bytes calldata client,
      bytes calldata provider,
      uint size
    ) = specific_deal_proposal_cbor_parse(deal_proposal_cbor_bytes);
    authorizeData(cidraw, client, provider, size);
  }
}
