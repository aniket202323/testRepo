CREATE PROCEDURE [dbo].[spSDK_ConvertDate]
 	 @InDate 	  	  	  	  	  	  	  	  	 datetime OUTPUT,
 	 @OutDate 	  	  	  	  	  	  	  	 Varchar(14) OUTPUT
AS
 	 IF @InDate IS NULL 
 	 BEGIN
 	  	 SET @OutDate = NULL
 	  	 RETURN
 	 END
 	 DECLARE @sPart Varchar(2)
 	 
 	 If (DATEPART(Second,@InDate) <> 0)
 	  	 Select @InDate = DATEADD(Second,-DATEPART(Second,@InDate),@InDate)
 	 If (DATEPART(Millisecond,@InDate) <> 0)
 	  	 Select @InDate = DATEADD(Millisecond,-DATEPART(Millisecond,@InDate),@InDate)
 	 
 	 SET @OutDate = Convert(varchar(4),DatePart(year,@InDate))
 	 SET @sPart = Convert(varchar(2),DatePart(Month,@InDate))
 	 IF Len(@sPart) = 2
 	  	 SET @OutDate = @OutDate + @sPart
 	 ELSE
 	  	 SET @OutDate = @OutDate + '0' + @sPart
 	 SET @sPart = Convert(varchar(2),DatePart(Day,@InDate))
 	 IF Len(@sPart) = 2
 	  	 SET @OutDate = @OutDate + @sPart
 	 ELSE
 	  	 SET @OutDate = @OutDate + '0' + @sPart
 	 SET @sPart = Convert(varchar(2),DatePart(Hour,@InDate))
 	 IF Len(@sPart) = 2
 	  	 SET @OutDate = @OutDate + @sPart
 	 ELSE
 	  	 SET @OutDate = @OutDate + '0' + @sPart
 	 SET @sPart = Convert(varchar(2),DatePart(Minute,@InDate))
 	 IF Len(@sPart) = 2
 	  	 SET @OutDate = @OutDate + @sPart
 	 ELSE
 	  	 SET @OutDate = @OutDate + '0' + @sPart
 	 SET @OutDate = @OutDate + '00' --no seconds supported
 	  	 
