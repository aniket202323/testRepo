CREATE PROCEDURE dbo.spRS_GetReportTreeNode
@Node_Id int
 AS
Declare @SendParameters tinyint
Declare @ForceRunMode tinyint
Declare @ForceRunModeSource int
Declare @SendParametersSource int
Declare @SourceReportType int
Declare @SourceTreeNode int
Select RD.Report_Name, RT.Description, RTN.SendParameters as SendParametersLocal, RTN.ForceRunMode as ForceRunModeLocal,
RT.Send_Parameters as SendParametersDefault, RT.ForceRunMode as ForceRunModeDefault,
RTN.Node_Id, RTN.Report_Tree_Template_Id, RTN.Node_Id_Type, RTN.Parent_Node_Id,
RTN.Report_Def_Id, RTN.Report_Type_Id, RTN.Node_Order, RTN.Node_Level, RTN.Node_Name, RTN.URL
From Report_Tree_Nodes RTN
Left Join Report_Definitions RD on RTN.Report_Def_Id = RD.Report_Id
Left Join Report_Types RT on RTN.Report_Type_Id = RT.Report_Type_Id
Where Node_Id = @Node_ID
/*
Select @SourceReportType = 0
Select @SourceTreeNode = 1
-------------------------------------------------------------
-- Determine If SendParameters Has Been Set At The Node Level
-------------------------------------------------------------
Select 
 	 @SendParameters = SendParameters,
 	 @ForceRunMode = ForceRunMode
From Report_Tree_Nodes 
Where Node_Id = @Node_Id
If ((@SendParameters Is Null) or (@SendParameters = 0)) and ((@ForceRunMode Is Null) or (@ForceRunMode = 0))
  Begin
 	 Select @SendParametersSource = @SourceReportType
 	 Select @ForceRunModeSource = @SourceReportType
 	 Select RD.Report_Name, RT.Description, RT.Send_Parameters as SendParameters, RT.ForceRunMode as ForceRunMode,
 	 RTN.Node_Id, RTN.Report_Tree_Template_Id, RTN.Node_Id_Type, RTN.Parent_Node_Id,
 	 RTN.Report_Def_Id, RTN.Report_Type_Id, RTN.Node_Order, RTN.Node_Level, RTN.Node_Name, RTN.URL, @SendParametersSource 'SendParametersSource', @ForceRunModeSource 'ForceRunModeSource'
 	 From Report_Tree_Nodes RTN
 	 Left Join Report_Definitions RD on RTN.Report_Def_Id = RD.Report_Id
 	 Left Join Report_Types RT on RTN.Report_Type_Id = RT.Report_Type_Id
 	 Where Node_Id = @Node_ID
  End
If ((@SendParameters Is Null) or (@SendParameters = 0)) and (@ForceRunMode Is Not Null) 
  Begin
 	 Select @SendParametersSource = @SourceReportType
 	 Select @ForceRunModeSource = @SourceTreeNode
 	 Select RD.Report_Name, RT.Description, RT.Send_Parameters as SendParameters, 
 	 RTN.Node_Id, RTN.Report_Tree_Template_Id, RTN.Node_Id_Type, RTN.Parent_Node_Id,
 	 RTN.Report_Def_Id, RTN.Report_Type_Id, RTN.Node_Order, RTN.Node_Level, RTN.Node_Name,
 	 RTN.URL, RTN.ForceRunMode, @SendParametersSource 'SendParametersSource', @ForceRunModeSource 'ForceRunModeSource'
 	 From Report_Tree_Nodes RTN
 	 Left Join Report_Definitions RD on RTN.Report_Def_Id = RD.Report_Id
 	 Left Join Report_Types RT on RTN.Report_Type_Id = RT.Report_Type_Id
 	 Where Node_Id = @Node_ID
  End
If (@SendParameters Is Not Null) and ((@ForceRunMode Is Null) or (@ForceRunMode = 0))
  Begin
 	 Select @SendParametersSource = @SourceTreeNode
 	 Select @ForceRunModeSource = @SourceReportType
 	 Select RD.Report_Name, RT.Description, RT.ForceRunMode as ForceRunMode, 
 	 RTN.Node_Id, RTN.Report_Tree_Template_Id, RTN.Node_Id_Type, RTN.Parent_Node_Id,
 	 RTN.Report_Def_Id, RTN.Report_Type_Id, RTN.Node_Order, RTN.Node_Level, RTN.Node_Name,
 	 RTN.URL, RTN.SendParameters, @SendParametersSource 'SendParametersSource', @ForceRunModeSource 'ForceRunModeSource'
 	 From Report_Tree_Nodes RTN
 	 Left Join Report_Definitions RD on RTN.Report_Def_Id = RD.Report_Id
 	 Left Join Report_Types RT on RTN.Report_Type_Id = RT.Report_Type_Id
 	 Where Node_Id = @Node_ID
  End
If (@SendParameters Is Not Null) and (@ForceRunMode Is Not Null) 
  Begin
 	 Select @SendParametersSource = @SourceTreeNode
 	 Select @ForceRunModeSource = @SourceTreeNode
 	 Select RD.Report_Name, RT.Description, 
 	 RTN.Node_Id, RTN.Report_Tree_Template_Id, RTN.Node_Id_Type, RTN.Parent_Node_Id,
 	 RTN.Report_Def_Id, RTN.Report_Type_Id, RTN.Node_Order, RTN.Node_Level, RTN.Node_Name,
 	 RTN.URL, RTN.SendParameters, RTN.ForceRunMode, @SendParametersSource 'SendParametersSource', @ForceRunModeSource 'ForceRunModeSource'
 	 From Report_Tree_Nodes RTN
 	 Left Join Report_Definitions RD on RTN.Report_Def_Id = RD.Report_Id
 	 Left Join Report_Types RT on RTN.Report_Type_Id = RT.Report_Type_Id
 	 Where Node_Id = @Node_ID
  End
*/
