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
