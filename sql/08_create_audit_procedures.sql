/* =========================================
   START LOAD AUDIT
   ========================================= */

CREATE PROCEDURE audit.usp_StartLoad
AS
BEGIN

    INSERT INTO audit.LoadAudit
    (
        StartTime,
        Status
    )
    VALUES
    (
        GETDATE(),
        'Running'
    );

END;


/* =========================================
   END LOAD AUDIT - SUCCESS
   ========================================= */

CREATE PROCEDURE audit.usp_EndLoad
AS
BEGIN

    UPDATE audit.LoadAudit
    SET
        EndTime = GETDATE(),
        Status = 'Success'
    WHERE Status = 'Running';

END;


/* =========================================
   END LOAD AUDIT - FAILURE
   ========================================= */

CREATE PROCEDURE audit.usp_FailLoad
AS
BEGIN

    UPDATE audit.LoadAudit
    SET
        EndTime = GETDATE(),
        Status = 'Failed'
    WHERE Status = 'Running';

END;
