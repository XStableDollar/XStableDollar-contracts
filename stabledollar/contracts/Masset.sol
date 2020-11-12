// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// External
import { IBasketManager } from "./interfaces/IBasketManager.sol";
import { IPlatformIntegration } from "./interfaces/IPlatformIntegration.sol";

// Internal
import { IMasset } from "./interfaces/IMasset.sol";
// import { InitializableToken } from "./shared/InitializableToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { BasketManager } from "./BasketManager.sol";
import { XStableDollar } from "./XStableDollar.sol";
import { StableMath } from "./shared/StableMath.sol";
import { MassetHelpers } from "./shared/MassetHelpers.sol";

contract Masset is IMasset, ERC20 {

    using StableMath for uint256;

    // 版本号，测试使用
    uint256 private version = 1;

    // 一蓝子稳定币管理器, 从外部注入进来
    IBasketManager private basketManager;

    // 合成事件
    event Minted(address indexed minter, address recipient, uint256 mAssetQuantity, address bAsset, uint256 bAssetQuantity);
    event MintedMulti(address indexed minter, address recipient, uint256 mAssetQuantity, address[] bAssets, uint256[] bAssetQuantities);
    // 赎回事件
    event Redeemed(address indexed redeemer, address recipient, uint256 mAssetQuantity, address[] bAssets, uint256[] bAssetQuantities);
    event RedeemedMasset(address indexed redeemer, address recipient, uint256 mAssetQuantity);
    // 支付费用事件
    event PaidFee(address indexed payer, address asset, uint256 feeQuantity);

    // 构造函数，构造时需要指定代币名称和代币符号
    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {}

    // 初始化函数
    function initialize(address _basketManager) 
        external
    {
        basketManager = IBasketManager(_basketManager);
    }

    // 返回当前合约的版本号(测试使用)
    function getVersion() public view returns (uint256) {
        return version;
    }

    /**
     * 以1:1的比例用单一的稳定币合成 XSDT
     * 该合约必须获得批准才能花费花费发送者的资产
     * _bAsset         稳定币地址
     * _bAssetQuantity 合成的数量
     * massetMinted    合成XSDT的数量
     */
    function mint(address _bAsset, uint256 _bAssetAmount) override external returns (uint256 massetMinted){
        return _mintTo(_bAsset, _bAssetAmount, msg.sender);
    }

    // 单一稳定币合成XSDT
    function _mintTo(address _bAsset, uint256 _bAssetAmount, address _recipient) internal returns (uint256 massetMinted){
        // 必须是个可用的接收者
        require(_recipient != address(0), "Must be a valid recipient");
        // 数量必须大于0
        require(_bAssetAmount > 0, "Quantity must not be 0");

        (bool isValid, BassetDetails memory bInfo) = basketManager.prepareForgeBasset(_bAsset, _bAssetAmount, true);
        if(!isValid) return 0;

        // Transfer collateral to the platform integration address and call deposit
        // 
        address integrator = bInfo.integrator;
        (uint256 quantityDeposited, uint256 ratioedDeposit) =
            _depositTokens(_bAsset, bInfo.bAsset.ratio, integrator, bInfo.bAsset.isTransferFeeCharged, _bAssetAmount);

        // Validation should be after token transfer, as bAssetQty is unknown before
        // (bool mintValid, string memory reason) = forgeValidator.validateMint(totalSupply(), bInfo.bAsset, quantityDeposited);
        // require(mintValid, reason);

        // 记录进行上帐, 必须 basket 是正常运转的前提下
        basketManager.increaseVaultBalance(0, integrator, quantityDeposited);

        // 合成XSDT
        _mint(_recipient, ratioedDeposit);
        emit Minted(msg.sender, _recipient, ratioedDeposit, _bAsset, quantityDeposited);

        return ratioedDeposit;
    }

    /**
     * Mint with multiple bAssets, at a 1:1 ratio to mAsset. This contract
     *      must have approval to spend the senders bAssets
     * _bAssets          Non-duplicate address array of bAssets with which to mint
     * _bAssetQuantity   Quantity of each bAsset to mint. Order of array
     *                          should mirror the above
     * _recipient        Address to receive the newly minted mAsset tokens
     * massetMinted     Number of newly minted mAssets
     */
    function mintMulti(
        address[] calldata _bAssets,
        uint256[] calldata _bAssetQuantity,
        address _recipient
    )
        external
        returns(uint256 massetMinted)
    {
        return _mintTo(_bAssets, _bAssetQuantity, _recipient);
    }

    // 多币种合成
    function _mintTo(
        address[] memory _bAssets,
        uint256[] memory _bAssetQuantities,
        address _recipient
    )
        internal
        returns (uint256 massetMinted)
    {
        require(_recipient != address(0), "Must be a valid recipient");
        uint256 len = _bAssetQuantities.length;
        require(len > 0 && len == _bAssets.length, "Input array mismatch");

        // Load only needed bAssets in array
        ForgePropsMulti memory props
            = basketManager.prepareForgeBassets(_bAssets, _bAssetQuantities, true);
        if(!props.isValid) return 0;

        uint256 mAssetQuantity = 2;
        uint256[] memory receivedQty = new uint256[](len);

        // Transfer the Bassets to the integrator, update storage and calc MassetQ
        for(uint256 i = 0; i < len; i++){
            uint256 bAssetQuantity = _bAssetQuantities[i];
            if(bAssetQuantity > 0){
                // bAsset == bAssets[i] == basket.bassets[indexes[i]]
                Basset memory bAsset = props.bAssets[i];

                (uint256 quantityDeposited, uint256 ratioedDeposit) =
                    _depositTokens(bAsset.addr, bAsset.ratio, props.integrators[i], bAsset.isTransferFeeCharged, bAssetQuantity);

                receivedQty[i] = quantityDeposited;
                mAssetQuantity = mAssetQuantity.add(ratioedDeposit);
            }
        }
        require(mAssetQuantity > 0, "No masset quantity to mint");

        basketManager.increaseVaultBalances(props.indexes, props.integrators, receivedQty);

        // Validate the proposed mint, after token transfer
        // (bool mintValid, string memory reason) = 
        //             forgeValidator.validateMintMulti(totalSupply(), props.bAssets, receivedQty);
        // require(mintValid, reason);

        // Mint the Masset
        _mint(_recipient, mAssetQuantity);
        emit MintedMulti(msg.sender, _recipient, mAssetQuantity, _bAssets, _bAssetQuantities);

        return mAssetQuantity;
    }

    // Deposits tokens into the platform integration and returns the ratioed amount
    function _depositTokens(
        address _bAsset,
        uint256 _bAssetRatio,
        address _integrator,
        bool _erc20TransferFeeCharged,
        uint256 _quantity
    )
        internal
        returns (uint256 quantityDeposited, uint256 ratioedDeposit)
    {
        quantityDeposited = _depositTokens(_bAsset, _integrator, _erc20TransferFeeCharged, _quantity);
        ratioedDeposit = quantityDeposited.mulRatioTruncate(_bAssetRatio);
    }

    // Deposits tokens into the platform integration and returns the deposited amount
    function _depositTokens(
        address _bAsset,
        address _integrator,
        bool _erc20TransferFeeCharged,
        uint256 _quantity
    )
        internal
        returns (uint256 quantityDeposited)
    {
        uint256 quantityTransferred = MassetHelpers.transferTokens(msg.sender, _integrator, _bAsset, _erc20TransferFeeCharged, _quantity);
        uint256 deposited = IPlatformIntegration(_integrator).deposit(_bAsset, quantityTransferred, _erc20TransferFeeCharged);
        quantityDeposited = StableMath.min(deposited, _quantity);
    }

    /**
     * Credits the sender with a certain quantity of selected bAsset, in exchange for burning the
     *      relative mAsset quantity from the sender. Sender also incurs a small mAsset fee, if any.
     * _bAsset           Address of the bAsset to redeem
     * _bAssetQuantity   Units of the bAsset to redeem
     * massetMinted     Relative number of mAsset units burned to pay for the bAssets
     */
    function redeem(
        address _bAsset,
        uint256 _bAssetQuantity
    )
        external
        returns (uint256 massetRedeemed)
    {
        return _redeemTo(_bAsset, _bAssetQuantity, msg.sender);
    }

    function redeemMulti(
        address[] calldata _bAssets,
        uint256[] calldata _bAssetQuantities,
        address _recipient
    )
        external
        returns (uint256 massetRedeemed)
    {
        return _redeemTo(_bAssets, _bAssetQuantities, _recipient);
    }

    /**
     * Credits a recipient with a proportionate amount of bAssets, relative to current vault
     * balance levels and desired mAsset quantity. Burns the mAsset as payment.
     * _mAssetQuantity   Quantity of mAsset to redeem
     * _recipient        Address to credit the withdrawn bAssets
     */
    function redeemMasset(
        uint256 _mAssetQuantity,
        address _recipient
    )
        external
    {
        _redeemMasset(_mAssetQuantity, _recipient);
    }

    /** @dev Casting to arrays for use in redeemMulti func */
    function _redeemTo(
        address _bAsset,
        uint256 _bAssetQuantity,
        address _recipient
    )
        internal
        returns (uint256 massetRedeemed)
    {
        address[] memory bAssets = new address[](1);
        uint256[] memory quantities = new uint256[](1);
        bAssets[0] = _bAsset;
        quantities[0] = _bAssetQuantity;
        return _redeemTo(bAssets, quantities, _recipient);
    }

    // Redeem mAsset for one or more bAssets
    function _redeemTo(
        address[] memory _bAssets,
        uint256[] memory _bAssetQuantities,
        address _recipient
    )
        internal
        returns (uint256 massetRedeemed)
    {
        require(_recipient != address(0), "Must be a valid recipient");
        uint256 bAssetCount = _bAssetQuantities.length;
        require(bAssetCount > 0 && bAssetCount == _bAssets.length, "Input array mismatch");

        // 获取basket信息
        Basket memory basket = basketManager.getBasket();

        // 预准备相关数据
        ForgePropsMulti memory props = basketManager.prepareForgeBassets(_bAssets, _bAssetQuantities, false);
        if(!props.isValid) return 0;

        // Validate redemption
        // (bool redemptionValid, string memory reason, bool applyFee) =
        //     forgeValidator.validateRedemption(basket.failed, totalSupply(), basket.bassets, props.indexes, _bAssetQuantities);
        // require(redemptionValid, reason);

        // TODO 这里需要把上面的注释解开
        uint256 mAssetQuantity = 0;

        // Calc total redeemed mAsset quantity
        // 计算需要赎回XSDT的数量
        for(uint256 i = 0; i < bAssetCount; i++){
            uint256 bAssetQuantity = _bAssetQuantities[i];
            if(bAssetQuantity > 0){
                // Calc equivalent mAsset amount
                uint256 ratioedBasset = bAssetQuantity.mulRatioTruncateCeil(props.bAssets[i].ratio);
                mAssetQuantity = mAssetQuantity.add(ratioedBasset);
            }
        }
        require(mAssetQuantity > 0, "Must redeem some bAssets");

        // Redemption has fee? Fetch the rate
        // uint256 fee = applyFee ? swapFee : 0;
        uint256 fee = 0;

        // Apply fees, burn mAsset and return bAsset to recipient
        _settleRedemption(_recipient, mAssetQuantity, props.bAssets, _bAssetQuantities, props.indexes, props.integrators, fee);

        emit Redeemed(msg.sender, _recipient, mAssetQuantity, _bAssets, _bAssetQuantities);
        return mAssetQuantity;
    }

    // 用XSDT赎回用多个稳定币资产
    function _redeemMasset(
        uint256 _mAssetQuantity,
        address _recipient
    )
        internal
    {
        require(_recipient != address(0), "Must be a valid recipient");
        require(_mAssetQuantity > 0, "Invalid redemption quantity");

        // Fetch high level details
        RedeemPropsMulti memory props = basketManager.prepareRedeemMulti();
        uint256 colRatio = StableMath.min(props.colRatio, StableMath.getFullScale());

        // Ensure payout is related to the collateralised mAsset quantity
        uint256 collateralisedMassetQuantity = _mAssetQuantity.mulTruncate(colRatio);

        // // Calculate redemption quantities
        // (bool redemptionValid, string memory reason, uint256[] memory bAssetQuantities) =
        //     forgeValidator.calculateRedemptionMulti(collateralisedMassetQuantity, props.bAssets);
        // require(redemptionValid, reason);

        // TODO 这里需要把上面的注释解开,来计算数量
        uint256[] memory bAssetQuantities = new uint256[](1);

        // 目前暂时定位0
        uint256 redemptionFee = 0;

        // Apply fees, burn mAsset and return bAsset to recipient
        _settleRedemption(_recipient, _mAssetQuantity, props.bAssets, bAssetQuantities, props.indexes, props.integrators, redemptionFee);

        emit RedeemedMasset(msg.sender, _recipient, _mAssetQuantity);
    }

    /**
     * Internal func to update contract state post-redemption
     * @param _recipient        Recipient of the bAssets
     * @param _mAssetQuantity   Total amount of mAsset to burn from sender
     * @param _bAssets          Array of bAssets to redeem
     * @param _bAssetQuantities Array of bAsset quantities
     * @param _indices          Matching indices for the bAsset array
     * @param _integrators      Matching integrators for the bAsset array
     * @param _feeRate          Fee rate to be applied to this redemption
     */
    function _settleRedemption(
        address _recipient,
        uint256 _mAssetQuantity,
        Basset[] memory _bAssets,
        uint256[] memory _bAssetQuantities,
        uint8[] memory _indices,
        address[] memory _integrators,
        uint256 _feeRate
    ) 
        internal 
    {
        // Burn the full amount of Masset
        _burn(msg.sender, _mAssetQuantity);

        // Reduce the amount of bAssets marked in the vault
        basketManager.decreaseVaultBalances(_indices, _integrators, _bAssetQuantities);

        // Transfer the Bassets to the recipient
        uint256 bAssetCount = _bAssets.length;
        for(uint256 i = 0; i < bAssetCount; i++){
            address bAsset = _bAssets[i].addr;
            uint256 q = _bAssetQuantities[i];
            if(q > 0){
                // Deduct the redemption fee, if any
                q = _deductSwapFee(bAsset, q, _feeRate);
                // Transfer the Bassets to the user
                IPlatformIntegration(_integrators[i]).withdraw(_recipient, bAsset, q, _bAssets[i].isTransferFeeCharged);
            }
        }
    }

    /**
     * Pay the forging fee by burning relative amount of mAsset
     * @param _bAssetQuantity     Exact amount of bAsset being swapped out
     */
    function _deductSwapFee(address _asset, uint256 _bAssetQuantity, uint256 _feeRate)
        private
        returns (uint256 outputMinusFee)
    {
        outputMinusFee = _bAssetQuantity;
        if(_feeRate > 0){
            (uint256 fee, uint256 output) = _calcSwapFee(_bAssetQuantity, _feeRate);
            outputMinusFee = output;
            emit PaidFee(msg.sender, _asset, fee);
        }
    }

    /**
     * Pay the forging fee by burning relative amount of mAsset
     * @param _bAssetQuantity     Exact amount of bAsset being swapped out
     */
    function _calcSwapFee(uint256 _bAssetQuantity, uint256 _feeRate)
        private
        pure
        returns (uint256 feeAmount, uint256 outputMinusFee)
    {
        // e.g. for 500 massets.
        // feeRate == 1% == 1e16. _quantity == 5e20.
        // (5e20 * 1e16) / 1e18 = 5e18
        feeAmount = _bAssetQuantity.mulTruncate(_feeRate);
        outputMinusFee = _bAssetQuantity.sub(feeAmount);
    }

}