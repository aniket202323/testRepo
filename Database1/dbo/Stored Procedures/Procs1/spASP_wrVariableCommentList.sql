CREATE procedure [dbo].[spASP_wrVariableCommentList]
@VariableId int,
@ProductId int,
@StartTime datetime, 
@EndTime datetime,
@InTimeZone varchar(200)=NULL
AS
Declare @ReportName varchar(255)
Declare @CriteriaString varchar(1000)
Declare @VariableName varchar(255)
Declare @ProductCode varchar(50)
/*********************************************
-- For Testing
--*********************************************
Select @VariableId = 28
Select @ProductId = 1
Select @StartTime = '1-jan-01'
Select @EndTime = getdate()
--**********************************************/
--**********************************************
-- Loookup Parameters For This Report Id
--**********************************************
Select @ReportName = 'Comment Listing'
Select @VariableName = var_desc from Variables Where Var_id = @VariableId
If @ProductId Is Not Null
  Select @ProductCode = prod_Code From Products Where Prod_id = @ProductId
 	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 SELECT @EndTime =  dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
 --**********************************************
-- Return Header Information
--**********************************************
-- Line1: Report Name
-- Line2: Criteria
-- Line3: Generate Time
-- Line4 - n: Column Names
Create Table #Prompts (
  PromptId int identity(1,1),
  PromptName varchar(20),
  PromptValue varchar(1000)
)
Insert into #Prompts (PromptName, PromptValue) Values ('ReportName', @ReportName)
Select @CriteriaString = 'Comments'
If @ProductId Is Not Null
 	 Select @CriteriaString = @CriteriaString + ' For ' + @ProductCode 
 	 Select @CriteriaString = @CriteriaString + ' From [' + convert(varchar(17), dbo.fnServer_CmnConvertFromDBTime(@StartTime,@InTimeZone),109) + '] To [' + convert(varchar(17), dbo.fnServer_CmnConvertFromDBTime(@EndTime,@InTimeZone),109) + ']'
Insert into #Prompts (PromptName, PromptValue) Values ('Criteria', @CriteriaString)
Insert into #Prompts (PromptName, PromptValue) Values ('GenerateTime', 'Created: ' + convert(varchar(17), dbo.fnServer_CmnGetDate(getutcdate()),109))
Insert into #Prompts (PromptName, PromptValue) Values ('TabTitle', @VariableName)
Insert into #Prompts (PromptName, PromptValue) Values ('Time', 'Time')
Insert into #Prompts (PromptName, PromptValue) Values ('Value', 'Value')
Insert into #Prompts (PromptName, PromptValue) Values ('Product', 'Product')
Insert into #Prompts (PromptName, PromptValue) Values ('Target', 'Target')
Insert into #Prompts (PromptName, PromptValue) Values ('WarningLimits', 'Warning Limits')
Insert into #Prompts (PromptName, PromptValue) Values ('RejectLimits', 'Reject Limits')
Insert into #Prompts (PromptName, PromptValue) Values ('Comments', 'Comments')
Insert into #Prompts (PromptName, PromptValue) Values ('TargetTimeZone',@InTimeZone)
select * From #Prompts
Drop Table #Prompts
--**********************************************
-- Return Data For Report
--**********************************************
Declare @MasterUnit int
Declare @IsEventBased int
Select @MasterUnit = coalesce(pu.Master_Unit, pu.PU_Id),
       @IsEventBased = Case When v.Event_Type = 1 Then 1 Else 0 End
  From Variables v
  Join Prod_Units pu on pu.pu_id = v.pu_id 
  where v.Var_id = @VariableId
If @ProductId Is Null
  Begin
     If @IsEventBased = 1
       Begin
          Select TimeStamp =   dbo.fnServer_CmnConvertFromDBTime(t.Result_On,@InTimeZone)  , Event = e.Event_Num, EventId = e.Event_Id, Product = p.Prod_Code, Value = t.Result, 
                 Target = coalesce(vs.target,'*'), 
                 WarningLimits = coalesce(vs.l_warning,'*') + ' - ' + coalesce(vs.u_warning,'*'), 
                 RejectLimits = coalesce(vs.l_reject,'*') + ' - ' + coalesce(vs.u_reject,'*'), 
                 Comment = c.Comment_Text
           From Tests t
           Join Comments c on c.Comment_Id = t.Comment_Id
           Join Events e on e.pu_Id = @MasterUnit and e.Timestamp = t.Result_On 
           Join Production_Starts ps on ps.PU_Id = @MasterUnit and ps.Start_Time <= t.Result_On and ((ps.End_Time > t.Result_On) or (ps.End_Time Is Null))
           Join Products p on p.Prod_Id = Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End
           Left Outer Join Var_Specs vs on vs.Var_id = @VariableId and vs.Prod_Id = Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End and vs.effective_date <= t.Result_on and ((vs.expiration_date > t.result_on) or (vs.expiration_date Is Null))
           Where t.Var_Id = @VariableId and
                 t.Result_On >= @StartTime and
                 t.Result_On < @EndTime and
                 t.Comment_Id Is Not Null
       End
     Else
       Begin
          Select TimeStamp =  dbo.fnServer_CmnConvertFromDBTime(t.Result_On,@InTimeZone) , Event = NULL, EventId = NULL, Product = p.Prod_Code, Value = t.Result, 
                 Target = coalesce(vs.target,'*'), 
                 WarningLimits = coalesce(vs.l_warning,'*') + ' - ' + coalesce(vs.u_warning,'*'), 
                 RejectLimits = coalesce(vs.l_reject,'*') + ' - ' + coalesce(vs.u_reject,'*'), 
                 Comment = c.Comment_Text
           From Tests t
           Join Comments c on c.Comment_Id = t.Comment_Id
           Join Production_Starts ps on ps.PU_Id = @MasterUnit and ps.Start_Time <= t.Result_On and ((ps.End_Time > t.Result_On) or (ps.End_Time Is Null))
           Join Products p on p.Prod_Id = ps.Prod_Id
           Left Outer Join Var_Specs vs on vs.Var_id = @VariableId and vs.Prod_Id = ps.Prod_Id and vs.effective_date <= t.Result_on and ((vs.expiration_date > t.result_on) or (vs.expiration_date Is Null))
           Where t.Var_Id = @VariableId and
                 t.Result_On >= @StartTime and
                 t.Result_On < @EndTime and
                 t.Comment_Id Is Not Null
       End        
  End
Else
  Begin
    If @IsEventBased = 1
      Begin
          Select TimeStamp =   dbo.fnServer_CmnConvertFromDBTime(t.Result_On,@InTimeZone)  , Event = e.Event_Num, EventId = e.Event_Id, Product = @ProductCode, Value = t.Result, 
                 Target = coalesce(vs.target,'*'), 
                 WarningLimits = coalesce(vs.l_warning,'*') + ' - ' + coalesce(vs.u_warning,'*'), 
                 RejectLimits = coalesce(vs.l_reject,'*') + ' - ' + coalesce(vs.u_reject,'*'), 
                 Comment = c.Comment_Text
           From Tests t
           Join Comments c on c.Comment_Id = t.Comment_Id
           Join Events e on e.pu_Id = @MasterUnit and e.Timestamp = t.Result_On 
           Join Production_Starts ps on ps.PU_Id = @MasterUnit and ps.Start_Time <= t.Result_On and ((ps.End_Time > t.Result_On) or (ps.End_Time Is Null))
           Left Outer Join Var_Specs vs on vs.Var_id = @VariableId and vs.Prod_Id = Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End and vs.effective_date <= t.Result_on and ((vs.expiration_date > t.result_on) or (vs.expiration_date Is Null))
           Where t.Var_Id = @VariableId and
                 t.Result_On >= @StartTime and
                 t.Result_On < @EndTime and
                 t.Comment_Id Is Not Null and
                 ((ps.Prod_Id = @ProductId) or (e.Applied_Product = @ProductId))
      End
    Else
      Begin
          Select TimeStamp =   dbo.fnServer_CmnConvertFromDBTime(t.Result_On,@InTimeZone)  , Event = NULL, EventId = NULL, Product = @ProductCode, Value = t.Result, 
                 Target = coalesce(vs.target,'*'), 
                 WarningLimits = coalesce(vs.l_warning,'*') + ' - ' + coalesce(vs.u_warning,'*'), 
                 RejectLimits = coalesce(vs.l_reject,'*') + ' - ' + coalesce(vs.u_reject,'*'), 
                 Comment = c.Comment_Text
           From Tests t
           Join Comments c on c.Comment_Id = t.Comment_Id
           Join Production_Starts ps on ps.PU_Id = @MasterUnit and ps.Prod_Id = @ProductId and ps.Start_Time <= t.Result_On and ((ps.End_Time > t.Result_On) or (ps.End_Time Is Null))
           Left Outer Join Var_Specs vs on vs.Var_id = @VariableId and vs.Prod_Id = ps.Prod_Id and vs.effective_date <= t.Result_on and ((vs.expiration_date > t.result_on) or (vs.expiration_date Is Null))
           Where t.Var_Id = @VariableId and
                 t.Result_On >= @StartTime and
                 t.Result_On < @EndTime and
                 t.Comment_Id Is Not Null
      End
  End
