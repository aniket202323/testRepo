create function dbo.fnSecondsToTime(@seconds INT)
returns nvarchar(50)
as
BEGIN
  declare @remainder int
  declare @hours int, @minutes int
  declare @returnstring nvarchar(50)
  set @minutes = @seconds / 60
  set @seconds = @seconds % 60
  set @hours = @minutes / 60
  set @minutes = @minutes % 60  
 	 
  set @returnstring = case when @hours < 10 then '0' else '' end + convert(nvarchar(10), @hours) + ':'  + case when @minutes < 10 then '0' else '' end + convert(nvarchar(10), @minutes) + ':' + case when @seconds < 10 then '0' else '' end + convert(nvarchar(10), @seconds) + ' hrs'
  RETURN @ReturnString
END
