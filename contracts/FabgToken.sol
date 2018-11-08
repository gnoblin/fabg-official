pragma solidity ^0.4.24;

import "./OZ/ERC-721/ERC721Token.sol";
import "./OZ/Ownable.sol";
import "./PreSale.sol";

contract FabgToken is ERC721Token, Ownable {
    struct data {
        tokenType typeOfToken;
        bytes32 name;
        bytes32 url;
        bool isSnatchable;
    }
    
    mapping(uint256 => data) internal tokens;
    mapping(uint256 => uint256) internal pricesForIncreasingAuction;
    
    address presale;

    enum tokenType{MASK, LAND}
    
    event TokenCreated(
        address Receiver, 
        tokenType Type, 
        bytes32 Name, 
        bytes32 URL, 
        uint256 TokenId, 
        bool IsSnatchable
    );
    event TokenChanged(
        address Receiver, 
        tokenType Type, 
        bytes32 Name, 
        bytes32 URL, 
        uint256 TokenId, 
        bool IsSnatchable
    );
    event Paused();
    event Unpaused();
    
    modifier onlySaleAgent {
        require(msg.sender == saleAgent);
        _;
    }
    
    /**
     * @dev constructor which calling parent's constructor with params
     */
    constructor() ERC721Token("FABGToken", "FABG") public {
    }

    /**
     * @dev fallback function which can't receive ether
     */
    function() public payable {
        revert();
    }

    /**
     * @dev onlyOwner func for stopping all operations with contract
     */ 
    function setPauseForAll() public onlyOwner {
        require(isPaused == false, "transactions on pause");
        isPaused = true;
        PreSale(saleAgent).setPauseForAll();

        emit Paused();
    }

    /**
     * @dev onlyOwner func for unpausing all operations with contract
     */ 
    function setUnpauseForAll() public onlyOwner {
        require(isPaused == true, "transactions isn't on pause");
        isPaused = false;
        PreSale(saleAgent).setUnpauseForAll();

        emit Unpaused();
    }

    /**
     * @dev setting the address of contract which can get tokens from users wallets
     * @param _saleAgent address of contract of auction
     */
    function setSaleAgent(address _saleAgent) public onlyOwner {
        saleAgent = _saleAgent;
    }
    
    /**
     * @dev process of creation of card 
     * @param _receiver address of token receiver
     * @param _type type of token from enum
     * @param _name bytes32 name of token
     * @param _url bytes32 url of token
     * @param _isSnatchable type of market for trading
     */
    function adminsTokenCreation(address _receiver, uint256 _price, tokenType _type, bytes32 _name, bytes32 _url, bool _isSnatchable) public onlyOwner {
        tokenCreation(_receiver, _price, _type, _name, _url, _isSnatchable);
    }

    /**
     * @dev process of creation of card 
     * @param _receiver address of token receiver
     * @param _type type of token from enum
     * @param _name bytes32 name of token
     * @param _url bytes32 url of token
     * @param _isSnatchable type of market for trading
     */
    function tokenCreation(address _receiver, uint256 _price, tokenType _type, bytes32 _name, bytes32 _url, bool _isSnatchable) internal {
        require(isPaused == false, "transactions on pause");
        uint256 tokenId = totalSupply();
        
        data memory info = data(_type, _name, _url, _isSnatchable);
        tokens[tokenId] = info;
        
        if(_isSnatchable == true) {
            pricesForIncreasingAuction[tokenId] = _price;
        }
        
        _mint(_receiver, tokenId);

        emit TokenCreated(_receiver, _type, _name, _url, tokenId, _isSnatchable);
    }

    /**
     * @dev convert string to bytes32 and revert it if length was more than 32
     * @param source current string for convertion
     * @return bytes32 result of string convertation
     */
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        require(bytes(source).length <= 32, "too high length of source");
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    /**
     * @dev convert bytes32 to string and revert it if length was more than 32
     * @param x current bytes for convertion
     * @return string result of bytes32 convertation
     */
    function bytes32ToString(bytes32 x) public pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    /**
     * @dev token info by Id
     * @param _tokenId Id of token
     * @return typeOfToken index of enum
     * @return name bytes32 name of token
     * @return URL bytes32 URL of token
     * @return isSnatchable type of auction
     */
    function getTokenById(uint256 _tokenId) public view returns (
        tokenType typeOfToken, 
        bytes32 name, 
        bytes32 URL, 
        bool isSnatchable
    ) {
        typeOfToken = tokens[_tokenId].typeOfToken;
        name = tokens[_tokenId].name;
        URL = tokens[_tokenId].url;
        isSnatchable = tokens[_tokenId].isSnatchable;
    }
        
    /**
     * @dev token price for increasing auction
     * @param _tokenId Id of token for selling
     * @return uint256 price in Wei
     */
    function getTokenPriceForIncreasing(uint256 _tokenId) public view returns (uint256) {
        require(tokens[_tokenId].isSnatchable == true);

        return pricesForIncreasingAuction[_tokenId];
    }

    /**
     * @dev list of tokens of user
     * @param _owner address of user
     * @return uint256[] array of token's ID which are belomg to user
     */
    function allTokensOfUsers(address _owner) public view returns(uint256[]) {
        return ownedTokens[_owner];
    }
    
    /**
     * @dev store information about presale contract
     * @param _presale address of presale contract
     */ 
    function setPresaleAddress(address _presale) public onlyOwner {
        presale = _presale;
    }

    /**
     * @dev process of changing information of card 
     * @param _receiver address of token receiver
     * @param _type type of token from enum
     * @param _name bytes32 name of token
     * @param _url bytes32 url of token
     * @param _isSnatchable type of market for trading
     */    
    function rewriteTokenFromPresale(
        uint256 _tokenId,
        address _receiver, 
        uint256 _price, 
        tokenType _type, 
        bytes32 _name, 
        bytes32 _url, 
        bool _isSnatchable
    ) public onlyOwner {
        require(ownerOf(_tokenId) == presale);
        data memory info = data(_type, _name, _url, _isSnatchable);
        tokens[_tokenId] = info;
        
        if(_isSnatchable == true) {
            pricesForIncreasingAuction[_tokenId] = _price;
        }
        
        emit TokenChanged(_receiver, _type, _name, _url, _tokenId, _isSnatchable);
    }
}
