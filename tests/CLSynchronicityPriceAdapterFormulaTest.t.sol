// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';

import {CLSynchronicityPriceAdapter} from '../src/contracts/CLSynchronicityPriceAdapter.sol';
import {IChainlinkAggregator} from '../src/interfaces/IChainlinkAggregator.sol';

contract StablecoinPriceAdapterFormulaTest is Test {
  IChainlinkAggregator public constant ETH_USD_AGGREGATOR =
    IChainlinkAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('ethereum'), 15588955);
  }

  function testFormula() public {
    uint256 TESTS_NUM = 10;

    int256 ethPrice = ETH_USD_AGGREGATOR.latestAnswer();
    uint8 ethAggregatorDecimals = ETH_USD_AGGREGATOR.decimals();

    for (uint256 i = 1; i <= TESTS_NUM; i++) {
      address mockAggregator = address(0);
      int256 mockPrice = ethPrice / int256(i);
      _setMockPrice(mockAggregator, mockPrice, 8);

      CLSynchronicityPriceAdapter adapter = new CLSynchronicityPriceAdapter(
        address(ETH_USD_AGGREGATOR),
        mockAggregator,
        18
      );

      int256 price = adapter.latestAnswer();
      int256 expectedPriceInEth = int256(1 ether / i);

      int256 maxDiff = int256(10 ** (ethAggregatorDecimals));
      assertApproxEqAbs(
        uint256(price),
        uint256(expectedPriceInEth),
        uint256(maxDiff)
      );
    }
  }

  function testPriceIsReturnedWhenResultDecimalsIsLessThanDiff() public {
    address mockAggregator1 = address(0);
    address mockAggregator2 = address(1);

    _setMockPrice(mockAggregator1, 100, 2);
    _setMockPrice(mockAggregator2, 10000000, 7);

    CLSynchronicityPriceAdapter adapter = new CLSynchronicityPriceAdapter(
      mockAggregator1,
      mockAggregator2,
      4
    );

    // 10000000 * 10^4 * 10^2 / 100 * 10^7 = 10000
    int256 price = adapter.latestAnswer();
    assertEq(price, 10000);
  }

  function _setMockPrice(
    address mockAggregator,
    int256 mockPrice,
    uint256 decimals
  ) internal {
    bytes memory latestAnswerCall = abi.encodeWithSignature('latestAnswer()');
    bytes memory decimalsCall = abi.encodeWithSignature('decimals()');

    vm.mockCall(mockAggregator, latestAnswerCall, abi.encode(mockPrice));
    vm.mockCall(mockAggregator, decimalsCall, abi.encode(decimals));
  }
}
