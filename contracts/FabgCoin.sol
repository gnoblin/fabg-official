pragma solidity ^0.4.24;

import "./OZ/ERC-20/ERC20.sol";
import "./OZ/Ownable.sol";

contract FabgCoin is ERC20, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;

    //tokens per one eth
    uint256 public rate;
    uint256 public minimalPayment;

    bool public isBuyBlocked;
    address saleAgent;
    uint256 public totalEarnings;

    event TokensCreatedWithoutPayment(address Receiver, uint256 Amount);
    event BoughtTokens(address Receiver, uint256 Amount, uint256 sentWei);
    event BuyPaused();
    event BuyUnpaused();
    event UsagePaused();
    event UsageUnpaused();
    event Payment(address payer, uint256 weiAmount);

    modifier onlySaleAgent() {
        require(msg.sender == saleAgent);
        _;
    }

    function changeRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    function pauseCustomBuying() public onlyOwner {
        require(isBuyBlocked == false);
        isBuyBlocked = true;
        emit BuyPaused();
    }

    function resumeCustomBuy() public onlyOwner {
        require(isBuyBlocked == true);
        isBuyBlocked = false;
        emit BuyUnpaused();
    }

    function pauseUsage() public onlyOwner {
        require(isPaused == false);
        isPaused = true;
        emit UsagePaused();
    }

    function resumeUsage() public onlyOwner {
        require(isPaused == true);
        isPaused = false;
        emit UsageUnpaused();
    }

    function setSaleAgent(address _saleAgent) public onlyOwner {
        require(saleAgent == address(0));
        saleAgent = _saleAgent;
    }

    function createTokenWithoutPayment(address _receiver, uint256 _amount) public onlyOwner {
        _mint(_receiver, _amount);

        emit TokensCreatedWithoutPayment(_receiver, _amount);
    }

    function createTokenViaSaleAgent(address _receiver, uint256 _amount) public onlySaleAgent {
        _mint(_receiver, _amount);
    }

    function buyTokens() public payable {
        require(msg.value >= minimalPayment);
        require(isBuyBlocked == false);

        uint256 amount = msg.value.mul(rate).div(1 ether); 
        _mint(msg.sender, amount);
        (msg.sender).transfer(msg.value.sub(amount.mul(1 ether).div(rate)));

        totalEarnings = totalEarnings.add(amount.mul(1 ether).div(rate));

        emit BoughtTokens(msg.sender, amount, msg.value);
    }
}