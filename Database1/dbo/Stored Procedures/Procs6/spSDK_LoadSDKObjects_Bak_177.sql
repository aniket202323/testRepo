CREATE procedure [dbo].[spSDK_LoadSDKObjects_Bak_177]
AS
DECLARE @UserId INT
select  ObjectName  from SDK_Objects where SDKVersion = '5.0' order by ObjectName
