Create Procedure dbo.spSPC_GetData
@VariableList nvarchar(2500), 
@StartTime datetime,
@EndTime datetime,
@ProductFilterType int,
@ProductKey int,
@ProductText nvarchar(100),
@AppliedProduct int,
@StatusList nvarchar(500),
@ValueFilterList nvarchar(2500),
@ProductGrouping 	 Int 	 = 1
AS
--set nocount on 'ProfSVR handles this at connection (ECR #26686: mt/10-7-2003)
select @ProductGrouping 	 = Coalesce(@ProductGrouping,1)
--**********************************************
--Select @VariableList = '12,13,14'
--Select @StartTime = dateadd(day,-180,getdate())
--Select @EndTime = getdate()
--Select @ProductFilterType = 1
--Select @ProductKey = 1
--Select @ProductText = NULL
--Select @AppliedProduct = 1
--Select @StatusList = '8,5'
--Select @ValueFilterList = '2 Var_Id = 12 And convert(float, Result) < 30.0~1 Var_Id = 13 And convert(float, Result) > 3550.0'
--**********************************************
Declare @MasterUnit int
Declare @CurList nvarchar(2500)
Declare @i integer
Declare @tchar char
Declare @tvchar nVarChar(255)
Declare @tID integer
Declare @ItemCount int
If @ProductKey = 0 and @ProductFilterType = 1
 	 Select @ProductFilterType = 3,@ProductText = ''
Create Table #VariableList (
  Var_Order int,
  Var_Id int
) 
Create Table #ProductList (
  Prod_Id int,
  Prod_Code nvarchar(50)
)
Create Table #IncludeTimes (
  Prod_Id int,
  Prod_Code nvarchar(50),
  Start_Time datetime,
  End_Time datetime,
  IsApplied int NULL,
  Run_Id int NULL
)
CREATE INDEX IncludeStart ON #IncludeTimes (Start_Time)
CREATE INDEX IncludeEnd ON #IncludeTimes (End_Time)
Create Table #ExcludeTimes (
  Prod_Id int,
  Prod_Code nvarchar(50),
  Start_Time datetime,
  End_Time datetime
)
CREATE INDEX ExcludeStart ON #ExcludeTimes (Start_Time)
CREATE INDEX ExcludeEnd ON #ExcludeTimes (End_Time)
Create Table #OverrideTimes (
  Prod_Id int,
  Prod_Code nvarchar(50),
  Start_Time datetime,
  End_Time datetime
)
CREATE INDEX OverrideStart ON #OverrideTimes (Start_Time)
CREATE INDEX OverrideEnd ON #OverrideTimes (End_Time)
Create Table #StatusList (
  Production_Status int
)
Create Table #DataList (
  Var_Order int,
  Var_Id int,
  Prod_Id int,
  Prod_Code nvarchar(50),
  Timestamp datetime,
  Result float(32),
  Run_Id int,
  LReject float(32) NULL,
  LWarning float(32) NULL,
  Target float(32) NULL,
  UWarning float(32) NULL,
  UReject float(32) NULL
)
CREATE INDEX DataTime ON #DataList (TimeStamp)
Create Table #ValueFilter (
  FilterOrder int,
  FilterType int,
  FilterSQL nVarChar(255)
)
Create Table #FilterTimes (
  TimeStamp datetime
)
CREATE INDEX FilterTime ON #FilterTimes (TimeStamp)
Create Table #WorkTimes1 (
  TimeStamp datetime
)
CREATE INDEX WorkTime1 ON #WorkTimes1 (TimeStamp)
Create Table #WorkTimes2 (
  TimeStamp datetime
)
CREATE INDEX WorkTime2 ON #WorkTimes2 (TimeStamp)
--********************************************************************************
-- Build Variable List
--********************************************************************************
SELECT @tvchar = ''
SELECT @i = 1 	  	     
Select @ItemCount = 0
SELECT @CurList = @VariableList
SELECT @tchar = SUBSTRING (@CurList, @i, 1)
WHILE (@tchar <> '$') AND (@i <= Len(@CurList))
  BEGIN
    IF @tchar <> ',' AND @tchar <> '_'
 	 SELECT @tvchar = @tvchar + @tchar
    ELSE
      BEGIN
 	 SELECT @tvchar = LTRIM(RTRIM(@tvchar))
        IF @tvchar <> '' 
          BEGIN
   	     SELECT @tID = CONVERT(integer, @tvchar)
            Select @ItemCount = @ItemCount + 1
 	     INSERT into #VariableList (var_order, var_id) values (@ItemCount, @tID)
          END
        IF @tchar = ','
 	   BEGIN
 	     SELECT @tvchar = ''
 	   END
       END
       SELECT @i = @i + 1
       SELECT @tchar = SUBSTRING(@CurList, @i, 1)
  END
 	  	 
SELECT @tvchar = LTRIM(RTRIM(@tvchar))
IF @tvchar <> '' 
  BEGIN
    SELECT @tID = CONVERT(integer, @tvchar)
    Select @ItemCount = @ItemCount + 1
    INSERT into #VariableList (var_order, var_id) values (@ItemCount, @tID)
  END
-- Get Master Unit Of First Variable
Select @MasterUnit = Coalesce(Master_Unit, PU_Id)
  From Prod_Units 
  Where PU_Id = (Select PU_Id From Variables Where Var_Id = 
                  (Select Var_Id From #VariableList Where Var_Order = 1)
                 )
--********************************************************************************
--********************************************************************************
-- Build Product List If Applicable
--********************************************************************************
If @ProductFilterType = 1 
  Begin
    -- Filtering By Product Group
    Insert Into #ProductList (Prod_Id, Prod_Code) 
      Select pg.Prod_Id, p.Prod_Code 
        From Product_Group_Data pg
        Join Products p on p.prod_id = pg.prod_id
        Where pg.Product_Grp_Id = @ProductKey
  End
Else If @ProductFilterType = 2
  Begin
    -- Filtering By Specific Product
    Insert Into #ProductList (Prod_Id, Prod_Code) 
      Select @ProductKey, Prod_Code 
        From Products Where Prod_Id = @ProductKey 
  End
Else If @ProductFilterType = 3
  Begin
    -- Filtering By Product Code Text
    Insert Into #ProductList (Prod_Id, Prod_Code) 
      Select Prod_Id, Prod_Code
        From Products 
        Where Prod_Code like '%' + @ProductText + '%'
  End
--********************************************************************************
--********************************************************************************
-- Build Production Start INCLUDE Times
--********************************************************************************
--********************************************************************************
If @ProductFilterType <> 0
  Begin
    Insert Into #IncludeTimes (Prod_Id, Prod_Code, Start_Time, End_Time, Run_Id)
      Select p.Prod_Id, p.Prod_Code, ps.Start_Time, End_Time = Case When ps.End_Time Is Null Then Getdate() Else ps.End_Time End, ps.Start_Id
        From Production_Starts ps 
        Join #ProductList p on p.Prod_Id = ps.Prod_id
        Where PU_Id = @MasterUnit and
              (ps.Start_Time Between @StartTime and @EndTime or
               ps.End_Time Between @StartTime and @EndTime or  
              (ps.Start_Time < @EndTime and ((ps.End_Time > @EndTime) or (ps.End_Time Is NULL))
              )) 
  End
Else
  Begin
    Insert Into #IncludeTimes (Prod_Id, Prod_Code, Start_Time, End_Time, Run_Id)
      Select ps.Prod_Id, p.Prod_Code, ps.Start_Time, End_Time = Case When ps.End_Time Is Null Then Getdate() Else ps.End_Time End, ps.Start_Id
        From Production_Starts ps 
        Join Products p on p.Prod_Id = ps.Prod_id
        Where PU_Id = @MasterUnit and
              (ps.Start_Time Between @StartTime and @EndTime or
               ps.End_Time Between @StartTime and @EndTime or  
              (ps.Start_Time < @EndTime and ((ps.End_Time > @EndTime) or (ps.End_Time Is NULL))
              )) 
  End
--********************************************************************************
-- Build Applied Product INCLUDE Times
--********************************************************************************
--********************************************************************************
If @ProductFilterType <> 0 And @AppliedProduct <> 0 
  Begin
    Insert Into #IncludeTimes (Prod_Id, Prod_Code, Start_Time, End_Time, IsApplied, Run_Id)
      Select p.Prod_Id, p.Prod_Code,Start_Time = Case When e.Start_Time Is Null Then dateadd(second,-1,e.TimeStamp) Else e.Start_Time End, e.TimeStamp, 1, e.Event_Id
        From Events e 
        Join #ProductList p on p.Prod_Id = e.Applied_Product
        Where e.PU_Id = @MasterUnit and
              e.TimeStamp Between @StartTime and @EndTime And
              e.Applied_Product Is Not NULL 
  End
--********************************************************************************
-- Build Applied Product EXCLUDE Times Inside Production Starts
-- (Applied Product IS NOT What We Want)
--********************************************************************************
If @ProductFilterType <> 0 And @AppliedProduct <> 0 
  Begin
    Insert Into #ExcludeTimes (Prod_Id, Prod_Code, Start_Time, End_Time)
      Select e.Applied_Product, 'Exclude',Start_Time = Case When e.Start_Time Is Null Then dateadd(second,-1,e.TimeStamp) Else e.Start_Time End, e.TimeStamp
        From Events e 
        Where e.PU_Id = @MasterUnit and
              e.TimeStamp Between @StartTime and @EndTime And
              e.Applied_Product Is Not Null And
              e.Applied_Product Not In (Select Prod_Id From #ProductList)
  End
--********************************************************************************
--********************************************************************************
-- Build Applied Product OVERRIDE Times Inside Production Starts
-- (Applied Product IS What We Want, Need To Delete "Original Product" Data)
--********************************************************************************
If @ProductFilterType <> 0 And @AppliedProduct <> 0 
  Begin
    Insert Into #OverrideTimes (Prod_Id, Prod_Code, Start_Time, End_Time)
      Select ps.Prod_Id, ps.Prod_Code,i.Start_Time, i.End_Time
        From #IncludeTimes i
        Join #IncludeTimes ps on ps.Start_Time <= i.Start_Time and ps.End_Time >= i.Start_Time and ps.IsApplied Is Null
        Where i.IsApplied = 1
  End
--********************************************************************************
--***********************
--set nocount off
--select 'Exclude Times Before Status'
--select * from #excludetimes
--***********************
--********************************************************************************
-- Build Event Status EXCLUDE Times
--********************************************************************************
Declare @SQL nVarChar(255)
If @StatusList Is Not Null
  Begin
    Select @SQL = 'Select ProdStatus_Id From production_Status Where ProdStatus_Id Not In (' + @StatusList + ')'
    Insert Into #StatusList (Production_Status)      
      Execute (@SQL)     
    Insert Into #ExcludeTimes (Prod_Id, Prod_Code, Start_Time, End_Time)
      Select 1, 'Status',Start_Time = Case When e.Start_Time Is Null Then dateadd(second,-1,e.TimeStamp) Else e.Start_Time End, e.TimeStamp
        From Events e 
        Where e.PU_Id = @MasterUnit and
              e.TimeStamp Between @StartTime and @EndTime And
              e.Event_Status In (Select Production_Status From #StatusList)
  End
--********************************************************************************
--***********************
--set nocount off
--select 'Exclude Times After Status'
--select * from #excludetimes
--select 'Exclude Status List'
--select * from #StatusList
--***********************
--***********************
--set nocount off
--select 'Include Times'
--select * from #includetimes
--***********************
--********************************************************************************
-- Cursor Through Each Variable And Add Data To INCLUDE Data List
--********************************************************************************
Declare @@VarId int
Declare @@VarOrder int
DECLARE VariableCursor INSENSITIVE CURSOR
  FOR (Select Var_Order, Var_Id From #VariableList)
  FOR READ ONLY 
Open VariableCursor
Fetch_Loop:
  Fetch Next From VariableCursor Into @@VarOrder, @@VarId
  If @@Fetch_Status = 0 
    Begin
      Insert Into #DataList (Var_Order, Var_Id, Prod_Id, Prod_code, Timestamp, Result, Run_Id, LReject, LWarning, Target, UWarning, UReject)
        Select @@VarOrder, @@VarId, i.Prod_Id, i.Prod_Code, t.Result_On, 
               Case When Isnumeric(t.result) = 1 Then convert(float(32), t.Result) Else NULL End, 
               i.Run_Id, 
               Case When Isnumeric(vs.L_Reject) = 1 Then convert(float(32), vs.L_Reject) Else NULL End,
               Case When Isnumeric(vs.L_Warning) = 1 Then convert(float(32), vs.L_Warning) Else NULL End,
               Case When Isnumeric(vs.Target) = 1 Then convert(float(32), vs.Target) Else NULL End,
               Case When Isnumeric(vs.U_Warning) = 1 Then convert(float(32), vs.U_Warning) Else NULL End,
               Case When Isnumeric(vs.U_Reject) = 1 Then convert(float(32), vs.U_Reject) Else NULL End
          From Tests t
          --Join #IncludeTimes i on i.Start_Time < t.Result_On and i.End_Time >= t.Result_On --ECR #29523/mt/4-13-2005
          Join #IncludeTimes i on i.Start_Time <= t.Result_On and i.End_Time > t.Result_On   --ECR #29523/mt/4-13-2005
          Left Outer Join Var_Specs vs on vs.Var_Id = @@VarId and vs.Prod_Id = i.Prod_Id and vs.Effective_Date <= t.result_On and ((vs.expiration_date > t.result_On) or (vs.expiration_date is null))
          Where t.Var_Id = @@VarId And
                t.Result_On Between @StartTime and @EndTime And
                t.Result Is Not Null      
      Goto Fetch_Loop
    End
Close VariableCursor
Deallocate VariableCursor
--********************************************************************************
--***********************
--select * from #datalist order by timestamp ASC
--select 'Exclude Times'
--select * from #excludetimes
--***********************
--********************************************************************************
-- Delete EXCLUDE Times and Remove From INCLUDE Data List
--********************************************************************************
If (@ProductFilterType <> 0 And @AppliedProduct <> 0)  or @StatusList is not null
  Begin
    Delete #DataList
      From #DataList
      Join #ExcludeTimes on #ExcludeTimes.Start_Time < #DataList.Timestamp and 
           #ExcludeTimes.End_Time >= #DataList.Timestamp
  End
--********************************************************************************
--***********************
--select 'Override Times'
--select * from #overridetimes
--***********************
--********************************************************************************
-- Delete OVERRIDE Times and Remove From INCLUDE Data List
--********************************************************************************
If @ProductFilterType <> 0 And @AppliedProduct <> 0 
  Begin
    Delete From #DataList
      From #DataList
      Join #OverrideTimes on #OverrideTimes.Start_Time < #DataList.Timestamp and 
           #OverrideTimes.End_Time >= #DataList.Timestamp and
           #OverrideTimes.Prod_Id = #DataList.Prod_Id
  End
--********************************************************************************
--********************************************************************************
-- Build Value Filter List
--********************************************************************************
If @ValueFilterList Is Not Null
  Begin
    SELECT @tvchar = ''
    SELECT @i = 1 	  	     
    Select @ItemCount = 0
    SELECT @CurList = @ValueFilterList
    SELECT @tchar = SUBSTRING (@CurList, @i, 1)
    WHILE (@tchar <> '$') AND (@i <= Len(@CurList))
      BEGIN
        IF @tchar <> '~'
 	     SELECT @tvchar = @tvchar + @tchar
        ELSE
          BEGIN
            IF @tvchar <> '' 
              BEGIN
                --*************************************************
                -- First Character Of Filter SQL Tells:
                -- 1. Whether The Query is UNION (OR) or JOIN (AND)
                -- 
                -- Values Map:
                -- 1 - AND 
                -- 2 - OR 
                --
   	         SELECT @tID = CONVERT(integer, left(@tvchar,1))
                Select @ItemCount = @ItemCount + 1
 	         INSERT into #ValueFilter (FilterOrder, FilterType, FilterSQL) values (@ItemCount, @tID, Substring(@tvchar, 3,255))
              END
              IF @tchar = '~'
 	         BEGIN
 	           SELECT @tvchar = ''
 	         END
           END
           SELECT @i = @i + 1
           SELECT @tchar = SUBSTRING(@CurList, @i, 1)
      END
 	  	 
    IF @tvchar <> '' 
      BEGIN
        SELECT @tID = CONVERT(integer, left(@tvchar,1))
        Select @ItemCount = @ItemCount + 1
 	 INSERT into #ValueFilter (FilterOrder, FilterType, FilterSQL) values (@ItemCount, @tID, Substring(@tvchar, 3,255))
      END
End
--********************************************************************************
--********************************************************************************
-- Cursor Through Queries And Build Up INCLUDE Times
--********************************************************************************
If @ValueFilterList Is Not Null
  Begin
    Declare @@FilterType int
    Declare @@FilterSQL nVarChar(255)
    Declare @TotalSQL nVarChar(255)
    DECLARE FilterCursor INSENSITIVE CURSOR
      FOR Select FilterType, FilterSQL From #ValueFilter Order By FilterOrder ASC
      FOR READ ONLY 
    Open FilterCursor
Fetch_Loop2:
      Fetch Next From FilterCursor Into @@FilterType, @@FilterSQL
      If @@Fetch_Status = 0 
        Begin
          Delete From #WorkTimes1
          Delete From #WorkTimes2
          Select @TotalSQL = 'Select Result_On From Tests Where (Result_On Between ' + '''' + convert(nvarchar(30),@StartTime,109) + '''' + ' And ' + '''' + convert(nvarchar(30),@EndTime,109) + '''' + ') And (' + @@FilterSQL + ')'
          Insert Into #WorkTimes1 (Timestamp)
            Execute (@TotalSQL)
          Insert Into #WorkTimes2 (Timestamp)
            Select TimeStamp 
              From #FilterTimes
          Delete From #FilterTimes
          If @@FilterType = 1
            Begin
              -- AND (JOIN)
              Insert Into #FilterTimes
                Select Distinct w1.Timestamp
                  From #WorkTimes1 w1
                  Join #WorkTimes2 w2 on w2.TimeStamp = w1.TimeStamp
            End
          Else If @@FilterType = 2
            Begin
              -- OR (UNION)
              Insert Into #FilterTimes
                Select Distinct Timestamp
                  From #WorkTimes1
                UNION
                Select Distinct Timestamp
                  From #WorkTimes2
            End
--***********************
--select 'Value Filter Times ' + @@FilterSQL 
--select * from #FilterTimes
--***********************
          Goto Fetch_Loop2
        End
    Close FilterCursor
    Deallocate FilterCursor
  End
--********************************************************************************
-- Return Data Based On Whether There Is A Value Filter Or Not
--********************************************************************************
If @ProductGrouping  = 0 
  Begin
 	 If @ValueFilterList Is Null
 	   Begin
 	     Select * 
 	       From #DataList
 	       Order By Var_Order, Timestamp ASC
 	   End
 	 Else
 	   Begin
 	     Select d.* 
 	       From #DataList d
 	       Join #FilterTimes f on f.Timestamp = d.Timestamp
 	       Order By d.Var_Order,  d.Timestamp ASC
 	   End
  End
Else
  Begin
 	 If @ValueFilterList Is Null
 	   Begin
 	     Select * 
 	       From #DataList
 	       Order By Var_Order, Prod_Id, Timestamp ASC
 	   End
 	 Else
 	   Begin
 	     Select d.* 
 	       From #DataList d
 	       Join #FilterTimes f on f.Timestamp = d.Timestamp
 	       Order By d.Var_Order, d.Prod_Id, d.Timestamp ASC
 	   End
  End
Drop Table #WorkTimes1
Drop Table #WorkTimes2
Drop Table #FilterTimes
Drop Table #VariableList
Drop Table #ProductList
Drop Table #IncludeTimes
Drop Table #ExcludeTimes
Drop Table #OverrideTimes
Drop Table #StatusList
Drop Table #DataList
Drop Table #ValueFilter
