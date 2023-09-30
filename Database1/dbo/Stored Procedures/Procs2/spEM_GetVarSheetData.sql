CREATE PROCEDURE dbo.spEM_GetVarSheetData
  @Var_Id int  AS
  --
  SELECT v.Spec_Id,
 	  	 s.Spec_desc,
 	  	 pp.Prop_Desc,
         v.Sampling_Interval,
         v.Sampling_Offset,
         v.Sampling_Type,
         Sampling_Window_Type = CASE
 	  	  	  	    WHEN ((v.Sampling_Window >= 0 ) OR (v.Sampling_Window IS NULL)) THEN 0
                                   ELSE v.Sampling_Window
                                END,
         v.Event_Type,
         v.Var_Reject,
         v.Unit_Reject,
         v.Rank,
         Input_Tag = dbo.fnEM_ConvertVarIdToTag(v.Input_Tag),
         Input_Tag2 = dbo.fnEM_ConvertVarIdToTag(v.Input_Tag2),
         Output_Tag = dbo.fnEM_ConvertVarIdToTag(v.Output_Tag),
         DQ_Tag = dbo.fnEM_ConvertVarIdToTag(v.DQ_Tag),
         UEL_Tag = dbo.fnEM_ConvertVarIdToTag(v.UEL_Tag),
         URL_Tag = dbo.fnEM_ConvertVarIdToTag(v.URL_Tag),
         UWL_Tag = dbo.fnEM_ConvertVarIdToTag(v.UWL_Tag),
         UUL_Tag = dbo.fnEM_ConvertVarIdToTag(v.UUL_Tag),
         Target_Tag = dbo.fnEM_ConvertVarIdToTag(v.Target_Tag),
         LUL_Tag = dbo.fnEM_ConvertVarIdToTag(v.LUL_Tag),
         LWL_Tag = dbo.fnEM_ConvertVarIdToTag(v.LWL_Tag),
         LRL_Tag = dbo.fnEM_ConvertVarIdToTag(v.LRL_Tag),
         LEL_Tag = dbo.fnEM_ConvertVarIdToTag(v.LEL_Tag),
         v.Tot_Factor,
         v.TF_Reset,
         v.SA_Id,
 	   	  v.Comparison_Operator_Id,
 	   	  V.Comparison_Value,
         Repeating = CASE
                       WHEN (v.Repeating IS NULL) OR
                            ((v.Repeating IS NOT NULL) AND (v.Repeating = 0)) THEN 0
                       ELSE 1
                     END,
         v.Repeat_Backtime,
         v.Sampling_Window,
         Should_Archive = CASE
                            WHEN (v.ShouldArchive IS NULL) OR
                                 ((v.ShouldArchive IS NOT NULL) AND (v.ShouldArchive = 0)) THEN 0
                            ELSE 1
                          END,
 	  	 v.Extended_Info,
 	  	 v.User_Defined1,
 	  	 v.User_Defined2,
 	  	 v.User_Defined3,
 	  	 v.Unit_Summarize,
 	  	 v.Force_Sign_Entry,
 	  	 v.Test_Name,
 	  	 v.Extended_Test_Freq,
 	  	 v.ArrayStatOnly,
 	  	 v.Max_RPM,
 	  	 v.Reset_Value,
 	  	 v.Is_Conformance_Variable,
 	  	 v.Esignature_Level,
 	  	 v.Event_Subtype_Id,
 	  	 v.Event_Dimension,
 	  	 v.PEI_Id,
 	  	 v.SPC_Calculation_Type_Id, 
 	  	 v.SPC_Group_Variable_Type_Id,
 	  	 v.Sampling_Reference_Var_Id,
 	  	 v.String_Specification_Setting,
 	  	 Write_Group_DS_Id = Isnull(v.Write_Group_DS_Id,-1),
 	  	 CPK_SubGroup_Size = IsNull(v.CPK_SubGroup_Size,1),
 	  	 Reload_Flag  = isnull(v.Reload_Flag,0),
 	  	 ReadLagTime = isnull(v.ReadLagTime,0),
 	  	 EventLookup=isnull(Perform_Event_Lookup,0),
 	  	 Debug = isnull(Debug,0),
 	  	 Ignore_Event_Status = isnull(Ignore_Event_Status,0)
    FROM Variables v
 	  Left Join Specifications s on s.Spec_Id = v.Spec_Id
 	  Left Join Product_Properties pp on pp.Prop_Id = s.Prop_Id  	 
    WHERE v.Var_Id = @Var_Id
