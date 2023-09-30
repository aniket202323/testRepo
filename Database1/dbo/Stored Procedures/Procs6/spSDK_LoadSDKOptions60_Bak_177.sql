CREATE procedure [dbo].[spSDK_LoadSDKOptions60_Bak_177]
AS
DECLARE @UserId INT
DECLARE @Options TABLE (OptionName Varchar(50) COLLATE DATABASE_DEFAULT, OptionValue Varchar(100) COLLATE DATABASE_DEFAULT)
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fnServer_CmnGetDate]') and xtype in (N'FN', N'IF', N'TF'))
 	 insert into @Options (OptionName, OptionValue) select 'HasCmnGetDate', '1'
else
 	 insert into @Options (OptionName, OptionValue) select 'HasCmnGetDate', '0'
select OptionName, OptionValue from @Options
