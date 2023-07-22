pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import { IPool } from "./interfaces/IPool.sol";
import "hardhat/console.sol";

interface IRevolutSendVerifier {
  function verify(
    uint[2] memory a,
    uint[2][2] memory b,
    uint[2] memory c,
    uint256[31] memory input
  ) external view returns (bool);
}

contract EuropePool is IPool {
  mapping(uint256 => Order) public orders;
  mapping(uint256 => bytes) public claimedOrders;

  uint16 private constant bytesInPackedBytes = 7; // 7 bytes in a packed item returned from circom

  IPool public usdcPool;
  IRevolutSendVerifier public verifier;
  IERC20 public ageuro;

  ISwapRouter public swapRouter;
  IQuoterV2 public quoter;
  IERC20 public usdc;
  uint24 public usdcEuroPoolFee;

  uint256 public numOrders;

  uint256 constant rsaModulusChunksLen = 17;
  uint256[rsaModulusChunksLen] public revolutServerKeys = [
    1357877033487705755044473051962315017,
    1992913992454963774321360338650810838,
    1332679464913641539987869420620959603,
    2348132427872155825755866901316180901,
    1883906444029850560136606276757266463,
    2450997574449119024683227690782146111,
    2287069363878927698261632102663638321,
    2446813570435318449337400488662901236,
    48497691420903457,
    0,
    0,
    0,
    0,
    0,
    0,
    0
  ];

  constructor(
    IRevolutSendVerifier _verifier,
    IERC20 _ageuro,
    ISwapRouter _swapRouter,
    IQuoterV2 _quoter,
    uint24 euroUsdcPoolFee,
    IERC20 _usdc
  ) {
    verifier = _verifier;
    ageuro = _ageuro;
    swapRouter = _swapRouter;
    quoter = _quoter;
    usdcEuroPoolFee = euroUsdcPoolFee;
    usdc = _usdc;

    // Set initial orderId
    numOrders = 1;
  }

  // Update helpers
  function updateVerifier(IRevolutSendVerifier _verifier) public {
    verifier = _verifier;
  }

  function updateUsdcPool(IPool _usdcPool) public {
    usdcPool = _usdcPool;
  }

  function updateUSDC(IERC20 _usdc) public {
    usdc = _usdc;
  }

  function updateSwapRouter(ISwapRouter _swapRouter) public {
    swapRouter = _swapRouter;
  }

  function updateEuro(IERC20 _ageuro) public {
    ageuro = _ageuro;
  }

  function updateQuoter(IQuoterV2 _quoter) public {
    quoter = _quoter;
  }

  function updateEuroUsdcPoolFee(uint24 _usdcEuroPoolFee) public {
    usdcEuroPoolFee = _usdcEuroPoolFee;
  }

  // Approve helpers
  function approveUsdcToUniswap() public {
    usdc.approve(address(swapRouter), type(uint256).max);
  }

  // Pool functions

  // Called by the LP
  // Locks agEURO in the pool
  // Creates an order in the pool

  // Note: Before create order make sure to approve the contract to spend the amount of agEURO you want to lock.

  function createOrder(
    uint256 amount,
    string memory offChainPaymentAddress
  ) external override {
    orders[numOrders] = Order({
      id: numOrders,
      amount: amount,
      offChainPaymentAddress: offChainPaymentAddress,
      claimed: false,
      completedAt: 0,
      takerEmailHash: [uint256(0), uint256(0), uint256(0)]
    });

    ageuro.transferFrom(msg.sender, address(this), amount);

    numOrders += 1;
  }

  // Called by the taker
  // Claims an order in the pool
  function claimOrder(
    uint256 id,
    bytes memory emailHash // will be set to 0 for the demo
  ) external override {
    require(!orders[id].claimed, "Order has already been claimed.");
    claimedOrders[id] = emailHash;
    orders[id].claimed = true;
  }

  // Called by the taker
  // Completes an order in the pool
  function completeCrossChainOrder(
    Proof memory proof,
    uint256[31] memory inputs,
    string memory xBorderRecieverAddress
  ) external {
    (uint256 orderId) = _verifyOnRampOrder(
      proof,
      inputs
    );

    // Update order status
    orders[orderId].completedAt = uint56(block.timestamp);
    // orders[orderId].takerEmailHash = 0;     // Not updating this for now.
    // Todo: Nullify the nullifier. // skipping for now.

    // Swaps USDC for EURO on Uniswap V3
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
      .ExactInputSingleParams({
        tokenIn: address(ageuro),
        tokenOut: address(usdc),
        fee: usdcEuroPoolFee,
        recipient: msg.sender,
        deadline: block.timestamp,
        amountIn: orders[orderId].amount,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      });

    // The call to `exactInputSingle` executes the swap.
    uint256 amountOut = swapRouter.exactInputSingle(params);

    // Deposit USD into the USD pool on the taker's receiver behalf
    // usdcPool.createOrder(amount, xBorderRecieverAddress);
  }

  function completeOnRampOrder(
    Proof memory proof,
    uint256[31] memory inputs
  ) public {
    (uint256 orderId) = _verifyOnRampOrder(
      proof,
      inputs
    );

    // Update order status
    orders[orderId].completedAt = uint56(block.timestamp);
    // orders[orderId].takerEmailHash = 0;     // Not updating this for now.
    // Todo: Nullify the nullifier. // skipping for now.

    // Transfer the EURO to the receiver
    ageuro.transfer(msg.sender, orders[orderId].amount);

  }

  function _verifyOnRampOrder(
    Proof memory proof,
    uint256[31] memory inputs
  ) internal returns (uint256 _orderId) {
    // Verify that proof generated by onRamper is valid
    (
      uint256 receiverIdentifier,
      uint256 euroAmount,
      bytes memory nullfier,
      uint256 orderId
    ) = _verifyAndParseOnRampProof(proof, inputs);

    require(
      orders[orderId].claimed,
      "Order must be claimed before it can be completed."
    );
    require(orders[orderId].completedAt == 0, "Order must not be completed.");

    // Verify the right amount of EURO was sent to the right receiver address
    require(
      stringToUint256(orders[orderId].offChainPaymentAddress) ==
        receiverIdentifier,
      "Receiver address must match the offchain payment receiver address."
    );
    require(
      euroAmount >= orders[orderId].amount,
      "Amount must be greater than the order amount."
    );

    return (orderId);
  }

  function getOrder(uint256 id) external view override returns (Order memory) {
    return orders[id];
  }

  function matchOrder(
    uint256 euroAmount
  )
    external
    returns (
      uint256 orderId,
      string memory offChainPaymentAddress,
      uint256 outputAmount
    )
  {
    // Iterate over all open orders and find order whose amount is greater than the amount of USDC we want to swap
    for (uint256 i = 0; i < orderId; i++) {
      if (orders[i].amount >= euroAmount) {
        orderId = orders[i].id;
        offChainPaymentAddress = orders[i].offChainPaymentAddress;
        break;
      }
    }

    // Simulates the swap on Uniswap V3
    IQuoterV2.QuoteExactInputSingleParams memory params = IQuoterV2
      .QuoteExactInputSingleParams({
        tokenIn: address(ageuro),
        tokenOut: address(usdc),
        amountIn: euroAmount,
        fee: usdcEuroPoolFee,
        sqrtPriceLimitX96: 0
      });
    // (uint256 exptedAmountOut, uint160 , uint32 , uint256 ) = quoter.quoteExactInputSingle(params);
    (uint256 exptedAmountOut, , , ) = quoter.quoteExactInputSingle(params);
    outputAmount = exptedAmountOut;
  }

  function _verifyAndParseOnRampProof(
    Proof memory proof,
    uint256[31] memory inputs
  )
    internal
    view
    returns (
      uint256 receiverIdentifier,
      uint256 euroAmount,
      bytes memory nullifier,
      uint256 orderId
    )
  {
    // verify proof
    // require(
    //   verifier.verify(proof.a, proof.b, proof.c, inputs),
    //   "Invalid proof"
    // );

    // Extract out all public inputs
    // Signals [0..4] are the packed amount
    // [206966893618, 0,  0, 0, 0]
    // 2,000
    // 2000
    uint256[5] memory amountPacked;
    for (uint256 i = 0; i < 5; i++) {
      amountPacked[i] = inputs[i];
    }
    uint256 amount = stringToUint256(
      convertPackedBytesToBytes(amountPacked, 30)
    );
    euroAmount = amount * 10 ** 18;
    console.log("euroAmount: ", euroAmount);

    // Signals [5..9] are the packed receiver identifier (IBAN)
    // [14689682314318928, 24866598145579061, 24866934413088856, 14412613993125976, 0]
    // PT500045X= XXXXXXXXXXXX1243
    // 5000451243
    uint256[5] memory receiverIdentifierPacked;
    for (uint256 i = 0; i < 5; i++) {
      receiverIdentifierPacked[i] = inputs[i + 5];
    }
    receiverIdentifier = stringToUint256(
      convertPackedBytesToBytes(receiverIdentifierPacked, 30)
    );
    console.log("receiverIdentifier: ", receiverIdentifier);

    // Signals [10, 11, 12] are nullifier
    nullifier = abi.encodePacked(inputs[10], inputs[11], inputs[12]);

    // Signals [13...29] are modulus
    for (uint256 i = 0; i < 17; i++) {
      
      console.log("inputs[i + 13]: ", inputs[i + 13], "revolutServerKeys[i]: ", revolutServerKeys[i]);
      // require(inputs[i + 13] == revolutServerKeys[i], "Invalid modulus");
    }

    // Signal [30] is the order id
    orderId = inputs[30];
  }

  ///
  /// MAGICAL DECODING FUNCTIONS IMPORTED FROM ZK-EMAIL
  ///

  // Unpacks uint256s into bytes and then extracts the non-zero characters
  // Only extracts contiguous non-zero characters and ensures theres only 1 such state
  // Note that unpackedLen may be more than packedBytes.length * 8 since there may be 0s
  // TODO: Remove console.logs and define this as a pure function instead of a view
  function convertPackedBytesToBytes(
    uint256[5] memory packedBytes,
    uint256 maxBytes
  ) public pure returns (string memory extractedString) {
    uint8 state = 0;
    // bytes: 0 0 0 0 y u s h _ g 0 0 0
    // state: 0 0 0 0 1 1 1 1 1 1 2 2 2
    bytes memory nonzeroBytesArray = new bytes(packedBytes.length * 7);
    uint256 nonzeroBytesArrayIndex = 0;
    for (uint16 i = 0; i < packedBytes.length; i++) {
      uint256 packedByte = packedBytes[i];
      uint8[] memory unpackedBytes = new uint8[](bytesInPackedBytes);
      for (uint j = 0; j < bytesInPackedBytes; j++) {
        unpackedBytes[j] = uint8(packedByte >> (j * 8));
      }

      for (uint256 j = 0; j < bytesInPackedBytes; j++) {
        uint256 unpackedByte = unpackedBytes[j]; //unpackedBytes[j];
        if (unpackedByte != 0) {
          nonzeroBytesArray[nonzeroBytesArrayIndex] = bytes1(
            uint8(unpackedByte)
          );
          nonzeroBytesArrayIndex++;
          if (state % 2 == 0) {
            state += 1;
          }
        } else {
          if (state % 2 == 1) {
            state += 1;
          }
        }
        packedByte = packedByte >> 8;
      }
    }

    string memory returnValue = string(nonzeroBytesArray);
    require(state == 2, "Invalid final state of packed bytes in email");
    // console.log("Characters in username: ", nonzeroBytesArrayIndex);
    require(nonzeroBytesArrayIndex <= maxBytes, "Venmo id too long");
    return returnValue;
    // Have to end at the end of the email -- state cannot be 1 since there should be an email footer
  }

  function stringToUint256(string memory s) public pure returns (uint256) {
    bytes memory b = bytes(s);
    uint256 result = 0;
    uint256 oldResult = 0;

    for (uint i = 0; i < b.length; i++) {
      // c = b[i] was not needed
      // UNSAFE: Check that the character is a number - we include padding 0s in Venmo ids
      if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
        // store old value so we can check for overflows
        oldResult = result;
        result = result * 10 + (uint8(b[i]) - 48);
        // prevent overflows
        require(result >= oldResult, "Overflow detected");
      }
    }
    return result;
  }
}
