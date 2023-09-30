create function dbo.fnMinutesToTime(@minutes decimal(10,2))
returns nvarchar(50)
as
BEGIN
  declare @hours int, @intminutes int, @seconds int
  declare @returnstring nvarchar(50)
  set @seconds = @minutes * 100
  set @seconds = @seconds % 100
  set @seconds = Round(Cast((60 * @seconds) as float) / cast(100 as float),0)
  set @intminutes = @minutes
  set @hours = @intminutes / 60
  set @intminutes = @intminutes % 60  
 	 
  set @returnstring = case when @hours < 10 then '0' else '' end + convert(nvarchar(10), @hours) + ':'  + case when @intminutes < 10 then '0' else '' end + convert(nvarchar(10), @intminutes) + ':' + case when @seconds < 10 then '0' else '' end + convert(nvarchar(10), @seconds) + ' hrs'
  RETURN @ReturnString
END
