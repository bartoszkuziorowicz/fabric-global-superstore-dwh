# Microsoft Fabric Global Superstore Data Warehouse

End-to-end dimensional data warehouse built in Microsoft Fabric, including data ingestion, dimensional modeling, incremental loading, pipeline orchestration, auditing and error handling.

## Project Overview

The goal of this project was to design and implement a complete dimensional data warehouse based on the Global Superstore dataset.

The project started with a raw CSV file and gradually evolved into an automated incremental loading process in Microsoft Fabric.

The solution covers:

- CSV ingestion through a Fabric Lakehouse
- Warehouse staging layer
- Data profiling and grain analysis
- Star schema design
- Business and surrogate keys
- Dimension and fact tables
- Initial DWH load
- Incremental loading
- SQL stored procedures
- Parameterized Fabric Data Pipeline
- Audit logging
- Success and failure handling
- Post-load validation

## Architecture

The overall data flow is:

`CSV -> Lakehouse Files -> Fabric Data Pipeline -> Warehouse Staging -> Dimensions -> FactSales`

Incremental processing extends the flow with orchestration and auditing:

`New CSV Batch -> Audit Start -> TRUNCATE CurrentBatch -> Copy Data -> Load Dimensions -> Load FactSales -> Audit Success`

If the Copy Data activity fails:

`Copy Data -> On Failure -> Audit Failed`

## Technologies

- Microsoft Fabric
- Fabric Lakehouse
- OneLake
- Fabric Warehouse
- Fabric Data Pipelines
- T-SQL
- Stored Procedures
- Dimensional Data Modeling
- GitHub

## Data Ingestion

Raw CSV files are uploaded to the `Files` section of a Microsoft Fabric Lakehouse.

The Lakehouse acts as the landing zone for source files stored in OneLake.

A Fabric Copy Data activity moves the currently selected CSV batch from the Lakehouse into the reusable Warehouse staging table:

`staging.GlobalSuperStore_CurrentBatch`

The staging layer preserves the raw source representation before data is transformed into the dimensional model.

## Data Profiling and Grain

Before creating the dimensional model, the source data was analyzed to determine the correct grain and business keys.

### FactSales

`Order ID` was tested first but was not unique because a single order can contain multiple product lines.

`Row ID` was then validated as unique.

Final FactSales grain:

**One FactSales row represents one order line and is uniquely identified by RowID.**

### Customer

Business key:

`CustomerID`

Validation confirmed that a CustomerID consistently identifies the customer attributes used in the dimension.

### Product

`ProductID` alone was not sufficient to uniquely identify the required product representation.

Final business key:

`ProductID + ProductName`

### Geography

The source system does not contain a dedicated GeographyID.

The dimension is therefore identified using the composite business key:

`City + State + Country + Market + Region`

## Dimensional Model

The Warehouse follows a star schema design.

### Dimensions

- `dim.dimCustomer`
- `dim.dimProduct`
- `dim.dimGeography`
- `dim.dimShipMode`
- `dim.dimOrderPriority`
- `dim.dimDate`

### Fact

- `fact.FactSales`

Dimension tables use surrogate keys generated in the Warehouse.

Examples:

- `CustomerKey`
- `ProductKey`
- `GeographyKey`
- `ShipModeKey`
- `OrderPriorityKey`

`dimDate` uses an integer `DateKey` in `YYYYMMDD` format instead of an identity value.

The date dimension covers the period from 2011 through 2030 and is reused for both:

- `OrderDateKey`
- `ShipDateKey`

## Initial Load

During the initial DWH load, dimensions are populated before the fact table.

The load pattern is:

`Staging -> Dimensions -> Surrogate Keys -> FactSales`

Business keys from staging are used to locate dimension records and retrieve their surrogate keys.

For example:

```sql
INNER JOIN dim.dimProduct AS p
    ON p.ProductID = s.[Product ID]
    AND p.ProductName = s.[Product Name]
```

The resulting `ProductKey` is stored in `FactSales`.

The same pattern is applied to the other dimensions.

## Incremental Load

Incremental processing uses one reusable staging table:

`staging.GlobalSuperStore_CurrentBatch`

Before every load the table is cleared:

```sql
TRUNCATE TABLE staging.GlobalSuperStore_CurrentBatch;
```

The new CSV batch is then loaded into the same staging table.

New dimension members are detected using `NOT EXISTS`.

Example:

```sql
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
```

Dimensions are always processed before `FactSales`, ensuring that new dimension members already have surrogate keys when the fact table is loaded.

## Incremental Fact Load

After dimension processing, business keys from the current batch are mapped to surrogate keys using joins.

New fact rows are protected against duplicate loading using the FactSales grain:

```sql
WHERE NOT EXISTS
(
    SELECT 1
    FROM fact.FactSales AS f
    WHERE f.RowID = CONVERT(BIGINT, s.[Row ID])
);
```

Because `RowID` defines the grain of `FactSales`, the same source row cannot be loaded multiple times.

The incremental logic is implemented in:

`dbo.usp_LoadIncremental`

## Fabric Data Pipeline

The final pipeline orchestrates the complete incremental loading process:

`StartLoadAudit -> TruncateCurrentBatch -> LH_to_DW -> LoadIncrementalDWH -> EndTimeAudit`

The pipeline uses several Fabric activities:

- Stored Procedure activity
- Script activity
- Copy Data activity
- Success dependencies
- Failure dependency

A detailed description of the pipeline is available in:

[Fabric Data Pipeline documentation](docs/pipeline.md)

## Pipeline Parameterization

The pipeline uses the parameter:

`FileName`

The Copy Data source references it through dynamic content:

`@pipeline().parameters.FileName`

Example runtime value:

`Global_Superstore_Batch4.csv`

This makes the pipeline reusable for future batches without modifying the Copy Data activity or incremental stored procedure.

## Audit Logging

Each monitored load is recorded in:

`audit.LoadAudit`

The table contains:

- `LoadID`
- `StartTime`
- `EndTime`
- `Status`

At the beginning of a load:

`audit.usp_StartLoad`

creates
