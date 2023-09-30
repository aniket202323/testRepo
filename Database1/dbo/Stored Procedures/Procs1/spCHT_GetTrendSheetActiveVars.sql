Create Procedure dbo.spCHT_GetTrendSheetActiveVars
@StartTime datetime,
@EndTime datetime,
@Sheet_Desc nvarchar(50),
@VariableList1 nvarchar(255),
@VariableList2 nvarchar(255) =NULL,
@VariableList3 nvarchar(255) =NULL,
@VariableList4 nvarchar(255) =NULL,
@VariableList5 nvarchar(255) =NULL
AS
create table #IdList (
  ItemId int,
  ItemOrder int
)
declare @CurIds nvarchar(255)
declare @i integer
declare @IdCount integer
declare @tchar char
declare @tvchar nvarchar(10)
declare @ParCount integer
declare @tID integer
declare @Sheet_id int
Select @Sheet_Id = Sheet_Id From Sheets Where (Sheet_Desc = @Sheet_Desc)
-- Build temporary table with all Variables that are being shown now (includes belonging to the Sheet_Desc or not)
Select @Parcount=1
Select @IdCount = 0
Select @i = 1 	  	     
Select @CurIds = @VariableList1
Select @tchar = SUBSTRING (@CurIds, @i, 1)
While (@tchar <> '$') And (@i < 254) and (@tchar is not null)
  Begin
     If @tchar <> ',' And @tchar <> '_'
       Select @tvchar = @tvchar + @tchar
     Else
       Begin
         Select @tvchar = LTRIM(RTRIM(@tvchar))
         If @tvchar <> '' 
           Begin
             Select @tID = CONVERT(integer, @tvchar)
             If (Select Count(*) From #IdList Where ItemId=@Tid)=0 
              Begin
               Select @IdCount = @IdCount + 1
               Insert into #IdList (ItemId, ItemOrder) values (@tID, @IdCount)
              End
           End
           If @tchar = ','
             Begin
 	        Select @tvchar = ''
 	      End
           Else -- Go To Next Set Of Ids (@tchar = '_')
             Begin
               Select @ParCount = @ParCount+1
               Select @tvchar = ''
               Select @i = 0
               If @ParCount = 2
                 Select @CurIds = @VariableList2
               If @ParCount = 3
                 Select @CurIds = @VariableList3
               If @ParCount = 4
                 Select @CurIds = @VariableList4
               If @ParCount = 5
                 Select @CurIds = @VariableList5
 	     End
       End
     Select @i = @i + 1
     Select @tchar = SUBSTRING(@CurIds, @i, 1)
  End
 	  	 
Select @tvchar = LTRIM(RTRIM(@tvchar))
If @tvchar <> '' and (@tvchar is not null)
  Begin
    Select @tID = CONVERT(integer, @tvchar)
    If (Select Count(*) From #IdList Where ItemId=@Tid)=0 
    Begin
      Select @IdCount = @IdCount + 1
      Insert into #IdList (ItemId, ItemOrder) values (@tID, @IdCount)
    End
  End
-- Merge into this temp table all variables that belong to the Sheet_Desc but didn't have tests before(so not in temp until now)
 Insert Into #IdList
  Select v.Var_Id, (Select Max(ItemOrder) From #IdLIst)+sv.var_order -- it doesn't matter if ItemId is not sequential 
  From Variables V Inner Join Sheet_Variables sv on v.var_id = sv.var_id
  Where (sv.Sheet_Id = @Sheet_Id) And v.data_type_id in (1,2,6,7)
  And v.var_id not in (Select ItemId From #IdList Where #IdList.ItemId = v.var_id)  
  Order by sv.var_order
Create Table #Vars (
    Var_Id int, 
    Var_Desc nvarchar(100) NULL,
    Var_Order int NULL,
    Var_Event_Type int NULL,
    Var_Precision int NULL,
    Qtt_tests int NULL,
    Var_Master_Unit_Id int NULL
  )
  -- Get Variable Information Together
  Insert Into #Vars
    Select v.Var_Id, v.var_desc, i.ItemOrder,v.Event_Type, v.Var_Precision, 0,Case When pu.Master_Unit IS NULL Then pu.PU_Id Else pu.Master_Unit End
     From  #IdList i
     Inner Join Variables v on v.var_id = i.ItemId
     Inner Join Prod_Units pu on pu.PU_Id = v.PU_Id
 Declare  @CursorVarId int
 Declare MyCursor Insensitive Cursor
  For (Select  Var_Id From #Vars)
   For Read Only
 Open MyCursor
 MyLoop1:
  Fetch Next From MyCursor Into @CursorVarId
 If (@@Fetch_Status=0)
  Begin
   Update #Vars
    Set Qtt_Tests = 
     (Select Count (T.Var_Id) 
      From Tests T 
       Where var_id = @CursorVarId 
        And Result_On>=@StartTime 
         And Result_On <=@EndTime 
          And Result Is Not NULL)
     Where #Vars.Var_Id = @CursorVarId  
   Goto MyLoop1
 End
 Close MyCursor
 Deallocate MyCursor
/*
 Update #Vars  
 Set Qtt_tests =  
 (Select count(t.Var_Id)
      From Tests t 
       Where #vars.Var_Id = t.Var_id and
             t.Result_On >= @StartTime and
             t.Result_On <= @EndTime and
             t.Result Is Not Null  -- and t.var_id<>101 
      group by t.var_id)
*/
-- Keep only the active variables
 delete #Vars
  Where qtt_tests is null or qtt_tests=0
select var_id, var_order, var_desc, var_event_type, var_precision, qtt_tests, var_master_unit_id  from #vars order by var_order
  Drop table #IdList
 Drop Table #Vars
