CREATE PROCEDURE sp_hvr_repldone
    @xactid     BINARY(10),
    @xact_seqno BINARY(10),
    @numtrans   INTEGER = NULL,
    @time       INTEGER = NULL,
    @reset      INTEGER = NULL
WITH EXECUTE AS SELF
AS
    DECLARE @stmt VARCHAR(200)
    SET @stmt = 'EXEC sp_repldone ' +
            '@xactid= ' + CASE WHEN @xactid IS NULL THEN 'NULL' ELSE CONVERT(VARCHAR, @xactid, 1) END +
            ', @xact_seqno= ' + CASE WHEN @xact_seqno IS NULL THEN 'NULL' ELSE CONVERT(VARCHAR, @xact_seqno, 1) END
    IF @numtrans IS NOT NULL
        SET @stmt = @stmt + ', @numtrans= ' + CONVERT(VARCHAR, @numtrans)
    IF @time IS NOT NULL
        SET @stmt = @stmt + ', @time= ' + CONVERT(VARCHAR, @time)
    IF @reset IS NOT NULL
        SET @stmt = @stmt + ', @reset= ' + CONVERT(VARCHAR, @reset)
    EXEC(@stmt)
