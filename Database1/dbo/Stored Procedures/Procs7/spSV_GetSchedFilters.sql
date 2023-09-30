CREATE Procedure dbo.spSV_GetSchedFilters
@Sheet_Id int,
@SF_Desc nvarchar(100) = NULL,
@Path_Id int = NULL,
@PP_Id int = NULL,
@DisplayUnboundOrders bit = NULL
AS
If @Sheet_Id = 0
  Select @Sheet_Id = NULL
If @Path_Id = 0
  Select @Path_Id = NULL
If @PP_Id = 0
  Select @PP_Id = NULL
If @DisplayUnboundOrders = 0
  Select @DisplayUnboundOrders = NULL
Declare @Process_Order nvarchar(50)
Select @Process_Order = NULL
Select @Process_Order = Process_Order From Production_Plan Where PP_Id = @PP_Id
Create Table #ScheduleFilters (SF_Id int IDENTITY (1, 1) NOT NULL, SF_Desc nvarchar(100), SF_Key_Id int, SF_Type nvarchar(50))
If @Process_Order is NOT NULL
  Begin
    If PATINDEX('%<CHILDREN>%', @SF_Desc) > 0
      Insert Into #ScheduleFilters (SF_Desc, SF_Key_Id, SF_Type) Values ('<CHILDREN> - ' + @Process_Order, -200, '<CHILDREN>')
    Else If PATINDEX('%<PARENT>%', @SF_Desc) > 0
      Insert Into #ScheduleFilters (SF_Desc, SF_Key_Id, SF_Type) Values ('<PARENT> - ' + @Process_Order, -300, '<PARENT>')
  End
Insert Into #ScheduleFilters (SF_Desc, SF_Key_Id, SF_Type) Values ('<ALL>', -100, '<ALL>')
If @DisplayUnboundOrders = 1
  Insert Into #ScheduleFilters (SF_Desc, SF_Key_Id, SF_Type) Values ('<UNBOUND>', -50, '<UNBOUND>')
Insert Into #ScheduleFilters (SF_Desc, SF_Key_Id, SF_Type)
  Select '<STATUS> - ' + PP_Status_Desc, PP_Status_Id, '<STATUS>'
    From Production_Plan_Statuses
if @Sheet_Id is NOT NULL
  Insert Into #ScheduleFilters (SF_Desc, SF_Key_Id, SF_Type)
    Select '<PATH> - ' + Path_Code, Path_Id, '<PATH>'
      From PrdExec_Paths
      Where Path_id in (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id) 
Else If @Path_Id is NOT NULL
  Insert Into #ScheduleFilters (SF_Desc, SF_Key_Id, SF_Type)
    Select '<PATH> - ' + Path_Code, Path_Id, '<PATH>'
      From PrdExec_Paths
      Where Path_id = @Path_Id
Select SF_Id, SF_Desc, SF_Key_Id, SF_Type
From #ScheduleFilters
Order By SF_Desc ASC
Drop Table #ScheduleFilters
