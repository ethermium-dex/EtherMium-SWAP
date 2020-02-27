pragma solidity ^0.4.19;

/* Interface for ERC20 Tokens */
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    // optional
    function name() external view returns (string);
    function symbol() external view returns (string);
    function decimals() external view returns (string);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

/* Interface for the Uniswap Exchange contract */
contract UniswapExchangeInterface {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
    // ERC20 comaptibility for liquidity tokens
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    // Never use
    function setup(address token_addr) external;
}

contract UniswapFactoryInterface {
    // Public Variables
    address public exchangeTemplate;
    uint256 public tokenCount;
    // Create Exchange
    function createExchange(address token) external returns (address exchange);
    // Get Exchange and Token Info
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
    // Never use
    function initializeFactory(address template) external;
}

/* Interface for pTokens contract */
contract pTokensInterface {
    function redeem(uint256 _value, string memory _btcAddress) public returns (bool _success);
}

// The EtherMium Atomic Swap DEX Contract
contract EtherMium_Atomic_Swap_DEX {
    function assert(bool assertion) {
        if (!assertion) throw;
    }

    // Safe Multiply Function - prevents integer overflow 
    function safeMul(uint a, uint b) returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    // Safe Subtraction Function - prevents integer overflow 
    function safeSub(uint a, uint b) returns (uint) {
        assert(b <= a);
        return a - b;
    }

    // Safe Addition Function - prevents integer overflow 
    function safeAdd(uint a, uint b) returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    address public owner; // holds the address of the contract owner
    mapping (address => bool) public admins; // mapping of admin addresses

    // Event fired when the owner of the contract is changed
    event SetOwner(address indexed previousOwner, address indexed newOwner);

    // Allows only the owner of the contract to execute the function
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    // Allows only the swapFeeAccount to execute the function
    modifier onlyFeeAccount {
        assert(msg.sender == swapFeeAccount);
        _;
    }

    // Changes the owner of the contract
    function setOwner(address newOwner) onlyOwner {
        SetOwner(owner, newOwner);
        owner = newOwner;
    }

    // Owner getter function
    function getOwner() returns (address out) {
        return owner;
    }

    address public gasFeeAccount; // gas fees go to this account
    address public swapFeeAccount; // swap fees go to this account


    address public uniswapFactory; // the Uniswap Factory address
    uint256 public swapFee; // pct swap fee * 1e18 (0.003 * 1e18 = 0.3%)
    uint256 public gasFee; // gas fee in ETH

    bool public swapFeeAccountChangeDisabled = false; // when set to True, the swap fee account cannot be changed

    bool public destroyed = false; // contract is destoryed
    uint256 public destroyDelay = 1000000; // number of blocks after destroy contract still active (aprox 6 monthds)
    uint256 public destroyBlock;

    

    // Deposit event fired when a deposit takes place
    event Deposit(address indexed token, address indexed user, uint256 amount, uint256 balance);

    // Withdraw event fired when a withdrawal id executed
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance, uint256 withdrawFee);
    
    // pTokenRedeemEvent event fired when a pToken withdrawal is executed
    event pTokenRedeemEvent(address indexed token, address indexed user, uint256 amount, string destinationAddress);

    // Fee account changed event
    event FeeAccountChanged(address indexed newFeeAccount);

    // Fee change event
    event FeeChange(uint256 indexed newSwapFee);

    // Constructor function, initializes the contract and sets the core variables
    function EtherMium_Atomic_Swap_DEX(address gasFeeAccount_, address swapFeeAccount_, address uniswapFactory_, uint256 swapFee_, uint256 gasFee_) {
        owner = msg.sender;
        gasFeeAccount = gasFeeAccount_;
        swapFeeAccount = swapFeeAccount_;
        uniswapFactory = uniswapFactory_;
        swapFee = swapFee_;
        gasFee = gasFee_;
    }

    // Change fee account
    function changeFeeAccount (address swapFeeAccount_) onlyOwner {
        if (swapFeeAccountChangeDisabled) revert();
        swapFeeAccount = swapFeeAccount_;
        emit FeeAccountChanged(swapFeeAccount_);
    }

    // Changes the fees
    function setSwapFee(uint256 swapFee_) onlyOwner {
        require(swapFee_      < 10 finney); // The fee cannot be set higher than 1%
        swapFee = swapFee_;

        emit FeeChange(swapFee);
    }

    // Disable future fee account change
    function disableFeeAccountChange() onlyOwner {
        swapFeeAccountChangeDisabled = true;
    }

    // Sets the inactivity period before a user can withdraw funds manually
    function destroyContract() onlyOwner returns (bool success) {
        if (destroyed) throw;
        destroyBlock = block.number;

        return true;
    }

    // Sets the uniswap exchange contract address for a specific token
    function setUniswapExchange(address token, address _uniswapExchange) onlyOwner  {
        uniswapExchange[token]  = _uniswapExchange;
    }

    // Returns balance available on the swap contract (balance on the swap contract is all fees)
    function availableBalanceOf(address token, address user) view returns (uint256)
    {
        if (token == address(0))
        {
            return address(this).balance;
        }
        else
        {
            return ERC20Interface(token).balanceOf(this);
        }
    }

    // Function for fee withdrawal
    function withdraw(address token, uint256 amount) onlyFeeAccount returns (bool success) {
        
        if (availableBalanceOf(token, msg.sender) < amount) revert();

        subBalance(token, msg.sender, amount); // subtracts the withdrawed amount from user balance

        if (token == address(0)) { // checks if withdrawal is a token or ETH, ETH has address 0x00000... 
            if (!msg.sender.send(amount)) revert(); // send ETH
        } else {
            if (!Token(token).transfer(msg.sender, amount)) revert(); // Send token
        }
        emit Withdraw(token, msg.sender, amount, balanceOf(token, msg.sender), 0); // fires the Withdraw event
    }
    

    // Swap ETH -> pToken
    function swapETHtoPToken (address token, string destinationAddress) public payable returns (uint256 amount)
    {
        if (msg.value < gasFee) revert();

        address uniswapExchange = UniswapFactoryInterface(uniswapFactory).getExchange(token);
        uint256 ethAmount = msg.value;

        // deduct swap fee
        uint256 fee = safeMul(safeSub(ethAmount, gasFee), swapFee) / 1e18;
        uint256 netEthAmount = safeSub(safeSub(ethAmount, gasFee), fee);

        gasFeeAccount.send(gasFee);

        // swap eth for pToken
        uint256 ptokens_bought = UniswapExchangeInterface(uniswapExchange).ethToTokenSwapInput.value(netEthAmount)(1, 2**256 - 1);
    
        // redeem pTokens
        if (!pTokensInterface(token).redeem(ptokens_bought, destinationAddress))
        {
            revert();
        }

        return ptokens_bought;
    }


    // Swap ERC20 Token -> ETH
    function swapERC20TokenToETH (address token, uint256 tokenAmount, address destinationAddress) public returns (uint256 amount)
    {
        address uniswapExchange = UniswapFactoryInterface(uniswapFactory).getExchange(token);
        
        // retrieve token (must be approved first)
        if (!ERC20Interface(token).transferFrom(msg.sender, this, tokenAmount)) revert(); 

        // convert token to ETH
        ERC20Interface(token).approve(uniswapExchange, tokenAmount);
        uint256 ethAmount = UniswapExchangeInterface(uniswapExchange).tokenToEthSwapInput(tokenAmount, 1, 2**256 - 1);

        if (ethAmount < gasFee) revert();

        if (!gasFeeAccount.send(gasFee)) revert();

        // deduct swap fee
        uint256 fee = safeMul(safeSub(ethAmount, gasFee), swapFee) / 1e18;
        uint256 netEthAmount = safeSub(safeSub(ethAmount, gasFee), fee);

        if (!destinationAddress.send(netEthAmount)) revert();

        return netEthAmount;
    }


    // Swap ETH -> ERC20 Token
    function swapETHtoERC20Token (address token, address destinationAddress) public payable returns (uint256 amount)
    {
        if (msg.value < gasFee) revert();

        address uniswapExchange = UniswapFactoryInterface(uniswapFactory).getExchange(token);
        uint256 ethAmount = msg.value;


        // deduct gas fee
        uint256 netEthAmount = safeSub(ethAmount, gasFee);

        if (!gasFeeAccount.send(gasFee)) revert();

        // swap eth for erc20 token
        uint256 tokens_bought = UniswapExchangeInterface(uniswapExchange).ethToTokenSwapInput.value(netEthAmount)(1, 2**256 - 1);
    
        // deduct swap fee
        uint256 fee = safeMul(tokens_bought, swapFee) / 1e18;

        // send token to destination address
        if (!ERC20Interface(token).transfer(destinationAddress, safeSub(tokens_bought, fee))) revert();

        return tokens_bought;
    }  

    // Swap ERC20 Token -> ERC20 Token
    function swapERC20TokentoERC20Token (address tokenIn, uint256 tokenInAmount, address tokenOut, address destinationAddress) public payable returns (uint256 amount)
    {
        address inUniswapExchange = UniswapFactoryInterface(uniswapFactory).getExchange(tokenIn);
       
        // retrieve token (must be approved first)
        if (!ERC20Interface(token).transferFrom(msg.sender, this, tokenInAmount)) revert(); 

        // swap token to 
        ERC20Interface(tokenIn).approve(inUniswapExchange, tokenInAmount);
        uint256 ethAmount = UniswapExchangeInterface(inUniswapExchange).tokenToEthSwapInput(tokenInAmount, 1, 2**256 - 1);


        // deduct swap fee
        uint256 netEthAmount = safeSub(ethAmount, gasFee);

        if (!gasFeeAccount.send(gasFee)) revert();

        address outUniswapExchange = UniswapFactoryInterface(uniswapFactory).getExchange(tokenIn);

        // swap eth for erc20token
        uint256 tokens_bought = UniswapExchangeInterface(outUniswapExchange).ethToTokenSwapInput.value(netEthAmount)(1, 2**256 - 1);

        // compute swap fee
        uint256 fee = safeMul(tokens_bought, swapFee) / 1e18;

        // send token to destination address
        if (!ERC20Interface(tokenOut).transfer(destinationAddress, safeSub(tokens_bought, fee))) revert();

        return tokens_bought;
    }  
}