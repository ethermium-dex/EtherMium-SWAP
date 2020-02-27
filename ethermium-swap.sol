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

/* Interface for pTokens contract */
contract pToken {
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

    // Allows only the feeAccount to execute the function
    modifier onlyFeeAccount {
        assert(msg.sender == feeAccount);
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


    mapping (address => mapping (address => uint256)) public balances; // mapping of token addresses to mapping of balances and reserve (bitwise compressed) // balances[token][user]
    mapping (address => address) public uniswapExchange; // mapping of tokens to uniswap exchange

    address public feeAccount; // ethermium fees go to this account
    uint256 public swapFee = 2e15; // pct swap fee * 1e18 (0.002 * 1e18)

    bool public feeAccountChangeDisabled = false;

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
    function EtherMium_Atomic_Swap_DEX(address feeAccount_) {
        owner = msg.sender;
        feeAccount = feeAccount_;
    }

    // Change fee account
    function changeFeeAccount (address feeAccount_) onlyOwner {
        if (feeAccountChangeDisabled) revert();
        feeAccount = feeAccount_;
        emit FeeAccountChanged(feeAccount_);
    }

    // Changes the fees
    function setFees(uint256 swapFee_) onlyOwner {
        require(swapFee_      < 10 finney); // The fees cannot be set higher then 1%
        swapFee = swapFee_;

        emit FeeChange(swapFee);
    }

    // Disable future fee account change
    function disableFeeAccountChange() onlyOwner {
        feeAccountChangeDisabled = true;
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
        if (uniswapExchange[token] == address(0)) revert(); // no uniswap exchange set for token
        uint256 ethAmount = msg.value;

        // deduct swap fee
        uint256 fee = safeMul(ethAmount, swapFee) / 1e18;
        uint256 netEthAmount = safeSub(ethAmount, fee);

        // swap eth for pToken
        uint256 ptokens_bought = UniswapExchangeInterface(uniswapExchange[address(0)]).ethToTokenSwapInput.value(netEthAmount)(1, 2**256 - 1);
    
        // redeem pTokens
        if (!pToken(token).redeem(ptokens_bought, destinationAddress))
        {
            revert();
        }

        return ptokens_bought;
    }


    // Swap ERC20 Token -> ETH
    function swapERC20TokenToETH (address token, uint256 tokenAmount, address destinationAddress) public returns (uint256 amount)
    {
        if (uniswapExchange[token] == address(0)) revert(); // no uniswap exchange set for token
        
        // retrieve token (must be approved first)
        if (!ERC20Interface(token).transferFrom(msg.sender, this, tokenAmount)) revert(); 

        // convert token to ETH
        ERC20Interface(token).approve(uniswapTokenContracts[token], tokenAmount);
        uint256 ethAmount = UniswapExchangeInterface(uniswapTokenContracts[token]).tokenToEthSwapInput(tokenAmount, 1, 2**256 - 1);

        // deduct swap fee
        uint256 fee = safeMul(ethAmount, swapFee) / 1e18;
        uint256 netEthAmount = safeSub(ethAmount, fee);

        if (!destinationAddress.send(netEthAmount)) revert();

        return netEthAmount;
    }


    // Swap ETH -> ERC20 Token
    function swapETHtoERC20Token (address token, address destinationAddress) public payable returns (uint256 amount)
    {
        if (uniswapExchange[token] == address(0)) revert(); // no uniswap exchange set for token
        uint256 ethAmount = msg.value;

        // deduct swap fee
        uint256 fee = safeMul(ethAmount, swapFee) / 1e18;
        uint256 netEthAmount = safeSub(ethAmount, fee);

        // swap eth for pToken
        uint256 tokens_bought = UniswapExchangeInterface(uniswapExchange[address(0)]).ethToTokenSwapInput.value(netEthAmount)(1, 2**256 - 1);
    
        // send token to destination address
        if (!ERC20Interface(token).transfer(destinationAddress, tokens_bought)) revert();

        return tokens_bought;
    }    
}