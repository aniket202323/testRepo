CREATE FUNCTION dbo.fnMESCore_Split(
    @delimited NVARCHAR(MAX),
    @delimiter NVARCHAR(100)=','
) RETURNS @t TABLE (id INT IDENTITY(1,1), val NVARCHAR(MAX))
AS
BEGIN
    DECLARE @xml XML
    SET @xml = N'<t>' + REPLACE(@delimited,@delimiter,'</t><t>') + '</t>'
    INSERT INTO @t(val)
    SELECT  r.value('.','varchar(MAX)') as item
    FROM  @xml.nodes('/t') as records(r)
    RETURN
END
