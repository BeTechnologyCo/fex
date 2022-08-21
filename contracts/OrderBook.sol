// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./OrderDexToken.sol";
import "./IWETH.sol";
import "./TransferHelper.sol";

/**
 * @notice There are some conditions to make this work
 *
 *  - Trader needs to have approval of the users BREWERY
 *  - Helper should be able to burn xMEAD
 *  - Helper should be able to award reputation
 *
 */
contract OrderBook is Ownable, AccessControlEnumerable {
    enum OrderStatus {
        Active,
        Canceled,
        Sold,
        SoldAndCanceled
    }

    struct Order {
        uint256 id;
        OrderStatus status;
        uint256 feeAmount;
        uint256 amountToSell;
        uint256 amountToBuy;
        uint256 amountToSellCompleted;
        uint256 amountToBuyCompleted;
        address trader;
        address tokenToSell;
        address tokenToBuy;
        uint256 timestamp;
        bool fromETH;
        bool toETH;
    }

    OrderDexToken public immutable nativeToken;
    IWETH public immutable WETH;
    // todo configurable fee
    uint256 public creationFee = 2 * 10**18;

    /// @notice A mapping from order id to order data
    /// @dev This is a static, ever increasing list
    mapping(uint256 => Order) public orders;

    /// @notice The amount of orders
    uint256 public orderCount;

    event OrderAdded(
        uint256 indexed id,
        address indexed trader,
        Order orderInfo
    );

    event Sold(
        uint256 indexed orderIdA,
        uint256 indexed orderIdB,
        address indexed trader,
        uint256 amount,
        bool filled
    );

    event OrderCanceled(uint256 indexed id, bool partiallySold);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MATCHER_ROLE = keccak256("MATCHER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(OrderDexToken _nativeToken, IWETH _weth) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(MATCHER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        nativeToken = _nativeToken;
        WETH = _weth;
    }

    receive() external payable {}

    function rewardfee(uint256 _fee) public pure returns (uint256) {
        // todo configurable reward fee
        return _fee / 2;
    }

    // function withdraw() external payable onlyOwner {
    //     payable(owner()).transfer(address(this).balance);
    // }

    // function withdrawToken(address token) external payable onlyOwner {
    //     IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    // }

    /**
     * @notice Creates an order, transfering into th
     */
    function createOrderFromETH(address tokenToBuy, uint256 amountToBuy)
        external
        payable
    {
        require(msg.value > 0, "You need to sell more than 0 token");
        require(amountToBuy > 0, "You need to buy more than 0 token");

        IWETH(WETH).deposit{value: msg.value}();

        // no fee on native token
        if (creationFee > 0 && tokenToBuy != address(nativeToken)) {
            TransferHelper.safeTransferFrom(
                address(nativeToken),
                _msgSender(),
                address(this),
                creationFee
            );
        }

        // Create the order
        orders[orderCount] = Order({
            id: orderCount,
            feeAmount: creationFee,
            status: OrderStatus.Active,
            amountToSell: msg.value,
            amountToBuy: amountToBuy,
            amountToSellCompleted: 0,
            amountToBuyCompleted: 0,
            tokenToSell: address(WETH),
            tokenToBuy: tokenToBuy,
            trader: _msgSender(),
            timestamp: block.timestamp,
            fromETH: true,
            toETH: false
        });

        emit OrderAdded(orderCount, _msgSender(), orders[orderCount]);

        orderCount++;
    }

    /**
     * @notice Creates an order, transfering into th
     */
    function createOrder(
        address tokenToSell,
        address tokenToBuy,
        uint256 amountToSell,
        uint256 amountToBuy,
        bool toETH
    ) external {
        require(amountToSell > 0, "You need to sell more than 0 token");
        require(amountToBuy > 0, "You need to buy more than 0 token");

        if (toETH) {
            require(tokenToBuy == address(WETH), "Wrong weth address");
        }

        // no fee on native token
        if (
            creationFee > 0 &&
            tokenToBuy != address(nativeToken) &&
            tokenToSell != address(nativeToken)
        ) {
            TransferHelper.safeTransferFrom(
                address(nativeToken),
                _msgSender(),
                address(this),
                creationFee
            );
        }

        uint256 balanceBefore = IERC20(tokenToSell).balanceOf(address(this));

        TransferHelper.safeTransferFrom(
            tokenToSell,
            _msgSender(),
            address(this),
            amountToSell
        );

        uint256 balanceAfter = IERC20(tokenToSell).balanceOf(address(this));

        // todo support fee token
        require(
            balanceAfter - balanceBefore >= amountToSell,
            "Didn't support tax token"
        );

        // Create the order
        orders[orderCount] = Order({
            id: orderCount,
            feeAmount: creationFee,
            status: OrderStatus.Active,
            amountToSell: amountToSell,
            amountToBuy: amountToBuy,
            amountToSellCompleted: 0,
            amountToBuyCompleted: 0,
            tokenToSell: tokenToSell,
            tokenToBuy: tokenToBuy,
            trader: _msgSender(),
            timestamp: block.timestamp,
            fromETH: false,
            toETH: toETH
        });

        emit OrderAdded(orderCount, _msgSender(), orders[orderCount]);

        orderCount++;
    }

    /**
     * @notice Updates the price of a listed orders
     */
    function sellOrder(uint256 orderId, uint256[] calldata ordersMatches)
        external
        onlyRole(MATCHER_ROLE)
    {
        Order storage orderA = orders[orderId];
        require(
            orderA.status == OrderStatus.Active,
            "Order A is no longer available!"
        );
        require(ordersMatches.length > 0, "No match");

        uint256 amountToBuyA = orderA.amountToBuy - orderA.amountToBuyCompleted;
        require(amountToBuyA > 0, "Not enough token in the order A");

        uint256 priceByTokenA = orderA.amountToBuy / orderA.amountToSell;

        for (uint256 index = 0; index < ordersMatches.length; index++) {
            Order storage orderB = orders[ordersMatches[index]];
            require(
                orderB.status == OrderStatus.Active,
                "Order B is no longer available!"
            );
            require(
                orderB.tokenToBuy == orderA.tokenToSell &&
                    orderB.tokenToSell == orderA.tokenToBuy,
                "Token doesn't match"
            );
            uint256 amountToSellB = orderB.amountToSell -
                orderB.amountToSellCompleted;
            require(amountToSellB > 0, "Not enough token in the order B");

            uint256 priceByTokenB = orderB.amountToSell / orderA.amountToBuy;
            require(priceByTokenA >= priceByTokenB, "Price to high");

            uint256 amountTransfered = amountToBuyA;
            if (amountToBuyA > amountToSellB) {
                amountTransfered = amountToSellB;
            }

            uint256 amountFromAToB = amountTransfered / priceByTokenA;

            _sellTranfer(orderA, amountTransfered);

            orderA.amountToBuyCompleted += amountTransfered;
            orderB.amountToSellCompleted += amountTransfered;

            _sellTranfer(orderB, amountFromAToB);

            orderA.amountToSellCompleted += amountFromAToB;
            orderB.amountToBuyCompleted += amountFromAToB;

            bool filledA = orderA.amountToBuyCompleted == orderA.amountToBuy;
            bool filledB = orderB.amountToBuyCompleted == orderB.amountToBuy;

            emit Sold(
                orderA.id,
                orderB.id,
                orderA.trader,
                amountTransfered,
                filledA
            );
            emit Sold(
                orderB.id,
                orderA.id,
                orderB.trader,
                amountFromAToB,
                filledB
            );

            if (filledB) {
                orderB.status = OrderStatus.Sold;
                _rewardTrader(orderB);
            }

            if (filledA) {
                orderA.status = OrderStatus.Sold;
                _rewardTrader(orderA);
                return;
            }
        }
    }

    function _sellTranfer(Order storage order, uint256 amount) private {
        if (order.toETH) {
            TransferHelper.safeTransferETH(order.trader, amount);
        } else {
            uint256 balanceBefore = IERC20(order.tokenToBuy).balanceOf(
                order.trader
            );
            TransferHelper.safeTransfer(order.tokenToBuy, order.trader, amount);
            uint256 balanceAfter = IERC20(order.tokenToBuy).balanceOf(
                order.trader
            );
            // todo support tax token
            require(
                balanceAfter - balanceBefore >= amount,
                "Didn't support tax token"
            );
        }
    }

    function _rewardTrader(Order storage order) private {
        if (order.feeAmount > 0) {
            uint256 reward = rewardfee(order.feeAmount);
            if (reward > 0) {
                nativeToken.transfer(order.trader, reward);
            }
            if (reward < order.feeAmount) {
                uint256 burnFee = order.feeAmount - reward;
                nativeToken.burn(burnFee);
            }
        }
    }

    /**
     * @notice Cancels a currently listed order, returning the BREWERY to the owner
     */
    function cancelOrder(uint256 orderId) external payable {
        Order storage order = orders[orderId];
        require(
            order.status == OrderStatus.Active,
            "Order is no longer available!"
        );
        require(
            order.trader == _msgSender(),
            "Only the seller can cancel order"
        );

        // Mark order
        bool sold = order.amountToBuyCompleted > 0;
        if (sold) {
            order.status = OrderStatus.SoldAndCanceled;
        } else {
            order.status = OrderStatus.Canceled;
        }

        if (order.feeAmount > 0) {
            // burn all fee
            nativeToken.burn(order.feeAmount);
        }

        uint256 amount = order.amountToSell - order.amountToSellCompleted;

        if (order.fromETH) {
            TransferHelper.safeTransferETH(order.trader, amount);
        } else {
            TransferHelper.safeTransfer(order.tokenToBuy, order.trader, amount);
        }

        emit OrderCanceled(orderId, sold);
    }

    function fetchPageOrders(uint256 cursor, uint256 howMany)
        public
        view
        returns (Order[] memory values, uint256 newCursor)
    {
        uint256 length = howMany;
        if (length > orderCount - cursor) {
            length = orderCount - cursor;
        }

        values = new Order[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = orders[cursor + i];
        }

        return (values, cursor + length);
    }
}
