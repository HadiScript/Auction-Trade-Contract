// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract Auction_Trade {
    struct Auction {
        uint256 id;
        address payable seller;
        string name;
        string description;
        uint256 min; // min offer
        uint256 end; // end date
        uint256 bestOfferId;
        uint256[] offerIds;
    }

    struct Offer {
        uint256 id;
        uint256 auctionId;
        address payable buyer;
        uint256 price;
    }

    mapping(uint256 => Auction) private auctions;
    mapping(uint256 => Offer) private offers;

    // user auctions, i mean here is my auction
    mapping(address => uint256[]) private userAuctions;
    mapping(address => uint256[]) private userOffers;

    uint256 private nextAuthctionId = 1;
    uint256 private nextOfferId = 1;

    function createAuction(
        string calldata _name,
        string calldata _description,
        uint256 _min,
        uint256 _duration
    ) external {
        require(_min > 0, "_min must be > 0");
        require(
            _duration > 86400 && _duration < 864000,
            "_duration must be comprised between 1 to 10 days"
        );
        uint256[] memory offerIds = new uint256[](0);
        auctions[nextAuthctionId] = Auction(
            nextAuthctionId,
            payable(msg.sender),
            _name,
            _description,
            _min,
            block.timestamp + _duration,
            0,
            offerIds
        );

        userAuctions[msg.sender].push(nextAuthctionId);
        nextAuthctionId++;
    }

    function createOffer(uint256 _auctionId)
        external
        payable
        auctionExists(_auctionId)
    {
        Auction storage auction = auctions[_auctionId]; //pointer
        Offer storage bestOffer = offers[auction.bestOfferId];
        require(block.timestamp < auction.end, "Auction has expired");
        require(
            msg.value >= auction.min && msg.value > bestOffer.price,
            "msg.value must be superior to min and bestOffer"
        );
        auction.bestOfferId = nextOfferId;
        auction.offerIds.push(nextOfferId);
        offers[nextOfferId] = Offer(
            nextOfferId,
            _auctionId,
            payable(msg.sender),
            msg.value
        );
        userOffers[msg.sender].push(nextOfferId);
        nextOfferId++;
    }

    function trade(uint256 _id) external auctionExists(_id) {
        Auction storage auction = auctions[_id]; //pointer
        Offer storage bestOffer = offers[auction.bestOfferId];

        require(block.timestamp > auction.end, "auction is still there");

        for (uint256 i = 0; i < auction.offerIds.length; i++) {
            uint256 offerId = auction.offerIds[i];
            // now we have to return all money that offered becourse they were not best
            if (offerId != auction.bestOfferId) {
                Offer storage offer = offers[offerId];
                offer.buyer.transfer(offer.price);
            }
        }

        auction.seller.transfer(bestOffer.price);
    }

    function getAuctions() external view returns (Auction[] memory) {
        Auction[] memory _auctions = new Auction[](nextAuthctionId - 1); // creating new array
        for (uint256 i = 1; i < nextAuthctionId + 1; i++) {
            _auctions[i - 1] = auctions[i];
        }
        return _auctions;
    }

    function getUserAuctions(address _user)
        external
        view
        returns (Auction[] memory)
    {
        uint256[] storage userAuctionIds = userAuctions[_user];
        Auction[] memory _auctions = new Auction[](userAuctionIds.length);
        for (uint256 i = 0; i < userAuctionIds.length; i++) {
            uint256 auctionId = userAuctionIds[i];
            _auctions[i] = auctions[auctionId];
        }
        return _auctions;
    }

    function getUserOffers(address _user)
        external
        view
        returns (Offer[] memory)
    {
        uint256[] storage userOfferIds = userOffers[_user];
        Offer[] memory _offers = new Offer[](userOfferIds.length);
        for (uint256 i = 0; i < userOfferIds.length; i++) {
            uint256 offerId = userOfferIds[i];
            _offers[i] = offers[offerId];
        }
        return _offers;
    }

    modifier auctionExists(uint256 _auctionId) {
        require(
            _auctionId > 0 && _auctionId < nextAuthctionId,
            "Auction does not exist"
        );
        _;
    }
}
