//GNU 3.0
//MEYERSNFT Land Drop Exchange - Potential NFT Marketplace Foundational Template

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//I'm also importing 1155 libs/(1155 compatibility) for instances when
//Meyers participants wish to mint multiple copies of their LandDrop Maps.  
//This is because the ERC(BEP)721 standard only supports a single-copy mint.

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

//Security import

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";


contract MEYERSNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address contractAddress;
    
    constructor(address marketplaceAddress) ERC721("MEYERS LANDDROP EXCHANGE", "MLX") {
        contractAddress = marketplaceAddress;
    }
    
    function createToken(string memory tokenURI) public returns (uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(contractAddress, true);
        return newItemId;
    }
}

//MarketPlace Contract
//(see ReentrancyGuard imported lib above)
//ReentrancyGuard is a security protocol offered in the openzeppelin-contracts library.

contract MEYERSEXCHANGE is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    
    address payable owner;
    uint256 listingPrice = 10 ether;
    
    constructor() {
        owner = payable(msg.sender);
    }
    
    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
    }
    
    mapping(uint256 => MarketItem) private idToMarketItem;
    
    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price
        );
        
  //THis is another area where parameters will be adjusted to suit our specific needs
  
  
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
        ) public payable nonReentrant{
          require(price > 0, "Price must be at least one wei(Wallet Must Contain at Least One Meyers Token)");
          require(msg.value == listingPrice, "Price must be equal to listing price(Wallet Must Contain at Least One Meyers Token");
          
          _itemIds.increment();
          uint256 itemId = _itemIds.current();
          
          idToMarketItem[itemId] = MarketItem(
              itemId,
              nftContract,
              tokenId,
              payable(msg.sender),
              payable(address(0)),
              price
          );
          
          IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
          
          emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price
          );
    }

//This function facilitates the actual transaction.  
//Clearly we will need to modify the parameters a bit to suit our own purposes.

    function createMarketSale(
        address nftContract,
        uint256 itemId
        ) public payable nonReentrant {
            
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;
        
        require(msg.value == price, "Please submit at least the amount of asking price in order to complete the purchase");
        
        idToMarketItem[itemId].seller.transfer(msg.value);
        
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].owner = payable(msg.sender);
        _itemsSold.increment();
        payable(owner).transfer(listingPrice);
            
        }

//Displays available LandDrop Maps

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = itemCount - _itemsSold.current();
        uint currentIndex = 0;
        
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    
    function fetchMyNFTs() public view returns(MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }
        
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
















}
