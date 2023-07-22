pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "hardhat/console.sol";

interface IERC20 {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function mint(address to, uint256 amount) external;
}

contract UniswapV3SwapRouterMock {
  IERC20 public usdc;
  IERC20 public euro;
  
  constructor(
    IERC20 _usdc,
    IERC20 _euro
  ) {
    usdc = _usdc;
    euro = _euro;
  }

  function updateUSDC(IERC20 _usdc) public {
    usdc = _usdc;
  }

  function updateEuro(IERC20 _euro) public {
    euro = _euro;
  }

  function exactInputSingle(
    ISwapRouter.ExactInputSingleParams memory params
  ) external payable returns (uint256 amountOut) {
    // Transfers USDC from the taker
    usdc.transferFrom(msg.sender, address(this), params.amountIn);

    // Mints fake EURO to the taker
    euro.mint(msg.sender, params.amountIn);

    return params.amountIn;
  }
}