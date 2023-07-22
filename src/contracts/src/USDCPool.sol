pragma solidity =0.7.6;
pragma abicoder v2;

import "https://github.com/Uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "https://github.com/Uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "https://github.com/Uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";

// interface IERC20 {
//   /**
//    * @dev Emitted when `value` tokens are moved from one account (`from`) to
//    * another (`to`).
//    *
//    * Note that `value` may be zero.
//    */
//   event Transfer(address indexed from, address indexed to, uint256 value);

//   /**
//    * @dev Emitted when the allowance of a `spender` for an `owner` is set by
//    * a call to {approve}. `value` is the new allowance.
//    */
//   event Approval(address indexed owner, address indexed spender, uint256 value);

//   /**
//    * @dev Returns the value of tokens in existence.
//    */
//   function totalSupply() external view returns (uint256);

//   /**
//    * @dev Returns the value of tokens owned by `account`.
//    */
//   function balanceOf(address account) external view returns (uint256);

//   /**
//    * @dev Moves a `value` amount of tokens from the caller's account to `to`.
//    *
//    * Returns a boolean value indicating whether the operation succeeded.
//    *
//    * Emits a {Transfer} event.
//    */
//   function transfer(address to, uint256 value) external returns (bool);

//   /**
//    * @dev Returns the remaining number of tokens that `spender` will be
//    * allowed to spend on behalf of `owner` through {transferFrom}. This is
//    * zero by default.
//    *
//    * This value changes when {approve} or {transferFrom} are called.
//    */
//   function allowance(
//     address owner,
//     address spender
//   ) external view returns (uint256);

//   /**
//    * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
//    * caller's tokens.
//    *
//    * Returns a boolean value indicating whether the operation succeeded.
//    *
//    * IMPORTANT: Beware that changing an allowance with this method brings the risk
//    * that someone may use both the old and the new allowance by unfortunate
//    * transaction ordering. One possible solution to mitigate this race
//    * condition is to first reduce the spender's allowance to 0 and set the
//    * desired value afterwards:
//    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
//    *
//    * Emits an {Approval} event.
//    */
//   function approve(address spender, uint256 value) external returns (bool);

//   /**
//    * @dev Moves a `value` amount of tokens from `from` to `to` using the
//    * allowance mechanism. `value` is then deducted from the caller's
//    * allowance.
//    *
//    * Returns a boolean value indicating whether the operation succeeded.
//    *
//    * Emits a {Transfer} event.
//    */
//   function transferFrom(
//     address from,
//     address to,
//     uint256 value
//   ) external returns (bool);
// }

interface IPool {
  struct Order {
    uint256 id;
    uint256 amount;
    string offChainPaymentAddress;
    bool claimed;
    uint56 completedAt;
    uint256[3] takerEmailHash;
  }

  struct Proof {
    uint[2] a;
    uint[2][2] b;
    uint[2] c;
  }

  function createOrder(
    uint256 amount,
    string memory offChainPaymentAddress
  ) external;

  function claimOrder(uint256 id, bytes32 emailHash) external;

  function completeOrder(
    Proof memory proof,
    uint256[8] memory inputs,
    string memory xBorderRecieverAddress
  ) external;

  function getOrder(uint256 id) external view returns (Order memory);
}

interface IVerifier {
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

  IPool public euroPool;
  IVerifier public verifier;
  // Todo: Switch to SafeERC20.
  IERC20 public usdc;

  ISwapRouter public swapRouter;
  IQuoterV2 public quoter;
  IERC20 public euro;
  uint24 public usdcEuroPoolFee;

  uint256 public orderId;

  constructor(
    IPool _euroPool,
    IVerifier _verifier,
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
    orderId = 1;
  }

  // Update helpers
  function updateVerifier(IVerifier _verifier) public {
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
    orders[orderId] = Order({
      id: orderId,
      amount: amount,
      offChainPaymentAddress: offChainPaymentAddress,
      claimed: false,
      completedAt: 0,
      takerEmailHash: [uint256(0), uint256(0), uint256(0)]
    });

    usdc.transferFrom(msg.sender, address(this), amount);

    orderId += 1;
  }

  // Called by the taker
  // Claims an order in the pool
  function claimOrder(uint256 id, bytes32 emailHash) external override {
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
  ) external override {
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
}
