pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import { IPool } from "./interfaces/IPool.sol";

interface IVenmoSendVerifier {
  function verify(
    uint[2] memory a,
    uint[2][2] memory b,
    uint[2] memory c,
    uint256[8] memory input
  ) external view returns (bool);
}

contract USDCPool is IPool {
  mapping(uint256 => Order) public orders;
  mapping(uint256 => bytes32) public claimedOrders;

  uint16 private constant bytesInPackedBytes = 7; // 7 bytes in a packed item returned from circom

  IPool public euroPool;
  IVenmoSendVerifier public verifier;
  // Todo: Switch to SafeERC20.
  IERC20 public usdc;

  ISwapRouter public swapRouter;
  IQuoterV2 public quoter;
  IERC20 public euro;
  uint24 public usdcEuroPoolFee;

  uint256 public numOrders;

  uint256 constant rsaModulusChunksLen = 17;
  uint256[rsaModulusChunksLen] public venmoMailServerKeys = [
    683441457792668103047675496834917209,
    1011953822609495209329257792734700899,
    1263501452160533074361275552572837806,
    2083482795601873989011209904125056704,
    642486996853901942772546774764252018,
    1463330014555221455251438998802111943,
    2411895850618892594706497264082911185,
    520305634984671803945830034917965905,
    47421696716332554,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0
  ];

  constructor(
    IPool _euroPool,
    IVenmoSendVerifier _verifier,
    IERC20 _usdc,
    ISwapRouter _swapRouter,
    IQuoterV2 _quoter,
    uint24 euroUsdcPoolFee,
    IERC20 _euro
  ) {
    euroPool = _euroPool;
    verifier = _verifier;
    usdc = _usdc;
    swapRouter = _swapRouter;
    euro = _euro;
    quoter = _quoter;
    usdcEuroPoolFee = euroUsdcPoolFee;

    // Set initial orderId
    numOrders = 1;
  }

  // Update helpers
  function updateVerifier(IVenmoSendVerifier _verifier) public {
    verifier = _verifier;
  }

  function updateEuroPool(IPool _euroPool) public {
    euroPool = _euroPool;
  }

  function updateUSDC(IERC20 _usdc) public {
    usdc = _usdc;
  }

  function updateSwapRouter(ISwapRouter _swapRouter) public {
    swapRouter = _swapRouter;
  }

  function updateEuro(IERC20 _euro) public {
    euro = _euro;
  }

  function updateQuoter(IQuoterV2 _quoter) public {
    quoter = _quoter;
  }

  function updateEuroUsdcPoolFee(uint24 _usdcEuroPoolFee) public {
    usdcEuroPoolFee = _usdcEuroPoolFee;
  }

  // Approve helpers
  function approveEuroToUniswap() public {
    euro.approve(address(swapRouter), type(uint256).max);
  }

  // Pool functions

  // Called by the LP
  // Locks USDC in the pool
  // Creates an order in the pool

  // Note: Before create order make sure to approve the contract to spend the amount of USDC you want to lock.

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

    usdc.transferFrom(msg.sender, address(this), amount);

    numOrders += 1;
  }

  // Called by the taker
  // Claims an order in the pool
  function claimOrder(
    uint256 id,
    bytes32 emailHash // will be set to 0 for the demo
  ) external override {
    require(!orders[id].claimed, "Order has already been claimed.");
    claimedOrders[id] = emailHash;
    orders[id].claimed = true;
  }

  // Called by the taker
  // Completes an order in the pool
  function completeOrder(
    Proof memory proof,
    uint256[8] memory inputs,
    string memory xBorderRecieverAddress
  ) external {
    // Extract out all public inputs
    uint256 orderId = inputs[0];
    uint256[3] memory receiverIdentifier = [inputs[1], inputs[2], inputs[3]];
    uint256 amount = inputs[4];
    uint256[3] memory senderEmailHash = [inputs[5], inputs[6], inputs[7]];

    require(
      orders[orderId].claimed,
      "Order must be claimed before it can be completed."
    );
    require(orders[orderId].completedAt == 0, "Order must not be completed.");

    // verify proof
    verifier.verify(proof.a, proof.b, proof.c, inputs);

    // Verify the right amount of USDC was sent to the right receiver address
    // TODO: FELIX.
    // require(
    //   identifiersMatch(orderId, receiverIdentifier),
    //   "Receiver address must match the order receiver address."
    // );
    require(
      amount >= orders[orderId].amount,
      "Amount must be greater than the order amount."
    );

    // Swaps USDC for EURO on Uniswap V3
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
      .ExactInputSingleParams({
        tokenIn: address(usdc),
        tokenOut: address(euro),
        fee: usdcEuroPoolFee,
        recipient: msg.sender,
        deadline: block.timestamp,
        amountIn: amount,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      });

    // The call to `exactInputSingle` executes the swap.
    uint256 amountOut = swapRouter.exactInputSingle(params);

    // Deposit EURO into the EURO pool on the taker's receiver behalf
    // euroPool.createOrder(amount, xBorderRecieverAddress);
  }

  function getOrder(uint256 id) external view override returns (Order memory) {
    return orders[id];
  }

  function matchOrder(
    uint256 usdcAmount
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
      if (orders[i].amount >= usdcAmount) {
        orderId = orders[i].id;
        offChainPaymentAddress = orders[i].offChainPaymentAddress;
        break;
      }
    }

    // Simulates the swap on Uniswap V3
    IQuoterV2.QuoteExactInputSingleParams memory params = IQuoterV2
      .QuoteExactInputSingleParams({
        tokenIn: address(usdc),
        tokenOut: address(euro),
        amountIn: usdcAmount,
        fee: usdcEuroPoolFee,
        sqrtPriceLimitX96: 0
      });
    // (uint256 exptedAmountOut, uint160 , uint32 , uint256 ) = quoter.quoteExactInputSingle(params);
    (uint256 exptedAmountOut, , , ) = quoter.quoteExactInputSingle(params);
    outputAmount = exptedAmountOut;
  }

  // This assumes the numbers are being inputted as uint32 (as there are 128 ASCII characters)
  function identifiersMatch(
    uint256 orderId,
    uint8[] memory receiverIdentifier
  ) internal returns (bool) {
    string memory storedAddress = orders[orderId].offChainPaymentAddress;
    bytes memory storedAddressBytes = bytes(storedAddress);

    if (receiverIdentifier.length != storedAddressBytes.length) {
      return false;
    }

    for (uint i; i < receiverIdentifier.length; i++) {
      uint8 storedDecimal = uint8(storedAddressBytes[i]);
      if (receiverIdentifier[i] != storedDecimal) {
        return false;
      }
    }

    return true;
  }

  ///
  /// MAGICAL DECODING FUNCTIONS IMPORTED FROM ZK-EMAIL
  ///

  // Unpacks uint256s into bytes and then extracts the non-zero characters
  // Only extracts contiguous non-zero characters and ensures theres only 1 such state
  // Note that unpackedLen may be more than packedBytes.length * 8 since there may be 0s
  // TODO: Remove console.logs and define this as a pure function instead of a view
  function _convertPackedBytesToBytes(
    uint256[3] memory packedBytes,
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

  // Code example:
  function stringToUint256(string memory s) external pure returns (uint256) {
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
