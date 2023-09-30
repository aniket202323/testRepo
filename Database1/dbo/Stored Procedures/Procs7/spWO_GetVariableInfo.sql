CREATE PROCEDURE [dbo].[spWO_GetVariableInfo]
  @VariableId INT
AS
SELECT *
FROM Variables
WHERE VAR_Id = @VariableId
