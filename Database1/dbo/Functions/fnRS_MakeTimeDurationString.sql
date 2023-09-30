CREATE FUNCTION [dbo].[fnRS_MakeTimeDurationString](@TotalMin FLOAT)
RETURNS nvarchar(14)
AS
BEGIN
Declare @TotalSec int
Declare @o nvarchar(14)
Declare @D int -- days
Declare @R int -- remainder seconds
Declare @H int -- hours
Declare @M int -- minutes
Declare @S int -- seconds
Declare @Ds nvarchar(3)
Declare @Hs nvarchar(2)
Declare @Ms nvarchar(2)
Declare @Ss nvarchar(2)
-- Initialize
Select @R = 0
Select @TotalSec = @TotalMin * 60 
-- Check
If @TotalMin < 0 
  Begin
 	 Select @o = convert(nvarchar(14), @TotalMin)
    goto ProcEnd
  End
-- How Many Days?
Select @D = @TotalSec / 86400 -- Total Days
If @D <> 0
 	 Select @R = @TotalSec % 86400 -- Remainder Seconds
Else
 	 Select @R = @TotalSec
If @D = 0 
     Select @Ds = ''
Else
     Select @Ds = Convert(nvarchar(3), @D)
-- How Many Hours?
Select @H = @R / 3600     -- Total Hours
If @H <> 0
 	 Select @R = @R % 3600 	  	 -- Remainder Seconds
If @H < 10 
     Select @Hs = '0' + convert(nvarchar(1), @H)
Else
     Select @Hs = convert(nvarchar(2), @H)
-- How Many Minutes?
Select @M = @R / 60 	  	 -- Total Minutes
If @M <> 0
 	 Select @R = @R % 60 	  	 -- Remainder Seconds
If @M < 10 
     Select @Ms = '0' + convert(nvarchar(1), @M)
Else
     Select @Ms = convert(nvarchar(2), @M)
-- How Many Seconds
Select @S = @R
If @S < 10 
     Select @Ss = '0' + convert(nvarchar(1), @S)
Else
     Select @Ss = convert(nvarchar(2), @S)
-- Make String
Select @o = ltrim(rtrim(convert(nvarchar(3), @Ds) + ' ' + Convert(nvarchar(2), @Hs) + ':' + Convert(nvarchar(2), @Ms) + ':' + Convert(nvarchar(2), @Ss)))
ProcEnd:
return @o
END
