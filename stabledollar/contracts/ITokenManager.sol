// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.6.12;

import { TokenStructs } from "./TokenStructs.sol";

// ICustomToken
interface ITokenManager is TokenStructs {

    // Minting 合成
    function mintMulti(address[] calldata _preToken, uint256[] calldata _bassetAmount) external returns (uint256 massetMinted);

    // Redeeming 赎回
    function redeem(address _targetAsset, uint256 _bassetAmount) external returns (uint256 massetRedeemed);
}
