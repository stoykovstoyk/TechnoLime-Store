// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Store {
    
    address Owner;
    uint Products;
    uint Orders;
    uint constant ALLOWED_RETURN_PERIOD = 100;

    event Purchase(uint _id);
    event NewProduct(uint _id);
    event ProductUpdate(string _name, uint _id);
    event ProductReturn(uint _id);

    constructor(){
        Owner = msg.sender;
    }    

    struct Product {
        string name;
        uint quantity;
        uint price;
    }

    struct Order{
        address buyer;
        uint productId;
        uint quantity;
        uint blockNumber;
    }

    mapping(uint => Product ) public products;
    mapping(uint => Order) public ordersByClient;

    modifier onlyAdmin{
        require(msg.sender == Owner, "you are not admin, you are not authorized to add products");
        _;
    }

    function buyProduct(uint _productId, uint _quantity) payable public {
        for (uint i; i<=Orders; i++){
            require(msg.sender != ordersByClient[i].buyer, "you alreade bought this product. you can buy only once");
        }       

        require(_quantity > 0, "please enter amount greater then zero.");
        require(msg.value == _quantity * products[_productId].price, "received amount less then required to buy this product. please send more eth" );
        require(products[_productId].quantity >= _quantity, "order qty exceed available qty.");

        ordersByClient[Orders] = Order({
            buyer: msg.sender,
            productId: _productId,
            quantity: _quantity,
            blockNumber: block.number
        });

        emit Purchase(Orders);

        Orders += 1;

        products[_productId].quantity -= _quantity;     
    }
     
    address[] addressList;
    function showClientsByProduct(uint _id) public returns(address[] memory){  
        address[] memory tempAddrlist;
        addressList = tempAddrlist;

        for (uint i; i<=Orders; i++){
            if(ordersByClient[i].productId == _id && ordersByClient[i].buyer != address(0) ){
                addressList.push(ordersByClient[i].buyer);
            }
        }    
        return (addressList);
    }

    function addProduct(string calldata _name, uint _quantity, uint _price) public onlyAdmin{  
        for (uint i; i<= Products; i++){
            require(keccak256(abi.encodePacked(products[i].name)) != keccak256(abi.encodePacked(_name)), "Product exists, not allowed to add same product again. Update product quantity instead");
        }

        products[Products] = Product({
            name: _name,
            quantity: _quantity,
            price: _price
        });  

        emit NewProduct(Products);
        
        Products +=1;
    }

    function updateProductQty(uint _id, uint _qty) public onlyAdmin{
        products[_id].quantity = _qty; 
        emit ProductUpdate(products[_id].name, _qty);
    }

    function showProductDetails(uint _productId) public view returns(string memory, uint, uint){         
         return (products[_productId].name ,products[_productId].quantity, products[_productId].price);
    }    

    function returnProduct(uint _orderId) payable public{
        uint _productId = ordersByClient[_orderId].productId;
        require (block.number - ordersByClient[_orderId].blockNumber <= ALLOWED_RETURN_PERIOD, "return period expired, not allowed to return the product");
        products[_productId].quantity += ordersByClient[_orderId].quantity;
        
        uint returnAmount = ordersByClient[_orderId].quantity * products[_productId].price;
        (bool sendSuccess, ) = address(msg.sender).call{value: returnAmount}("");
        require(sendSuccess, "refund failed");

        delete ordersByClient[_orderId];
     
        emit ProductReturn(_orderId);
    }

    function getStoreBalance() external view returns(uint){
        return address(this).balance;
    }    

}