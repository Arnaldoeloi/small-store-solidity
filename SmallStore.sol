// SPDX-License-Identifier: MIT
// Arnaldo Souza
pragma solidity ^0.8.11; //necessary for return array of structs

contract SmallStore {

    address payable public owner;

    struct Product {
        uint id;
        string name;
        uint price;
        string img_link;
        uint8 stock; //We'll keep this limitation of 255 of stock.
        bool canBeBought; //Essentially, this is a flag for deleting. It won't show the product on the front store no more if it's false.
    }

    struct Purchase{
        uint[] productId;
        uint8[] amounts;
        uint paid;
        uint256 date;
    }

    mapping (address => Purchase[]) private purchases; // Each address can buy several products at different amounts each time.
    mapping (uint => Product) public productIds; // Each product has it's id.
    
    Product [] public products;

    event NewProductStored(Product product);
    event PurchaseWasMade(uint256 indexed id, Purchase, address indexed buyer);


    constructor(){
		owner =  payable(msg.sender);
	}

	modifier onlyOwner {
		require(msg.sender == owner, "Only the owner can execute this function.");
		_;
	}

    function storeProduct(string memory name, uint price, string memory img_link, uint8 stock) public onlyOwner{
        Product memory product = Product(products.length,name,price,img_link,stock,true);
        products.push(product);
        productIds[products.length]=product;
        emit NewProductStored(product);
    }

    function buyProduct(uint productId, uint8 amount) internal{
        require(products[productId].canBeBought, "This product can't be bought.");
        require(products[productId].stock>0, "This item's stock is over.");
        require(amount >= 1, "You can't buy less than one unit of any product.");
        require(amount <= products[productId].stock, "There's not so many products on stock at the moment.");
        products[productId].stock -= amount; 
    }

    function buyProducts(uint[] memory _products, uint8[] memory _amounts) public payable{
        uint total = 0;
        for (uint i = 0; i < _products.length; i++) {
            total+=products[_products[i]].price*_amounts[i];
            require(products[_products[i]].stock>=_amounts[i], "There's not so many products on stock at the moment.");
        }
        require(total==msg.value, "You don't have the necessary amount of ethers to complete the transaction.");    
        for (uint i = 0; i < _products.length; i++) {
            buyProduct(_products[i], _amounts[i]);
        }
        Purchase memory purchase = Purchase(_products, _amounts, total, block.timestamp);
        purchases[msg.sender].push(purchase);
        emit PurchaseWasMade(purchases[msg.sender].length,purchase,msg.sender); 
    }

    function removeProduct(uint _productId) public onlyOwner returns(Product memory) {
        products[_productId].canBeBought = false;
        return products[_productId];
    }

    function editProduct(uint _productId, string memory name, uint price, string memory img_link, uint8 stock, bool _canBeBought) public onlyOwner returns(Product memory){
        products[_productId] = Product(_productId,name,price,img_link,stock,_canBeBought);
        return products[_productId];
    }

    function getMyPurchases() external view returns(Purchase[] memory) {
        return purchases[msg.sender];
    }

    function withdraw() external onlyOwner{
        require(address(this).balance>0, "The contract needs to have more than 0 balance so the owner can be able to withdraw.");
        owner.transfer(address(this).balance);
    }

    function getAllProducts() external view returns(Product[] memory){
        return products;
    }


    


}