CREATE PROCEDURE dbo.spServer_DBMgrEncodeDateTime
  @Year     smallint,
  @Month    tinyint,
  @Day      tinyint,
  @Hour     tinyint,
  @Minute   tinyint,
  @Second   tinyint,
  @DateTime datetime OUTPUT     AS
  -- Encode the datetime.
  IF @Year = 0
    SELECT @DateTime = NULL
  ELSE
    BEGIN
      SELECT @DateTime = DATEADD(year,   @Year - 1970, 'Jan 1 1970 00:00:00')
      SELECT @DateTime = DATEADD(month,  @Month - 1,   @DateTime)
      SELECT @DateTime = DATEADD(day,    @Day - 1,     @DateTime)
      SELECT @DateTime = DATEADD(hour,   @Hour,        @DateTime)
      SELECT @DateTime = DATEADD(minute, @Minute,      @DateTime)
      SELECT @DateTime = DATEADD(second, @Second,      @DateTime)
    END
