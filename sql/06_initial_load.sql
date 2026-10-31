/* =========================================================
   INITIAL DWH LOAD

   Prerequisite:
   The complete source CSV must first be loaded into:

   staging.GlobalSuperStore_CurrentBatch

   This script should be executed against empty dimension
   and fact tables.

   ========================================================= */


/* =========================================================
   1. DIM DATE

   Calendar range:
   2011-01-01 through 2030-12-31

   DateKey format:
   YYYYMMDD, for example:
   2015-03-01 -> 20150301
   ========================================================= */

DECLARE @StartDate DATE = '2011-01-01';
DECLARE @EndDate DATE = '2030-12-31';

INSERT INTO dim.dimDate
(
    DateKey,
    [Date],
    [Year],
    [Quarter],
    [Month],
    MonthName,
    [Day]
)
SELECT
    YEAR(d.[Date]) * 10000
        + MONTH(d.[Date]) * 100
        + DAY(d.[Date]) AS DateKey,
    d.[Date],
    YEAR(d.[Date]) AS [Year],
    DATEPART(QUARTER,d.[Date]) AS [Quarter],
    MONTH(d.[Date]) AS [Month],
    DATENAME(MONTH,d.[Date]) AS MonthName,
    DAY(d.[Date]) AS [Day]

FROM
(
    SELECT
        DATEADD(DAY, value, @StartDate) AS [Date]
    FROM GENERATE_SERIES(0, DATEDIFF(DAY, @StartDate, @EndDate))
) AS d;

/* =========================================================
   2. DIM CUSTOMER

   Grain: One row represents one customer.

   Business key: CustomerID
   ========================================================= */

INSERT INTO dim.dimCustomer
(
    CustomerID,
    CustomerName,
    Segment
)
SELECT DISTINCT
    s.[Customer ID],
    s.[Customer Name],
    s.Segment
FROM staging.GlobalSuperStore_CurrentBatch AS s;


/* =========================================================
   3. DIM PRODUCT

   Grain: One row represents one unique ProductID and ProductName
   combination.

   Business key: ProductID + ProductName
   ========================================================= */

INSERT INTO dim.dimProduct
(
    ProductID,
    ProductName,
    Category,
    SubCategory
)
SELECT DISTINCT
    s.[Product ID],
    s.[Product Name],
    s.Category,
    s.[Sub-Category]
FROM staging.GlobalSuperStore_CurrentBatch AS s;


/* =========================================================
   4. DIM GEOGRAPHY

   Grain and business key: City + State + Country + Market + Region
   ========================================================= */

INSERT INTO dim.dimGeography
(
    City,
    State,
    Country,
    Market,
    Region
)
SELECT DISTINCT
    s.City,
    s.State,
    s.Country,
    s.Market,
    s.Region
FROM staging.GlobalSuperStore_CurrentBatch AS s;


/* =========================================================
   5. DIM SHIP MODE

   Grain: One row represents one shipping method.

   Business key: ShipMode
   ========================================================= */

INSERT INTO dim.dimShipMode
(
    ShipMode
)
SELECT DISTINCT
    s.[Ship Mode]
FROM staging.GlobalSuperStore_CurrentBatch AS s;


/* =========================================================
   6. DIM ORDER PRIORITY

   Grain: One row represents one order priority.

   Business key: OrderPriority
   ========================================================= */

INSERT INTO dim.dimOrderPriority
(
    OrderPriority
)
SELECT DISTINCT
    s.[Order Priority]
FROM staging.GlobalSuperStore_CurrentBatch AS s;


/* =========================================================
   7. FACT SALES

   Grain:
   One row represents one order line,
   uniquely identified by RowID.

   The source business keys are matched to dimensions.
   Dimension surrogate keys are stored in FactSales.

   The staging data types are VARCHAR, so the source
   measures and dates are converted to their target types.
   ========================================================= */

INSERT INTO fact.FactSales
(
    RowID,
    OrderID,
    CustomerKey,
    ProductKey,
    GeographyKey,
    ShipModeKey,
    OrderPriorityKey,
    OrderDateKey,
    ShipDateKey,
    Sales,
    Quantity,
    Discount,
    Profit,
    ShippingCost
)
SELECT
    CONVERT(BIGINT, s.[Row ID]) AS RowID,

    s.[Order ID] AS OrderID,

    c.CustomerKey,
    p.ProductKey,
    g.GeographyKey,
    sm.ShipModeKey,
    op.OrderPriorityKey,

    od.DateKey AS OrderDateKey,
    sd.DateKey AS ShipDateKey,

    CONVERT(DECIMAL(18, 2),s.Sales) AS Sales,
    CONVERT(INT, s.Quantity) AS Quantity,
    CONVERT(DECIMAL(10, 4), s.Discount) AS Discount,
    CONVERT(DECIMAL(18, 2),s.Profit) AS Profit,
    CONVERT(DECIMAL(18, 2),s.[Shipping Cost]) AS ShippingCost

FROM staging.GlobalSuperStore_CurrentBatch AS s

INNER JOIN dim.dimCustomer AS c
    ON c.CustomerID = s.[Customer ID]

INNER JOIN dim.dimProduct AS p
    ON p.ProductID = s.[Product ID]
   AND p.ProductName = s.[Product Name]

INNER JOIN dim.dimGeography AS g
    ON g.City = s.City
   AND g.State = s.State
   AND g.Country = s.Country
   AND g.Market = s.Market
   AND g.Region = s.Region

INNER JOIN dim.dimShipMode AS sm
    ON sm.ShipMode = s.[Ship Mode]

INNER JOIN dim.dimOrderPriority AS op
    ON op.OrderPriority = s.[Order Priority]

INNER JOIN dim.dimDate AS od
    ON CONVERT(DATE,s.[Order Date],105) = od.[Date]

INNER JOIN dim.dimDate AS sd
    ON CONVERT(DATE,s.[Ship Date],105) = sd.[Date];
