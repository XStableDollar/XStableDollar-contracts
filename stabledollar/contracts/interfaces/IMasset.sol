// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.6.12;

import { MassetStructs } from "./MassetStructs.sol";

/// @title IMasset
/// @author
/// @notice (Internal) Masset交互接口
interface IMasset is MassetStructs {

    // Calc interest 
    function collectInterest() external returns (uint256 massetMinted, uint256 newTotalSupply);

    // Minting
    function mint(address _basset, uint256 _bassetQuantity) external returns (uint256 massetMinted);
    function mintTo(address _basset, uint256 _bassetQuantity, address _recipient) external returns (uint256 massetMinted);
    function mintMulti(address[] calldata _bAssets, uint256[] calldata _bassetQuantity, address _recipient) external returns (uint256 massetMinted);

    // Swapping
    function swap(address _input, address _output, uint256 _quantity, address _recipient) external returns (uint256 output);
    function getSwapOutput(address _input, address _output, uint256 _quantity) external view returns (bool, string memory, uint256 output);

    // Redeeming
    function redeem(address _basset, uint256 _bassetQuantity) external returns (uint256 massetRedeemed);
    function redeemTo(address _basset, uint256 _bassetQuantity, address _recipient) external returns (uint256 massetRedeemed);
    function redeemMulti(address[] calldata _bAssets, uint256[] calldata _bassetQuantities, address _recipient) external returns (uint256 massetRedeemed);
    function redeemMasset(uint256 _mAssetQuantity, address _recipient) external;

    // Setters for the Manager or Gov to update module info
    function upgradeForgeValidator(address _newForgeValidator) external;

    // Setters for Gov to set system params
    function setSwapFee(uint256 _swapFee) external;

    // Getters
    function getBasketManager() external view returns(address);
    function forgeValidator() external view returns (address);
    function totalSupply() external view returns (uint256);
    function swapFee() external view returns (uint256);
}
