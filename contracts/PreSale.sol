pragma solidity ^0.4.24;

import "./FabgToken.sol";
import "./OZ/Ownable.sol";
import "./OZ/SafeMath.sol";

contract PreSale is Ownable {
    using SafeMath for uint;
    
    FabgToken token;
    /**
     * @notice address of wallet for comission payment. can be hardcoded
     */
    address adminsWallet;
    bool public isPaused;
    uint256 totalMoney;
    
    event TokenBought(address Buyer, uint256 tokenID, uint256 price);
    event Payment(address payer, uint256 weiAmount);
    event Withdrawal(address receiver, uint256 weiAmount);
    
    modifier onlyToken() {
        require(msg.sender == address(token), "called not from token");
        _;
    }

    /**
     * @dev setted address of token contract and wallet where will be eth in withdrawal
     * @param _tokenAddress address of token
     * @param _walletForEth address for receiving payments
     */
    constructor(FabgToken _tokenAddress, address _walletForEth) public {
        token = _tokenAddress;
        adminsWallet = _walletForEth;
    }
    
    /**
     * @dev fallback function which can receive ether with no actions
     */
    function() public payable {
       emit Payment(msg.sender, msg.value);
    }
    
    /**
     * @dev only token func for stopping all operations with contract
     */ 
    function setPauseForAll() public onlyToken {
        require(isPaused == false, "transactions on pause");
        isPaused = true;
    }

    /**
     * @dev only token func for unpausing all operations with contract
     */ 
    function setUnpauseForAll() public onlyToken {
        require(isPaused == true, "transactions on pause");
        isPaused = false;
    }   
    
    /**
     * @dev buy token, owner of which is market. contract will send back change
     * @param _tokenId id of token for buying
     */
    function buyToken(uint256 _tokenId) public payable {
        require(isPaused == false, "transactions on pause");
        require(token.exists(_tokenId), "token doesn't exist");
        require(token.ownerOf(_tokenId) == address(this), "contract isn't owner of token");
        require(msg.value >= token.getTokenPriceForIncreasing(_tokenId), "was sent not enough ether");
        
        token.transferFrom(address(this), msg.sender, _tokenId);
        (msg.sender).transfer(msg.value.sub(token.getTokenPriceForIncreasing(_tokenId)));
        
        totalMoney = totalMoney.add(token.getTokenPriceForIncreasing(_tokenId));

        emit TokenBought(msg.sender, _tokenId, token.getTokenPriceForIncreasing(_tokenId));
    }

    /**
     * @dev set address for wallet for withdrawal
     * @param _newMultisig new address for withdrawal
     */
    function setAddressForPayment(address _newMultisig) public onlyOwner {
        adminsWallet = _newMultisig;
    }    
    
    /**
     * @dev withdraw all ether from this contract to sender's wallet
     */
    function withdraw() public onlyOwner {
        require(adminsWallet != address(0), "admins wallet couldn't be 0x0");

        uint256 amount = address(this).balance;  
        (adminsWallet).transfer(amount);
        emit Withdrawal(adminsWallet, amount);
    }
}