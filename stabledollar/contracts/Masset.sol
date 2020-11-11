// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.6.12;

// External
import { IBasketManager } from "./interfaces/IBasketManager.sol";

// Internal
import { IMasset } from "./interfaces/IMasset.sol";

contract Masset is IMasset {

    uint256 public version = 66;
    IBasketManager private basketManager;

    // 合成事件
    event Minted(address indexed minter, address recipient, uint256 mAssetQuantity, address bAsset, uint256 bAssetQuantity);
    event MintedMulti(address indexed minter, address recipient, uint256 mAssetQuantity, address[] bAssets, uint256[] bAssetQuantities);
    
    function initialize( 
        address _basketManager
    )
        external
    {
        basketManager = IBasketManager(_basketManager);
    }

    function getVersion() public view returns (uint256) {
        return version;
    }

    /**
     * @dev Mint a single bAsset, at a 1:1 ratio with the bAsset. This contract
     *      must have approval to spend the senders bAsset
     * @param _bAsset         Address of the bAsset to mint
     * @param _bAssetQuantity Quantity in bAsset units
     * @return massetMinted   Number of newly minted mAssets
     */
    function mint(address _bAsset, uint256 _bAssetQuantity) override external returns (uint256 massetMinted){
        return _mintTo(_bAsset, _bAssetQuantity, msg.sender);
    }

    /***************************************
              MINTING (INTERNAL)
    ****************************************/

    // Mint Single
    // 单一币种进行合成
    function _mintTo(address _bAsset, uint256 _bAssetQuantity, address _recipient) internal returns (uint256 massetMinted){
        // 必须是个可用的接收者
        require(_recipient != address(0), "Must be a valid recipient");
        // 数量不能为0
        require(_bAssetQuantity > 0, "Quantity must not be 0");

        uint256 quantityDeposited = 66;
        uint256 ratioedDeposit = 55;
        
        // (bool isValid, BassetDetails memory bInfo) = basketManager.prepareForgeBasset(_bAsset, _bAssetQuantity, true);
        // if(!isValid) return 0;

        // Transfer collateral to the platform integration address and call deposit
        // address integrator = bInfo.integrator;
        // (uint256 quantityDeposited, uint256 ratioedDeposit) =
        //     _depositTokens(_bAsset, bInfo.bAsset.ratio, integrator, bInfo.bAsset.isTransferFeeCharged, _bAssetQuantity);

        // Validation should be after token transfer, as bAssetQty is unknown before
        // (bool mintValid, string memory reason) = forgeValidator.validateMint(totalSupply(), bInfo.bAsset, quantityDeposited);
        // require(mintValid, reason);

        // Log the Vault increase - can only be done when basket is healthy
        // basketManager.increaseVaultBalance(bInfo.index, integrator, quantityDeposited);

        // Mint the Masset
        // _mint(_recipient, ratioedDeposit);
        emit Minted(msg.sender, _recipient, ratioedDeposit, _bAsset, quantityDeposited);

        // return ratioedDeposit;
        return quantityDeposited;
    }

}