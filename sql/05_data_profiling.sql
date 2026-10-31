-- Check whether OrderID can define the FactSales grain (finally NO)

SELECT
    [Order ID],
    COUNT(*) AS RowCount
FROM staging.GlobalSuperStore
GROUP BY [Order ID]
HAVING COUNT(*) > 1;


-- Check whether RowID uniquely identifies each sales line

SELECT
    [Row ID],
    COUNT(*) AS RowCount
FROM staging.GlobalSuperStore
GROUP BY [Row ID]
HAVING COUNT(*) > 1;


-- Validate CustomerID as the Customer business key

SELECT
    [Customer ID],
    COUNT(DISTINCT [Customer Name]) AS CustomerNameCount,
    COUNT(DISTINCT Segment) AS SegmentCount
FROM staging.GlobalSuperStore
GROUP BY [Customer ID]
HAVING
       COUNT(DISTINCT [Customer Name]) > 1
    OR COUNT(DISTINCT Segment) > 1;


-- Check whether ProductID alone is sufficient

SELECT
    [Product ID],
    COUNT(DISTINCT [Product Name]) AS ProductNameCount
FROM staging.GlobalSuperStore
GROUP BY [Product ID]
HAVING COUNT(DISTINCT [Product Name]) > 1;


-- Validate ProductID + ProductName as the Product business key

SELECT
    [Product ID],
    [Product Name],
    COUNT(DISTINCT Category) AS CategoryCount,
    COUNT(DISTINCT [Sub-Category]) AS SubCategoryCount
FROM staging.GlobalSuperStore
GROUP BY
    [Product ID],
    [Product Name]
HAVING
       COUNT(DISTINCT Category) > 1
    OR COUNT(DISTINCT [Sub-Category]) > 1;


-- Checking Geography combinations

SELECT
    City,
    State,
    Country,
    Market,
    Region,
    COUNT(*) AS SourceRows
FROM staging.GlobalSuperStore
GROUP BY
    City,
    State,
    Country,
    Market,
    Region
ORDER BY SourceRows DESC;
