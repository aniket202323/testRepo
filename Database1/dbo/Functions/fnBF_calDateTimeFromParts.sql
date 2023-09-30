CREATE FUNCTION dbo.fnBF_calDateTimeFromParts(
    @year int,
    @month int,
    @day int,
    @hour int,
    @minute int,
    @second int,
    @nanos int)
 RETURNS DATETIME AS
BEGIN
      DECLARE @Result DATETIME ;
      SELECT @Result = DATEADD(SECOND, @second, 
        DATEADD(MINUTE, @minute, 
        DATEADD(HOUR, @hour, 
        DATEADD(DAY, @day-1, 
        DATEADD(MONTH, @month-1, 
        DATEADD(YEAR, @year-1900, CAST(0 AS DATETIME) ) ) ) ) ) ) ;
      return @Result ;
END
