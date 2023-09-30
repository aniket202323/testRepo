
CREATE PROCEDURE dbo.spMES_GetFaults
		@LocationId  Int = Null
		,@FaultId	 Int = Null

AS

DECLARE @UnitId Int = Null /* Not currently used */

/*
 EXECUTE dbo.spMES_GetFaults 1,null
 EXECUTE dbo.spMES_GetFaults null,1
 */
IF @LocationId Is Not Null
BEGIN
	SELECT 
		FaultId = TEFault_Id
		,ERTDId = Event_Reason_Tree_Data_Id
		,UnitId = a.PU_Id
		,Unit = pu1.PU_Desc
		,LocationId = Source_PU_Id
		,Location = pu.PU_Desc 
		,Reason1Id = Reason_Level1 , Reason1 = r1.Event_Reason_Name
		,Reason2Id = Reason_Level2 , Reason2 = r2.Event_Reason_Name
		,Reason3Id = Reason_Level3 , Reason3 = r3.Event_Reason_Name
		,Reason4Id = Reason_Level4,  Reason4 = r4.Event_Reason_Name
		,FaultValue = TEFault_Value 
		,FaultName = TEFault_Name 
		 from Timed_Event_Fault a
		 Left Join Prod_Units_Base pu on pu.PU_Id = a.Source_PU_Id
		 Left Join Prod_Units_Base pu1 on pu1.PU_Id = a.PU_Id
		 LEFT Join Event_Reasons r1 on r1.Event_Reason_Id = a.Reason_Level1 
		 LEFT Join Event_Reasons r2 on r2.Event_Reason_Id = a.Reason_Level2 
		 LEFT Join Event_Reasons r3 on r3.Event_Reason_Id = a.Reason_Level3 
		 LEFT Join Event_Reasons r4 on r4.Event_Reason_Id = a.Reason_Level4
		WHERE a.Source_PU_Id = @LocationId 
End
ELSE IF @FaultId Is Not Null
BEGIN
	SELECT 
		FaultId = TEFault_Id
		,ERTDId = Event_Reason_Tree_Data_Id
		,UnitId = a.PU_Id
		,Unit = pu1.PU_Desc
		,LocationId = Coalesce(a.Source_PU_Id,a.PU_Id)
		,Location = Coalesce(pu.PU_Desc,pu1.PU_Desc) 
		,Reason1Id = Reason_Level1 , Reason1 = r1.Event_Reason_Name
		,Reason2Id = Reason_Level2 , Reason2 = r2.Event_Reason_Name
		,Reason3Id = Reason_Level3 , Reason3 = r3.Event_Reason_Name
		,Reason4Id = Reason_Level4,  Reason4 = r4.Event_Reason_Name
		,FaultValue = TEFault_Value 
		,FaultName = TEFault_Name 
		 from Timed_Event_Fault a
		 Left Join Prod_Units_Base pu on pu.PU_Id = a.Source_PU_Id
		 Left Join Prod_Units_Base pu1 on pu1.PU_Id = a.PU_Id
		 LEFT Join Event_Reasons r1 on r1.Event_Reason_Id = a.Reason_Level1 
		 LEFT Join Event_Reasons r2 on r2.Event_Reason_Id = a.Reason_Level2 
		 LEFT Join Event_Reasons r3 on r3.Event_Reason_Id = a.Reason_Level3 
		 LEFT Join Event_Reasons r4 on r4.Event_Reason_Id = a.Reason_Level4
		WHERE a.TEFault_Id = @FaultId 
END
ELSE
BEGIN
	SELECT 
		FaultId = TEFault_Id
		,ERTDId = Event_Reason_Tree_Data_Id
		,UnitId = a.PU_Id
		,Unit = pu1.PU_Desc
		,LocationId = Coalesce(a.Source_PU_Id,a.PU_Id)
		,Location = Coalesce(pu.PU_Desc,pu1.PU_Desc) 
		,Reason1Id = Reason_Level1 , Reason1 = r1.Event_Reason_Name
		,Reason2Id = Reason_Level2 , Reason2 = r2.Event_Reason_Name
		,Reason3Id = Reason_Level3 , Reason3 = r3.Event_Reason_Name
		,Reason4Id = Reason_Level4,  Reason4 = r4.Event_Reason_Name
		,FaultValue = TEFault_Value 
		,FaultName = TEFault_Name 
		 from Timed_Event_Fault a
		 Left Join Prod_Units_Base pu on pu.PU_Id = a.Source_PU_Id
		 Left Join Prod_Units_Base pu1 on pu1.PU_Id = a.PU_Id
		 LEFT Join Event_Reasons r1 on r1.Event_Reason_Id = a.Reason_Level1 
		 LEFT Join Event_Reasons r2 on r2.Event_Reason_Id = a.Reason_Level2 
		 LEFT Join Event_Reasons r3 on r3.Event_Reason_Id = a.Reason_Level3 
		 LEFT Join Event_Reasons r4 on r4.Event_Reason_Id = a.Reason_Level4
		WHERE a.PU_Id = @UnitId 
END

