// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract GMPBundle is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable, PausableUpgradeable { 
    
    enum Rarity {Normal, Rare, Mythic}
    address[] public whitelistedAddresses;
    address public beneficiary;
    bool public onlyWhitelisted;
    uint256 public totalBalance;
    uint constant E6 = 10**6;
    IERC20 public token;

    struct Attribute {
      string name;
      string image_url;
      bool isGenesis;
      bool isOpened;
      uint landSpotSize;
      uint moleQuantity;
      Rarity rarity;
      TypeOfBox typeOfBox;
    }
    mapping(uint256 => Attribute) public attributes;
    
    mapping (Rarity => uint256) public NFTLimitCount;
    mapping (Rarity => uint256) public NFTPrice;
    mapping (Rarity => uint256) public NFTLandSlot;
    mapping (Rarity => uint256) public NFTMoleSlot;
    mapping (address => uint256[]) public ownerOfNFT;
    event Withdraw(address operator, uint amount );
    event PreOrder(address sender, Rarity rarity, uint quantity, uint amount );
    enum TypeOfBox {GoldMiningPit, GoldKingdomPit, ForgingPit}
    AggregatorV3Interface internal priceFeedFTMUSD;
    AggregatorV3Interface internal priceFeedUSDCUSD;

    function initialize(IERC20 _token, address _beneficiary, string memory _name, string memory _symbol,bool _onlyWhitelisted ) initializer public {
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();
        __Ownable_init();
        onlyWhitelisted = _onlyWhitelisted;
        token = _token;
        beneficiary = _beneficiary;
        NFTLimitCount[Rarity.Normal] = 2999;
        NFTLimitCount[Rarity.Rare] = 999;
        NFTLimitCount[Rarity.Mythic] = 99;
        
        NFTPrice[Rarity.Normal] = 1 * E6;
        NFTPrice[Rarity.Rare] = 2 * E6;
        NFTPrice[Rarity.Mythic] = 4 * E6;
        
        NFTLandSlot[Rarity.Normal] = 1;
        NFTLandSlot[Rarity.Rare] = 4;
        NFTLandSlot[Rarity.Mythic] = 9;
        
        NFTMoleSlot[Rarity.Normal] = 0;
        NFTMoleSlot[Rarity.Rare] = 3;
        NFTMoleSlot[Rarity.Mythic] = 9;
        priceFeedFTMUSD = AggregatorV3Interface(0xe04676B9A9A2973BCb0D1478b5E1E9098BBB7f3D);
        priceFeedUSDCUSD = AggregatorV3Interface(0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128);
    }

    function safeMint(address to, uint256 tokenId, string memory _name, string memory _image_url, bool _isGenesis, uint _landSpotSize, uint _moleQuantity, Rarity _rarity, TypeOfBox _typeOfBox) public onlyOwner {
        _safeMint(to, tokenId);
        attributes[tokenId] = Attribute(_name, _image_url, _isGenesis, false, _landSpotSize, _moleQuantity, _rarity, _typeOfBox);

    }
    function getPriceFTMUSD()  public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeedFTMUSD.latestRoundData();
        return price;
    }
    function getPriceUSDCUSD()  public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeedUSDCUSD.latestRoundData();
        return price;
    }
    function getPriceUSDCFTM() public view returns (int) {
        
        int usdcftm = (getPriceFTMUSD() / getPriceUSDCUSD()) ;
        return usdcftm;
    }
    function setDataPriceFeed(address ftm_usd, address usdc_usd) external onlyOwner{
        priceFeedFTMUSD = AggregatorV3Interface(ftm_usd);
        priceFeedUSDCUSD = AggregatorV3Interface(usdc_usd);
    }
    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function setOnlyWhitelisted(bool _state) external onlyOwner {
      onlyWhitelisted = _state;
    }

    function setERC20Token(IERC20 _token) external onlyOwner{
        token = _token;
    }

    function setNFTLimit(Rarity rarity, uint256 limit) external onlyOwner{
        NFTLimitCount[rarity] = limit;
    }

    function setNFTPrice(Rarity rarity, uint256 cost) external onlyOwner{
        NFTPrice[rarity] = cost * E6;
    }

    // Update beneficiary address by the previous beneficiary.
    function setBeneficiary(address _newBeneficiary) external onlyOwner {
        beneficiary = _newBeneficiary;
    }

    function getAvailableSlot(Rarity rarity) public view returns (uint256 count) {
        count = NFTLimitCount[rarity];
    }
    function preorder(Rarity rarity, uint256 quantity) public whenNotPaused notContract{
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "Whitelist: not in list");
        }
        
        require(quantity > 0, "Quality not zero");
        uint256 estAmount = NFTPrice[rarity] * quantity;
        require(token.balanceOf(msg.sender) >= estAmount, "Not enough to purchase");
        require(NFTLimitCount[rarity] >= quantity, "NFT is limited");
        token.transferFrom(msg.sender, address(this), estAmount);
        for (uint256 index = 0; index < quantity; index++) {
            uint mintIndex = totalSupply();
            string memory package_name = "";
            string memory image_url = "";
            if(rarity == Rarity.Normal){
              package_name = "Single Package";
              image_url = "https://zuckzuck.land/static/video/gold-mining/SINGLE.gif";
            }
            if(rarity == Rarity.Rare) {
              package_name = "Rare Package";
              image_url = "https://zuckzuck.land/static/video/gold-mining/RARE.gif";
            }
            if(rarity == Rarity.Mythic) {
              package_name = "Mythic Package";
              image_url = "https://zuckzuck.land/static/video/gold-mining/MYTHIC.gif";
            }
            ownerOfNFT[msg.sender].push(mintIndex);
            _safeMint(msg.sender, mintIndex);
            attributes[mintIndex] = Attribute(package_name, image_url, true, false, NFTLandSlot[rarity], NFTMoleSlot[rarity], rarity, TypeOfBox.GoldMiningPit);
        }
        totalBalance += estAmount;
        NFTLimitCount[rarity] -= quantity;
        emit PreOrder(msg.sender, rarity, quantity, estAmount);
        
    }
    function preorder_with_nft(Rarity rarity, uint256 quantity) public payable whenNotPaused notContract{
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "Whitelist: not in list");
        }
        
        require(quantity > 0, "Quality not zero");
        uint256 estAmount = NFTPrice[rarity] * quantity;
        require(token.balanceOf(msg.sender) >= estAmount, "Not enough to purchase");
        require(NFTLimitCount[rarity] >= quantity, "NFT is limited");
        int256 usdcftm = 1.3 * 10 ** 18 * (getPriceUSDCUSD() / getPriceFTMUSD());
        
        token.transferFrom(msg.sender, address(this), estAmount);
        for (uint256 index = 0; index < quantity; index++) {
            uint mintIndex = totalSupply();
            string memory package_name = "";
            string memory image_url = "";
            if(rarity == Rarity.Normal){
              package_name = "Single Package";
              image_url = "https://zuckzuck.land/static/video/gold-mining/SINGLE.gif";
            }
            if(rarity == Rarity.Rare) {
              package_name = "Rare Package";
              image_url = "https://zuckzuck.land/static/video/gold-mining/RARE.gif";
            }
            if(rarity == Rarity.Mythic) {
              package_name = "Mythic Package";
              image_url = "https://zuckzuck.land/static/video/gold-mining/MYTHIC.gif";
            }
            ownerOfNFT[msg.sender].push(mintIndex);
            _safeMint(msg.sender, mintIndex);
            attributes[mintIndex] = Attribute(package_name, image_url, true, false, NFTLandSlot[rarity], NFTMoleSlot[rarity], rarity, TypeOfBox.GoldMiningPit);
        }
        totalBalance += estAmount;
        NFTLimitCount[rarity] -= quantity;
        emit PreOrder(msg.sender, rarity, quantity, estAmount);
        
    }
    function getMyNFTs() public view returns(uint256[] memory tokenIds) {
       tokenIds = ownerOfNFT[msg.sender];
       return tokenIds;
    }
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    function withdraw() external onlyOwner {
        uint256 total_amount = token.balanceOf(address(this));
        token.transfer(beneficiary, total_amount);
        emit Withdraw(beneficiary, total_amount);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    function openBundle(uint256 tokenId) external {
        require(tokenId >= 0, "No item");
        require(ownerOf(tokenId) == msg.sender, "Not owned");
        Attribute memory attr = attributes[tokenId];
        if(attr.rarity == Rarity.Normal){
            // land.openBundles(msg.sender, landType);
        }else{
            for (uint256 i = 0; i < attr.landSpotSize; i++) {
                // land.openBundles(msg.sender, landType);    
            }
            for(uint256 i = 0; i < attr.moleQuantity; i++) {
                // mole.openBundles(msg.sender);
            }
        }
        burn(msg.sender, tokenId);
    }
    function burn(address owner, uint256 tokenId) private {
        require(ownerOf(tokenId) == owner, "You are not owned it");
        uint256[] memory tokenIds = ownerOfNFT[owner];
        if(tokenIds.length > 1) {
            delete attributes[tokenId];
            delete ownerOfNFT[owner];
            for (uint256 index = 0; index < tokenIds.length; index++) {
                if(tokenId != tokenIds[index]) {
                    ownerOfNFT[owner].push(tokenIds[index]);
                }
            }
        }
        _burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId) override(ERC721Upgradeable) public view returns (string memory) {
        string memory rarity = "";
        Attribute storage attr = attributes[tokenId];
        string memory genesis = attr.isGenesis ? "Yes" : "No";
        if(attr.rarity == Rarity.Normal) {
            rarity = "Normal";
        }
        else if(attributes[tokenId].rarity == Rarity.Rare) {
            rarity =  "Rare";
        }
        else if(attributes[tokenId].rarity == Rarity.Mythic) {
            rarity =  "Mythic";
        }
       
        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "',attr.name, '",',
                    '"image_url": "',attr.image_url, '",',
                    '"attributes": [{"trait_type": "Genesis", "value": "', genesis, '"},',
                    '{"trait_type": "Land_plot_size", "value": ', uint2str(attr.landSpotSize), '},',
                    '{"trait_type": "Mole_quantity", "value": ', uint2str(attr.moleQuantity), '},',
                    '{"trait_type": "Rarity", "value": "', rarity , '"}',
                    ']}'
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }    
    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}