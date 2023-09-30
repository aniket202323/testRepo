CREATE PROCEDURE dbo.spServer_DBMgrDecodeDateTime
  @DateTime datetime,
  @Year     smallint  OUTPUT,
  @Month    tinyint   OUTPUT,
  @Day      tinyint   OUTPUT,
  @Hour     tinyint   OUTPUT,
  @Minute   tinyint   OUTPUT,
  @Second   tinyint   OUTPUT     AS
  -- Decode the date time.
  IF @DateTime IS NULL
    SELECT @Year   = 0,
           @Month  = 0,
           @Day    = 0,
           @Hour   = 0,
           @Minute = 0,
           @Second = 0
  ELSE  
    SELECT @Year   = DATEPART(year,   @DateTime),
           @Month  = DATEPART(month,  @DateTime),
           @Day    = DATEPART(day,    @DateTime),
           @Hour   = DATEPART(hour,   @DateTime),
           @Minute = DATEPART(minute, @DateTime),
           @Second = DATEPART(second, @DateTime)
