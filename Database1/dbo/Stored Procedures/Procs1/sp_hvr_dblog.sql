CREATE PROCEDURE sp_hvr_dblog
    @start    NVARCHAR(25),
    @end      NVARCHAR(25),
    @devtype  NVARCHAR(260),
    @seqnum   INTEGER,
    @fname    NVARCHAR(260),
    @skip_lsn NVARCHAR(25)
WITH EXECUTE AS SELF
AS
    IF @skip_lsn IS NULL
        SELECT TOP 1 CONVERT(VARCHAR, [Current LSN]) AS [Current LSN]
          FROM sys.fn_dump_dblog(@start, @end, @devtype, @seqnum, @fname,
                                 null, null, null, null, null, null, null, null,
                                 null, null, null, null, null, null, null, null,
                                 null, null, null, null, null, null, null, null,
                                 null, null, null, null, null, null, null, null,
                                 null, null, null, null, null, null, null, null,
                                 null, null, null, null, null, null, null, null,
                                 null, null, null, null, null, null, null, null,
                                 null, null, null, null, null, null, null);
    ELSE
        BEGIN
            IF @skip_lsn = 'MAXLSN'
                SELECT CONVERT(VARCHAR, max([Current LSN])) AS [Current LSN]
                  FROM sys.fn_dump_dblog(@start, @end, @devtype, @seqnum, @fname,
                                         null, null, null, null, null, null, null, null,
                                         null, null, null, null, null, null, null, null,
                                         null, null, null, null, null, null, null, null,
                                         null, null, null, null, null, null, null, null,
                                         null, null, null, null, null, null, null, null,
                                         null, null, null, null, null, null, null, null,
                                         null, null, null, null, null, null, null, null,
                                         null, null, null, null, null, null, null);
            ELSE
                SELECT CONVERT(VARCHAR, [Current LSN]) AS [Current LSN],
                       [Log Record], [RowLog Contents 0], [RowLog Contents 1]
                  FROM sys.fn_dump_dblog(@start, @end, @devtype, @seqnum, @fname,
                                         null, null, null, null, null, null, null, null,
                                         null, null, null, null, null, null, null, null,
                                         null, null, null, null, null, null, null, null,
                                         null, null, null, null, null, null, null, null,
                                         null, null, null, null, null, null, null, null,
                                         null, null, null, null, null, null, null, null,
                                         null, null, null, null, null, null, null, null,
                                         null, null, null, null, null, null, null)
                 WHERE LOWER([Current LSN]) > @skip_lsn;
        END;
