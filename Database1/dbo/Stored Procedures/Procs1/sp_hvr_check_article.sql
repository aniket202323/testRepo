CREATE PROCEDURE sp_hvr_check_article
    @publication SYSNAME,
    @article SYSNAME,
    @returnfilter bit
WITH EXECUTE AS SELF
AS
    EXEC sp_helparticle
        @publication= @publication,
        @article= @article,
        @returnfilter=@returnfilter
