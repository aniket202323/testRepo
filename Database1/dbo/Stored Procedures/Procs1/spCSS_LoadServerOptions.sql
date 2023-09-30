CREATE PROCEDURE dbo.spCSS_LoadServerOptions 
AS
/*
Create Table #Options (OptionName nvarchar(50), OptionValue nvarchar(50))
Insert Into #Options (OptionName, OptionValue) Values ('TimerInterval', '60000')
Insert Into #Options (OptionName, OptionValue) Values ('MaxLoginAttempts', '3')
Insert Into #Options (OptionName, OptionValue) Values ('MessageDestination', 'File')
Insert Into #Options (OptionName, OptionValue) Values ('RealTimeLogging', 'Off')
Insert Into #Options (OptionName, OptionValue) Values ('RealTimeLoggingVersioning', 'No')
DECLARE @Addr nvarchar(25), @Port nvarchar(25)
Select @Addr = COALESCE(Listener_Address, ""), @Port = COALESCE(Listener_Port, "") from CXS_Service where Service_ID = 14
Insert Into #Options (OptionName, OptionValue) Values ('RealTimeAddress', @Addr)
Insert Into #Options (OptionName, OptionValue) Values ('RealTimePort', @Port)
Select * From #Options
Drop Table #Options
*/
--SELECT Parm_Name, String_value FROM App_Parameters WHERE App_Id = 0
Create table #App_Parameters (Parm_Name nvarchar(25), string_value nVarChar(255))
select parm_name, string_value from #app_parameters 
