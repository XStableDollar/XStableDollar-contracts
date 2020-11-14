// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// External
import { ITokenManager } from "./ITokenManager.sol";
import { IDataManager } from "./IDataManager.sol";

// Internal
import { TokenStructs } from "./TokenStructs.sol";
import { CustomToken } from "./CustomToken.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { StableMath } from "./shared/StableMath.sol";
import { MassetHelpers } from "./shared/MassetHelpers.sol";

contract TokenManager is ITokenManager, ERC20 {

    using StableMath for uint256;

    address[] public customAssets;
    uint256 public totalAssets;

    // 创建事件
    event Created(string name, string symbol, uint256 supply, address token_addr);
    // 合成事件
    event Minted(address indexed minter, address recipient, uint256 mAssetQuantity, address bAsset, uint256 bAssetQuantity);
    event MintedMulti(address indexed minter, address recipient, uint256 mAssetQuantity, address[] bAssets, uint256[] bAssetQuantities);
    // 赎回事件
    event Redeemed(address indexed redeemer, address recipient, uint256 mAssetQuantity, address[] bAssets, uint256[] bAssetQuantities);
    event RedeemedMasset(address indexed redeemer, address recipient, uint256 mAssetQuantity);
    // 支付费用事件
    event PaidFee(address indexed payer, address asset, uint256 feeQuantity);

    // CustomAsset[] public customAssets;

    // 合成币地址对应合成币的信息
    mapping(address => CustomAsset) public ercAddrToCustomToken;

    // 合成币地址对应待合成币数组
    mapping(address => PreToken[]) public preTokens;

    // 合成币对应的比例
    mapping(address => uint256[]) public token2ratio;
    // 合成币对应的币种
    mapping(address => address[]) public token2symbol;

    // 构造函数，构造时需要指定代币名称和代币符号
    constructor(string memory name, string memory symbol) public ERC20(name, symbol) {}

    // 初始化函数
    function initialize()
        external
    {

    }

    // 创建
    function create(
        string memory _name,
        string memory _symbol
    )
        override
        external
        returns (address)
    {
        CustomToken token = new CustomToken(_name, _symbol);
        uint256[] memory ratios = new uint256[](1);
        uint256 status = 1;
        CustomAsset memory asset = CustomAsset(
            _name,
            _symbol,
            address(token),
            status,
            ratios
        );

        ercAddrToCustomToken[address(token)] = asset;
        customAssets.push(address(token));
        totalAssets++;

        emit Created(_name, _symbol, 0, address(token));
        return address(token);
    }

    // 合成
    function mintMulti(
        address erc20Addr,
        address[] calldata _preToken,
        uint256[] calldata _bassetAmount,
        bool[] calldata _isTransferFee,
        address receipt
    )
        override
        external
        returns (uint256 massetMinted)
    {
        require(_preToken.length > 0, "_preToken lenght must not be 0");
        require(_preToken.length == _bassetAmount.length, "lenght must be equal");

        // TODO 检测合成数量是否正确

        CustomAsset memory customAsset = ercAddrToCustomToken[erc20Addr];
        require(customAsset.status != 0);

        uint256 len = _preToken.length;
        // 将资产划转到合约
        for(uint256 i = 0; i < len; i++) {
            address tokenAddr = _preToken[i];
            uint256 amount = _bassetAmount[i];
            bool isTransferFee = _isTransferFee[i];
            uint256 quantityTransferred = MassetHelpers.transferTokens(msg.sender, address(this), tokenAddr, isTransferFee, amount);
        }

        token2ratio[erc20Addr] = _bassetAmount;
        token2symbol[erc20Addr] = _preToken;

        CustomToken(erc20Addr).mint(msg.sender, 1);
        return 1;
    }

    // 赎回
    function redeem(
        address _targetAddr,
        uint256 _backAmount
    )
        override
        external
        returns (uint256 massetRedeemed)
    {
        // 一个合成币换回等比例的资产
        // 取回待合成的币种
        PreToken[] memory pre_tokens = preTokens[_targetAddr];

        // 获取当时的比例信息mapping
        address[] memory mapSymbol = token2symbol[_targetAddr];
        uint256[] memory mapRadio = token2ratio[_targetAddr];

        // 找出币种的对应种类
        for(uint256 i = 0; i < mapSymbol.length; i++) {
            address tokenAddr = mapSymbol[i];
            uint256 amount = mapRadio[i] * _backAmount;
            bool isTransferFee = false;
            uint256 quantityTransferred = MassetHelpers.transferTokens2(msg.sender, address(this), tokenAddr, isTransferFee, amount);
        }

        CustomToken(_targetAddr).burn(msg.sender, _backAmount);
        return _backAmount;
    }

}