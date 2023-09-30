CREATE PROCEDURE dbo.spRHSheetDataWithEnum 
@Sheet_Desc varchar(25),
@Start_Time datetime,
@EventAssn int
AS
DECLARE @Sheet_id int,
        @MasterUnit int,
        @spName nvarchar(25),
        @RCount int
Declare @GenealogyLevel int
Declare @MinTime datetime
Declare @MaxTime datetime
Declare @MaxID int
Declare @MinID int
set nocount on
Create Table #Times (
  Event_Id int,
  Event_Num nVarchar(50),
  Event_Status int NULL,
  MTimeStamp datetime,
  CTimeStamp datetime,
  CUnit int,
  CSourceEvent int NULL,
  CComment_Id int NULL,
  ShowEvent int NULL,
  GenealogyLevel int
)
  -- Get general sheet information.
  SELECT @Sheet_Id = Sheet_Id,
         @MasterUnit = Master_Unit
    FROM Sheets
    WHERE (Sheet_Desc = @Sheet_Desc)
  -- Create temporary table containing all the variables on named sheet.
  SELECT sv.Var_Id,
         sv.Var_Order,
         v.PU_Id,
         v.Spec_Id,
         ds.DS_Desc, 
         Aliased_Var = null
    INTO #Var
    FROM Sheet_Variables sv
    JOIN Variables v on v.var_id = sv.var_id 
    JOIN Data_Source ds on ds.ds_id = v.ds_id
    WHERE (sv.Sheet_Id = @Sheet_Id) 
    ORDER BY sv.Var_Order
  INSERT INTO #Var
    SELECT Var_Id = av.Src_Var_Id,
           Var_Order = 10000,
           PU_Id = 
               CASE
                 WHEN p.Master_Unit Is Null THEN p.PU_Id
                 ELSE p.Master_Unit
               END,                 
           Spec_Id = Null,
           DS_Desc = 'Alias-Src',
           Aliased_Var = av.Dst_Var_Id
    FROM Variable_Alias av
    JOIN Variables v on (v.var_id = av.Src_Var_Id)
    JOIN #Var on (#Var.Var_Id = av.Dst_Var_Id)
    JOIN Prod_Units p on (p.PU_Id = v.PU_Id)
-- Select Master Unit Events, Looking Forward In Genealogy
Insert Into #Times
SELECT Event_Id,
       Event_Num,
       Event_Status,
       MTimeStamp = TimeStamp,
       CTimeStamp = TimeStamp,
       CUnit = Pu_Id,
       CSourceEvent = Source_Event,
       CComment_Id = Comment_Id,
       ShowEvent = 1, 
       GenealogyLevel = 1
  FROM Events
  WHERE (Pu_Id = @MasterUnit) AND
        (TimeStamp >= @Start_Time) 
Select @GenealogyLevel = 1
  if @EventAssn = 1
    begin
      --Search Forward In Genealogy Until No More Events Found
      While (((Select Count(Event_Id) From #Times Where GenealogyLevel = @GenealogyLevel) > 0)  and (@GenealogyLevel <= 20))
        Begin
          Select @MinID = min(Event_ID) From #Times Where GenealogyLevel = @GenealogyLevel
          Select @MaxID = max(Event_ID) From #Times Where GenealogyLevel = @GenealogyLevel
          Insert Into #Times  
          SELECT a.Event_Id,
             a.Event_Num,
             a.Event_Status,
             MTimeStamp = b.MTimeStamp,
             CTimeStamp = a.TimeStamp,
             CUnit = a.Pu_Id,
             CSourceEvent = a.Source_Event,
             CComment_Id = a.Comment_Id,
             ShowEvent = 1,
             GenalogyLevel = @GenealogyLevel + 1
          FROM Events a WITH (INDEX(Events_IDX_Source_Event))   
          JOIN #Times b on (b.Event_Id = a.Source_Event) and b.GenealogyLevel = @GenealogyLevel
          Where a.Source_Event >= @MinID and a.Source_Event <= @MaxId
          Select @GenealogyLevel = @GenealogyLevel + 1
        End
        --
        -- Go Through And Update "ShowEvent" Based On Event Status
        --
        Update #Times Set #Times.ShowEvent = 0 
          Where ((#Times.Event_Status = 8) or (#Times.Event_Status = 12)) and
                 (Select Count(T2.Event_Id) From #Times T2 Where T2.CSourceEvent = #Times.Event_Id) > 0   
    End
 else -- Looking Backward In Genealogy
    begin 
      --Search Backward In Genealogy Until No More Events Found
      While (((Select Count(Event_Id) From #Times Where GenealogyLevel = @GenealogyLevel) > 0)  and (@GenealogyLevel <= 20))
        Begin
          Select @MinID = min(CSourceEvent) From #Times Where GenealogyLevel = @GenealogyLevel and CSourceEvent Is Not Null
          Select @MaxID = max(CSourceEvent) From #Times Where GenealogyLevel = @GenealogyLevel and CSourceEvent Is Not Null
          Insert Into #Times  
          SELECT a.Event_Id,
             a.Event_Num,
             a.Event_Status,
             MTimeStamp = b.MTimeStamp,
             CTimeStamp = a.TimeStamp,
             CUnit = a.Pu_Id,
             CSourceEvent = a.Source_Event,
             CComment_Id = a.Comment_Id,
             ShowEvent = 0,
             GenalogyLevel = @GenealogyLevel + 1
          FROM Events a 
          JOIN #Times b on (b.CSourceEvent = a.Event_Id) and b.GenealogyLevel = @GenealogyLevel 
          Where a.Event_Id >= @MinID and a.Event_Id <= @MaxID
          Select @GenealogyLevel = @GenealogyLevel + 1
        End
    end
  Select @MinTime = min(CTimeStamp) From #Times
  Select @MaxTime = max(CTimeStamp) From #Times
  -- Create temporary table containing all the tests on the named sheet at given times.
  SELECT DISTINCT t.*,
         v.PU_Id
    INTO #Tst
    FROM Tests t 
    join #Var v on v.var_id = t.var_id
    join #Times c on c.CTimeStamp = t.result_on
    Where t.Result_On >= @MinTime and t.Result_On <= @MaxTime    
  -- Return resultset [#1/6] indicating sheet information.
  SELECT Sheet_Id = @Sheet_Id, 	  	  	  	                         -- sheet identifier
         Var_Count = (SELECT COUNT(*) FROM #Var Where Aliased_Var Is Null), 	                         -- number of variables
         Column_Count = (SELECT COUNT(*) FROM #Times Where ShowEvent = 1)
  -- Return resultset [#2/6] containing distinct times.
  SELECT * 
    FROM #Times
    ORDER BY MTimeStamp ASC,
             CTimeStamp ASC
  -- Drop the temporary times table.
  DROP TABLE #Times
  -- Return resultset [#3/6] containing variable-specific information.
  SELECT #Var.Var_Order,
         #Var.DS_Desc,
 	  Write_Access =
           CASE
             WHEN #Var.DS_Desc = 'AutoLog' THEN 1
             ELSE 0
           END,
         v.Data_Type_Id,
 	  Var_Precision = 
             CASE 
               WHEN v.Var_Precision Is Null THEN 0
               ELSE v.Var_Precision
             END,
         Spec_Id = 
             CASE 
               WHEN v.Spec_Id Is Null THEN 0
               ELSE v.Spec_Id
             END,
         Spec_Desc = 
             CASE 
               WHEN v.Spec_Id Is Null THEN ''
               ELSE (select spec_desc from specifications where spec_id = v.spec_id)
             END,
         pl.PL_Id,
         pl.PL_Desc,
         pu.PU_Id,
 	  pu.PU_Desc,
         #Var.Var_Id,
         v.Var_Desc,
         v.Eng_Units,
 	  v.group_id,
         pu.master_unit, 
         v.input_tag,
         v.output_tag,
         v.sa_id
    FROM #Var
    join Variables v on v.Var_Id = #Var.Var_Id 
    join Prod_Units pu on pu.pu_id = #Var.PU_Id
    join Prod_Lines pl on pl.pl_id = pu.pl_id
    WHERE #Var.Aliased_Var Is Null
    ORDER BY #Var.Var_Order ASC
  -- Return resultset [#4/6] containing enumerated type information
  Select Distinct p.Data_type_id, p.phrase_value, p.phrase_order into #Enum
 	 from #Var join variables v on #Var.var_id = v.var_id
 	 join phrase p on p.data_type_id = v.data_type_id
 	 where v.data_type_id > 5
 	 order by p.data_type_id, p.phrase_order, p.phrase_value
  Select @rcount = @@rowcount
  Select *, rcount = @rcount from #Enum
  -- Return resultset [#5/6] containing the test information.
  Select Var_Id,
         PU_Id,  
         Aliased_Var
   From #Var 
   Where Aliased_Var Is Not Null
  -- Drop the temporaty variables table.
  DROP TABLE #Var
  -- Return resultset [#6/6] containing the test information.
  Update #Tst Set Entry_By = 4 Where Entry_By = 26
  SELECT *
    FROM #Tst
  -- Drop the remaining temporary tables.
  DROP TABLE #Tst
