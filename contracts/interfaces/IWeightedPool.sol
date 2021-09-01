//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.4;

interface IWeightedPool {
    function getPoolId() external view returns (bytes32);
    function setSwapFeePercentage(uint256 swapFeePercentage) external;
}
