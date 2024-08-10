# DOLPHINWORLD VAULT AND ERC20 CONTRACTS
This repository contains Solidity smart contracts for the Dolphinworld game, including an ERC20 token contract and a Vault contract for managing dolphins and user ranks.

## DESCRIPTION
This project consists of two main contracts:

ERC20 Contract: Implements a basic ERC20 token with minting, burning, transferring, and approval functionalities. It represents a token named "Ultratech" with the symbol "UTH".

Vault Contract: Manages the interaction between users and dolphins. It allows users to deposit and withdraw tokens, buy and send dolphins, burn tokens, and rank up based on their tokens and dolphins' agility.

## Getting Started
### Steps
1. Set up your EVM subnet: You can use our guide and the Avalanche documentation to create a custom EVM subnet on the Avalanche network.

2. Define your native currency: You can set up your own native currency, which can be used as the in-game currency for your Dolphinworld game.

3. Connect to Metamask: Connect your EVM Subnet to Metamask by following the steps laid out in our guide.

4. Deploy basic building blocks: Use Solidity and Remix to deploy the basic building blocks of your game, such as smart contracts for battling, exploring, and trading. These contracts will define the game rules, such as liquidity pools, tokens, and more.

### Executing Program
To run these contracts, you can use Remix, an online Solidity IDE. Follow the steps below to get started:

1. Open Remix IDE:
  - Go to Remix Ethereum IDE.
2. Create and Save Files:
  - Create new files for each contract by clicking on the "+" icon in the left-hand sidebar.
  - Save the files with .sol extensions (e.g., ERC20.sol, Vault.sol).
3. Paste the Code:
  ### ERC20.sol
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SaketsToken is ERC20 {
    constructor() ERC20("SaketsSubnet", "SKT") {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
}
```
### Vault.sol
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    struct Dolphin {
        string name;
        uint agility;
        uint price;
        string rarity;
    }

    Dolphin[] public dolphins;
    mapping(address => uint[]) public userDolphins;
    mapping(address => uint) public userRank;

    event DolphinPurchased(address indexed user, uint dolphinId, string dolphinName, uint price);
    event DolphinSent(address indexed from, address indexed to, uint dolphinId, string dolphinName);
    event TokensBurned(address indexed user, uint amount);
    event RankUp(address indexed user, uint newRank);

    uint8 public constant TOKEN_DECIMALS = 18;

    constructor(IERC20 _token) Ownable(msg.sender) {
        token = _token;
        _initializeDolphins();
    }

    function _initializeDolphins() internal {
        dolphins.push(Dolphin("Bottlenose", 100, 1000, "Common"));
        dolphins.push(Dolphin("Spinner", 80, 800, "Uncommon"));
        dolphins.push(Dolphin("Common", 90, 900, "Common"));
        dolphins.push(Dolphin("Risso's", 85, 850, "Rare"));
        dolphins.push(Dolphin("Pacific White-sided", 110, 1100, "Epic"));
        dolphins.push(Dolphin("Dusky", 95, 950, "Legendary"));
    }

    function _mint(address _to, uint _shares) private {
        totalSupply += _shares;
        balanceOf[_to] += _shares;
    }

    function _burn(address _from, uint _shares) private {
        totalSupply -= _shares;
        balanceOf[_from] -= _shares;
    }

    function deposit(uint _amount) external {
        uint shares;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply) / token.balanceOf(address(this));
        }
        _mint(msg.sender, shares);
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint _shares) external {
        uint amount = (_shares * token.balanceOf(address(this))) / totalSupply;
        _burn(msg.sender, _shares);
        token.safeTransfer(msg.sender, amount);
    }

    function buyDolphin(uint dolphinId) external {
        require(dolphinId < dolphins.length, "Invalid dolphinId");
        Dolphin memory dol = dolphins[dolphinId];
        require(token.balanceOf(msg.sender) >= dol.price, "Not enough tokens");
        token.safeTransferFrom(msg.sender, address(this), dol.price);
        userDolphins[msg.sender].push(dolphinId);
        emit DolphinPurchased(msg.sender, dolphinId, dol.name, dol.price);
    }

    function sendDolphin(address to, uint dolphinId) external {
        require(dolphinId < dolphins.length, "Invalid dolphinId");
        uint[] storage dols = userDolphins[msg.sender];
        bool found = false;
        for (uint i = 0; i < dols.length; i++) {
            if (dols[i] == dolphinId) {
                dols[i] = dols[dols.length - 1];
                dols.pop();
                found = true;
                break;
            }
        }
        require(found, "Dolphin not found in sender's collection");
        userDolphins[to].push(dolphinId);
        emit DolphinSent(msg.sender, to, dolphinId, dolphins[dolphinId].name);
    }

    function burnTokens(uint amount) external {
        token.safeTransferFrom(msg.sender, address(0), amount);
        emit TokensBurned(msg.sender, amount);
    }

    function rankUp() external {
        uint tokenShare = balanceOf[msg.sender] / totalSupply;
        uint dolAgility = 0;
        for (uint i = 0; i < userDolphins[msg.sender].length; i++) {
            dolAgility += dolphins[userDolphins[msg.sender][i]].agility;
        }
        userRank[msg.sender] = dolAgility + tokenShare;
        emit RankUp(msg.sender, userRank[msg.sender]);
    }

    function getUserDolphins(address _user) external view returns (string[] memory) {
        uint[] memory dolIds = userDolphins[_user];
        string[] memory dolNames = new string[](dolIds.length);

        for (uint i = 0; i < dolIds.length; i++) {
            uint dolId = dolIds[i];
            dolNames[i] = dolphins[dolId].name;
        }

        return dolNames;
    }

    function getRank(address _user) public view returns (uint) {
        return userRank[_user];
    }

    function getAllDolphins() external view returns (Dolphin[] memory) {
        return dolphins;
    }
}
```
### Compiling the Code
#### Select Compiler Version:
```
Click on the "Solidity Compiler" tab in the left-hand sidebar.
Ensure the "Compiler" option is set to "0.8.17" (or the version specified).
```
#### Compile Contracts:
```
Click on the "Compile ERC20.sol" button.
Click on the "Compile Vault.sol" button.
```
### Deploying the Contract
#### Deploy ERC20 Contract:
```
Go to the "Deploy & Run Transactions" tab.
Select "ERC20" from the dropdown menu.
Click "Deploy".
```
#### Deploy Vault Contract:
```
After deploying the ERC20 contract, copy its address.
Go to the "Deploy & Run Transactions" tab.
Select "Vault" from the dropdown menu.
Enter the ERC20 contract address in the constructor parameter.
Click "Deploy".
```
### Interacting with the Contract
1. Mint Tokens:

  - Select the mint function.
  - Enter the amount to mint.
  - Click "transact".
  
2. Transfer Tokens:

  - Select the transfer function.
  - Enter the recipient address and amount.
  - Click "transact".
  
3. Deposit Tokens:

  - Select the deposit function.
  - Enter the amount to deposit.
  - Click "transact".
  
4. Withdraw Tokens:

  - Select the withdraw function.
  - Enter the number of shares to withdraw.
  - Click "transact".
5. Buy Dolphin:

  - Select the buyDolphin function.
  - Enter the dolphin ID.
  - Click "transact".
  
6. Send Dolphin:

  - Select the sendDolphin function.
  - Enter the recipient address and dolphin ID.
  - Click "transact".
  
7. Burn Tokens:

  - Select the burnTokens function.
  - Enter the amount of tokens to burn.
  - Click "transact".

## Authors
Saket Agarwal
