CREATE PROCEDURE dbo.spEM_GetMultiLingualData
  @Object_Type  nVarChar(2),
  @QueryType 	 Int,
  @SearchString 	 nvarchar(255)
 AS
Select @SearchString = replace(@SearchString,'*','%')
Declare @Sql nvarchar(2000)
  If @Object_Type = 'aa'
    Begin
 	   Select @Sql = 'Select Id = Event_Reason_Id,Desc1 = Event_Reason_Name_Local,Desc2 = Event_Reason_Name_Global From Event_Reasons'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' Where Event_Reason_Name_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' Where Event_Reason_Name_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' Where Event_Reason_Name_Global Is Null'
 	   Select @Sql = @Sql + ' Order by Event_Reason_Name_Local'
 	 End
  Else If @Object_Type = 'ab'
    Begin
 	   Select @Sql = 'Select Id = ProdStatus_Id,Desc1 = ProdStatus_Desc_Local,Desc2 = ProdStatus_Desc_Global From Production_Status'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' Where ProdStatus_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' Where ProdStatus_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' Where ProdStatus_Desc_Global Is Null'
 	   Select @Sql = @Sql + '  Order by ProdStatus_Desc_Local'
 	 End
  Else If @Object_Type = 'ac'
    Begin
 	   Select @Sql = 'Select Id = WET_Id,Desc1 = WET_Name_Local,Desc2 = WET_Name_Global From Waste_Event_Type'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' Where WET_Name_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' Where WET_Name_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' Where WET_Name_Global Is Null'
 	   Select @Sql = @Sql + ' Order by WET_Name_Local'
 	 End
  Else If @Object_Type = 'ad'
    Begin
 	   Select @Sql = 'Select Id = Tree_Name_Id,Desc1 = Tree_Name_Local,Desc2 = Tree_Name_Global From Event_Reason_Tree'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' Where Tree_Name_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' Where Tree_Name_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' Where Tree_Name_Global Is Null'
 	   Select @Sql = @Sql + ' Order by Tree_Name_Local'
 	 End
  Else If @Object_Type = 'ae'
    Begin
 	   Select @Sql = 'Select Id = Sheet_Id,Desc1 = Sheet_Desc_Local,Desc2 = Sheet_Desc_Global From Sheets'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' Where Sheet_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' Where Sheet_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' Where Sheet_Desc_Global Is Null'
 	   Select @Sql = @Sql + ' Order By Sheet_Desc_Local'
 	 End
  Else If @Object_Type = 'af'
    Begin
 	   Select @Sql = 'Select Id = Sheet_Group_Id,Desc1 = Sheet_Group_Desc_Local,Desc2 = Sheet_Group_Desc_Global From Sheet_Groups'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' Where Sheet_Group_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' Where Sheet_Group_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' Where Sheet_Group_Desc_Global Is Null'
 	   Select @Sql = @Sql + ' Order by Sheet_Group_Desc_Local'
 	 End
  Else If @Object_Type = 'ag'
    Begin
 	   Select @Sql = 'Select Id = View_Id,Desc1 = View_Desc_Local,Desc2 = View_Desc_Global From Views'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' Where View_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' Where View_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' Where View_Desc_Global Is Null'
 	   Select @Sql = @Sql + ' Order by View_Desc_Local'
 	 End
  Else If @Object_Type = 'ah'
    Begin
 	   Select @Sql = 'Select Id = Product_Family_Id,Desc1 = Product_Family_Desc_Local,Desc2 = Product_Family_Desc_Global From Product_Family'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' Where Product_Family_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' Where Product_Family_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' Where Product_Family_Desc_Global Is Null'
 	   Select @Sql = @Sql + ' Order by Product_Family_Desc_Local'
 	 End
  Else If @Object_Type = 'ai'
    Begin
 	   Select @Sql = 'Select Id = Product_Grp_Id,Desc1 = Product_Grp_Desc_Local,Desc2 = Product_Grp_Desc_Global From Product_Groups'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' Where Product_Grp_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' Where Product_Grp_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' Where Product_Grp_Desc_Global Is Null'
 	   Select @Sql = @Sql + ' Order by Product_Grp_Desc_Local'
 	 End
  Else If @Object_Type = 'aj'
    Begin
 	   Select @Sql = 'Select Id = Prod_Id,Desc1 = Prod_Desc_Local,Desc2 = Prod_Desc_Global From Products Where Prod_Id > 1'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' and Prod_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' and Prod_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' and Prod_Desc_Global Is Null'
 	   Select @Sql = @Sql + ' Order by Prod_Desc_Local'
 	 End
  Else If @Object_Type = 'ak'
    Begin
 	   Select @Sql = 'Select Id = Prop_Id,Desc1 = Prop_Desc_Local,Desc2 = Prop_Desc_Global From Product_Properties'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' Where Prop_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' Where Prop_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' Where Prop_Desc_Global Is Null'
 	   Select @Sql = @Sql + ' Order by Prop_Desc_Local'
 	 End
  Else If @Object_Type = 'al'
    Begin
 	   Select @Sql = 'Select Id = Char_Id,Desc1 = Char_Desc_Local,Desc2 = Char_Desc_Global From Characteristics'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' Where Char_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' Where Char_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' Where Char_Desc_Global Is Null'
 	   Select @Sql = @Sql + ' Order by Char_Desc_Local'
 	 End
  Else If @Object_Type = 'am'
    Begin
 	   Select @Sql = 'Select Id = Characteristic_Grp_Id,Desc1 = Characteristic_Grp_Desc_Local,Desc2 = Characteristic_Grp_Desc_Global From Characteristic_Groups'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' Where Characteristic_Grp_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' Where Characteristic_Grp_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' Where Characteristic_Grp_Desc_Global Is Null'
 	   Select @Sql = @Sql + ' Order by Characteristic_Grp_Desc_Local'
 	 End
  Else If @Object_Type = 'an'
    Begin
 	   Select @Sql = 'Select Id = Spec_Id,Desc1 = Spec_Desc_Local,Desc2 = Spec_Desc_Global From Specifications'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' Where Spec_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' Where Spec_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' Where Spec_Desc_Global Is Null'
 	   Select @Sql = @Sql + ' Order by Spec_Desc_Local'
 	 End
  Else If @Object_Type = 'ao'
    Begin
 	   Select @Sql = 'Select Id = PL_Id,Desc1 = PL_Desc_Local,Desc2 = PL_Desc_Global From Prod_Lines Where PL_Id > 0'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' and PL_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' and PL_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' and PL_Desc_Global Is Null'
 	   Select @Sql = @Sql + ' Order by PL_Desc_Local'
 	 End
  Else If @Object_Type = 'ap'
    Begin
 	   Select @Sql = 'Select Id = PU_Id,Desc1 = PU_Desc_Local,Desc2 = PU_Desc_Global From Prod_Units Where PU_Id > 0'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' and PU_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' and PU_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' and PU_Desc_Global Is Null'
 	   Select @Sql = @Sql + ' Order by PU_Desc_Local'
 	 End
  Else If @Object_Type = 'aq'
    Begin
 	   Select @Sql = 'Select Id = PUG_Id,Desc1 = PUG_Desc_Local,Desc2 = PUG_Desc_Global From PU_Groups 	 Where PUG_Id > 0'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' and PUG_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' and PUG_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' and PUG_Desc_Global Is Null'
 	   Select @Sql = @Sql + ' Order by PUG_Desc_Local'
 	 End
  Else If @Object_Type = 'ar'
    Begin
 	   Select @Sql = 'Select Id = Var_Id,Desc1 = Var_Desc_Local,Desc2 = Var_Desc_Global, Info1 = pu.PU_Desc, Info2 = PUG_Desc, Info1_Header = ''Unit'', Info2_Header = ''Group'' From Variables v  Join Prod_Units pu on pu.PU_id = v.PU_Id Join PU_Groups pug on pug.PUG_id = v.PUG_Id  Where Var_Id > 0 and v.pu_Id <> 0 and (system = 0 or system is null)'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' and Var_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' and Var_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' and Var_Desc_Global Is Null'
 	   Select @Sql = @Sql + ' Order by Var_Desc_Local'
  End
  Else If @Object_Type = 'as'
    Begin
 	   Select @Sql = 'Select Id = Dept_Id,Desc1 = Dept_Desc_Local,Desc2 = Dept_Desc_Global From Departments Where Dept_Id > 0'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' and Dept_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' and Dept_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' and Dept_Desc_Global Is Null'
 	   Select @Sql = @Sql + ' Order by Dept_Desc_Local'
 	 End
  Else If @Object_Type = 'at'
    Begin
 	   Select @Sql = 'Select Id = WEMT_Id,Desc1 = WEMT_Name_Local,Desc2 = WEMT_Name_Global, Info1 = pu.PU_Desc, Info2 = Conversion, Info1_Header = ''Unit'', Info2_Header = ''Conversion''  From Waste_Event_Meas w Join Prod_Units pu on pu.PU_id = w.PU_Id Where WEMT_Id > 0'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' and WEMT_Name_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' and WEMT_Name_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' and WEMT_Name_Global Is Null'
 	   Select @Sql = @Sql + ' Order by Info1, Info2'
  End
  Else If @Object_Type = 'au'
    Begin
 	   Select @Sql = 'Select Id = RS_Id,Desc1 = Shortcut_Name_Local,Desc2 = Shortcut_Name_Global, Info1 = pu.PU_Desc, Info2 = Amount, Info1_Header = ''Unit'', Info2_Header = ''Amount'' From Reason_Shortcuts r  Join Prod_Units pu on pu.PU_id = r.PU_Id Where RS_Id > 0'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' and Shortcut_Name_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' and Shortcut_Name_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' and Shortcut_Name_Global Is Null'
 	   Select @Sql = @Sql + ' Order by Shortcut_Name_Local'
  End
  Else If @Object_Type = 'av'
    Begin
 	   Select @Sql = 'Select Id = TEStatus_Id,Desc1 = TEStatus_Name_Local,Desc2 = TEStatus_Name_Global From Timed_Event_Status Where TEStatus_Id > 0'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' and TEStatus_Name_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' and TEStatus_Name_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' and TEStatus_Name_Global Is Null'
 	   Select @Sql = @Sql + ' Order by TEStatus_Name_Local'
  End
  Else If @Object_Type = 'aw'
    Begin
 	   Select @Sql = 'Select Id = WEFault_Id,Desc1 = WEFault_Name_Local,Desc2 = WEFault_Name_Global From Waste_Event_Fault Where WEFault_Id > 0'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' and WEFault_Name_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' and WEFault_Name_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' and WEFault_Name_Global Is Null'
 	   Select @Sql = @Sql + ' Order by WEFault_Name_Local'
  End
  Else If @Object_Type = 'ax'
    Begin
 	   Select @Sql = 'Select Id = TEFault_Id,Desc1 = TEFault_Name_Local,Desc2 = TEFault_Name_Global From Timed_Event_Fault Where TEFault_Id > 0'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' and TEFault_Name_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' and TEFault_Name_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' and TEFault_Name_Global Is Null'
 	   Select @Sql = @Sql + ' Order by TEFault_Name_Local'
  End
  Else If @Object_Type = 'ay'
    Begin
 	   Select @Sql = 'Select Id = PP_Status_Id,Desc1 = PP_Status_Desc_Local,Desc2 = PP_Status_Desc_Global From Production_Plan_Statuses Where PP_Status_Id > -1'
 	   If @QueryType = 0
 	   	 Select @Sql = @Sql + ' and PP_Status_Desc_Local Like ''' + @SearchString + ''''
 	   Else If @QueryType = 1
 	   	 Select @Sql = @Sql + ' and PP_Status_Desc_Global Like ''' + @SearchString + ''''
 	   Else
 	   	 Select @Sql = @Sql + ' and PP_Status_Desc_Global Is Null'
 	   Select @Sql = @Sql + ' Order by PP_Status_Desc_Local'
  End
Execute (@Sql)
