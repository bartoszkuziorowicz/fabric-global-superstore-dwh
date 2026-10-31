-- FACT SALES

-- Grain:
--  One row represents one order line, uniquely identified by RowID.

CREATE TABLE fact.FactSales
(
    RowID BIGINT NOT NULL,
    OrderID VARCHAR(50),

    CustomerKey BIGINT,
    ProductKey BIGINT,
    GeographyKey BIGINT,
    ShipModeKey BIGINT,
    OrderPriorityKey BIGINT,

    OrderDateKey INT,
    ShipDateKey INT,

    Sales DECIMAL(18, 2),
    Quantity INT,
    Discount DECIMAL(10, 4),
    Profit DECIMAL(18, 2),
    ShippingCost DECIMAL(18, 2)
);
