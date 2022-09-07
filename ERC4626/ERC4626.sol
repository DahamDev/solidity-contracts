// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC4626 is ERC20{

    ERC20 public immutable assetToken;

    uint256 private _totalAssests;

    mapping (address=>uint256) private maxAssets;

    mapping (address=>uint256) private shareHolder;

    constructor(ERC20 _underline,string memory _name, string memory _symbol ) ERC20(_name, _symbol) {
        assetToken=_underline;
    }

    event Deposit(address sender,uint256 amountOfAssests);
    event Withdraw(address caller, address receiver, uint256 amt, uint256 shares);

    function asset() public view returns(address){
        return address(assetToken);
    }

    function totalAssests() public view returns(uint256){
        return _totalAssests;
    }

    function setMaxDeposit(address receiver,uint256 _maxAmount) public{
        maxAssets[receiver] = _maxAmount;
    }

    // a deposit function that receives assets from users
    function deposit(uint256 assets) public{
        require (assets > 0, "Deposit less than Zero");
        require(assets<=maxDeposit(msg.sender),"assets are larger than the allowed maximum deposit");
        
        assetToken.transferFrom(msg.sender, address(this), assets);
        shareHolder[msg.sender] += assets;
        _mint(msg.sender, assets);
        _totalAssests+=assets;
        emit Deposit(msg.sender, assets);

    }

    // allow msg.sender to withdraw his deposit plus interest
    function withdraw(uint256 shares, address receiver) public {
        uint256 payout = redeem(shares, receiver);
        assetToken.transfer(receiver, payout);
        _totalAssests-=payout;
    }



    //internal functions

    function convertToShares(uint256 _asset) private pure returns(uint256){
        //thsi should return amount of shares provides for the number of assets
        return 1*_asset;
    }

    function convertToAssets(uint256 _shares) private pure returns(uint256){
        //thsi should return amount of assets provides for the number of shares
        return 1*_shares;
    }

    function maxDeposit(address receiver) private view returns(uint256){
        return maxAssets[receiver];
    }

    function maxRedeem(address owner) private view returns(uint256){
        //let user redeem all the shares they own
        return shareHolder[owner];
    }

    
    // users to return shares and get thier token back before they can withdraw, and requiers that the user has a deposit
    function redeem(uint256 shares, address receiver ) internal returns (uint256 assets) {
        require(shareHolder[msg.sender] > 0, "Not a share holder");
        shareHolder[msg.sender] -= shares;
        uint256 per = (10 * shares) / 100;
        _burn(msg.sender, shares);

        assets = convertToAssets(shares) + per;

        emit Withdraw(msg.sender, receiver, per,shares);
        return assets;
    }

}
