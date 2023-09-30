Create Procedure [dbo].[spSDK_GetCommandTimeout60]
  @SPName VARCHAR(50)
--With Encryption
AS
Declare @Timeout Int
Select @Timeout = Timeout
From Client_SP_Prototypes
Where SP_Name = @SPName
If @Timeout Is Null
  Return -1
Else
  Return @Timeout
