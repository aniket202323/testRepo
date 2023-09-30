Create Procedure dbo.spAL_CheckVersion
@InputBuild int,
@HighestBuild int OUTPUT
AS
Select @HighestBuild = 49
If @InputBuild > 48 
   return(1)
Else
   return(0)
