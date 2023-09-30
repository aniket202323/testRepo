CREATE PROCEDURE sp_hvr_check_publication
    @publication SYSNAME,
    @found INTEGER OUTPUT
WITH EXECUTE AS SELF
AS
    EXEC sp_helppublication
        @publication=@publication,
        @found=@found OUTPUT
