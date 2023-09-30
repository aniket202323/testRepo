CREATE PROCEDURE dbo.spRHScrollSheet 
@Sheet_Desc varchar(25),
@Start_Time datetime,
@End_Time datetime,
@EventAssn int
AS
DECLARE @Sheet_id int,
        @MasterUnit int,
        @spName nvarchar(25)
--
--
Declare @GenealogyLevel int
Declare @MinTime datetime
Declare @MaxTime datetime
Declare @MaxID int
Declare @MinID int
--
set nocount on
Create Table #Times (
  Event_Id int,
  Event_Num nVarchar(25),
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
  SELECT Var_Id
    INTO #Var
    FROM Sheet_Variables 
    WHERE (Sheet_Id = @Sheet_Id) 
  INSERT INTO #Var
    SELECT Var_Id = av.Src_Var_Id 
    FROM Variable_Alias av
    JOIN #Var on (#Var.Var_Id = av.Dst_Var_Id)
--
--
-- NOTE: "ShowEvent" Is Legacy Until Extended Client Can Look Forward And Backward In Genealogy 
--       Anything That Is Consumed And Has Children, Should Not Be Shown In Client In The Meantime
-- 
--
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
        (TimeStamp >= @Start_Time) AND
        ((TimeStamp <= @End_Time) OR (@End_Time Is Null))
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
  SELECT DISTINCT t.*
    INTO #Tst
    FROM Tests t 
    join #Var v on v.var_id = t.var_id
    join #Times c on c.CTimeStamp = t.result_on
    Where t.Result_On >= @MinTime and t.Result_On <= @MaxTime    
  -- Drop the temporaty variables table.
  DROP TABLE #Var
  -- Return resultset [#1/4] indicating sheet information.
  SELECT Sheet_Id = @Sheet_Id, 	  	  	  	                              -- sheet identifier
         Column_Count = (SELECT COUNT(*) FROM #Times Where ShowEvent = 1)
  -- Return resultset [#2/4] containing distinct times.
  SELECT * 
    FROM #Times
    ORDER BY MTimeStamp
  -- Drop the temporary times table.
  DROP TABLE #Times
  -- Return resultset [#3/4] containing the test information.
  Update #Tst Set Entry_By = 4 Where Entry_By = 26
  SELECT *
    FROM #Tst
  -- Drop the remaining temporary tables.
  DROP TABLE #Tst
