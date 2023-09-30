CREATE PROCEDURE dbo.spEM_PutMultiLingualData
  @Object_Type   nVarChar(2),
  @Id 	  	  	  Int,
  @Desc1 	  	  nvarchar(255),
  @Desc2 	  	  nvarchar(255),
  @UserId 	  	  Int
 AS
 	 Declare @Sql nvarchar(1000),@MasterId 	 Int,@Rc Int
 	 Create Table #Check (value Int)
 	 Select @Sql = ''
 	 If @Desc2 = ''
 	  	 select @Desc2 = Null
 	 
 	 Select @Desc1 = ''''  + Replace(@Desc1,'''','''''') + ''''
 	 Select @Desc2 =   '''' + Replace(@Desc2,'''','''''') + ''''
  IF @Object_Type = 'aa'
 	 BEGIN
 	  	 Select @Sql =  'select Count(*) From Event_Reasons Where Event_Reason_Name_Local = ' + @Desc1 + ' and Event_Reason_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Event_Reasons Where Event_Reason_Name_Global = ' + @Desc2 + ' and Event_Reason_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Event_Reasons set Event_Reason_Name_Local = ' + @Desc1 + ',Event_Reason_Name_Global = ' + Coalesce(@Desc2,'null') + ' Where Event_Reason_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'ab'
 	 BEGIN
 	  	 Select @Sql =  'select Count(*) From Production_Status Where ProdStatus_Desc_Local = ' + @Desc1 + ' and ProdStatus_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Production_Status Where ProdStatus_Desc_Global = ' + @Desc2 + ' and ProdStatus_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Production_Status Set ProdStatus_Desc_Local = ' + @Desc1 + ',ProdStatus_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where ProdStatus_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'ac'
 	 BEGIN
 	  	 Select @Sql =  'select Count(*) From Waste_Event_Type Where WET_Name_Local = ' + @Desc1 + ' and WET_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Waste_Event_Type Where WET_Name_Global = ' + @Desc2 + ' and WET_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Waste_Event_Type Set WET_Name_Local = ' + @Desc1 + ',WET_Name_Global =  ' + Coalesce(@Desc2,'null') + ' Where WET_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'ad'
 	 BEGIN
 	  	 Select @Sql =  'select Count(*) From Event_Reason_Tree Where Tree_Name_Local = ' + @Desc1 + ' and Tree_Name_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Event_Reason_Tree Where Tree_Name_Global = ' + @Desc2 + ' and Tree_Name_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Event_Reason_Tree Set Tree_Name_Local = ' + @Desc1 + ',Tree_Name_Global =  ' + Coalesce(@Desc2,'null') + ' Where Tree_Name_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'ae'
 	 BEGIN
 	  	 Select @Sql =  'select Count(*) From Sheets Where Sheet_Desc_Local = ' + @Desc1 + ' and Sheet_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Sheets Where Sheet_Desc_Global = ' + @Desc2 + ' and Sheet_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Sheets Set Sheet_Desc_Local = ' + @Desc1 + ',Sheet_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where Sheet_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'af'
 	 BEGIN
 	  	 Select @Sql =  'select Count(*) From Sheet_Groups Where Sheet_Group_Desc_Local = ' + @Desc1 + ' and Sheet_Group_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Sheet_Groups Where Sheet_Group_Desc_Global = ' + @Desc2 + ' and Sheet_Group_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Sheet_Groups Set Sheet_Group_Desc_Local = ' + @Desc1 + ',Sheet_Group_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where Sheet_Group_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'ag'
 	 BEGIN
 	  	 Select @Sql =  'select Count(*) From Views Where View_Desc_Local = ' + @Desc1 + ' and View_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Views Where View_Desc_Global = ' + @Desc2 + ' and View_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Views Set View_Desc_Local = ' + @Desc1 + ',View_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where View_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'ah'
 	 BEGIN
 	  	 Select @Sql =  'select Count(*) From Product_Family Where Product_Family_Desc_Local = ' + @Desc1 + ' and Product_Family_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Product_Family Where Product_Family_Desc_Global = ' + @Desc2 + ' and Product_Family_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Product_Family Set Product_Family_Desc_Local = ' + @Desc1 + ',Product_Family_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where Product_Family_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'ai'
 	 BEGIN
 	  	 Select @Sql =  'select Count(*) From Product_Groups Where Product_Grp_Desc_Local = ' + @Desc1 + ' and Product_Grp_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Product_Groups Where Product_Grp_Desc_Global = ' + @Desc2 + ' and Product_Grp_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Product_Groups Set Product_Grp_Desc_Local = ' + @Desc1 + ',Product_Grp_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where Product_Grp_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'aj'
 	 BEGIN
 	  	 Select @Sql =  'select Count(*) From Products Where Prod_Desc_Local = ' + @Desc1 + ' and Prod_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Products Where Prod_Desc_Global = ' + @Desc2 + ' and Prod_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Products_Base Set Prod_Desc = ' + @Desc1 + ',Prod_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where Prod_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'ak'
 	 BEGIN
 	  	 Select @Sql =  'select Count(*) From Product_Properties Where Prop_Desc_Local = ' + @Desc1 + ' and Prop_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Product_Properties Where Prop_Desc_Global = ' + @Desc2 + ' and Prop_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	  Select @Sql = 'Update Product_Properties Set Prop_Desc_Local = ' + @Desc1 + ',Prop_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where Prop_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'al'
 	 BEGIN
 	  	 Select @MasterId = Prop_Id From Characteristics where Char_Id = @Id
 	  	 Select @Sql =  'select Count(*) From Characteristics Where Char_Desc_Local = ' + @Desc1 + ' and Char_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and Prop_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Characteristics Where Char_Desc_Global = ' + @Desc2 + ' and Char_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and Prop_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	  Select @Sql = 'Update Characteristics Set Char_Desc_Local = ' + @Desc1 + ',Char_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where Char_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'am'
 	 BEGIN
 	  	 Select @MasterId = Prop_Id From Characteristic_Groups where Characteristic_Grp_Id = @Id
 	  	 Select @Sql =  'select Count(*) From Characteristic_Groups Where Characteristic_Grp_Desc_Local = ' + @Desc1 + ' and Characteristic_Grp_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and Prop_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Characteristic_Groups Where Characteristic_Grp_Desc_Global = ' + @Desc2 + ' and Characteristic_Grp_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and Prop_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Characteristic_Groups Set Characteristic_Grp_Desc_Local = ' + @Desc1 + ',Characteristic_Grp_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where Characteristic_Grp_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'an'
 	 BEGIN
 	  	 Select @MasterId = Prop_Id From Specifications where Spec_Id = @Id
 	  	 Select @Sql =  'select Count(*) From Specifications Where Spec_Desc_Local = ' + @Desc1 + ' and Spec_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and Prop_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Specifications Where Spec_Desc_Global = ' + @Desc2 + ' and Spec_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and Prop_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Specifications Set Spec_Desc_Local = ' + @Desc1 + ',Spec_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where Spec_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'ao'
 	 BEGIN
 	  	 Select @Sql =  'select Count(*) From Prod_Lines Where PL_Desc_Local = ' + @Desc1 + ' and PL_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Prod_Lines Where PL_Desc_Global = ' + @Desc2 + ' and PL_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Prod_Lines_Base Set PL_Desc = ' + @Desc1 + ',PL_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where PL_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'ap'
 	 BEGIN
 	  	 Select @MasterId = PL_Id From Prod_Units where PU_Id = @Id
 	  	 Select @Sql =  'select Count(*) From Prod_Units Where PU_Desc_Local = ' + @Desc1 + ' and PU_Id !=  ' +  Convert(nVarChar(10),@Id)  + ' and PL_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Prod_Units Where PU_Desc_Global = ' + @Desc2 + ' and PU_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and PL_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Prod_Units_Base Set PU_Desc = ' + @Desc1 + ',PU_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where PU_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'aq'
 	 BEGIN
 	  	 Select @MasterId = PU_Id From PU_Groups where PUG_Id = @Id
 	  	 Select @Sql =  'select Count(*) From PU_Groups Where PUG_Desc_Local = ' + @Desc1 + ' and PUG_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and PU_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From PU_Groups Where PUG_Desc_Global = ' + @Desc2 + ' and PUG_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and PU_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update PU_Groups Set PUG_Desc_Local = ' + @Desc1 + ',PUG_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where PUG_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'ar'
 	 BEGIN
 	  	 Select @MasterId = PU_Id From Variables where Var_Id = @Id
 	  	 Select @Sql =  'select Count(*) From Variables Where Var_Desc_Local = ' + @Desc1 + ' and Var_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and PU_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Variables Where Var_Desc_Global = ' + @Desc2 + ' and Var_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and PU_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Variables_Base Set Var_Desc = ' + @Desc1 + ',Var_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where Var_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'as'
 	 BEGIN
 	  	 Select @Sql =  'select Count(*) From Departments Where Dept_Desc_Local = ' + @Desc1 + ' and Dept_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Departments Where Dept_Desc_Global = ' + @Desc2 + ' and Dept_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Departments_Base Set Dept_Desc = ' + @Desc1 + ',Dept_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where Dept_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'at'
 	 BEGIN
 	  	 Select @MasterId = PU_Id From Waste_Event_Meas where WEMT_Id = @Id
 	  	 Select @Sql =  'select Count(*) From Waste_Event_Meas Where WEMT_Name_Local = ' + @Desc1 + ' and WEMT_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and PU_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Waste_Event_Meas Where WEMT_Name_Global = ' + @Desc2 + ' and WEMT_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and PU_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	 Select @Sql = 'Update Waste_Event_Meas Set WEMT_Name_Local = ' + @Desc1 + ',WEMT_Name_Global =  ' + Coalesce(@Desc2,'null') + ' Where WEMT_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'au'
 	 BEGIN
 	  	 Select @MasterId = PU_Id From Reason_Shortcuts where RS_Id = @Id
 	  	 Select @Sql =  'select Count(*) From Reason_Shortcuts Where Shortcut_Name_Local = ' + @Desc1 + ' and RS_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and PU_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Reason_Shortcuts Where Shortcut_Name_Global = ' + @Desc2 + ' and RS_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and PU_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Reason_Shortcuts Set Shortcut_Name_Local = ' + @Desc1 + ',Shortcut_Name_Global =  ' + Coalesce(@Desc2,'null') + ' Where RS_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'av'
 	 BEGIN
 	  	 Select @MasterId = PU_Id From Timed_Event_Status where TEStatus_Id = @Id
 	  	 Select @Sql =  'select Count(*) From Timed_Event_Status Where TEStatus_Name_Local = ' + @Desc1 + ' and TEStatus_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and PU_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Timed_Event_Status Where TEStatus_Name_Global = ' + @Desc2 + ' and TEStatus_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and PU_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Timed_Event_Status Set TEStatus_Name_Local = ' + @Desc1 + ',TEStatus_Name_Global =  ' + Coalesce(@Desc2,'null') + ' Where TEStatus_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'aw'
 	 BEGIN
 	  	 Select @MasterId = PU_Id From Waste_Event_Fault where WEFault_Id = @Id
 	  	 Select @Sql =  'select Count(*) From Waste_Event_Fault Where WEFault_Name_Local = ' + @Desc1 + ' and WEFault_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and PU_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Waste_Event_Fault Where WEFault_Name_Global = ' + @Desc2 + ' and WEFault_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and PU_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Waste_Event_Fault Set WEFault_Name_Local = ' + @Desc1 + ',WEFault_Name_Global =  ' + Coalesce(@Desc2,'null') + ' Where WEFault_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'ax'
 	 BEGIN
 	  	 Select @MasterId = PU_Id From Timed_Event_Fault where TEFault_Id = @Id
 	  	 Select @Sql =  'select Count(*) From Timed_Event_Fault Where TEFault_Name_Local = ' + @Desc1 + ' and TEFault_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and PU_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Timed_Event_Fault Where TEFault_Name_Global = ' + @Desc2 + ' and TEFault_Id !=  ' +  Convert(nVarChar(10),@Id) + ' and PU_Id =  ' +  Convert(nVarChar(10),@MasterId)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Timed_Event_Fault Set TEFault_Name_Local = ' + @Desc1 + ',TEFault_Name_Global =  ' + Coalesce(@Desc2,'null') + ' Where TEFault_Id = ' + Convert(nVarChar(10),@Id)
 	 END
  Else If @Object_Type = 'ay'
 	 BEGIN
 	  	 Select @Sql =  'select Count(*) From Production_Plan_Statuses Where PP_Status_Desc_Local = ' + @Desc1 + ' and PP_Status_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	 INsert Into #Check
 	  	  Execute  (@Sql)
 	  	 If (Select value from #Check) != 0 RETURN(-100)
 	  	 If @Desc2 Is Not Null
 	  	   BEGIN
 	  	  	 Select @Sql =  'select Count(*) From Production_Plan_Statuses Where PP_Status_Desc_Global = ' + @Desc2 + ' and PP_Status_Id !=  ' +  Convert(nVarChar(10),@Id)
 	  	  	 Truncate table #Check
 	  	  	 Insert Into #Check
 	  	   	 Execute  (@Sql) 	 
 	  	  	 If (Select value from #Check) != 0 RETURN(-200)
 	  	   END
 	  	 Select @Sql = 'Update Production_Plan_Statuses Set PP_Status_Desc_Local = ' + @Desc1 + ',PP_Status_Desc_Global =  ' + Coalesce(@Desc2,'null') + ' Where PP_Status_Id = ' + Convert(nVarChar(10),@Id)
 	 END
Drop table #Check
Execute (@Sql)
