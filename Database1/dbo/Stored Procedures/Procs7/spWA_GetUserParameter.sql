CREATE procedure [dbo].[spWA_GetUserParameter]
  @UserId INT,
  @ParameterId INT
AS
SELECT Value
FROM User_Parameters
WHERE [User_Id] = @UserId AND [Parm_Id] = @ParameterId
