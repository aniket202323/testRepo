CREATE PROCEDURE dbo.spServer_CmnNoSecTime
@TimeStamp Datetime OUTPUT
 AS
Declare
  @StrTime nVarChar(30)
Select @StrTime = Convert(nVarChar(30),@TimeStamp,100)
Select @TimeStamp = Convert(Datetime,@StrTime)
