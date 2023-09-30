CREATE FUNCTION dbo.fnS95OE_ConvertDate(@DateString nvarchar(50))
RETURNS DATETIME
WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE @X TINYINT, 
    @DatePreVerify nvarchar(50),
    @Dateformatted DATETIME 
  SELECT @X = CHARINDEX('.',REVERSE(@DateString))
  IF @X > 0 
    BEGIN
      SELECT @DatePreVerify = REVERSE(SUBSTRING(REVERSE(@DateString),@X-3,50)) + 'Z'  ;
    END
  ELSE
    BEGIN
      SELECT @DatePreVerify = @DateString;
    END
  SELECT @Dateformatted= NULL;
  IF ISDATE(@DatePreVerify) = 1
    BEGIN
      SELECT @Dateformatted= @DatePreVerify;
    END
  RETURN(@Dateformatted);
END;
