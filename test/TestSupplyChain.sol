pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

contract TestSupplyChain {

    string name = 'books';
    uint price = 1000 wei;
    uint public initialBalance = 1 ether;
    SupplyChain instance; //= SupplyChain(DeployedAddresses.SupplyChain());

    function beforeEach() public{
        instance = new SupplyChain();   
    }

    // Test for failing conditions in this contracts:
    // https://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests

    //addItem
    function testAddItem() public{
        bool success = instance.addItem(name, price);
        Assert.equal(success, true, "should add an Item successfuly");
    }

    // function testfetchItem() public{
    //     bool success = instance.addItem(name, price);
    //     (string memory expectedname,, 
    //     uint expectedprice, 
    //     uint expectedstate, 
    //     address seller, 
    //     address buyer) = instance.fetchItem(0);
    //     Assert.equal(expectedname, name, "The item's name should be given name");
    //     Assert.equal(expectedprice, price, "The item's price should be given price");
    //     Assert.equal(expectedstate, 0, "The item's should be for sale");
    //     Assert.equal(seller, this, "This contract should be the seller");
    //     //Assert.equal(buyer, address(0), "There should be no buyer yet");
    // }

    // buyItem
    function testBuyItem() public{
        instance.addItem(name, price);
        instance.buyItem.value(2000)(0);
        (,,, uint xstate,,) = instance.fetchItem(0);
        Assert.equal(xstate, 1, "Should have a Sold state");
    }
    // test for failure if user does not send enough funds
    function testBuyWithInadequateFunds() public{
        instance.addItem(name, price);
        bool success  = true;
        
        (success, ) = address(instance).call.value(500)(abi.encodeWithSelector(instance.buyItem.selector, 0));
        Assert.isFalse(success, "Item was bought with inadequate funds");
    }
    // test for purchasing an item that is not for Sale
    function testBuyNotForSale() public{
        instance.addItem(name, price);
        bool success  = true;

        (success, ) = address(instance).call.value(1000)(abi.encodeWithSelector(instance.buyItem.selector, 1));
        Assert.isFalse(success, "Item which was not for sale was bought");
    }

    // shipItem
    function testShipItem() public{
        instance.addItem(name, price);
        instance.buyItem.value(2000)(0);
        instance.shipItem(0);

        (,,, uint xstate,,) = instance.fetchItem(0);
        Assert.equal(xstate, 2, "Should have a Shipped state");
    }
    // test for calls that are made by not the seller
    function testShipByNonSeller() public{
        instance.addItem(name, price);
        instance.buyItem.value(2000)(0);

        bool success  = true;
        (success, ) = address(instance).delegatecall(abi.encodeWithSelector(instance.shipItem.selector, 0));
        Assert.isFalse(success, "Item was shipped by NonOwner");
    }
    // test for trying to ship an item that is not marked Sold
    function testShipNotForSale() public{
        instance.addItem(name, price);
        instance.buyItem.value(2000)(0);

        bool success  = true;
        (success, ) = address(instance).call(abi.encodeWithSelector(instance.shipItem.selector, 1));
        Assert.isFalse(success, "Item which was NOTFORSALE was shipped");
    }
    // receiveItem
    function testReceiveItem() public{
        instance.addItem(name, price);
        instance.buyItem.value(2000)(0);
        instance.shipItem(0);
        instance.receiveItem(0);

        (,,, uint xstate,,) = instance.fetchItem(0);
        Assert.equal(xstate, 3, "Should have a Recieved state");
    }

    // test calling the function from an address that is not the buyer
    function testRecieveByNonSeller() public{
        instance.addItem(name, price);
        instance.buyItem.value(2000)(0);
        instance.shipItem(0);
        instance.receiveItem(0);

        bool success  = true;
        (success, ) = address(instance).delegatecall(abi.encodeWithSelector(instance.receiveItem.selector, 0));
        Assert.isFalse(success, "Item was received by NonOwner");
    }
    // test calling the function on an item not marked Shipped
    function testRecieveNotForSale() public{
        instance.addItem(name, price);
        instance.buyItem.value(2000)(0);
        instance.shipItem(0);
        instance.receiveItem(0);

        bool success  = true;
        (success, ) = address(instance).call(abi.encodeWithSelector(instance.receiveItem.selector, 1));
        Assert.isFalse(success, "Item NOTFORSALE was received");
    }

    function() payable external{}

}
