pragma solidity >0.4.99 <0.6.0;

// https://theethereum.wiki/w/index.php/ERC20_Token_Standard
contract ERC20Interface {
    function approve(address spender, uint tokens) public returns (bool success);
    function balanceOf(address tokenOwner) public view returns (uint balance);
}

contract DMEXBaseInterface {
    function depositTokenForUser(address token, uint128 amount, address user) public;
}

contract DepositToDMEX { 
    constructor() public {
        sendTokensToDMEX(address(<%= token %>));
    }
    
    function sendTokensToDMEX(address token) public
    {
        uint256 availableBalance = ERC20Interface(token).balanceOf(address(this));
        uint128 shortAvailableBalance = uint128(availableBalance);
        ERC20Interface(token).approve(address(<%= dmexContract %>), availableBalance);
        DMEXBaseInterface(address(<%= dmexContract %>)).depositTokenForUser(token, shortAvailableBalance, address(<%= owner %>));
    }
}

