// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { MassetStructs } from "./MassetStructs.sol";

/**
 * IBasketManager
 * (Internal) Interface for interacting with BasketManager
 * VERSION: 1.0
 */
interface IBasketManager is MassetStructs {

    // Setters for mAsset to update balances
    // 给单一金库增加余额
    function increaseVaultBalance(
        uint8 _bAsset,
        address _integrator,
        uint256 _increaseAmount) external;

    // 给多种金库增加余额
    function increaseVaultBalances(
        uint8[] calldata _bAsset,
        address[] calldata _integrator,
        uint256[] calldata _increaseAmount) external;

    // 给单一金库减少余额
    function decreaseVaultBalance(
        uint8 _bAsset,
        address _integrator,
        uint256 _decreaseAmount) external;

    // 给多种金库减少余额
    function decreaseVaultBalances(
        uint8[] calldata _bAsset,
        address[] calldata _integrator,
        uint256[] calldata _decreaseAmount) external;

    // 
    function collectInterest() external
        returns (uint256 interestCollected, uint256[] memory gains);

    // Setters for Gov to update Basket composition
    // 更新一揽子稳定的集合
    function addBasset(
        address _basset,
        address _integration,
        bool _isTransferFeeCharged) external returns (uint8 index);

    // 设置稳定币的权重
    function setBasketWeights(address[] calldata _bassets, uint256[] calldata _weights) external;
    function setTransferFeesFlag(address _bAsset, bool _flag) external;

    // Getters to retrieve Basket information
    // 获得一揽子稳定币信息
    function getBasket() external view returns (Basket memory b);

    // 铸造Basset预准备
    function prepareForgeBasset(address _token, uint256 _amt, bool _mint) external
        returns (bool isValid, BassetDetails memory bInfo);

    // 铸造多种bAsset做预准备
    function prepareForgeBassets(address[] calldata _bAssets, uint256[] calldata _amts, bool _mint) external
        returns (ForgePropsMulti memory props);

    // 
    function prepareRedeemMulti() external view returns (RedeemPropsMulti memory props);

    // 获取单个Basset
    function getBasset(address _token) external view returns (Basset memory bAsset);
    // 获取多个Basset
    function getBassets() external view returns (Basset[] memory bAssets, uint256 len);
    function paused() external view returns (bool);
}
