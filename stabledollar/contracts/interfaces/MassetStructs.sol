// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.6.12;

/// @title MassetStructs
/// @author
/// @notice
interface MassetStructs {

    // Stores high level basket info
    // 目前支持的稳定币集合信息
    struct Basket {
        // Array of Bassets currently active
        // 当前支持的稳定币币种
        Basset[] bassets;
        // Max number of bAssets that can be present in any Basket
        // 稳定币支持的数量上限
        uint8 maxBassets;
        // Some bAsset is undergoing re-collateralisation
        bool undergoingRecol;
        // In the event that we do not raise enough funds from the auctioning of a failed Basset,
        // The Basket is deemed as failed, and is undercollateralised to a certain degree.
        // The collateralisation ratio is used to calc Masset burn rate.
        bool failed;
        uint256 collateralisationRatio;
    }

    // Stores bAsset info. The struct takes 5 storage slots per Basset
    // 存储的bAsset信息
    struct Basset {
        // Address of the bAsset
        address addr;
        // Status of the basset
        BassetStatus status; // takes uint8 datatype (1 byte) in storage
        // An ERC20 can charge transfer fee, for example USDT, DGX tokens.
        // takes a byte in storage
        bool isTransferFeeCharged;
        // 1 Basset * ratio / ratioScale == x Masset (relative value)
        // If ratio == 10e8 then 1 bAsset = 10 mAssets
        // A ratio is divised as 10^(18-tokenDecimals) * measurementMultiple(relative value of 1 base unit)
        uint256 ratio;
        // Target weights of the Basset (100% == 1e18)
        uint256 maxWeight;
        // Amount of the Basset that is held in Collateral
        uint256 vaultBalance;
    }

    // Status of the Basset - has it broken its peg? 
    enum BassetStatus {
        Default,
        Normal,
        BrokenBelowPeg,
        BrokenAbovePeg,
        Blacklisted,
        Liquidating,
        Liquidated,
        Failed
    }

    // Internal details on Basset
    struct BassetDetails {
        Basset bAsset;
        address integrator;
        uint8 index;
    }

    // All details needed to Forge with multiple bAssets
    struct ForgePropsMulti {
        bool isValid; // Flag to signify that forge bAssets have passed validity check
        Basset[] bAssets;
        address[] integrators;
        uint8[] indexes;
    }

    // All details needed for proportionate Redemption
    struct RedeemPropsMulti {
        uint256 colRatio;
        Basset[] bAssets;
        address[] integrators;
        uint8[] indexes;
    }
}
