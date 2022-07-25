// SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";




//A basic ERC20 driven from OpenZepplin lib and modified according to the requirements.
contract Roxo is ERC20,Ownable {
    bool lock;//for locking the features.
    address public usd;//Abase fiat token for buying and selling.
    uint256 public basePrice;// A rate for buying  and selling.
    uint256 public preSaleAmount;// Number of tokens Allocated for presale.
    uint256 public emitAmount;//A container for total of token allocated for release overtime .
    uint256 immutable public investmentSecurityPercentage = 70;//by default 70%.
    mapping(address => uint256) public _sercureBalances;//based on this contract will allow user to sell his/her tokens.
    event buyToken (uint256 fiatAmount,address user,uint256 tokenAmount);//A basic buy event.
    event sellToken (uint256 fiatAmount,address user,uint256 tokenAmount);//A basic sell event.
    uint public totalEmissionBlocks; //this is for polygon mainnet...//68245181.
    uint public EmissionBlocksLeft;//number of blocks left which will emit tokens.
    uint public lastRedeemedBlock;//A last block in which admin redeemed tokens.
    uint256 public emissionLeft;//A container will show how much token left for emmission.
    


//In the constructor initializing variables
 constructor() ERC20("Roxo", "Roxo") {
        _mint(address(this), 10000000000 * 10 ** decimals());
        lock = false;
        basePrice = 7500000000000000;
       totalEmissionBlocks = 68245181;
        preSaleAmount =  ((10000000000*15) * 10 ** decimals())/100;
        emitAmount =  ((10000000000*70) * 10 ** decimals())/100;
        super._transfer(address(this),_msgSender(),((10000000000 *15* 10 ** decimals())/100));
        emissionLeft = emitAmount;
        lastRedeemedBlock = block.number;
        EmissionBlocksLeft = totalEmissionBlocks;
    }

//This below function is a withdraw function for owner only that will emit some token with every block for almost
//five years according to the poltgon matic chain

    function withdrawEmittedTokens()external onlyOwner returns (uint256){
          uint256  blockEmitAmount = emitAmount/totalEmissionBlocks;
            uint256 nBlocks = block.number - lastRedeemedBlock;
                if(nBlocks>=EmissionBlocksLeft){
                    nBlocks = EmissionBlocksLeft;
                }else{
                    nBlocks = nBlocks;
                }
            require(nBlocks <= EmissionBlocksLeft && nBlocks != 0,"Block Emission is Finished");
            require(balanceOf(address(this))>=nBlocks*blockEmitAmount && emissionLeft>=nBlocks*blockEmitAmount,"Amount Emission is Finished");
            EmissionBlocksLeft -= nBlocks;
            super._transfer(address(this),_msgSender(),nBlocks*blockEmitAmount);
            emissionLeft -= nBlocks*blockEmitAmount;
            lastRedeemedBlock = block.number;
            return (nBlocks*blockEmitAmount);
    }


//The buy function is pretty stright forward its just requires approved usdt and in return it will give 
//Roxo token and this will only be avaiable untill the presale amounts finished,its also giving a 70% backback
//option if user will buy from this function contract will posses the 70% usdt and remaning 30% will goes to the
//develpoers
    
  function  buy()external returns (bool){
        require(basePrice != 0, "Pre sale not set by an admin");
        uint256 _amount = IERC20(usd).allowance(_msgSender(),address(this));
        require(_amount/basePrice >= 1,"Minimum Requirement not met");
        require(preSaleAmount >= _amount * (1 * 10**decimals()) / basePrice);
        require(balanceOf(address(this)) >= _amount * (1 * 10**decimals()) / basePrice,"Not enough token's");

        _sercureBalances[_msgSender()] = ((_amount*investmentSecurityPercentage)/100 +  _sercureBalances[_msgSender()]);
         IERC20(usd).transferFrom(
                _msgSender(),
                address(this),
                _amount
            );
            IERC20(usd).transfer(owner(), (_amount*30)/100);
            super._transfer(address(this), _msgSender(), _amount * (1 * 10**decimals()) / basePrice);
            preSaleAmount -= _amount * (1 * 10**decimals()) / basePrice;
          emit  buyToken(_amount,_msgSender(),_amount * (1 * 10**decimals()) / basePrice);
            return true;
    }

//@Caution
//Requires Amount in usdt not in Roxo.
// The contract will buyback Roxo tokens from user who bought in the presale time.
function sell(uint256 _amount)external returns(bool){
    require(_sercureBalances[_msgSender()] >= _amount,"Not enough security balance");
    require(super.balanceOf(_msgSender()) >= _amount * (1 * 10**decimals()) / basePrice ,"Not enough Roxo tokens");
    require(IERC20(usd).balanceOf(address(this))>= _amount,"No secure balance available");
    _sercureBalances[_msgSender()] -= _amount;
    IERC20(usd).transfer(_msgSender(), _amount);
    super._transfer(_msgSender(),owner(), _amount * (1 * 10**decimals()) / basePrice);
    emit sellToken(_amount,_msgSender(),_amount * (1 * 10**decimals()) / basePrice);
    return true;
}


//It's a emergency withdraw function.
// function emergencyWithdraw()external onlyOwner returns (uint256){
//   super._transfer(address(this),owner(),super.balanceOf(address(this)));
//   return (super.balanceOf(address(this)));
// }

//This function is to set the base price during presale only.
function setbasePrice(uint256 _price)external onlyOwner returns (uint256)
{ require(!lock,"Cannot Change after lock");
    basePrice = _price;
    return basePrice;
}

//A function for change fiat for buying and selling
function setUsd(address _addr)external onlyOwner returns (bool)
{
    require(!lock,"Cannot Change after lock");
    usd = _addr;
    return true;
}



//Control lock function is for locking contract other function in order maintain users security
function controlLock()external onlyOwner{
    lock = true;
}

}