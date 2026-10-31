# Fabric Data Pipeline

The pipeline automates incremental loading of new Global Superstore data into the Fabric Warehouse.

Instead of creating a separate staging table for every new batch, the process uses one reusable table: `staging.GlobalSuperStore_CurrentBatch`

Before each load, the staging table is cleared and populated with the CSV file selected when the pipeline is started.

## Pipeline

The main flow is:

StartLoadAudit → TruncateCurrentBatch → LH_to_DW → LoadIncrementalDWH → EndTimeAudit

### StartLoadAudit

Starts the load and creates a new record in `audit.LoadAudit` with status `Running`.

It executes:

`audit.usp_StartLoad`

### TruncateCurrentBatch

Clears data left from the previous batch:
```sql
TRUNCATE TABLE staging.GlobalSuperStore_CurrentBatch;
```

This ensures that the staging table contains only the batch currently being processed.


### LH_to_DW

Copies the selected CSV file from the Fabric Lakehouse `Files` section into:

`staging.GlobalSuperStore_CurrentBatch`

The destination uses the existing staging table with `Insert` write behavior.

The source file name is provided through the pipeline parameter:

`FileName`

Dynamic content used in the Copy Data activity:

`@pipeline().parameters.FileName`

Example value:

`Global_Superstore_Batch4.csv`


### LoadIncrementalDWH

Executes:

`dbo.usp_LoadIncremental`

The stored procedure:

1. Detects and inserts new customers.
2. Detects and inserts new products.
3. Detects and inserts new geography members.
4. Detects and inserts new ship modes.
5. Detects and inserts new order priorities.
6. Resolves dimension business keys to surrogate keys.
7. Inserts new rows into `fact.FactSales`.

New dimension members and fact rows are detected using `NOT EXISTS`.

The FactSales incremental check uses `RowID`, because `RowID` defines the grain of the fact table.


### EndTimeAudit

Executed only after a successful incremental load.

It executes:

`audit.usp_EndLoad`

The procedure updates the active audit record:

```sql
UPDATE audit.LoadAudit
SET
    EndTime = GETDATE(),
    Status = 'Success'
WHERE Status = 'Running';
```


## Failure Handling

The `LH_to_DW` Copy Data activity also contains an `On failure` path.

If the source file cannot be loaded, the pipeline executes:

`audit.usp_FailLoad`

The procedure updates the audit record:

```sql
UPDATE audit.LoadAudit
SET
    EndTime = GETDATE(),
    Status = 'Failed'
WHERE Status = 'Running';
```

This failure path was tested using an invalid source file name. The Copy Data activity failed and the corresponding load was recorded with status `Failed`.


## Pipeline Parameter

The pipeline contains one parameter:

`FileName`

Example:

`Global_Superstore_Batch4.csv`

The Copy Data source references the parameter through:

`@pipeline().parameters.FileName`

This makes the pipeline reusable for future batches without changing the Copy Data activity or the SQL stored procedures.


## Final Pipeline Flow

Success path:

`StartLoadAudit -> TruncateCurrentBatch -> LH_to_DW -> LoadIncrementalDWH -> EndTimeAudit`

Failure path:

`LH_to_DW -> FailedLoad`


## Incremental Processing Pattern

The complete incremental process is:

`CSV file -> Lakehouse Files -> Pipeline -> CurrentBatch staging -> DIM first -> FACT second -> Audit`

Before each load, `CurrentBatch` is truncated and populated with the selected CSV file.

New dimension members are inserted first so that all required surrogate keys exist before loading `FactSales`.

Fact rows are inserted only when their `RowID` does not already exist in `fact.FactSales`.

## Pipeline overview

The final Microsoft Fabric pipeline:

<img width="1460" height="276" alt="image" src="https://github.com/user-attachments/assets/b15dfbf6-66cb-4577-8ded-dda4accd966e" />
