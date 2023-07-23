pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";

import "hardhat/console.sol";

interface IERC20 {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function mint(address to, uint256 amount) external;
}

contract UniswapV3QuoterMock {
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

  function quoteExactInputSingle(
    IQuoterV2.QuoteExactInputSingleParams memory params
  ) external payable returns (uint256 amountOut) {
    // Transfers USDC from the taker
    
    return params.amountIn;
  }
}