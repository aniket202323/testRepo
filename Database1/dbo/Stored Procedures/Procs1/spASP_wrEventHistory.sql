CREATE PROCEDURE [dbo].[spASP_wrEventHistory]
@EventId int,
@InTimeZone nvarchar(200)=NULL
AS
--*********************************************
-- For Testing
--*********************************************
-- Select @EventId = 327 --2572 --327
--**********************************************/
Declare @ReportName nvarchar(255)
Declare @CriteriaString nVarChar(1000)
Declare @Unit int
Declare @UnitName nVarChar(100)
Declare @EventType nVarChar(50)
Declare @EventName nVarChar(50)
Declare @EndTime DateTime
Declare @DimXName nvarchar(25)
Declare @DimXUnits nvarchar(25)
Declare @DimYName nvarchar(25)
Declare @DimYUnits nvarchar(25)
Declare @DimZName nvarchar(25)
Declare @DimZUnits nvarchar(25)
Declare @DimAName nvarchar(25)
Declare @DimAUnits nvarchar(25)
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
DECLARE @User nVarChar(100)
DECLARE @Warning nVarChar(100)
DECLARE @Reject nVarChar(100)
DECLARE @Entry nVarChar(100)
DECLARE @Good nVarChar(100)
-- Get Common Prompts
SET @User = dbo.fnTranslate(@LangId, 34688, 'User')
SET @Warning = dbo.fnTranslate(@LangId, 34689, 'Warning')
SET @Reject = dbo.fnTranslate(@LangId, 34690, 'Reject')
SET @Entry = dbo.fnTranslate(@LangId, 34691, 'Entry')
SET @Good = dbo.fnTranslate(@LangId, 34692, 'Good')
If @EventId Is Null
  Begin
    Raiserror('Event ID Is A Required Parameter',16,1)
    Return
  End
Select @Unit = PU_Id, @EventName = Event_Num , @EndTime = Timestamp
  From Events e
  Where Event_Id = @EventId 
Select @EventType = s.event_subtype_desc,
       @DimXName = s.dimension_x_name,
       @DimYName = s.dimension_y_name,
       @DimZName = s.dimension_z_name,
       @DimAName = s.dimension_a_name,
       @DimXUnits = s.dimension_x_eng_units,
       @DimYUnits = s.dimension_y_eng_units,
       @DimZUnits = s.dimension_z_eng_units,
       @DimAUnits = s.dimension_a_eng_units
  from event_configuration e 
  join event_subtypes s on s.Event_Subtype_Id = e.Event_Subtype_Id
  where e.pu_id = @Unit and 
        e.et_id = 1
Select @UnitName = PU_Desc
 From Prod_Units 
 Where PU_Id = @Unit
Select @ReportName = @EventType + ' ' + @EventName + ' ' + dbo.fnTranslate(@LangId, 34753, 'History')
--**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Declare @Prompts Table  (
  PromptId int null,
  PromptName nvarchar(20),
  PromptValue nvarchar(1000),
  PromptValue_Parameter SQL_Variant
)
Insert into @Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('Criteria', dbo.fnTranslate(@LangId, 34665, 'On {0}'), @UnitName)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('GenerateTime', dbo.fnTranslate(@LangId, 34521, 'Created: {0}'), dbo.fnServer_CmnGetDate(getutcdate()))
Insert into @Prompts (PromptName, PromptValue) Values ('History', dbo.fnTranslate(@LangId, 34648, 'History'))
Insert into @Prompts (PromptName, PromptValue) Values ('Updated', dbo.fnTranslate(@LangId, 34649, 'Updated'))
Insert into @Prompts (PromptName, PromptValue) Values ('Added', dbo.fnTranslate(@LangId, 34650, 'Added'))
Insert into @Prompts (PromptName, PromptValue) Values ('Removed', dbo.fnTranslate(@LangId, 34651, 'Removed'))
Insert into @Prompts (PromptName, PromptValue) Values ('Operation', dbo.fnTranslate(@LangId, 34754, 'Operation'))
Insert into @Prompts (PromptName, PromptValue) Values ('Field', dbo.fnTranslate(@LangId, 34755, 'Field'))
Insert into @Prompts (PromptName, PromptValue) Values ('FromValue', dbo.fnTranslate(@LangId, 34756, 'From Value'))
Insert into @Prompts (PromptName, PromptValue) Values ('ToValue', dbo.fnTranslate(@LangId, 34757, 'To Value'))
Insert into @Prompts (PromptName, PromptValue) Values ('UpdateTime', dbo.fnTranslate(@LangId, 34654, 'Update Time'))
Insert into @Prompts (PromptName, PromptValue) Values ('UpdateUser', dbo.fnTranslate(@LangId, 34655, 'Update User'))
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('EventNumber', dbo.fnTranslate(@LangId, 34758, '{0} Number'), @EventType)
Insert into @Prompts (PromptName, PromptValue) Values ('StartTime', dbo.fnTranslate(@LangId, 34011, 'Start Time'))
Insert into @Prompts (PromptName, PromptValue) Values ('EndTime', dbo.fnTranslate(@LangId, 34012, 'End Time'))
Insert into @Prompts (PromptName, PromptValue) Values ('Product', dbo.fnTranslate(@LangId, 34017, 'Product'))
Insert into @Prompts (PromptName, PromptValue) Values ('Status', dbo.fnTranslate(@LangId, 34019, 'Status'))
Insert into @Prompts (PromptName, PromptValue) Values ('Conformance', dbo.fnTranslate(@LangId, 34723, 'Conformance'))
Insert into @Prompts (PromptName, PromptValue) Values ('TestPercent', dbo.fnTranslate(@LangId, 34724, 'Testing Percent'))
Insert into @Prompts (PromptName, PromptValue) Values ('PlannedOrder', dbo.fnTranslate(@LangId, 34759, 'Planned Order'))
Insert into @Prompts (PromptName, PromptValue) Values ('PlannedCustomer', dbo.fnTranslate(@LangId, 34760, 'Planned Customer'))
Insert into @Prompts (PromptName, PromptValue) Values ('ActualOrder', dbo.fnTranslate(@LangId, 34761, 'Actual Order'))
Insert into @Prompts (PromptName, PromptValue) Values ('ActualCustomer', dbo.fnTranslate(@LangId, 34762, 'Actual Customer'))
Insert into @Prompts (PromptName, PromptValue) Values ('Shipment', dbo.fnTranslate(@LangId, 34735, 'Shipment'))
Insert into @Prompts (PromptName, PromptValue) Values ('ProcessOrder', dbo.fnTranslate(@LangId, 34763, 'Process Order'))
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('InitialDimensionX', dbo.fnTranslate(@LangId, 34721, 'Initial {0}'), @DimXName)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('InitialDimensionY', dbo.fnTranslate(@LangId, 34721, 'Initial {0}'), @DimYName)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('InitialDimensionZ', dbo.fnTranslate(@LangId, 34721, 'Initial {0}'), @DimZName)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('InitialDimensionA', dbo.fnTranslate(@LangId, 34721, 'Initial {0}'), @DimAName)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('FinalDimensionX', dbo.fnTranslate(@LangId, 34764, 'Remaining {0}'), @DimXName)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('FinalDimensionY', dbo.fnTranslate(@LangId, 34764, 'Remaining {0}'), @DimYName)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('FinalDimensionZ', dbo.fnTranslate(@LangId, 34764, 'Remaining {0}'), @DimZName)
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('FinalDimensionA', dbo.fnTranslate(@LangId, 34764, 'Remaining {0}'), @DimAName)
Insert into @Prompts (PromptName, PromptValue) Values ('OrientationX', dbo.fnTranslate(@LangId, 34765, 'Orientation X'))
Insert into @Prompts (PromptName, PromptValue) Values ('OrientationY', dbo.fnTranslate(@LangId, 34766, 'Orientation Y'))
Insert into @Prompts (PromptName, PromptValue) Values ('OrientationZ', dbo.fnTranslate(@LangId, 34767, 'Orientation Z'))
Insert into @Prompts (PromptName, PromptValue, PromptValue_Parameter) Values ('AlternateEventNumber', dbo.fnTranslate(@LangId, 34768, 'Alternate {0} Number'), @EventType)
Insert into @Prompts (PromptName, PromptValue) Values('ESigPerformer', dbo.fnTranslate(@LangId, 35145, 'E-Signature Performer'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigPerformedTime', dbo.fnTranslate(@LangId, 35146, 'E-Signature Performed Time'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigPerformerReason', dbo.fnTranslate(@LangId, 35147, 'E-Signature Performer Reason'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigPerformerComment', dbo.fnTranslate(@LangId, 35148, 'E-Signature Performer Comment'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigApprover', dbo.fnTranslate(@LangId, 35149, 'E-Signature Approver'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigApprovedTime', dbo.fnTranslate(@LangId, 35150, 'E-Signature Approved Time'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigApproverReason', dbo.fnTranslate(@LangId, 35151, 'E-Signature Approver Reason'))
Insert into @Prompts (PromptName, PromptValue) Values('ESigApproverComment', dbo.fnTranslate(@LangId, 35152, 'E-Signature Approver Comment'))
Insert Into @Prompts (PromptName, PromptValue) Values('Item', dbo.fnTranslate(@LangId, 34797, 'Item'))
 	 select PromptId,PromptName,PromptValue,'PromptValue_Parameter'= case when (ISDATE(Convert(varchar,PromptValue_Parameter))=1)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime] (convert(datetime,PromptValue_Parameter),@InTimeZone)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 else
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 PromptValue_Parameter
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 end 
 	 From @Prompts
--**********************************************
-- Return Data For Report
--**********************************************
Select UpdateTime =   [dbo].[fnServer_CmnConvertFromDbTime] (e.Entry_On,@InTimeZone)  ,
       UpdateUser = u1.Username,
 	  	  	  Item = @EventType,
       EventNumber = e.Event_Num,
       StartTime =  [dbo].[fnServer_CmnConvertFromDbTime] ((Case When e.Start_Time Is Null Then e2.[Timestamp] Else e.Start_Time End),@InTimeZone),
       EndTime =   [dbo].[fnServer_CmnConvertFromDbTime] (e.[Timestamp],@InTimeZone)  ,
       Product = Case When e.Applied_Product Is Null Then p1.Prod_Code Else p2.Prod_Code End,
       Status = s.ProdStatus_Desc,
       Conformance = Case
                        When e.Conformance = 1 Then @User
                        When e.Conformance = 2 Then @Warning
                        When e.Conformance = 3 Then @Reject
                        When e.Conformance = 4 Then @Entry 
                        Else @Good
                     End,
       TestPercent = e.Testing_Prct_Complete ,
 	  	  	  ESigPerformer = esig_pu.Username,
 	  	  	  ESigPerformedTime = esig.Perform_Time,
 	  	  	  ESigPerformerReason = pr.Event_Reason_Name,
 	  	  	  ESigPerformerComment = pc.Comment_Text,
 	  	  	  ESigApprover = esig_vu.Username,
 	  	  	  ESigApprovedTime =   [dbo].[fnServer_CmnConvertFromDbTime] (esig.Verify_Time,@InTimeZone), 
 	  	  	  ESigApproverReason = vr.Event_Reason_Name,
 	  	  	  ESigApproverComment = vc.Comment_Text  
  from event_history e
  Join Users u1 on u1.user_id = e.user_id
  Join Production_Status s on s.ProdStatus_Id = e.Event_Status 
  Join Production_Starts ps on ps.PU_Id = @Unit and ps.Start_Time <= e.Timestamp and ((ps.End_Time > e.Timestamp) or (ps.End_Time Is Null))
  Join Products p1 on p1.Prod_id = ps.prod_id
  Left Outer Join products p2 on p2.Prod_id = e.Applied_Product 
  Left Outer Join events e2 on e2.PU_Id = @Unit and e2.Timestamp = (Select max(e3.Timestamp) From Events e3 Where e3.PU_id = @Unit and e3.Timestamp < e.Timestamp)
 	 left outer join esignature esig on e.Signature_Id = esig.Signature_Id
 	 left outer join users esig_pu on esig.Perform_User_Id = esig_pu.user_id
 	 left outer join users esig_vu on esig.Verify_User_Id = esig_vu.user_id
 	 left outer join event_reasons pr On esig.Perform_Reason_Id = pr.Event_Reason_Id
 	 left outer join event_reasons vr On esig.Verify_Reason_Id = vr.Event_Reason_Id
 	 left outer join Comments pc On esig.Perform_Comment_Id = pc.Comment_Id
 	 left outer join Comments vc On esig.Verify_Comment_Id = vc.Comment_Id
  where e.event_id = @EventId
  Order By e.Entry_On ASC
Select UpdateTime =   [dbo].[fnServer_CmnConvertFromDbTime] (e.Modified_On,@InTimeZone) , 
       UpdateUser = u1.Username,
 	  	  	  Item = @EventType,
       PlannedOrder = co1.plant_order_number,
       PlannedCustomer = c1.customer_code, 
       ActualOrder = co2.plant_order_number,
       ActualCustomer = c2.customer_code, 
       Shipment = s.shipment_number,
       ProcessOrder = pp1.Process_Order,
       InitialDimensionX = '{0} ' + @DimXUnits,
       InitialDimensionX_Parameter = e.Initial_Dimension_X,
       InitialDimensionY = '{0} ' + @DimYUnits,
       InitialDimensionY_Parameter = e.Initial_Dimension_Y,
       InitialDimensionZ = '{0} ' + @DimZUnits,
       InitialDimensionZ_Parameter = e.Initial_Dimension_Z,
       InitialDimensionA = '{0} ' + @DimAUnits,
       InitialDimensionA_Parameter = e.Initial_Dimension_A,
       FinalDimensionX = '{0} ' + @DimXUnits,
       FinalDimensionX_Parameter = e.Final_Dimension_X,
       FinalDimensionY = '{0} ' + @DimYUnits,
       FinalDimensionY_Parameter = e.Final_Dimension_Y,
       FinalDimensionZ = '{0} ' + @DimZUnits,
       FinalDimensionZ_Parameter = e.Final_Dimension_Z,
       FinalDimensionA = '{0} ' + @DimAUnits,
       FinalDimensionA_Parameter = e.Final_Dimension_A,
       OrientationX = e.Orientation_X,
       OrientationY = e.Orientation_Y,
       OrientationZ = e.Orientation_Z,
       AlternateEventNumber = e.Alternate_Event_Num,
 	  	  	  ESigPerformer = esig_pu.Username,
 	  	  	  ESigPerformedTime = esig.Perform_Time,
 	  	  	  ESigPerformerReason = pr.Event_Reason_Name,
 	  	  	  ESigPerformerComment = pc.Comment_Text,
 	  	  	  ESigApprover = esig_vu.Username,
 	  	  	  ESigApprovedTime =   [dbo].[fnServer_CmnConvertFromDbTime] (esig.Verify_Time,@InTimeZone) ,
 	  	  	  ESigApproverReason = vr.Event_Reason_Name,
 	  	  	  ESigApproverComment = vc.Comment_Text     
  from event_detail_history e
 	 Join Events ev On e.Event_Id = ev.Event_Id
  Join Users u1 on u1.user_id = 1 --e.user_id
  Left outer join production_setup_detail psd on psd.pp_setup_detail_id = e.pp_setup_detail_id
  Left outer join customer_order_line_items col1 on col1.order_line_id = e.order_line_id
  Left outer join customer_orders co1 on co1.order_id = col1.order_id
  Left outer join customer c1 on c1.Customer_id = co1.customer_id
  Left outer join customer_orders co2 on co2.order_id = e.order_id
  Left outer join customer c2 on c2.Customer_id = co2.customer_id
  Left outer join shipment_line_items sl on sl.shipment_item_id = e.shipment_item_id
  Left outer join shipment s on s.shipment_id = sl.shipment_id
  left outer join production_plan pp1 on pp1.pp_id = e.pp_id
 	 left outer join esignature esig on e.Signature_Id = esig.Signature_Id
 	 left outer join users esig_pu on esig.Perform_User_Id = esig_pu.user_id
 	 left outer join users esig_vu on esig.Verify_User_Id = esig_vu.user_id
 	 left outer join event_reasons pr On esig.Perform_Reason_Id = pr.Event_Reason_Id
 	 left outer join event_reasons vr On esig.Verify_Reason_Id = vr.Event_Reason_Id
 	 left outer join Comments pc On esig.Perform_Comment_Id = pc.Comment_Id
 	 left outer join Comments vc On esig.Verify_Comment_Id = vc.Comment_Id
  where e.event_id = @EventId
  Order By e.Modified_On ASC
Select 	 UpdateTime =   [dbo].[fnServer_CmnConvertFromDbTime] (TH.Modified_On, @InTimeZone),
 	  	  	  	 UpdateUser = u1.Username,
 	  	  	  	 Item = Coalesce(v.Var_Desc, '-'),
 	  	  	  	 TH.Result,
 	  	  	  	 ESigPerformer = esig_pu.Username,
 	  	  	  	 ESigPerformedTime = esig.Perform_Time,
 	  	  	  	 ESigPerformerReason = pr.Event_Reason_Name,
 	  	  	  	 ESigPerformerComment = pc.Comment_Text,
 	  	  	  	 ESigApprover = esig_vu.Username,
 	  	  	  	 ESigApprovedTime =  [dbo].[fnServer_CmnConvertFromDbTime] (esig.Verify_Time, @InTimeZone),
 	  	  	  	 ESigApproverReason = vr.Event_Reason_Name,
 	  	  	  	 ESigApproverComment = vc.Comment_Text  
From Variables v
Join prod_units pu on pu.pu_id = v.pu_id and pu.pu_id = @Unit or pu.master_Unit = @Unit
Join pu_groups pug on pug.pu_id = pu.pu_id and pug.pug_id = v.pug_id
Join tests t on t.var_id = v.var_id and t.result_on = @EndTime
Join test_history th on th.test_id = t.test_id And th.Event_Id Is Not Null and th.result_on = t.result_on
Join Users u1 on u1.user_id = TH.Entry_By
left outer join esignature esig on th.Signature_Id = esig.Signature_Id
left outer join users esig_pu on esig.Perform_User_Id = esig_pu.user_id
left outer join users esig_vu on esig.Verify_User_Id = esig_vu.user_id
left outer join event_reasons pr On esig.Perform_Reason_Id = pr.Event_Reason_Id
left outer join event_reasons vr On esig.Verify_Reason_Id = vr.Event_Reason_Id
left outer join Comments pc On esig.Perform_Comment_Id = pc.Comment_Id
left outer join Comments vc On esig.Verify_Comment_Id = vc.Comment_Id
Where v.event_type = 1 and v.pu_id <> 0
