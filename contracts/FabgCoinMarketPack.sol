pragma solidity ^0.4.24;

import "./FabgCoin.sol";
import "./OZ/Ownable.sol";
import "./OZ/SafeMath.sol";

contract FabgCoinMarketPack is FabgCoin {
    using SafeMath for uint256;

    bool isPausedForSale;

    /**
     * maping for store amount of tokens to amount of wei per that pack
     */
    mapping(uint256 => uint256) packsToWei;
    uint256[] packs;
    uint256 public totalEarningsForPackSale;
    address adminsWallet;

    event MarketPaused();
    event MarketUnpaused();
    event PackCreated(uint256 TokensAmount, uint256 WeiAmount);
    event PackDeleted(uint256 TokensAmount);
    event PackBought(address Buyer, uint256 TokensAmount, uint256 WeiAmount);
    event Withdrawal(address receiver, uint256 weiAmount);

    constructor() public {  
        name = "FabgCoin";
        symbol = "FABG";
        decimals = 18;
        rate = 100;
        minimalPayment = 1 ether / 100;
        isBuyBlocked = true;
    }

    /**
     * @dev set address for wallet for withdrawal
     * @param _newMultisig new address for withdrawals
     */
    function setAddressForPayment(address _newMultisig) public onlyOwner {
        adminsWallet = _newMultisig;
    }

    /**
     * @dev fallback function which can receive ether with no actions
     */
    function() public payable {
       emit Payment(msg.sender, msg.value);
    }

    /**
     * @dev pause possibility of buying pack of tokens
     */
    function pausePackSelling() public onlyOwner {
        require(isPausedForSale == false);
        isPausedForSale = true;
        emit MarketPaused();
    }

    /**
     * @dev return possibility of buying pack of tokens
     */
    function unpausePackSelling() public onlyOwner {
        require(isPausedForSale == true);
        isPausedForSale = false;
        emit MarketUnpaused();
    }    

    /**
     * @dev add pack to list of possible to buy
     * @param _amountOfTokens amount of tokens in pack
     * @param _amountOfWei amount of wei for buying 1 pack
     */
    function addPack(uint256 _amountOfTokens, uint256 _amountOfWei) public onlyOwner {
        require(packsToWei[_amountOfTokens] == 0);
        require(_amountOfTokens != 0);
        require(_amountOfWei != 0);
        
        packs.push(_amountOfTokens);
        packsToWei[_amountOfTokens] = _amountOfWei;

        emit PackCreated(_amountOfTokens, _amountOfWei);
    }

    /**
     * @dev buying existing pack of tokens
     * @param _amountOfTokens amount of tokens in pack for buying
     */
    function buyPack(uint256 _amountOfTokens) public payable {
        require(packsToWei[_amountOfTokens] > 0);
        require(msg.value >= packsToWei[_amountOfTokens]);
        require(isPausedForSale == false);

        _mint(msg.sender, _amountOfTokens);
        (msg.sender).transfer(msg.value.sub(packsToWei[_amountOfTokens]));

        totalEarnings = totalEarnings.add(packsToWei[_amountOfTokens]);
        totalEarningsForPackSale = totalEarningsForPackSale.add(packsToWei[_amountOfTokens]);

        emit PackBought(msg.sender, _amountOfTokens, packsToWei[_amountOfTokens]);
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

    /**
     * @dev delete pack from selling
     * @param _amountOfTokens which pack delete
     */
    function deletePack(uint256 _amountOfTokens) public onlyOwner {
        require(packsToWei[_amountOfTokens] != 0);
        require(_amountOfTokens != 0);

        packsToWei[_amountOfTokens] = 0;

        uint256 index;

        for(uint256 i = 0; i < packs.length; i++) {
            if(packs[i] == _amountOfTokens) {
                index = i;
                break;
            }
        }

        for(i = index; i < packs.length - 1; i++) {
            packs[i] = packs[i + 1];
        }
        packs.length--;

        emit PackDeleted(_amountOfTokens);
    }

    /**
     * @dev get list of all available packs
     * @return uint256 array of packs
     */
    function getAllPacks() public view returns (uint256[]) {
        return packs;
    }

    /**
     * @dev get price of current pack in wei
     * @param _amountOfTokens current pack for price
     * @return uint256 amount of wei for buying
     */
    function getPackPrice(uint256 _amountOfTokens) public view returns (uint256) {
        return packsToWei[_amountOfTokens];
    }
}