Create Procedure dbo.spRSQ_CheckVersion
@InputBuild int,
@HighestBuild int OUTPUT
AS
Select @HighestBuild = 19
If @InputBuild > 10 
   return(1)
Else
   return(0)
