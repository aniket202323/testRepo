Create Procedure dbo.spXLACheckVersion
@InputBuild int,
@HighestBuild int OUTPUT
AS
Select @HighestBuild = 22
If @InputBuild > 20 
   return(1)
Else
   return(0)
