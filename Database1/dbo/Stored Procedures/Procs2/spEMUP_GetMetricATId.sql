CREATE Procedure dbo.spEMUP_GetMetricATId
@User_Id int,
@AT_Id int OUTPUT
AS
SELECT @AT_Id = 0
SELECT @AT_Id = AT_Id From Alarm_Templates Where AT_Desc = 'Production Metrics'
