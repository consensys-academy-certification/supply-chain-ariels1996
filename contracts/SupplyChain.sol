// Implement the smart contract SupplyChain following the provided instructions.
// Look at the tests in SupplyChain.test.js and run 'truffle test' to be sure that your contract is working properly.
// Only this file (SupplyChain.sol) should be modified, otherwise your assignment submission may be disqualified.

pragma solidity ^0.5.0;

contract SupplyChain {

  constructor() public { owner = msg.sender; }
  address payable owner;

  // Create a variable named 'itemIdCount' to store the number of items and also be used as reference for the next itemId.
  uint itemIdCount = 0;

  // Create an enumerated type variable named 'State' to list the possible states of an item (in this order): 'ForSale', 'Sold', 'Shipped' and 'Received'.
  enum State {
    ForSale,
    Sold,
    Shipped,
    Received
  }

  // Create a struct named 'Item' containing the following members (in this order): 'name', 'price', 'state', 'seller' and 'buyer'.
  struct Item {
    string name;
    uint256 price;
    State state;
    address payable seller;
    address payable buyer;
  }

  // Create a variable named 'items' to map itemIds to Items.
  mapping(uint=>Item) items;

  // Create an event to log all state changes for each item.
  event ItemStateLog(
    uint indexed itemId,
    string itemName,
    uint price,
    State itemState,
    address payable seller,
    address payable buyer
  );

  // Create a modifier named 'onlyOwner' where only the contract owner can proceed with the execution.
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  // Create a modifier named 'checkState' where the execution can only proceed if the respective Item of a given itemId is in a specific state.
  modifier checkState(uint _itemId, State _state) {
    require(items[_itemId].state == _state);
    _;
  }

  // Create a modifier named 'checkCaller' where only the buyer or the seller (depends on the function) of an Item can proceed with the execution.
  modifier checkCaller(address _caller) {
    require(msg.sender == _caller);
    _;
  }

  // Create a modifier named 'checkValue' where the execution can only proceed if the caller sent enough Ether to pay for a specific Item or fee.
  modifier checkValue(uint256 _value) {
     require(msg.value >= _value);
     _;
   }


  // Create a function named 'addItem' that allows anyone to add a new Item by paying a fee of 1 finney.
  // Any overpayment amount should be returned to the caller. All struct members should be mandatory except the buyer.
  function addItem(string memory _name, uint256 _price) public payable checkValue(1 finney) returns (uint) {
    uint itemId = itemIdCount++;
    uint256 changes = msg.value - (1 finney);

    items[itemId].name = _name;
    items[itemId].price = _price;
    items[itemId].state = State.ForSale;
    items[itemId].seller = msg.sender;
    items[itemId].buyer = address(0);

    emit ItemStateLog(itemId, items[itemId].name, items[itemId].price, items[itemId].state, items[itemId].seller, items[itemId].buyer);

    if (changes > 0)
      msg.sender.transfer(changes);

    return itemId;
  }

  // Create a function named 'buyItem' that allows anyone to buy a specific Item by paying its price. The price amount should be transferred to the seller and any overpayment amount should be returned to the buyer.
  function buyItem(uint _itemId) public payable checkState(_itemId, State.ForSale) checkValue(items[_itemId].price)  {
    uint256 changes = msg.value - items[_itemId].price;
    address payable seller = items[_itemId].seller;

    items[_itemId].state = State.Sold;
    items[_itemId].buyer = msg.sender;

    emit ItemStateLog(_itemId, items[_itemId].name, items[_itemId].price, items[_itemId].state, items[_itemId].seller, items[_itemId].buyer);

    seller.transfer(items[_itemId].price);
    if (changes > 0)
      msg.sender.transfer(changes);
  }

  // Create a function named 'shipItem' that allows the seller of a specific Item to record that it has been shipped.
  function shipItem(uint _itemId) public checkState(_itemId, State.Sold) checkCaller(items[_itemId].seller)  {
   items[_itemId].state = State.Shipped;
   emit ItemStateLog(_itemId, items[_itemId].name, items[_itemId].price, items[_itemId].state, items[_itemId].seller, items[_itemId].buyer);

  }

  // Create a function named 'receiveItem' that allows the buyer of a specific Item to record that it has been received.
  function receiveItem(uint _itemId) public checkState(_itemId, State.Shipped) checkCaller(items[_itemId].buyer)  {
      items[_itemId].state = State.Received;
      emit ItemStateLog(_itemId, items[_itemId].name, items[_itemId].price, items[_itemId].state, items[_itemId].seller, items[_itemId].buyer);

  }

  // Create a function named 'getItem' that allows anyone to get all the information of a specific Item in the same order of the struct Item.
  function getItem(uint _itemId) public view returns (string memory, uint256, State, address, address) {
    require(_itemId < itemIdCount);
    return (
      items[_itemId].name,
      items[_itemId].price,
      items[_itemId].state,
      items[_itemId].seller,
      items[_itemId].buyer
      );
  }

  // Create a function named 'withdrawFunds' that allows the contract owner to withdraw all the available funds.
  function withdrawFunds() public onlyOwner() {
    require(address(this).balance > 0);
    owner.transfer(address(this).balance);
  }

}
