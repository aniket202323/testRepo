CREATE PROCEDURE dbo.spBF_calGetEventDetail
   @ID INTEGER
AS
BEGIN
 	 -- SET NOCOUNT ON added to prevent extra result sets from
 	 -- interfering with SELECT statements.
 	 SET NOCOUNT ON;
  SELECT te.TEDet_id,te.Start_Time,te.End_Time,te.Reason_Level1,r1.Event_Reason_Name_Local,te.PU_Id,u.PU_Desc, 
         c.Comment as comment, c2.Comment_Text as actionComment,
         te.Reason_Level2,r2.Event_Reason_Name_Local as Reason_Name2,
         te.Reason_Level3,r3.Event_Reason_Name_Local as Reason_Name3,
         te.Reason_Level4,r4.Event_Reason_Name_Local as Reason_Name4,
         te.Event_Reason_Tree_Data_Id as treeId
    from Timed_Event_details te
      left join Event_Reasons r1 on te.Reason_Level1 = r1.Event_Reason_Id 
      left join Event_Reasons r2 on te.Reason_Level2 = r2.Event_Reason_Id 
      left join Event_Reasons r3 on te.Reason_Level3 = r3.Event_Reason_Id 
      left join Event_Reasons r4 on te.Reason_Level4 = r4.Event_Reason_Id 
      left join comments c on c.Comment_Id = te.Cause_Comment_Id
      left join comments c2 on c2.Comment_Id = te.Action_Comment_Id
      join Prod_Units u on u.PU_Id = te.PU_Id
  where te.TEDet_Id = @ID
END
