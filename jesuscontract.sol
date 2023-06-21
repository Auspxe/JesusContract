// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Import PancakeSwap Router interface
import "./IPancakeRouter02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

interface IBEP20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    
    // Additional functions from the StandardToken contract
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function increaseApproval(address spender, uint256 addedValue) external returns (bool);
    function decreaseApproval(address spender, uint256 subtractedValue) external returns (bool);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, 'only owner');
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'not whitelisted');
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param addr address
     * @return success true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    /**
     * @dev add addresses to the whitelist
     * @param addrs addresses
     * @return success true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    /**
     * @dev remove an address from the whitelist
     * @param addr address
     * @return success true if the address was removed from the whitelist,
     * false if the address wasn't in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    /**
     * @dev remove addresses from the whitelist
     * @param addrs addresses
     * @return success true if at least one address was removed from the whitelist,
     * false if all addresses weren't in the whitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }
}

contract JesusContract is Whitelist {
    // Define PancakeSwap router address
    address constant PANCAKE_ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    // Define BUSD token address
    address constant BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;

    // Create a router instance
    IPancakeRouter02 public pancakeRouter;

    // Create an TokenA instance
    address public TokenA;

    // Declare TokenB as a mutable state variable
    address public TokenB;

    // Define a mapping to store whitelisted addresses
    mapping(address => bool) public whitelisted;

    // Define an array of recipient addresses and their percentages
    address[] public recipients;
    uint[] public percentages;

    // Define a state variable to store the threshold value for distribution
    uint public threshold;

    // Define a state variable to store the exchange rate of TokenB to BUSD (in wei)
    uint public exchangeRate;

    // Define an event to confirm that TokenB tokens are received
    event TokenBReceived(address sender, uint amount);

    constructor(address _TokenA, address _TokenB) {
        // Initialize router
        pancakeRouter = IPancakeRouter02(PANCAKE_ROUTER);
        // Set the TokenA contract address
        TokenA = _TokenA;
        // Set the TokenB contract address
        TokenB = _TokenB;
        // Set the deployer as the owner
        owner = msg.sender;
        // Add the owner to the whitelist
        whitelisted[owner] = true;
        // Set the default threshold value to 100 BUSD
        threshold = 100 * 10 ** 18;
        // Set the default exchange rate to zero
        exchangeRate = 0;
    }

    fallback() external payable { }

    receive() external payable { }

    function rescueBNB(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function rescueToken(address tokenAddress, uint256 tokens) external onlyOwner {
        IERC20(tokenAddress).transfer(owner, tokens);
    }

    function balanceOf(address tokenAddress) public view returns (uint256) {
        if (tokenAddress == BUSD) {
            return IBEP20(BUSD).balanceOf(address(this));
        } else if (tokenAddress == TokenB) {
            return IBEP20(TokenB).balanceOf(address(this));
        } else {
            // Invalid token address
            return 0;
        }
    }

    // A function to set the address of the TokenB contract
    function setTokenB(address _TokenB) external onlyOwner {
        require(_TokenB != address(0), "TokenB cannot be zero address");
        TokenB = _TokenB;
    }

    // A function to set the threshold value for distribution
    function setThreshold(uint _threshold) public onlyOwner {
        require(_threshold > 0, "Threshold must be positive");
        threshold = _threshold;
    }

    // A function to set the exchange rate of TokenB to BUSD (in wei)
    function setExchangeRate(uint _exchangeRate) public onlyOwner {
        require(_exchangeRate > 0, "Exchange rate must be positive");
        exchangeRate = _exchangeRate;
    }

     // A function to add a recipient and their percentage for distribution
    function addRecipient(address recipient, uint percentage) public onlyOwner {
        require(recipient != address(0), "Recipient address cannot be zero");
        require(percentage > 0, "Percentage must be positive");

        recipients.push(recipient);
        percentages.push(percentage);
    }

    // A function to remove a recipient and their percentage
    function removeRecipient(uint index) public onlyOwner {
        require(index < recipients.length, "Invalid recipient index");

        for (uint i = index; i < recipients.length - 1; i++) {
            recipients[i] = recipients[i + 1];
            percentages[i] = percentages[i + 1];
        }

        recipients.pop();
        percentages.pop();
    }

    // Track gas usage for different operations
    mapping(bytes4 => uint256) private gasUsage;

    // A function to distribute tokens to different wallets based on their percentages
    function distribute(address sender, uint amount, address token) public {
        require(token != address(0), "Token cannot be zero address");

        // Check if the received tokens are TokenB
        if (token == TokenB) {
            // Emit an event to confirm that TokenB tokens are received
            emit TokenBReceived(sender, amount);
        }

        // Calculate the estimated gas cost for the transaction
        uint gasCost = estimateGasCost(msg.sig); // Use the function signature as the method identifier

        // Ensure the contract has enough BNB balance to cover the gas fees
        require(address(this).balance >= gasCost, "Insufficient BNB balance for gas fees");

        // Deduct the gas fees from the contract's BNB balance
        (bool success, ) = address(this).call{gas: gasCost, value: gasCost}(""); // Transfer gas fees to the miner
        require(success, "Failed to pay gas fees");

        // Check if the received tokens are BUSD and the balance is greater than or equal to the threshold
        if (token == BUSD && IERC20(BUSD).balanceOf(address(this)) >= threshold) {
            // Calculate the amount of TokenB to send based on the exchange rate.
            uint amountToSend = threshold * exchangeRate / (10 ** 18);
            require(IERC20(TokenB).transfer(sender, amountToSend), "TokenB transfer failed");

            // Calculate the amount of BUSD to distribute to the wallets based on their percentages
            uint busdToDistribute = amount - amountToSend;

            for (uint i = 0; i < recipients.length; i++) {
                uint share = busdToDistribute * percentages[i] / 100;
                require(IERC20(BUSD).transfer(recipients[i], share), "BUSD transfer failed");
            }
        } else if (token == BUSD) {
            // Calculate the amount of TokenB to send based on the exchange rate.
            uint amountToSend = amount * exchangeRate / (10 ** 18);
            require(IERC20(TokenB).transfer(sender, amountToSend), "TokenB transfer failed");
        }
    }

    // Function to estimate the gas cost for a specific method
    function estimateGasCost(bytes4 method) internal view returns (uint256) {
        // Get the gas cost estimate for the specified method
        uint256 estimatedGas = gasUsage[method];
        require(estimatedGas > 0, "Gas cost estimate not available");

        return estimatedGas;
    }

    // Function to update the gas usage for a specific method
    function updateGasUsage(bytes4 method, uint256 gas) external {
        require(gas > 0, "Invalid gas usage");
        gasUsage[method] = gas;
    }

        // A function to add recipient addresses and their percentages
        function addRecipients(address[] memory _recipients, uint[] memory _percentages) external onlyOwner {
            require(_recipients.length == _percentages.length, "Arrays must have the same length");
            require(_recipients.length > 0, "At least one recipient must be added");

            for (uint i = 0; i < _recipients.length; i++) {
                require(_recipients[i] != address(0), "Recipient cannot be zero address");
                require(_percentages[i] > 0 && _percentages[i] <= 100, "Percentage must be between 1 and 100");

                recipients.push(_recipients[i]);
                percentages.push(_percentages[i]);
            }
        }

        // A function to remove recipient addresses
        function removeRecipients(address[] memory _recipients) external onlyOwner {
            require(_recipients.length > 0, "At least one recipient must be removed");

            for (uint i = 0; i < _recipients.length; i++) {
                require(_recipients[i] != address(0), "Recipient cannot be zero address");

                for (uint j = 0; j < recipients.length; j++) {
                    if (_recipients[i] == recipients[j]) {
                        recipients[j] = recipients[recipients.length - 1];
                        recipients.pop();
                        percentages[j] = percentages[percentages.length - 1];
                        percentages.pop();
                        break;
                    }
                }
            }
        }

    // A function to replace recipient addresses and their percentages
    function replaceRecipients(address[] memory _recipients, uint[] memory _percentages) external onlyOwner {
        require(_recipients.length == _percentages.length, "Arrays must have the same length");
        require(_recipients.length > 0, "At least one recipient must be added");

        // Clear the existing recipients and percentages
        recipients = new address[](0);
        percentages = new uint[](0);

        for (uint i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Recipient cannot be zero address");
            require(_percentages[i] > 0 && _percentages[i] <= 100, "Percentage must be between 1 and 100");

            recipients.push(_recipients[i]);
            percentages.push(_percentages[i]);
        }
    }
}

