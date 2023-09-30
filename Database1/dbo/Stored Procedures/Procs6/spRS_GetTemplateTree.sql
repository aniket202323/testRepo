CREATE PROCEDURE dbo.spRS_GetTemplateTree
@TemplateId int
AS
Select RTT.Report_Tree_Template_Name, RT.Class_Name,
 	 RTN.Node_Id, RTN.Report_Tree_Template_Id, RTN.Node_Id_Type, RTN.Parent_Node_Id,
 	 RTN.Report_Def_Id, RTN.Report_Type_Id, RTN.Node_Order, RTN.Node_Level, RTN.Node_Name,
 	 RTN.URL, RTN.ForceRunMode,
 	 'SendParameters' = 
 	 Case 
 	  	 When RTN.SendParameters Is Null Then RT.Send_Parameters
 	  	 Else RTN.SendParameters
 	 End
From Report_Tree_Nodes RTN
  Left join Report_Tree_Templates RTT on RTT.Report_Tree_Template_Id = @TemplateId
  Left Join Report_Definitions RD on RTN.Report_Def_Id = RD.Report_Id
  Left Join Report_Types RT on RTN.Report_Type_Id = RT.Report_Type_Id OR RT.Report_Type_Id = RD.Report_Type_Id
  where RTN.Report_Tree_Template_Id = @TemplateId
  Order By RTN.Node_Level asc, RTN.Node_Order asc
/*
Select RTT.Report_Tree_Template_Name,  rtn.*, RT.Class_Name
From Report_Tree_Nodes RTN
  Left join Report_Tree_Templates RTT on RTT.Report_Tree_Template_Id = @TemplateId
  Left Join Report_Definitions RD on RTN.Report_Def_Id = RD.Report_Id
  Left Join Report_Types RT on RTN.Report_Type_Id = RT.Report_Type_Id OR RT.Report_Type_Id = RD.Report_Type_Id
  where RTN.Report_Tree_Template_Id = @TemplateId
  Order By RTN.Node_Level asc, RTN.Node_Order asc
*/
