CREATE Procedure dbo.spEMED_spLookupValue
@Field_Id int,
@LookupId int,
@LookUpString nvarchar(500) Output
--@Sheet_Id int = NULL
AS
/* ##### spEMED_spLookupValue #####
Description 	 : Returns data for user defined parameters used for a particular unit along with other properties
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	 UserStory/Defect No 	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018-02-20 	 Prasad 	  	  	  	 7.0 SP3 	 F28159 	  	  	  	 Added condition for FieldId = 78
*/
/* 
8                Sampling Type
9                Unit Id
10               Variable Id
????? 13               Type
14               Measure
15               Reason
16               Production Status
23               Characteristic
24               Color Scheme
27               Event Type
28 	  	  Grid type
29 	    	  tree Stats
30               Security
31 	  	  Conformance Patterns
59 	  	 Paths
*/
  Create Table #Temp ([Id] Int,[Desc] nVarChar(100))
If @Field_Id = 27
BEGIN
  Declare @PUId int,@StrPU varchar(7000)
  Select @StrPU = ''
  Declare c cursor For select Pu_Id from prod_units where pu_Id <> 0
  Open c
  FetchC:
  Fetch next from c into @PUId
  If @@Fetch_Status  = 0
    Begin
     Select @StrPU = @StrPU + Convert(nVarChar(10),@PUId) + ','
     GoTo FetchC
    End
  Close c
  Deallocate c
  Insert Into  #Temp   Execute spCmn_GetEventSubEventByUnit null, @StrPU,1
END
--   Create Table #ScheduleFilters (SF_Id int, SF_Desc nVarChar(100), SF_Key_Id int, SF_Type nvarchar(50))
--   Insert Into #ScheduleFilters (SF_Id, SF_Desc, SF_Key_Id, SF_Type)
--     exec spSV_GetSchedFilters @Sheet_Id
  Select @LookUpString = 
 	 CASE When  @Field_Id = 22 and @LookupId = 1 Then 'TRUE'
 	  	 When  @Field_Id = 22 and @LookupId = 0 Then 'FALSE'
 	  	 When  @Field_Id = 8 Then (Select ST_Desc From Sampling_Type Where ST_Id = @LookupId)
 	  	 When  @Field_Id = 9 Then (Select Pu_Desc From Prod_Units Where pu_Id = @LookupId)
 	  	 When  @Field_Id = 10 Then (Select Var_Desc From Variables Where Var_Id = @LookupId)
 	  	 When  @Field_Id = 13 Then (Select WET_Name From Waste_Event_Type Where WET_Id = @LookupId)
 	  	 When  @Field_Id = 14 Then (Select WEMT_Name From Waste_Event_Meas Where WEMT_Id = @LookupId)
 	  	 When  @Field_Id = 15 Then (Select Event_Reason_Name From Event_Reasons Where Event_Reason_Id = @LookupId)
 	  	 When  @Field_Id = 16 Then (Select ProdStatus_Desc From Production_Status Where ProdStatus_Id = @LookupId)
 	  	 When  @Field_Id = 23 Then (Select Char_Desc From Characteristics Where Char_Id = @LookupId)
 	  	 When  @Field_Id = 24 Then (Select CS_Desc From Color_Scheme Where CS_Id = @LookupId)
 	  	 When  @Field_Id = 27 Then (Select [Desc] From #Temp Where Id = @LookupId)
 	  	 When  @Field_Id = 29 Then (Select Tree_Statistic_Desc From Tree_Statistics Where Tree_Statistic_Id = @LookupId)
 	  	 When  @Field_Id = 30 Then (Select AL_Desc From Access_Level Where Al_Id = @LookupId)
 	  	 When  @Field_Id = 33 Then (Select Sheet_Desc From Sheets where Sheet_Id = @LookupId)
 	  	 When  @Field_Id = 34 Then (Select Color_Desc From Colors Where Color_Id = @LookupId)
 	  	 When  @Field_Id = 39 Then (Select Tree_Name From Event_Reason_Tree Where Tree_Name_Id = @LookupId)
 	  	 When  @Field_Id = 40 Then (Select Event_Reason_Name From Event_Reasons Where Event_Reason_Id = @LookupId)
 	  	 When  @Field_Id = 50 Then (Select ET_Desc from Event_Types Where ET_Id = @LookupId)
 	  	 When @Field_Id In(28,31,38,41,42,43,45,46,47,48,49,55,60,74,76,78,79,81,82,83,84) Then
               (Select Field_Desc From ED_FieldType_ValidValues Where ED_Field_Type_Id = @Field_Id and Field_Id = @LookupId)
 	  	 When  @Field_Id = 59 Then (select Path_Desc from PrdExec_Paths Where Path_Id = @LookupId)
 	  	 When  @Field_Id = 61 Then (select Product_Family_Desc from Product_Family Where Product_Family_Id = @LookupId)
 	  	 When  @Field_Id = 63 Then (select DS_Desc from Data_Source Where DS_Id = @LookupId)
 	  	 When  @Field_Id = 75 Then (select Testing_Status_Desc from Test_Status  Where Testing_Status = @LookupId)
  	       Else  Convert(nVarChar(10),@LookupId)
        End
  Drop Table #Temp
--  Drop Table #ScheduleFilters
