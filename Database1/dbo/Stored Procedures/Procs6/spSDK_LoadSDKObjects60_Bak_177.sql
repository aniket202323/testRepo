CREATE procedure [dbo].[spSDK_LoadSDKObjects60_Bak_177]
AS
DECLARE @UserId INT
select  ObjectName  from SDK_Objects where sdkversion = '6.0' order by ObjectName
