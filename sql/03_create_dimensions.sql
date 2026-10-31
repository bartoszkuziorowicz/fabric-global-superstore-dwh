CREATE TABLE dim.dimCustomer
(
    CustomerKey BIGINT IDENTITY NOT NULL,
    CustomerID VARCHAR(50) NOT NULL,
    CustomerName VARCHAR(200),
    Segment VARCHAR(100)
);

CREATE TABLE dim.dimProduct
(
    ProductKey BIGINT IDENTITY NOT NULL,
    ProductID VARCHAR(50) NOT NULL,
    ProductName VARCHAR(255) NOT NULL,
    Category VARCHAR(100),
    SubCategory VARCHAR(100)
);

CREATE TABLE dim.dimGeography
(
    GeographyKey BIGINT IDENTITY NOT NULL,
    City VARCHAR(100),
    State VARCHAR(100),
    Country VARCHAR(100),
    Market VARCHAR(100),
    Region VARCHAR(100)
);

CREATE TABLE dim.dimShipMode
(
    ShipModeKey BIGINT IDENTITY NOT NULL,
    ShipMode VARCHAR(50)
);


CREATE TABLE dim.dimOrderPriority
(
    OrderPriorityKey BIGINT IDENTITY NOT NULL,
    OrderPriority VARCHAR(50)
);


CREATE TABLE dim.dimDate
(
    DateKey INT NOT NULL,
    [Date] DATE NOT NULL,
    [Year] INT,
    [Quarter] INT,
    [Month] INT,
    MonthName VARCHAR(20),
    [Day] INT
);
