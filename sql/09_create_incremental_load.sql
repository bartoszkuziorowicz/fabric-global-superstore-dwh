/* =========================================================
   INCREMENTAL DWH LOAD

   Source: staging.GlobalSuperStore_CurrentBatch

   Process:
   1. Insert new dimension members
   2. Resolve surrogate keys
   3. Insert new FactSales rows

   FactSales grain: One row = one RowID
   ========================================================= */


/* =========================================================
   DIM CUSTOMER
   Business key: CustomerID
   ========================================================= */

CREATE PROCEDURE dbo.usp_LoadIncremental
AS
BEGIN

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
    FROM staging.GlobalSuperStore_CurrentBatch AS s
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dim.dimCustomer AS c
        WHERE c.CustomerID = s.[Customer ID]
    );


    /* =====================================================
       DIM PRODUCT
       Business key: ProductID + ProductName
       ===================================================== */

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
    FROM staging.GlobalSuperStore_CurrentBatch AS s
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dim.dimProduct AS p
        WHERE p.ProductID = s.[Product ID]
          AND p.ProductName = s.[Product Name]
    );


    /* =====================================================
       DIM GEOGRAPHY
       Business key:
       City + State + Country + Market + Region
       ===================================================== */

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
    FROM staging.GlobalSuperStore_CurrentBatch AS s
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dim.dimGeography AS g
        WHERE g.City = s.City
          AND g.State = s.State
          AND g.Country = s.Country
          AND g.Market = s.Market
          AND g.Region = s.Region
    );


    /* =====================================================
       DIM SHIP MODE
       Business key: ShipMode
       ===================================================== */

    INSERT INTO dim.dimShipMode
    (
        ShipMode
    )
    SELECT DISTINCT
        s.[Ship Mode]
    FROM staging.GlobalSuperStore_CurrentBatch AS s
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dim.dimShipMode AS sm
        WHERE sm.ShipMode = s.[Ship Mode]
    );


    /* =====================================================
       DIM ORDER PRIORITY
       Business key: OrderPriority
       ===================================================== */

    INSERT INTO dim.dimOrderPriority
    (
        OrderPriority
    )
    SELECT DISTINCT
        s.[Order Priority]
    FROM staging.GlobalSuperStore_CurrentBatch AS s
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dim.dimOrderPriority AS op
        WHERE op.OrderPriority = s.[Order Priority]
    );


    /* =====================================================
       FACT SALES
       Grain: one RowID = one order line
       ===================================================== */

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
        CONVERT(BIGINT, s.[Row ID]),
        s.[Order ID],
        c.CustomerKey,
        p.ProductKey,
        g.GeographyKey,
        sm.ShipModeKey,
        op.OrderPriorityKey,
        od.DateKey,
        sd.DateKey,
        CONVERT(DECIMAL(18, 2), s.Sales),
        CONVERT(INT, s.Quantity),
        CONVERT(DECIMAL(10, 4), s.Discount),
        CONVERT(DECIMAL(18, 2), s.Profit),
        CONVERT(DECIMAL(18, 2), s.[Shipping Cost])
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
        ON CONVERT(DATE, s.[Order Date], 105) = od.[Date]

    INNER JOIN dim.dimDate AS sd
        ON CONVERT(DATE, s.[Ship Date], 105) = sd.[Date]

    WHERE NOT EXISTS
    (
        SELECT 1
        FROM fact.FactSales AS f
        WHERE f.RowID = CONVERT(BIGINT, s.[Row ID])
    );

END;
