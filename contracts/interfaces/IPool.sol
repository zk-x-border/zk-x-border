pragma solidity =0.7.6;
pragma abicoder v2;

interface IPool {
  struct Order {
    uint256 id;
    uint256 amount;
    string offChainPaymentAddress;
    bool claimed;
    uint56 completedAt;
    uint256[3] takerEmailHash;
  }

  struct ZKProof {
    uint[2] a;
    uint[2][2] b;
    uint[2] c;
  }

  function createOrder(
    uint256 amount,
    string memory offChainPaymentAddress
  ) external;

  function claimOrder(uint256 id, bytes memory emailHash) external;

  function getOrder(uint256 id) external view returns (Order memory);
}
