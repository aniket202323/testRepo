Create Procedure dbo.spEMEC_GetReasonsByTree
 	 @Tree_Id 	 Int,
 	 @Level 	  	 Int,
 	 @CurrentDesc 	 nVarChar(100) = Null,
 	 @User_Id  	 int
 As 
Declare @CurrentId Int
Select @CurrentId = Null
If @CurrentDesc Is Not Null 
  Select @CurrentId = Event_Reason_Tree_Data_Id
 	 From Event_Reason_Tree_Data ertd
 	 Join Event_Reasons er On ertd.Event_Reason_Id  = er.Event_Reason_Id 
 	 Where Tree_Name_Id = @Tree_Id 
 	 And Event_Reason_Level = @Level - 1
 	 And Event_Reason_Name = @CurrentDesc
If @CurrentId Is Null
Select Event_Reason_Name,ertd.Event_Reason_Id 
 	 From Event_Reason_Tree_Data ertd
 	 Join Event_Reasons er On ertd.Event_Reason_Id  = er.Event_Reason_Id 
 	 Where Tree_Name_Id = @Tree_Id 
 	 And Parent_Event_R_Tree_Data_Id Is Null
Else
Select Event_Reason_Name,ertd.Event_Reason_Id 
 	 From Event_Reason_Tree_Data ertd
 	 Join Event_Reasons er On ertd.Event_Reason_Id  = er.Event_Reason_Id 
 	 Where Tree_Name_Id = @Tree_Id 
 	 And Event_Reason_Level = @Level
 	 And Parent_Event_R_Tree_Data_Id = @CurrentId
