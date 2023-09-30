/*
How To Call
Select dbo.fnRS_GetMillStartTime()
or 
Print dbo.fnRS_GetMillStartTime()
or 
declare @o varchar(8)
Select @o = dbo.fnRS_GetMillStartTime()
select @o
*/
CREATE FUNCTION [dbo].[fnRS_GetMillStartTime]()
RETURNS varchar(8)
AS
BEGIN
DECLARE @h varchar(2)
DECLARE @m varchar(2)
DECLARE @t varchar(10)
select @h = convert(varchar(3),Value) from site_parameters where parm_Id = 14
select @m = convert(varchar(3),Value) from site_parameters where parm_Id = 15
If @h < 0 Select @h = 24 + @h
If @h < 0 Select @H = 0
If @h > 23 Select @h = 0
If @m < 0 Select @m = 60 + @m
If @m < 0 Select @m = 0
If @m > 59 Select @m = 0
if Len(@M) = 1 Select @m = '0' + @m
RETURN @h + ':' +  @m  + ':00'
END
