Create Procedure [dbo].[spWA_GetSPTimeout]
  @SPName nVarChar(50)
AS
Declare @Timeout Int
Select @Timeout = Timeout
From Client_SP_Prototypes
Where SP_Name = @SPName
If @Timeout Is Null
  Return 0
Else
  Return @Timeout
