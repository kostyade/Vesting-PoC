//
// ██╗   ██╗███████╗███████╗████████╗██╗███╗   ██╗ ██████╗
// ██║   ██║██╔════╝██╔════╝╚══██╔══╝██║████╗  ██║██╔════╝
// ██║   ██║█████╗  ███████╗   ██║   ██║██╔██╗ ██║██║  ███╗
// ╚██╗ ██╔╝██╔══╝  ╚════██║   ██║   ██║██║╚██╗██║██║   ██║
//  ╚████╔╝ ███████╗███████║   ██║   ██║██║ ╚████║╚██████╔╝
//   ╚═══╝  ╚══════╝╚══════╝   ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "hardhat/console.sol";

contract Vesting is ReentrancyGuard, Ownable, Pausable {
    IERC20 public token;
    uint256 public cliff;
    uint256 public start;
    uint256 public period;
    uint256 public releasesCount;

    mapping(address => uint256) private balances;
    mapping(address => uint256) private releases;

    // Let's do everything in constructor for simplicity
    constructor(
        address _token,
        uint256 _start,
        uint256 _cliff,
        uint256 _period,
        uint256 _releasesCount
    ) {
        require(_cliff <= 100, "cliff must be less than 100");
        token = IERC20(_token);
        period = _period;
        cliff = _cliff;
        start = _start;
        releasesCount = _releasesCount;
    }

    function _vestedAmount(address _user) private view returns (uint256) {
        if (block.timestamp < start) {
            return 0;
        } else {
            uint256 timeLeftAfterStart = block.timestamp - start;
            uint256 availableReleases = timeLeftAfterStart / period;
            uint256 percentagePerRelease = (100 - cliff) / releasesCount;
            console.log(availableReleases, percentagePerRelease);
            if (availableReleases >= releasesCount) {
                return balances[_user];
            } else {
                uint256 vestedAmount = (balances[_user] *
                    (cliff + availableReleases * percentagePerRelease)) / 100;
                return vestedAmount;
            }
        }
    }

    function withdrawableOf(address _user) public view returns (uint256) {
        return _vestedAmount(_user) - releases[_user];
    }

    function withdraw() public nonReentrant whenNotPaused {
        require(
            token.balanceOf(address(this)) > withdrawableOf(msg.sender),
            "not enough tokens"
        );
        uint256 amountToWithdraw = withdrawableOf(msg.sender);
        releases[msg.sender] += amountToWithdraw;
        token.transfer(msg.sender, amountToWithdraw);
    }

    // Actually don't really like batch transfer architecture as we need to perform lengths check,
    // also need to be sure that users are unique, as balances won't sum up.
    // Also need to be sure that there're enough tokens.
    function addUsers(address[] memory _users, uint256[] memory _amounts)
        public
        onlyOwner
    {
        require(_users.length == _amounts.length, "array length must match.");

        for (uint256 i = 0; i < _users.length; ++i) {
            address user = _users[i];
            uint256 amount = _amounts[i];
            balances[user] = amount;
        }
    }
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);
}
