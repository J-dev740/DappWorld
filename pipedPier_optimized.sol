// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TeamWallet is Ownable {
    using SafeMath for uint256;
    // mapping(address=>uint256) ApprovalToRequestNumber; 
    uint256 private transactionNumber;
    mapping(uint256=>uint256) private Approval;
    mapping(uint256=>uint256) private Rejection;
    mapping(uint256=>uint)  private isApproved;

    mapping(uint256=>uint256) private transactionNumberToAmount;
    mapping(address=>mapping(uint256=>uint256)) private addressToApproval;
    mapping(address=>mapping(uint256=>uint256)) private addressToRejection;

    address[]  private membersList;
    bool private executed;
    uint256 private win_credits;
    constructor(){
        executed=false;
        transactionNumber=0;
    }
        //modifier to execute function only once
        modifier onlyOnce() {
        require(!executed, "This function can only be executed once.");
        _;
        executed = true;
    }
        modifier onlyMember(address sender){
            bool  foundMember=false;
                for(uint256 i=0;i<membersList.length;i++){
                    if(membersList[i]==sender){
                        foundMember=true;
                        break ;
                    }
                }
                if(!foundMember){
                    revert("error_send:not a member");
                }
            _;

        }
        //modifier to check for approval or rejection
        modifier checkApproval(uint n){
            _;

            if(transactionNumberToAmount[n]>win_credits){
                isApproved[n]=2;
            }else
                 if(membersList.length==1){
                isApproved[n]=1;
                win_credits-=transactionNumberToAmount[n];
            }else 
                 if (Approval[n]>((membersList.length*70)/100)){
            isApproved[n]=1;
            win_credits -= transactionNumberToAmount[n];
            }
        }


        modifier checkRejection(uint n){
            _;
             if (Rejection[n]>((membersList.length*30)/100)){

            isApproved[n]=2;

        }
        }

    //For setting up the wallet
    function setWallet(address[] memory members, uint256 credit) public onlyOwner onlyOnce {
        if(!(credit>0)){
            revert("error:credits must be > 0");
        }
        address owner =msg.sender;
        address[] memory newEmptyArray = new address[](0);
            if(!(members.length>0)){
                revert("error_setWallet: no members array provided ");

            }else{
              for(uint256 i=0;i<members.length;i++){
                    if(members[i]==owner){
                        membersList=newEmptyArray;
                        revert("error:deployer in members list");
                    }
                    membersList.push(members[i]);
                }
            }
            win_credits=credit;

    }

    //For spending amount from the wallet
    function spend(uint256 amount) public checkApproval(transactionNumber+1)  onlyMember(msg.sender) {
        if(!(amount>0)){
            revert("error_send:enter a valid amount");
        }
        //record the transaction number 
        transactionNumber+=1;
        transactionNumberToAmount[transactionNumber]=amount;
        //default approval by that particular member
        Approval[transactionNumber] +=1;
        addressToApproval[msg.sender][transactionNumber] +=1;

    }

    //For approving a transaction request
    function approve(uint256 n) public onlyMember(msg.sender) checkApproval(n)  {
        //check if transaction amount is < win_credits
             if(transactionNumberToAmount[n]>win_credits){
                revert();

            }
            //check if the provided transaction exists
                    if(!(n<=transactionNumber) || n==0){
            revert("error:not a valid transaction");
        }
        //a Member can approve a transaction only once
        if(addressToApproval[msg.sender][n]==1){
            revert("error_approve:already approved");
            
        }
        else{

        //update approval for a particular transctionNumber by each member
            Approval[n] +=1;
            addressToApproval[msg.sender][n] +=1;

        }


    }

    //For rejecting a transaction request
    function reject(uint256 n) public checkRejection(n)  onlyMember(msg.sender){

        if(transactionNumberToAmount[n]>win_credits){
                revert();

            }
            //check if the provided transaction exists
        if(!(n<=transactionNumber) ||n==0){
            revert("error:not a valid transaction");
        }
        
        //revert if already approved by the calling member 

        if(addressToApproval[msg.sender][n]==1){
            revert("error_reject:already approved ");
        //a member can reject a transactionNumber (transaction) only once 
        } else if(addressToRejection[msg.sender][n]==1)
        {
            revert("error_reject:already rejected ");
        }
        //update Rejection for the specified transaction number 
        Rejection[n] +=1;
        //also update the addressToRejection mapping
        addressToRejection[msg.sender][n] +=1;
        //check rejection rate using modifier


    }

    //For checking remaing credits in the wallet
    function credits() onlyMember(msg.sender) public view returns (uint256) {
        //if a transaction is debited then some amount from it will be debited(status) 
        return win_credits;
    }

    //For checking nth transaction status
    function viewTransaction(uint256 n) public onlyMember(msg.sender) view   returns (uint amount,string memory status){

            //check if the provided transaction exists
        if(!(n<=transactionNumber) || n==0){
            revert("error:not a valid transaction");
        }

        amount=transactionNumberToAmount[n];
        if(isApproved[n]==1){
            status="debited";
        }
        else if(isApproved[n]==2){
            status="failed";
        }
        else{
            status="pending";
        }
    }

        //For checking the transaction stats for the wallet
    function transactionStats() public view onlyMember(msg.sender) returns (uint debitedCount,uint pendingCount,uint failedCount){

        for (uint256 i=1;i<=transactionNumber;i++)
        {
            if(isApproved[i]==1){
                debitedCount++;

            }else
                if(isApproved[i]==2){
                    failedCount++;

                }
                else{
                   pendingCount++;

                }
        }
    }



}