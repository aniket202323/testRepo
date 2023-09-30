Create View dbo.Variables 
AS
select a.Var_Id,ArrayStatOnly,Calculation_Id,a.Comment_Id,Comparison_Operator_Id,
 	 Comparison_Value,CPK_SubGroup_Size,Data_Type_Id,Debug,DQ_Tag,
 	 DS_Id,Eng_Units ,Esignature_Level,Event_Dimension,Event_Subtype_Id,
 	 Event_Type,a.Extended_Info,Extended_Test_Freq,a.External_Link,Force_Sign_Entry,
 	 a.Group_Id,Input_Tag,Input_Tag2,Is_Active,Is_Conformance_Variable,
 	 LEL_Tag,LRL_Tag,LUL_Tag,LWL_Tag,Max_RPM,
 	 Output_DS_Id,Output_Tag,PEI_Id,ProdCalc_Type,a.PU_Id,
 	 PUG_Id,PUG_Order,PVar_Id,Rank,ReadLagTime,
 	 Reload_Flag,Repeat_Backtime,Repeating,Reset_Value,Retention_Limit,
 	 SA_Id,Sampling_Interval,Sampling_Offset,Sampling_Reference_Var_Id,Sampling_Type,
 	 Sampling_Window,ShouldArchive,SPC_Calculation_Type_Id,SPC_Group_Variable_Type_Id,Spec_Id,
 	 String_Specification_Setting,System,a.Tag,Target_Tag,Test_Name,
 	 TF_Reset,Tot_Factor,UEL_Tag,Unit_Reject,Unit_Summarize,
 	 URL_Tag,a.User_Defined1,a.User_Defined2,a.User_Defined3,UUL_Tag,
 	 UWL_Tag,Var_Precision,Var_Reject,Write_Group_DS_Id,
 	 Perform_Event_Lookup,
 	 Var_Desc =  Case When @@options&(512) !=(0) THEN Coalesce(e.Origin1Name,a.Var_Desc,a.Var_Desc_Global)
 	  	  	  	   ELSE  Coalesce(a.Var_Desc_Global, e.Origin1Name,a.Var_Desc)
 	  	  	  	   END,
 	 a.Var_Desc_Global,
 	 Ignore_Event_Status, 	  	  	  	   
 	 Var_Desc_Local = Coalesce(e.Origin1Name,a.Var_Desc,a.Var_Desc_Global) 	  	  	   
FROM dbo.Variables_Base a
Left JOIN dbo.Variables_Aspect_EquipmentProperty e on e.Var_Id = a.Var_Id 
WHERE a.PU_Id  != 0

GO
CREATE TRIGGER [dbo].[VariablesViewIns]
 ON  [dbo].[Variables]
  Instead of INSERT
  AS
 	 
IF (Context_info() = 0x446174615075726765) RETURN --DataPurge
BEGIN
 	 SET NOCOUNT ON
 	 DECLARE 	 @GUIDId UniqueIdentifier
 	 DECLARE @NewDesc 	 nVarChar(100)
 	 DECLARE @TestName 	 nVarChar(100)
 	 DECLARE @EngUnit 	 nVarChar(100)
 	 DECLARE @PAId 	 Int
 	 DECLARE @PUID 	 Int
 	 
 	 INSERT INTO Variables_Base (ArrayStatOnly,Calculation_Id,Comment_Id,Comparison_Operator_Id,Comparison_Value,
 	  	  	  	  	  	  	  	 CPK_SubGroup_Size,Data_Type_Id,Debug,DQ_Tag,DS_Id,
 	  	  	  	  	  	  	  	 Eng_Units,Esignature_Level,Event_Dimension,Event_Subtype_Id,Event_Type,
 	  	  	  	  	  	  	  	 Extended_Info,Extended_Test_Freq,External_Link,Force_Sign_Entry,Group_Id,
 	  	  	  	  	  	  	  	 Input_Tag,Input_Tag2,Is_Active,Is_Conformance_Variable,LEL_Tag,
 	  	  	  	  	  	  	  	 LRL_Tag,LUL_Tag,LWL_Tag,Max_RPM,Output_DS_Id,
 	  	  	  	  	  	  	  	 Output_Tag,PEI_Id,ProdCalc_Type,PU_Id,PUG_Id,
 	  	  	  	  	  	  	  	 PUG_Order,PVar_Id,Rank,ReadLagTime,Reload_Flag,
 	  	  	  	  	  	  	  	 Repeat_Backtime,Repeating,Reset_Value,Retention_Limit,SA_Id,
 	  	  	  	  	  	  	  	 Sampling_Interval,Sampling_Offset,Sampling_Reference_Var_Id,Sampling_Type,Sampling_Window,
 	  	  	  	  	  	  	  	 ShouldArchive,SPC_Calculation_Type_Id,SPC_Group_Variable_Type_Id,Spec_Id,String_Specification_Setting,
 	  	  	  	  	  	  	  	 System,Tag,Target_Tag,Test_Name,TF_Reset,
 	  	  	  	  	  	  	  	 Tot_Factor,UEL_Tag,Unit_Reject,Unit_Summarize,URL_Tag,
 	  	  	  	  	  	  	  	 User_Defined1,User_Defined2,User_Defined3,UUL_Tag,UWL_Tag,
 	  	  	  	  	  	  	  	 Var_Precision,Var_Reject,Write_Group_DS_Id,Perform_Event_Lookup,Var_Desc,Ignore_Event_Status)
 	  	  	  	  	  	  	  	 
 	 SELECT Coalesce(ArrayStatOnly,0),Calculation_Id,Comment_Id,Comparison_Operator_Id,Comparison_Value,
 	  	  	  	  	  	  	  	 CPK_SubGroup_Size,Data_Type_Id,Coalesce(Debug,0),DQ_Tag,DS_Id,
 	  	  	  	  	  	  	  	 Eng_Units,Esignature_Level,Event_Dimension,Event_Subtype_Id,Coalesce(Event_Type,0),
 	  	  	  	  	  	  	  	 Extended_Info,Coalesce(Extended_Test_Freq,1),External_Link,Coalesce(Force_Sign_Entry,0),Group_Id,
 	  	  	  	  	  	  	  	 Input_Tag,Input_Tag2,Coalesce(Is_Active,1),Coalesce(Is_Conformance_Variable,0),LEL_Tag,
 	  	  	  	  	  	  	  	 LRL_Tag,LUL_Tag,LWL_Tag,Max_RPM,Output_DS_Id,
 	  	  	  	  	  	  	  	 Output_Tag,PEI_Id,ProdCalc_Type,PU_Id,PUG_Id,
 	  	  	  	  	  	  	  	 Coalesce(PUG_Order,1),PVar_Id,Coalesce(Rank,0),ReadLagTime,Reload_Flag,
 	  	  	  	  	  	  	  	 Repeat_Backtime,Repeating,Reset_Value,Retention_Limit,Coalesce(SA_Id,1),
 	  	  	  	  	  	  	  	 Sampling_Interval,Sampling_Offset,Sampling_Reference_Var_Id,Sampling_Type,Sampling_Window,
 	  	  	  	  	  	  	  	 Coalesce(ShouldArchive,1),SPC_Calculation_Type_Id,SPC_Group_Variable_Type_Id,Spec_Id,String_Specification_Setting,
 	  	  	  	  	  	  	  	 System,Tag,Target_Tag,Test_Name,Coalesce(TF_Reset,0),
 	  	  	  	  	  	  	  	 Coalesce(Tot_Factor,1.0),UEL_Tag,Coalesce(Unit_Reject,0),Coalesce(Unit_Summarize,0),URL_Tag,
 	  	  	  	  	  	  	  	 User_Defined1,User_Defined2,User_Defined3,UUL_Tag,UWL_Tag,
 	  	  	  	  	  	  	  	 Var_Precision,Coalesce(Var_Reject,0),Write_Group_DS_Id,Coalesce(Perform_Event_Lookup,1),Var_Desc,Ignore_Event_Status
 	  	  	  	 FROM INSERTED
 	 SELECT @PAId = SCOPE_IDENTITY()
 	 IF EXISTS(SELECT 1 FROM Variables_Base WHERE Var_Id = @PAId and PU_Id > 0) AND EXISTS(SELECT 1 FROM Site_Parameters WHERE Parm_Id = 87  and Value = 1 )
  	  	 INSERT INTO PlantAppsSOAPendingTasks(ActualId,TableId) 	 VALUES(@PAId,20)
END
