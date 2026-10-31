/* =========================================================
   DWH VALIDATION

   Post-load checks used to validate:
   - FactSales grain
   - duplicate RowIDs
   - dimension mappings
   - current staging batch size
   ========================================================= */


/* 1. Validate FactSales grain */

SELECT
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT RowID) AS UniqueRowIDs
FROM fact.FactSales;


/* 2. Check for duplicate RowIDs */

SELECT
    RowID,
    COUNT(*) AS RowCount
FROM fact.FactSales
GROUP BY RowID
HAVING COUNT(*) > 1;


/* 3. Check current batch size */

SELECT
    COUNT(*) AS CurrentBatchRows
FROM staging.GlobalSuperStore_CurrentBatch;


/* 4. Validate dimension mappings */

SELECT
    COUNT(*) AS MissingDimensionMappings
FROM staging.GlobalSuperStore_CurrentBatch AS s

LEFT JOIN dim.dimCustomer AS c
    ON c.CustomerID = s.[Customer ID]

LEFT JOIN dim.dimProduct AS p
    ON p.ProductID = s.[Product ID]
    AND p.ProductName = s.[Product Name]

LEFT JOIN dim.dimGeography AS g
    ON g.City = s.City
    AND g.State = s.State
    AND g.Country = s.Country
    AND g.Market = s.Market
    AND g.Region = s.Region

LEFT JOIN dim.dimShipMode AS sm
    ON sm.ShipMode = s.[Ship Mode]

LEFT JOIN dim.dimOrderPriority AS op
    ON op.OrderPriority = s.[Order Priority]

LEFT JOIN dim.dimDate AS od
    ON CONVERT(DATE, s.[Order Date], 105) = od.[Date]

LEFT JOIN dim.dimDate AS sd
    ON CONVERT(DATE, s.[Ship Date], 105) = sd.[Date]

WHERE c.CustomerKey IS NULL
   OR p.ProductKey IS NULL
   OR g.GeographyKey IS NULL
   OR sm.ShipModeKey IS NULL
   OR op.OrderPriorityKey IS NULL
   OR od.DateKey IS NULL
   OR sd.DateKey IS NULL;


/* 5. Audit history */

SELECT *
FROM audit.LoadAudit
ORDER BY StartTime DESC;
