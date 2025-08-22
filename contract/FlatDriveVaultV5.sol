// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address a) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from,address to,uint256 value) external returns (bool);
    function allowance(address owner,address spender) external view returns (uint256);
}

contract FlatDriveVaultV5 {
    IERC20 public immutable token;
    address public owner;
    address public player;

    uint256 public fundBalance;
    uint256 public playerBalance;
    uint256 public backendBalance;

    uint256 public constant WITHDRAW_FEE_BPS = 500; 
    uint256 public constant BPS_DEN = 10000;

    uint256 public constant PLAYER_BPS = 9000;
    uint256 public constant FUND_BPS   = 700;
    uint256 public constant BACKEND_BPS= 300;

    uint256 public minWithdraw = 50 * 1e6;

    event Credited(uint256 totalUsd, uint256 toPlayer, uint256 toFund, uint256 toBackend);
    event WithdrawnForPlayer(address indexed to, uint256 gross, uint256 fee, uint256 net);
    event FundConvertedToPlayer(uint256 amount);
    event FundWithdrawn(address indexed to, uint256 amount);
    event BackendWithdrawn(address indexed to, uint256 amount);
    event OwnerChanged(address indexed newOwner);
    event PlayerChanged(address indexed newPlayer);
    event MinWithdrawChanged(uint256 newMin);

    modifier onlyOwner() { require(msg.sender == owner, "only owner"); _; }
    modifier onlyPlayer(){ require(msg.sender == player, "only player"); _; }

    constructor(address usdtToken, address playerAddress) {
        require(usdtToken != address(0), "bad token");
        owner = msg.sender;
        token = IERC20(usdtToken);
        player = playerAddress;
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "bad owner");
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }
    function setPlayer(address newPlayer) external onlyOwner {
        require(newPlayer != address(0), "bad player");
        player = newPlayer;
        emit PlayerChanged(newPlayer);
    }
    function setMinWithdraw(uint256 newMin) external onlyOwner {
        require(newMin > 0, "bad min");
        minWithdraw = newMin;
        emit MinWithdrawChanged(newMin);
    }

    function credit(uint256 totalUsdAmount) external onlyOwner {
        require(totalUsdAmount > 0, "zero");
        uint256 toPlayer  = (totalUsdAmount * PLAYER_BPS) / BPS_DEN;
        uint256 toFund    = (totalUsdAmount * FUND_BPS) / BPS_DEN;
        uint256 toBackend = totalUsdAmount - toPlayer - toFund;

        playerBalance += toPlayer;
        fundBalance   += toFund;
        backendBalance += toBackend;

        emit Credited(totalUsdAmount, toPlayer, toFund, toBackend);
    }

    function withdrawForPlayer(uint256 amount, address to) external onlyOwner {
        require(to != address(0), "bad to");
        require(amount >= minWithdraw, "below min");
        require(playerBalance >= amount, "insufficient player balance");

        playerBalance -= amount;

        uint256 fee = (amount * WITHDRAW_FEE_BPS) / BPS_DEN;
        uint256 net = amount - fee;

        fundBalance += fee;

        require(token.transfer(to, net), "token transfer failed");
        emit WithdrawnForPlayer(to, amount, fee, net);
    }

    function ownerWithdrawBackend(uint256 amount, address to) external onlyOwner {
        require(to != address(0), "bad to");
        require(amount > 0 && amount <= backendBalance, "bad amount");
        backendBalance -= amount;
        require(token.transfer(to, amount), "token transfer failed");
        emit BackendWithdrawn(to, amount);
    }

    function convertFundToPlayer(uint256 amount) external onlyOwner {
        require(amount > 0 && amount <= fundBalance, "bad amount");
        fundBalance -= amount;
        playerBalance += amount;
        emit FundConvertedToPlayer(amount);
    }

    function ownerWithdrawFund(uint256 amount, address to) external onlyOwner {
        require(to != address(0), "bad to");
        require(amount > 0 && amount <= fundBalance, "bad amount");
        fundBalance -= amount;
        require(token.transfer(to, amount), "token transfer failed");
        emit FundWithdrawn(to, amount);
    }

    function ownerDeposit(uint256 amount) external onlyOwner {
        require(amount > 0, "zero");
        require(token.transferFrom(msg.sender, address(this), amount), "transferFrom failed");
    }

    function contractTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
