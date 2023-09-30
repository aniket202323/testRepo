Create Procedure dbo.spGBO_CheckVersion
@InputBuild int,
@HighestBuild int OUTPUT
AS
Select @HighestBuild = 15
If @InputBuild > 10 
   return(1)
Else
   return(0)
