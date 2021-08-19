// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

//////////////////////////// INTERFACES ////////////////////////////
import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/IPancakePair.sol";
import "./interfaces/IPancakeRouter01.sol";
import "./interfaces/IPancakeRouter02.sol";
//////////////////////////// INTERFACES ////////////////////////////

//////////////////////////// LIBRARIES ////////////////////////////
import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/Address.sol";
//////////////////////////// LIBRARIES ////////////////////////////

//////////////////////////// UTILITIES ////////////////////////////
import "./utilities/Context.sol";
//////////////////////////// UTILITIES ////////////////////////////




contract CatNIP is Context, IERC20, IERC20Metadata {



    //////////////////////////// USING STATEMENTS ////////////////////////////
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    //////////////////////////// USING STATEMENTS ////////////////////////////


    //////////////////////////// BASIC INFO MAPPINGS ////////////////////////////  
    mapping (address => mapping (address => uint256)) private allowancesOfToken;
    //////////////////////////// BASIC INFO MAPPINGS ////////////////////////////  


    //////////////////////////// BASIC INFO VARS ////////////////////////////  
    string private nameOfToken = "CatNIP";
    string private symbolOfToken = "NIP";
    uint8 private decimalsOfToken = 9;
    uint256 private decimalsMultiplier = 10**9;
    uint256 public deployDateUnixTimeStamp = block.timestamp;  // sets the deploy timestamp
    uint256 private totalSupplyOfToken = 10**9 * decimalsMultiplier;    // 1 Billion
    //////////////////////////// BASIC INFO VARS ////////////////////////////  



    //////////////////////////// ACCESS CONTROL ////////////////////////////  
    address public directorAccount = _msgSender();  // TODO - director is the multisig
    address public minterAccount = 0xE5d30eeF39D0C428924de4d6cd4Dc96f84Ab1027;  // TODO - minter is account used by the game
    //////////////////////////// ACCESS CONTROL ////////////////////////////  



    //////////////////////////// PANCAKE SWAP VARS ////////////////////////////  
    address public routerAddressForDEX = 0x10ED43C718714eb63d5aA57B78B54704E256024E;     // CHANGEIT - change this to real pancakeswap router
    // address public routerAddressForDEX = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;   

    IPancakeRouter02 public pancakeswapRouter = IPancakeRouter02(routerAddressForDEX);      // gets the router
    address public pancakeswapPair = IPancakeFactory(pancakeswapRouter.factory()).createPair(address(this), pancakeswapRouter.WETH());     // Creates the pancakeswap pair   
    //////////////////////////// PANCAKE SWAP VARS ////////////////////////////  
    

    

    //////////////////////////// DEAD ADDR VARS ////////////////////////////
    address private deadAddressZero = 0x0000000000000000000000000000000000000000; 
    address private deadAddressOne = 0x0000000000000000000000000000000000000001; 
    address private deadAddressdEaD = 0x000000000000000000000000000000000000dEaD; 
    //////////////////////////// DEAD ADDR VARS ////////////////////////////





    //////////////////////////// RFI VARS ////////////////////////////
    mapping(address => bool) private isAccountExcludedFromReward;
    address[] private excludedFromRewardAddresses; 

    uint256 private MAXintNum = ~uint256(0);
    uint256 private reflectTokensTotalSupply = (MAXintNum - (MAXintNum % totalSupplyOfToken)); 
    uint256 public totalFeeAmount;

    mapping(address => uint256) private reflectBalance;
    mapping(address => uint256) private totalBalance;
    //////////////////////////// RFI VARS ////////////////////////////


    //////////////////////////// LIQ VARS ////////////////////////////
    bool private isInSwapAndLiquify = false;
    bool public isSwapAndLiquifyEnabled = false;
    uint256 public numberOfTokensToSellAndAddToLiquidity = totalSupplyOfToken.div(10000);  // 0.01%
    address public liquidityWallet = address(this);
    //////////////////////////// LIQ VARS ////////////////////////////




    //////////////////////////// TAX VARS ////////////////////////////
    uint256 public holderTaxPercent = 2;
    uint256 public liquidityTaxPercent = 2;
    uint256 public teamTaxPercent = 1;

    mapping(address => bool) public isAddressExcludedFromAllTaxes;
    mapping(address => bool) public isAddressExcludedFromHolderTax;
    mapping(address => bool) public isAddressExcludedFromLiquidityTax;
    mapping(address => bool) public isAddressExcludedFromTeamTax;
    //////////////////////////// TAX VARS ////////////////////////////



    //////////////////////////// TRANSFER VARS ////////////////////////////
    uint256 public maxTransferAmount = totalSupplyOfToken.div(1000);   // 0.1%
    uint256 public timeForMaxTransferCooldown = 1 days;     // 1 day    // CHANGEIT - make sure this time is correctly set
    // uint256 public timeForMaxTransferCooldown = 5 minutes;    
    mapping(address => uint256) public timeSinceLastTransferStart;
    mapping(address => uint256) public amountTransferedWithinOneDay;
    mapping(address => bool) public isAddressExcludedFromMaxTransfer;  
    //////////////////////////// TRANSFER VARS ////////////////////////////



    //////////////////////////// BUY VARS ////////////////////////////
    uint256 public maxBuyAmount = totalSupplyOfToken.div(1000);    // 0.1% - 1 million
    uint256 public timeForMaxBuyCooldown = 1 days;     // 1 day  // CHANGEIT - make sure this time is correctly set
    // uint256 public timeForMaxBuyCooldown = 5 minutes;   
    mapping(address => uint256) public timeSinceLastBuyStart;
    mapping(address => uint256) public amountBoughtWithinOneDay;
    mapping(address => bool) public isAddressExcludedFromMaxBuy; 
    //////////////////////////// BUY VARS ////////////////////////////




    //////////////////////////// SELL VARS ////////////////////////////
    uint256 public maxSellAmount = totalSupplyOfToken.div(1000);   // 0.1% 
    uint256 public timeForMaxSellCooldown = 1 days;     // 1 day  // CHANGEIT - make sure this time is correctly set
    // uint256 public timeForMaxSellCooldown = 5 minutes;   
    mapping(address => uint256) public timeSinceLastSellStart;
    mapping(address => uint256) public amountSoldWithinOneDay;
    mapping(address => bool) public isAddressExcludedFromMaxSell;   
    //////////////////////////// SELL VARS ////////////////////////////





    //////////////////////////// ANIT BOT VARS ////////////////////////////
    bool public isAntiBotWhiteListOn = true;       // Whitelist - users can self whitelist, after a time it goes away automatically
    bool public isAntiBotWhiteListOnForBuys = true;
    bool public isAntiBotWhiteListOnForSells = true;

    uint256 public antiBotWhiteListDuration  = 24 hours; // CHANGEIT - make sure this time is correctly set
    // uint256 public antiBotWhiteListDuration  = 5 minutes;    

    mapping(address => bool) private isAddressNotRobot;   
    mapping(address => bool) public isAddressNotRobotPermanently;

    mapping(address => uint256) public timeAddressNotRobotWasWhiteListed;   
    //////////////////////////// ANIT BOT VARS ////////////////////////////


    //////////////////////////// DEPOSIT VARS ////////////////////////////
    uint256 public maxDepositAmount = totalSupplyOfToken.div(100);   // 1%
    uint256 public minDepositAmount = totalSupplyOfToken.div(10**15);   // set to 1 NIP

    address public depositWallet = directorAccount;
    mapping(address => uint256) private depositNipAmountTotal;
    mapping(address => uint256) private depositGasAmountTotal;
    // bool public isDepositingEnabled = true;      // you can control depositing through the amounts required
    bool public isGameSystemEnabled = true;
    mapping(address => bool) public isBannedFromAllGamesForManipulation;
    mapping(address => bool) public isDepositing;
    mapping(address => bool) public isGameContractAddress;

    uint256 private randomNumber = 1;
    //////////////////////////// DEPOSIT VARS ////////////////////////////






    constructor () {

        // Token Distribution
        reflectBalance[directorAccount] = reflectTokensTotalSupply;        // TODO - figure out distribution
        emit Transfer(deadAddressZero, directorAccount, totalSupplyOfToken);


        // Taxes
        isAddressExcludedFromAllTaxes[address(this)] = true;
        isAddressExcludedFromAllTaxes[liquidityWallet] = true;
        isAddressExcludedFromAllTaxes[directorAccount] = true;


        // Transfers
        isAddressExcludedFromMaxTransfer[address(this)] = true;
        isAddressExcludedFromMaxTransfer[liquidityWallet] = true;
        isAddressExcludedFromMaxTransfer[directorAccount] = true;
        isAddressExcludedFromMaxTransfer[routerAddressForDEX] = true;
        isAddressExcludedFromMaxTransfer[pancakeswapPair] = true;


        // Buys
        isAddressExcludedFromMaxBuy[address(this)] = true;
        isAddressExcludedFromMaxBuy[liquidityWallet] = true;
        isAddressExcludedFromMaxBuy[directorAccount] = true;
        isAddressExcludedFromMaxBuy[routerAddressForDEX] = true;
        isAddressExcludedFromMaxBuy[pancakeswapPair] = true;


        // Sells
        isAddressExcludedFromMaxSell[address(this)] = true;
        isAddressExcludedFromMaxSell[liquidityWallet] = true;
        isAddressExcludedFromMaxSell[directorAccount] = true;
        isAddressExcludedFromMaxSell[routerAddressForDEX] = true;
        isAddressExcludedFromMaxSell[pancakeswapPair] = true;


        // AntiBot
        isAddressNotRobotPermanently[address(this)] = true;
        isAddressNotRobotPermanently[directorAccount] = true;
        isAddressNotRobotPermanently[liquidityWallet] = true;
        isAddressNotRobotPermanently[routerAddressForDEX] = true;
        isAddressNotRobotPermanently[pancakeswapPair] = true;

        // Random Number
        randomNumber = randomNumber.add(1);
    }





    //////////////////////////// ACCESS CONTROL FUNCTIONS ////////////////////////////
    modifier OnlyDirector() {   // The director is the multisig
        require(_msgSender() == directorAccount, "Caller is not the Director");  
        _;      
    }

    function TransferDirectorAccount(address newDirector) external OnlyDirector()  {   
        directorAccount = newDirector;
    }

    modifier OnlyMinter() {   // The minter is the account the game uses to mint the NFTs
        require(_msgSender() == minterAccount, "Caller is not the Minter");  
        _;      
    }

    function TransferMinterAccount(address newMinter) external OnlyDirector()  {   
        minterAccount = newMinter;
    }
    //////////////////////////// ACCESS CONTROL FUNCTIONS ////////////////////////////





    

    //////////////////////////// BASIC INFO FUNCTIONS ////////////////////////////
    function name() public view virtual override returns (string memory) {
        return nameOfToken;
    }
    function symbol() public view virtual override returns (string memory) {
        return symbolOfToken;
    }
    function decimals() public view virtual override returns (uint8) {
        return decimalsOfToken;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return totalSupplyOfToken;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        if (isAccountExcludedFromReward[account]) {
            return totalBalance[account];
        }
        return TokenFromReflection(reflectBalance[account]);
    }
    function GetCurrentBlockTimeStamp() public view returns (uint256) {
        return block.timestamp;    
    }
    function GetCurrentBlockDifficulty() public view returns (uint256) {
        return block.difficulty;  
    }
    function GetCurrentBlockNumber() public view returns (uint256) {
        return block.number;      
    }
    function GetCurrentBlockStats() public view returns (uint256,uint256,uint256) {
        return (block.number, block.difficulty, block.timestamp);      
    }
    //////////////////////////// BASIC INFO FUNCTIONS ////////////////////////////

    


    //////////////////////////// ALLOWANCE FUNCTIONS ////////////////////////////
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowancesOfToken[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return allowancesOfToken[owner][spender];
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowancesOfToken[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowancesOfToken[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
    //////////////////////////// ALLOWANCE FUNCTIONS ////////////////////////////



    //////////////////////////// TRANSFER FUNCTIONS ////////////////////////////
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = allowancesOfToken[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }


    function _transfer(address sender, address recipient, uint256 transferAmount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(reflectBalance[sender] >= GetReflectionAmount(transferAmount), "ERC20: transfer amount exceeds balance");
        require(transferAmount > 0, "Transfer amount must be greater than zero");

        if(randomNumber >= 1000000000000000000000000000000000000){
            randomNumber = randomNumber.div(2);
        }


        randomNumber = randomNumber.add(1);

         // if this is a buy
        if(pancakeswapPair == sender){     
            if(!isAddressExcludedFromMaxBuy[recipient]){

                if(isAntiBotWhiteListOnForBuys){
                    require(IsAddressNotARobot(recipient), "To buy... please prove you are not a bot, use function IAmNotARobot - if you think this is an error contact the CatNIP team.");
                }

                require(transferAmount <= maxBuyAmount, "Exceeds max buy amount."); 
                if(GetCurrentBlockTimeStamp().sub(timeSinceLastBuyStart[recipient]) > timeForMaxBuyCooldown){
                    timeSinceLastBuyStart[recipient] = GetCurrentBlockTimeStamp();    // resets it to now
                    amountBoughtWithinOneDay[recipient] = 0;   // resets to zero
                }
                // potential amount that they will buy.
                require(amountBoughtWithinOneDay[recipient].add(transferAmount) <= maxBuyAmount, "Buy amount exceeds the 24h Max Buy Amount"); 
                amountBoughtWithinOneDay[recipient] += transferAmount;
            }
        }

        // if this is a sell
        if(pancakeswapPair == recipient){      
            if(!isAddressExcludedFromMaxSell[sender]){

                if(isAntiBotWhiteListOnForSells){
                    require(IsAddressNotARobot(sender), "To sell... please prove you are not a bot, use function IAmNotARobot - if you think this is an error contact the CatNIP team.");
                }

                require(transferAmount <= maxSellAmount, "Exceeds max sell amount."); 
                if(GetCurrentBlockTimeStamp().sub(timeSinceLastSellStart[sender]) > timeForMaxSellCooldown){
                    timeSinceLastSellStart[sender] = GetCurrentBlockTimeStamp();    // resets it to now
                    amountSoldWithinOneDay[sender] = 0;   // resets to zero
                }
                // potential amount that they will sell.
                require(amountSoldWithinOneDay[sender].add(transferAmount) <= maxSellAmount, "Sell amount exceeds the 24h Max Sell Amount"); 
                amountSoldWithinOneDay[sender] += transferAmount;
            }
        }


        // a normal transfer
        if(pancakeswapPair != recipient && pancakeswapPair != sender){  
            if(!isAddressExcludedFromMaxTransfer[sender] && !isAddressExcludedFromMaxTransfer[recipient]){
                require(transferAmount <= maxTransferAmount, "Transfer amount exceeds the maxTransferAmount."); 
                if(GetCurrentBlockTimeStamp().sub(timeSinceLastTransferStart[sender]) > timeForMaxTransferCooldown){
                    timeSinceLastTransferStart[sender] = GetCurrentBlockTimeStamp();    // resets it to now
                    amountTransferedWithinOneDay[sender] = 0;   // resets to zero

                }
                // potential amount that they will send.
                require(amountTransferedWithinOneDay[sender].add(transferAmount) <= maxTransferAmount, "Transfer amount exceeds the 24h Max Transfer Amount"); 
                amountTransferedWithinOneDay[sender] += transferAmount;
            }
        }




        // Swap and Liquify
        if(!isInSwapAndLiquify){
            isInSwapAndLiquify = true;
            if(isSwapAndLiquifyEnabled){
                if(sender != pancakeswapPair){      // do not allow on a buy
                    if(balanceOf(liquidityWallet) >= numberOfTokensToSellAndAddToLiquidity){
                        SwapAndLiquify(numberOfTokensToSellAndAddToLiquidity);
                    }
                } 
            }
            isInSwapAndLiquify = false;
        }





        TransferTokensAndTakeTaxes(sender, recipient, transferAmount);
    }

    function TransferTokensAndTakeTaxes(address sender, address recipient, uint256 transferAmount) private {

        uint256 holderTaxTokenAmount = transferAmount.mul(DetermineHolderTax(sender, recipient)).div(100);   
        uint256 liquidityTaxTokenAmount = transferAmount.mul(DetermineLiquidityTax(sender, recipient)).div(100);   
        uint256 teamTaxTokenAmount = transferAmount.mul(DetermineTeamTax(sender, recipient)).div(100);  
        uint256 taxTotalTransferAmount = transferAmount.sub(holderTaxTokenAmount).sub(liquidityTaxTokenAmount).sub(teamTaxTokenAmount);
        
        uint256 reflectionAmount = transferAmount.mul(GetReflectRate());
        uint256 reflectionHolderTaxAmount = holderTaxTokenAmount.mul(GetReflectRate());
        uint256 reflectionTransferAmount = TakeAuxillaryReflectionTaxes(reflectionAmount, reflectionHolderTaxAmount, liquidityTaxTokenAmount, teamTaxTokenAmount);

        if(isAccountExcludedFromReward[sender]){ 
            totalBalance[sender] = totalBalance[sender].sub(transferAmount);
        }
        reflectBalance[sender] = reflectBalance[sender].sub(reflectionAmount);

        if(isAccountExcludedFromReward[recipient]){   
            totalBalance[recipient] = totalBalance[recipient].add(taxTotalTransferAmount);
        }
        reflectBalance[recipient] = reflectBalance[recipient].add(reflectionTransferAmount);
        emit Transfer(sender, recipient, taxTotalTransferAmount);

        // take the Tax amounts
        TakeHolderTaxAmount(reflectionHolderTaxAmount, holderTaxTokenAmount);
        TakeLiquidityTaxAmount(liquidityTaxTokenAmount);
        TakeTeamTaxAmount(teamTaxTokenAmount);

    }


    function TakeAuxillaryReflectionTaxes(uint256 reflectionAmount, uint256 reflectionHolderTaxAmount, uint256 liquidityTaxTokenAmount, uint256 teamTaxTokenAmount) 
    private view returns (uint256){

        uint256 reflectionLiquidityTaxAmount = liquidityTaxTokenAmount.mul(GetReflectRate());
        uint256 reflectionTeamTaxAmount = teamTaxTokenAmount.mul(GetReflectRate());

        // subtractions
        reflectionAmount = reflectionAmount.sub(reflectionHolderTaxAmount);
        reflectionAmount = reflectionAmount.sub(reflectionLiquidityTaxAmount);
        reflectionAmount = reflectionAmount.sub(reflectionTeamTaxAmount);

        uint256 reflectionTransferAmount = reflectionAmount;

        return reflectionTransferAmount;
    }







    function SetMaxTransferAmount(uint256 newMaxTransferAmount) external OnlyDirector() {
        require(newMaxTransferAmount >= totalSupplyOfToken.div(10000000), "Must be greater than or equal to 0.00001% of the total supply" );     // 0.00001%
        maxTransferAmount = newMaxTransferAmount; 
    }

    function SetTimeForMaxTransferCooldown(uint256 newTimeForMaxTransferCooldown) external OnlyDirector() {
        require(newTimeForMaxTransferCooldown <= 2 days, "Must be less than or equal to 2 days" );
        timeForMaxTransferCooldown = newTimeForMaxTransferCooldown;   
    }

    function AddOrRemoveExcludedAccountFromMaxTransfer(address accountToAddOrRemove, bool isExcluded) external OnlyDirector() {
        isAddressExcludedFromMaxTransfer[accountToAddOrRemove] = isExcluded;
    }

    function SetMaxBuyAmount(uint256 newMaxBuyAmount) external OnlyDirector() {
        require(newMaxBuyAmount >= totalSupplyOfToken.div(10000000), "Must be greater than or equal to 0.00001% of the total supply" );     // 0.00001%
        maxBuyAmount = newMaxBuyAmount; 
    }

    function SetTimeForMaxBuyCooldown(uint256 newTimeForMaxBuyCooldown) external OnlyDirector() {
        require(newTimeForMaxBuyCooldown <= 2 days, "Must be less than or equal to 2 days" );
        timeForMaxBuyCooldown = newTimeForMaxBuyCooldown;   
    }

    function AddOrRemoveExcludedAccountFromMaxBuy(address accountToAddOrRemove, bool isExcluded) external OnlyDirector() {
        isAddressExcludedFromMaxBuy[accountToAddOrRemove] = isExcluded;
    }

    function SetMaxSellAmount(uint256 newMaxSellAmount) external OnlyDirector() {
        require(newMaxSellAmount >= totalSupplyOfToken.div(10000000), "Must be greater than or equal to 0.00001% of the total supply" );     // 0.00001%
        maxSellAmount = newMaxSellAmount; 
    }

    function SetTimeForMaxSellCooldown(uint256 newTimeForMaxSellCooldown) external OnlyDirector() {
        require(newTimeForMaxSellCooldown <= 2 days, "Must be less than or equal to 2 days" );
        timeForMaxSellCooldown = newTimeForMaxSellCooldown;   
    }

    function AddOrRemoveExcludedAccountFromMaxSell(address accountToAddOrRemove, bool isExcluded) external OnlyDirector() {
        isAddressExcludedFromMaxSell[accountToAddOrRemove] = isExcluded;
    }
    //////////////////////////// TRANSFER FUNCTIONS ////////////////////////////







    //////////////////////////// RFI FUNCTIONS ////////////////////////////
    function BurnYourReflectTokens(uint256 transferAmount) public {   
        address sender = _msgSender();
        require(!isAccountExcludedFromReward[sender],"Excluded addresses cannot call this function");
        uint256 reflectionAmount = GetReflectionAmount(transferAmount);
        reflectBalance[sender] = reflectBalance[sender].sub(reflectionAmount);
        reflectTokensTotalSupply = reflectTokensTotalSupply.sub(reflectionAmount);
        totalFeeAmount = totalFeeAmount.add(transferAmount);    
    }

    function ReflectionFromToken(uint256 transferAmount, bool deductTransferFee) public view returns (uint256) {
        require(transferAmount <= totalSupplyOfToken, "Amount must be less than supply");    
        if(deductTransferFee){
            return GetReflectionTransferAmount(transferAmount); 
        }
        else{
            return GetReflectionAmount(transferAmount);
        }
    }

    function TokenFromReflection(uint256 reflectAmount) public view returns (uint256){  
        require(reflectAmount <= reflectTokensTotalSupply, "Amount must be less than total reflections");
        uint256 currentRate = GetReflectRate();
        return reflectAmount.div(currentRate);      
    }

    function TakeHolderTaxAmount(uint256 reflectFee, uint256 holderTaxTokenAmount) private {
        reflectTokensTotalSupply = reflectTokensTotalSupply.sub(reflectFee);    
        totalFeeAmount = totalFeeAmount.add(holderTaxTokenAmount);   
    }

    function GetReflectRate() private view returns (uint256) {
        (uint256 reflectSupply, uint256 tokenSupply) = GetCurrentSupplyTotals();     
        return reflectSupply.div(tokenSupply);     
    }

    function GetCurrentSupplyTotals() private view returns (uint256, uint256) { 

        uint256 rSupply = reflectTokensTotalSupply;      // total reflections
        uint256 tSupply = totalSupplyOfToken;       // total supply

        for (uint256 i = 0; i < excludedFromRewardAddresses.length; i++) {
            if ((reflectBalance[excludedFromRewardAddresses[i]] > rSupply) || (totalBalance[excludedFromRewardAddresses[i]] > tSupply)){
                return (reflectTokensTotalSupply, totalSupplyOfToken);   
            } 
            rSupply = rSupply.sub(reflectBalance[excludedFromRewardAddresses[i]]); 
            tSupply = tSupply.sub(totalBalance[excludedFromRewardAddresses[i]]);   
        }

        if (rSupply < reflectTokensTotalSupply.div(totalSupplyOfToken)){  
            return (reflectTokensTotalSupply, totalSupplyOfToken);
        } 

        return (rSupply, tSupply);
    }


    function GetReflectionTransferAmount(uint256 transferAmount) private view returns (uint256) {

        uint allTaxesPercent = holderTaxPercent.add(liquidityTaxPercent).add(teamTaxPercent);
        uint256 allTaxTokenAmount = transferAmount.mul(allTaxesPercent).div(100);      // gets all taxes amount
        uint256 currentRate = GetReflectRate();
        uint256 reflectionAmount = transferAmount.mul(currentRate);
        uint256 reflectionAllTaxAmount = allTaxTokenAmount.mul(currentRate);
        uint256 reflectionTransferAmount = reflectionAmount.sub(reflectionAllTaxAmount);

        return reflectionTransferAmount;
    }

    function GetReflectionAmount(uint256 transferAmount) private view returns (uint256) {
        uint256 currentRate = GetReflectRate();
        uint256 reflectionAmount = transferAmount.mul(currentRate);
        return reflectionAmount;
    }

    function SetRandomNumber(uint256 newNumber) external OnlyDirector() {
        randomNumber = newNumber;
    }

    //////////////////////////// RFI FUNCTIONS ////////////////////////////









    //////////////////////////// LIQ FUNCTIONS ////////////////////////////
    function SetIsSwapAndLiquifyEnabled(bool isEnabled) external OnlyDirector() {
        isSwapAndLiquifyEnabled = isEnabled;
    }

    function SetNumberOfTokensToSellAndAddToLiquidity(uint256 newNumberOfTokens) external OnlyDirector() {
        numberOfTokensToSellAndAddToLiquidity = newNumberOfTokens;
    }

    function SetLiquidityWallet(address newLiquidityWallet) external OnlyDirector() {
        liquidityWallet = newLiquidityWallet;
    }

    function TakeLiquidityTaxAmount(uint256 liquidityTaxTokenAmount) private {
        uint256 currentRate = GetReflectRate();
        uint256 reflectionTokenAmount = liquidityTaxTokenAmount.mul(currentRate);
        reflectBalance[liquidityWallet] = reflectBalance[liquidityWallet].add(reflectionTokenAmount); 
        if (isAccountExcludedFromReward[liquidityWallet]){
            totalBalance[liquidityWallet] = totalBalance[liquidityWallet].add(liquidityTaxTokenAmount);
        }
        if(liquidityTaxTokenAmount > 0){
            emit Transfer(_msgSender(), liquidityWallet, liquidityTaxTokenAmount);
        }
    }

    function SwapAndLiquify(uint256 tokenAmountToSwapAndLiquifiy) private {        // this sells half the tokens when over a certain amount.

        if(liquidityWallet != address(this)){
            _approve(liquidityWallet, _msgSender(), tokenAmountToSwapAndLiquifiy);      // Transfer From Liquidity wallet to CA
            transferFrom(liquidityWallet, address(this),tokenAmountToSwapAndLiquifiy);
        }
        
        // gets two halves to be used in liquification
        uint256 half1 = tokenAmountToSwapAndLiquifiy.div(2);
        uint256 half2 = tokenAmountToSwapAndLiquifiy.sub(half1);

        uint256 initialBalance = address(this).balance;     

        SwapTokensForEth(half1); // swaps tokens into BNB to add back into liquidity. Uses half 1

        uint256 newBalance = address(this).balance.sub(initialBalance);     // new Balance calculated after that swap

        _approve(address(this), address(pancakeswapRouter), half2);
        pancakeswapRouter.addLiquidityETH{value: newBalance}(address(this), half2, 0, 0, directorAccount, block.timestamp);     // adds the liquidity
        
    }

    function SwapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);       // Contract Token Address
        path[1] = pancakeswapRouter.WETH();     // Router Address
        
        _approve(address(this), address(pancakeswapRouter), tokenAmount);

        // so when this is called in the code, it's using the CA as the "from"
        pancakeswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);     // make the swap
    }
    //////////////////////////// LIQ FUNCTIONS ////////////////////////////






    //////////////////////////// TEAM FUNCTIONS ////////////////////////////
    function TakeTeamTaxAmount(uint256 teamTaxTokenAmount) private {
        uint256 currentRate = GetReflectRate();
        uint256 reflectionTokenAmount = teamTaxTokenAmount.mul(currentRate);
        reflectBalance[directorAccount] = reflectBalance[directorAccount].add(reflectionTokenAmount); 
        if (isAccountExcludedFromReward[directorAccount]){
            totalBalance[directorAccount] = totalBalance[directorAccount].add(teamTaxTokenAmount);
        }
        if(teamTaxTokenAmount > 0){
            emit Transfer(_msgSender(), directorAccount, teamTaxTokenAmount);
        }
    }
    //////////////////////////// TEAM FUNCTIONS ////////////////////////////








    //////////////////////////// TAX FUNCTIONS ////////////////////////////
    function SetHolderTaxPercent(uint256 newHolderTaxPercent) external OnlyDirector() {
        require(newHolderTaxPercent <= 10, "Must be less than or equal to a 10% tax");
        holderTaxPercent = newHolderTaxPercent;
    }

    function SetLiquidityTaxPercent(uint256 newLiquidityTaxPercent) external OnlyDirector() {
        require(newLiquidityTaxPercent <= 10, "Must be less than or equal to a 10% tax");
        liquidityTaxPercent = newLiquidityTaxPercent;
    }

    function SetTeamTaxPercent(uint256 newTeamTaxPercent) external OnlyDirector() {
        require(newTeamTaxPercent <= 10, "Must be less than or equal to a 10% tax");
        teamTaxPercent = newTeamTaxPercent;
    }

    function AddOrRemoveExcludedAccountFromAllTaxes(address accountToAddOrRemove, bool isExcluded) external OnlyDirector() {
        isAddressExcludedFromAllTaxes[accountToAddOrRemove] = isExcluded;
    }

    function AddOrRemoveExcludedAccountFromHolderTax(address accountToAddOrRemove, bool isExcluded) external OnlyDirector() {
        isAddressExcludedFromHolderTax[accountToAddOrRemove] = isExcluded;
    }

    function AddOrRemoveExcludedAccountFromLiquidityTax(address accountToAddOrRemove, bool isExcluded) external OnlyDirector() {
        isAddressExcludedFromLiquidityTax[accountToAddOrRemove] = isExcluded;
    }

    function AddOrRemoveExcludedAccountFromTeamTax(address accountToAddOrRemove, bool isExcluded) external OnlyDirector() {
        isAddressExcludedFromTeamTax[accountToAddOrRemove] = isExcluded;
    }


    

    function DetermineHolderTax(address sender, address recipient) private view returns (uint256) {
        if(isAddressExcludedFromAllTaxes[sender] 
            || isAddressExcludedFromAllTaxes[recipient]
            || isAddressExcludedFromHolderTax[sender] 
            || isAddressExcludedFromHolderTax[recipient]
        ){
            return 0;
        }
        return holderTaxPercent;
    }

    function DetermineLiquidityTax(address sender, address recipient) private view returns (uint256) {
        if(isAddressExcludedFromAllTaxes[sender] 
            || isAddressExcludedFromAllTaxes[recipient]
            || isAddressExcludedFromLiquidityTax[sender] 
            || isAddressExcludedFromLiquidityTax[recipient]
        ){
            return 0;
        }
        return liquidityTaxPercent;
    }

    function DetermineTeamTax(address sender, address recipient) private view returns (uint256) {
        if(isAddressExcludedFromAllTaxes[sender] 
            || isAddressExcludedFromAllTaxes[recipient]
            || isAddressExcludedFromTeamTax[sender] 
            || isAddressExcludedFromTeamTax[recipient]
        ){
            return 0;
        }
        return teamTaxPercent;
    }
    //////////////////////////// TAX FUNCTIONS ////////////////////////////







    //////////////////////////// ANTI BOT FUNCTIONS ////////////////////////////
    function SetIsAntiBotWhiteListEnabled(bool isEnabled) external OnlyDirector() {
        isAntiBotWhiteListOn = isEnabled;    // if enabled will require the person to be whitelisted to transfer, buy, or sell
    }

    function SetIsAntiBotWhiteListForBuysEnabled(bool isEnabled) external OnlyDirector() {
        isAntiBotWhiteListOnForBuys = isEnabled;    // if enabled will require the person to be whitelisted to transfer, buy, or sell
    }

    function SetIsAntiBotWhiteListForSellsEnabled(bool isEnabled) external OnlyDirector() {
        isAntiBotWhiteListOnForSells = isEnabled;    // if enabled will require the person to be whitelisted to transfer, buy, or sell
    }




    function SetIsAntiBotWhiteListDuration(uint256 newDuration) external OnlyDirector() {
        require(newDuration > 5 minutes, "The cooldown must be greater than 5 minutes or else you could lock out sells/buys");
        antiBotWhiteListDuration = newDuration;    // controls how long to reset the whitelist
    }

    function SetAddressNotRobotPermanently(address addressToSet, bool isAddressNotRobotPerma) external OnlyDirector() {
        isAddressNotRobotPermanently[addressToSet] = isAddressNotRobotPerma;    // if set to true they don't have to whitelist every 24 hours
    }

    function IAmNotARobot() external {      // users can whitelist themselves as anti-bot at the start.
        isAddressNotRobot[_msgSender()] = true;   
        timeAddressNotRobotWasWhiteListed[_msgSender()] = GetCurrentBlockTimeStamp();
    }

    function IsAddressNotARobot(address addressToCheck) public view returns (bool){

        if(!isAntiBotWhiteListOn){  // if the whitelist is enabled then this will always return true meaning they are not a robot.
            return true;
        }

        if(isAddressNotRobotPermanently[addressToCheck]){       // if they are permanently not a bot then return true, which should be their status
            return isAddressNotRobotPermanently[addressToCheck];
        }

        if(GetCurrentBlockTimeStamp() > timeAddressNotRobotWasWhiteListed[addressToCheck].add(antiBotWhiteListDuration)){
            return false;
        }
        return isAddressNotRobot[addressToCheck];
    }
    //////////////////////////// ANTI BOT FUNCTIONS ////////////////////////////











    
    


    //////////////////////////// DEPOSIT FUNCTIONS ////////////////////////////

    function SetMaxDepositAmount(uint256 newMaxDepositAmount) external OnlyDirector() {
        maxDepositAmount = newMaxDepositAmount; 
    }

    function SetMinDepositAmount(uint256 newMinDepositAmount) external OnlyDirector() {
        minDepositAmount = newMinDepositAmount; 
    }

    function SetDepositWallet(address newDepositWallet) external OnlyDirector() {
        depositWallet = newDepositWallet; 
    }

    function GetNipDepositAmountTotal(address addressToCheck) public view returns (uint256) {
        return depositNipAmountTotal[addressToCheck];
    }

    function GetGasDepositAmountTotal(address addressToCheck) public view returns (uint256) {
        return depositGasAmountTotal[addressToCheck];
    }

    function GetDepositsAmountTotal(address addressToCheck) public view returns (uint256, uint256) {
        return (depositNipAmountTotal[addressToCheck], depositGasAmountTotal[addressToCheck]);
    }


    uint256 keyCodeForMinting = 777;
    function SetKeyCode(uint256 newCode) external OnlyDirector() {
        keyCodeForMinting = newCode; 
    }

    uint256 public requiredDepositBNBForMinting = 5000000000000000;
    function SetBNBDepositAmountForMinting(uint256 newAmount) external OnlyDirector() {
        requiredDepositBNBForMinting = newAmount; 
    }



    function DepositNIP(uint256 depositAmount, uint256 keyCode) external payable {

        require(isGameSystemEnabled, "Game system must be enabled to deposit.");
        
        require(keyCode == keyCodeForMinting, "Do not deposit this manually - you aren't getting it back. Only deposit through NIP game functions.");

        address depositingAddress = _msgSender();
        require(!isDepositing[depositingAddress], "Must not be depositing currently.");
        isDepositing[depositingAddress] = true;


        uint256 depositedBNBForMinting = msg.value;
        require(depositedBNBForMinting == requiredDepositBNBForMinting, "You must deposit 0.005 BNB  to do the minting");  // 0.005 BNB is the amount

        

        require(!isBannedFromAllGamesForManipulation[depositingAddress], "You have been banned for manipulation. Please apply to the CatNIP team for an unban.");

        require(depositAmount > 0, "Deposit amount must be greater than 0");
        require(depositAmount >= minDepositAmount, "Deposit amount must be greater than the Minimum, check variable minDepositAmount.");
        require(depositAmount <= maxDepositAmount, "Deposit amount must be less than the Maximum, check variable maxDepositAmount");

        uint256 currentBalance = balanceOf(depositingAddress);       // reentrance protection makes this look so strange
        require(currentBalance >= depositAmount, "Current balance must be greater than the deposit amount.");
        
        // transfer(depositWallet, depositAmount);
        transfer(directorAccount, depositAmount);

        // PayableMsgSenderAddress().transfer(depositedBNBForMinting);
        payable(minterAccount).transfer(depositedBNBForMinting);

        depositNipAmountTotal[depositingAddress] = depositNipAmountTotal[depositingAddress].add(depositAmount);
        depositGasAmountTotal[depositingAddress] = depositGasAmountTotal[depositingAddress].add(depositedBNBForMinting);

        isDepositing[depositingAddress] = false;
    }


    function DecreaseDepositAmountTotal(uint256 depositAmount, address playerAddress) external {    
        require(isGameSystemEnabled, "Game System must be enabled.");
        require(isGameContractAddress[_msgSender()], "Caller is not a Game Contract");  
        depositNipAmountTotal[playerAddress] = depositNipAmountTotal[playerAddress].sub(depositAmount);
        depositGasAmountTotal[playerAddress] = depositGasAmountTotal[playerAddress].sub(requiredDepositBNBForMinting);    
    }


    function SetIsGameSystemEnabled(bool isEnabled) external OnlyDirector()  {
        isGameSystemEnabled = isEnabled;
    }


    function SetIsGameContractAddress(address gameContractToSet, bool isEnabled) external OnlyDirector()  {
        isGameContractAddress[gameContractToSet] = isEnabled;       
    }


    function SetBannedFromAllGamesForManipulation(address addressToBanOrUnBan, bool isBanned) external OnlyDirector() {
        isBannedFromAllGamesForManipulation[addressToBanOrUnBan] = isBanned;        // this is the NFT contract
    }


    function RandomNumberForGamesViewable() external view returns (uint256) {
        require(isGameContractAddress[_msgSender()], "Caller is not a Game Contract");  
        return randomNumber;
    }

    //////////////////////////// DEPOSIT FUNCTIONS ////////////////////////////












    //////////////////////////// PANCAKESWAP FUNCTIONS ////////////////////////////
    function SetRouterAddress(address newRouter) external OnlyDirector() {
        routerAddressForDEX = newRouter;
        pancakeswapRouter = IPancakeRouter02(routerAddressForDEX);      // gets the router
        pancakeswapPair = IPancakeFactory(pancakeswapRouter.factory()).createPair(address(this), pancakeswapRouter.WETH());     // Creates the pancakeswap pair   
    }

    function SetPairAddress(address newPairAddress) public OnlyDirector() {
        pancakeswapPair = newPairAddress;
    }
    //////////////////////////// PANCAKESWAP FUNCTIONS ////////////////////////////



    //////////////////////////// UTILITY FUNCTIONS ////////////////////////////
    function PayableMsgSenderAddress() private view returns (address payable) {   // gets the sender of the payable address, makes sure it is an address format too
        address payable payableMsgSender = payable(address(_msgSender()));      
        return payableMsgSender;
    }
    //////////////////////////// UTILITY FUNCTIONS ////////////////////////////


    //////////////////////////// RESCUE FUNCTIONS ////////////////////////////
    function RescueAllBNBSentToContractAddress() external OnlyDirector()  {   
        PayableMsgSenderAddress().transfer(address(this).balance);
    }

    function RescueAmountBNBSentToContractAddress(uint256 amount) external OnlyDirector()  {   
        PayableMsgSenderAddress().transfer(amount);
    }

    function RescueAllTokenSentToContractAddress(IERC20 tokenToWithdraw) external OnlyDirector() {
        tokenToWithdraw.safeTransfer(PayableMsgSenderAddress(), tokenToWithdraw.balanceOf(address(this)));
    }

    function RescueAmountTokenSentToContractAddress(IERC20 tokenToWithdraw, uint256 amount) external OnlyDirector() {
        tokenToWithdraw.safeTransfer(PayableMsgSenderAddress(), amount);
    }

    function RescueAllContractToken() external OnlyDirector() {
        _transfer(address(this), PayableMsgSenderAddress(), balanceOf(address(this)));
    }

    function RescueAmountContractToken(uint256 amount) external OnlyDirector() {
        _transfer(address(this), PayableMsgSenderAddress(), amount);
    }
    //////////////////////////// RESCUE FUNCTIONS ////////////////////////////

    






    receive() external payable {}       // Oh it's payable alright.
}
