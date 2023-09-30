create procedure [dbo].[spWD_GetDTEventsWithoutReasons]
  @UnitIds VarChar(8000) = Null,
  @MaxCommentLength Int = 200,
  @InTimeZone nvarchar(200)=NULL
AS
create table #UnitIds(Id_Order int, Var_Id int)
-- Put the Unit Id's into a temp table
If @UnitIds Is Not Null
  Insert Into #UnitIds Exec spRS_MakeOrderedResultSet @UnitIds
Select ted.TEDet_Id EventId, ted.Source_PU_Id LocationId, u.PU_Desc LocationName, ted.TEFault_Id FaultId, tef.TEFault_Name FaultName,
       'Start_Time'=[dbo].[fnServer_CmnConvertFromDbTime] (ted.Start_Time,@InTimeZone), 'End_Time'=[dbo].[fnServer_CmnConvertFromDbTime] (ted.End_Time,@InTimeZone), ted.Duration,
       rh1.Level_Name ReasonHeader1, er1.Event_Reason_Name ReasonName1, rh2.Level_Name ReasonHeader2, er2.Event_Reason_Name ReasonName2,
       rh3.Level_Name ReasonHeader3, er3.Event_Reason_Name ReasonName3, rh4.Level_Name ReasonHeader4, er4.Event_Reason_Name ReasonName4,
       Left(dbo.fnWF_GetCommentSummary(ted.Cause_Comment_Id, @MaxCommentLength) + dbo.fnWF_GetCommentSummary(ted.Action_Comment_Id, @MaxCommentLength) + dbo.fnWF_GetCommentSummary(ted.Research_Comment_Id, @MaxCommentLength), @MaxCommentLength) CommentSummary,
       ted.PU_Id UnitId
From Timed_Event_Details ted
Join Event_Reason_Tree_Data ertd On ted.Event_Reason_Tree_Data_Id = ertd.Event_Reason_Tree_Data_Id
Left Outer Join Timed_Event_Fault tef On tef.TEFault_Id = ted.TEFault_Id
Left Outer Join Prod_Units u On ted.Source_PU_Id = u.PU_Id
Left Outer Join Prod_Events pe On (ted.Source_PU_Id = pe.PU_Id And Event_Type = 2)
Left Outer Join Event_Reason_Level_Headers rh1 On (pe.Name_Id = rh1.Tree_Name_Id And rh1.Reason_Level = 1)
Left Outer Join Event_Reason_Level_Headers rh2 On (pe.Name_Id = rh2.Tree_Name_Id And rh2.Reason_Level = 2)
Left Outer Join Event_Reason_Level_Headers rh3 On (pe.Name_Id = rh3.Tree_Name_Id And rh3.Reason_Level = 3)
Left Outer Join Event_Reason_Level_Headers rh4 On (pe.Name_Id = rh4.Tree_Name_Id And rh4.Reason_Level = 4)
Left Outer Join Event_Reasons er1 On ted.Reason_Level1 = er1.Event_Reason_Id
Left Outer Join Event_Reasons er2 On ted.Reason_Level2 = er2.Event_Reason_Id
Left Outer Join Event_Reasons er3 On ted.Reason_Level3 = er3.Event_Reason_Id
Left Outer Join Event_Reasons er4 On ted.Reason_Level4 = er4.Event_Reason_Id
Where ertd.Bottom_Of_Tree = 0
And (ted.PU_Id In (Select Var_Id From #UnitIds) Or @UnitIds Is Null)
