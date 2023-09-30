CREATE PROCEDURE dbo.spServer_CmnGetCXSServiceInfo
@ServiceName nVarChar(50),
@Found int OUTPUT,
@Service_Id int OUTPUT,
@Time_Stamp datetime OUTPUT,
@Start_Check_Time int OUTPUT,
@Restart_Wait_Time int OUTPUT,
@Reload_Flag int OUTPUT,
@Monitor_Interval int OUTPUT,
@Restart_Non_Responding int OUTPUT,
@Stop_Check_Time int OUTPUT,
@Start_Order int OUTPUT,
@Listener_Port int OUTPUT,
@Auto_Start int OUTPUT,
@Auto_Stop int OUTPUT,
@Monitor_Service int OUTPUT,
@NTService_Name nvarchar(50) OUTPUT,
@Proficy_Service_Name nvarchar(50) OUTPUT,
@Non_Responding_Kill_Script nVarChar(255) OUTPUT,
@Service_Desc nVarchar(50) OUTPUT,
@Service_Display nVarchar(50) OUTPUT,
@Listener_Address nvarchar(15) OUTPUT,
@Node_Name nVarchar(50) OUTPUT
 AS
Select @Found = 0
Select @Service_Id= null
Select top 1
       @Service_Id                 = Service_Id,
       @Time_Stamp                 = Time_Stamp,
       @Start_Check_Time           = Start_Check_Time,
       @Restart_Wait_Time          = Restart_Wait_Time,
       @Reload_Flag                = Reload_Flag,
       @Monitor_Interval           = Monitor_Interval,
       @Restart_Non_Responding     = Restart_Non_Responding,
       @Stop_Check_Time            = Stop_Check_Time,
       @Start_Order                = Start_Order,
       @Listener_Port              = Listener_Port,
       @Auto_Start                 = Auto_Start,
       @Auto_Stop                  = Auto_Stop,
       @Monitor_Service            = Monitor_Service,
       @NTService_Name             = NTService_Name,
       @Proficy_Service_Name       = Proficy_Service_Name,
       @Non_Responding_Kill_Script = Non_Responding_Kill_Script,
       @Service_Desc               = Service_Desc,
       @Service_Display            = Service_Display,
       @Listener_Address           = Listener_Address,
       @Node_Name                  = Node_Name
 From  CXS_Service
 Where Service_Desc = @ServiceName and Is_Active = 1
 order by Service_Id
if (@Service_Id is not null) Select @Found = 1
