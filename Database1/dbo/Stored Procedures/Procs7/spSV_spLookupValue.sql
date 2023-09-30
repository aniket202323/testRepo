CREATE Procedure dbo.spSV_spLookupValue
@Field_Id int,
@LookupId int,
@LookUpString nvarchar(500) Output
--@Sheet_Id int = NULL
AS
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
*/
  Create Table #Temp ([Id] Int,[Desc] nvarchar(100))
  Declare @PUId int,@StrPU varchar(7000)
  Select @StrPU = ''
  Declare c cursor For select Pu_Id from prod_units where pu_Id <> 0
  Open c
  FetchC:
  Fetch next from c into @PUId
  If @@Fetch_Status  = 0
    Begin
     Select @StrPU = @StrPU + Convert(nvarchar(10),@PUId) + ','
     GoTo FetchC
    End
  Close c
  Deallocate c
  Insert Into  #Temp   Execute spCmn_GetEventSubEventByUnit null, @StrPU,1
--   Create Table #ScheduleFilters (SF_Id int, SF_Desc nvarchar(100), SF_Key_Id int, SF_Type nvarchar(50))
--   Insert Into #ScheduleFilters (SF_Id, SF_Desc, SF_Key_Id, SF_Type)
--     exec spSV_GetSchedFilters @Sheet_Id
  Select @LookUpString = 
 	 CASE  When  @Field_Id = -4 Then (Select Control_Type_Desc From Control_Type Where Control_Type_Id = @LookupId)
 	       When  @Field_Id = -5 Then (Select PP_Type_Name From Production_Plan_Types Where PP_Type_Id = @LookupId)
 	       When  @Field_Id = -6 Then (Select Prod_Code From Products Where Prod_Id = @LookupId)
        When  @Field_Id = 22 and @LookupId = 1 Then 'TRUE'
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
--        When  @Field_Id = 52 Then (Select SF_Desc From #ScheduleFilters Where SF_Key_Id = @LookupId)
        When @Field_Id = 28 or @Field_Id = 31 or @Field_Id = 38 or @Field_Id = 41 or 
             @Field_Id = 42 or @Field_Id = 43 or @Field_Id = 45 or @Field_Id = 46 or 
             @Field_Id = 47 or @Field_Id = 48 or @Field_Id = 49 Then
               (Select Field_Desc From ED_FieldType_ValidValues Where ED_Field_Type_Id = @Field_Id and Field_Id = @LookupId)
  	       Else  Convert(nvarchar(10),@LookupId)
        End
  Drop Table #Temp
--  Drop Table #ScheduleFilters
