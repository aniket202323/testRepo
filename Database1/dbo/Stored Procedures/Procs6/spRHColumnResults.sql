CREATE PROCEDURE dbo.spRHColumnResults
@Sheet_Desc nvarchar(25),
@EventId int,
@EventAssn tinyint
AS
set nocount on
Create Table #Times (
  EventId int,
  EventNum nvarchar(25),
  EventStatus tinyint NULL,
  CTimeStamp datetime,
  CUnit int,
  CSourceEvent int NULL,
  CComment_Id int NULL,
  GenealogyLevel int
)
Declare @TopParent int
Declare @GenealogyLevel int
Declare @MinTime datetime
Declare @MaxTime datetime
Declare @MaxID int
Declare @MinID int
-- Select The Variables We Care About
select sv.var_id
  into #Vars
  from sheets s 
  join sheet_variables sv on sv.sheet_id = s.sheet_id 
  where s.sheet_desc = @sheet_desc
INSERT INTO #Vars
  SELECT Var_Id = av.Src_Var_Id 
  FROM Variable_Alias av
  JOIN #Vars on (#Vars.Var_Id = av.Dst_Var_Id)
--Get TimeStamps Of Related Events
execute spRHSingleEventTopParent @EventID, @TopParent OUTPUT 
Insert Into #Times  
    SELECT Event_Id,
           Event_Num,
           Event_Status,
           CTimeStamp = TimeStamp,
           CUnit = Pu_Id,
           CSourceEvent = Source_Event,
           CComment_Id = Comment_Id,
           GenealogyLevel = 1
    FROM Events a
    WHERE (Event_Id = @TopParent)
Select @GenealogyLevel = 1
--Search Forward In Genealogy Until No More Events Found
While (((Select Count(EventId) From #Times Where GenealogyLevel = @GenealogyLevel) > 0)  and (@GenealogyLevel <= 20))
  Begin
    Select @MinID = min(EventID) From #Times Where GenealogyLevel = @GenealogyLevel
    Select @MaxID = max(EventID) From #Times Where GenealogyLevel = @GenealogyLevel
    Insert Into #Times  
    SELECT a.Event_Id,
           a.Event_Num,
           a.Event_Status,
           CTimeStamp = a.TimeStamp,
           CUnit = a.Pu_Id,
           CSourceEvent = a.Source_Event,
           CComment_Id = a.Comment_Id,
           GenalogyLevel = @GenealogyLevel + 1
      FROM Events a WITH (INDEX(Events_IDX_Source_Event))   
      JOIN #Times b on (b.EventId = a.Source_Event) and b.GenealogyLevel = @GenealogyLevel
      Where a.Source_Event >= @MinID and
            a.Source_Event <= @MaxId
    Select @GenealogyLevel = @GenealogyLevel + 1
  End
Select @MinTime = min(CTimeStamp), @MaxTime = max(CTimeStamp)
  From #Times
-- Select Result Information.
SELECT DISTINCT v.Var_Id,
       t.Test_id,
       t.Result,
       t.Canceled,
       Entry_On = Case When t.Entry_On = 26 then 4
 	  	   Else t.Entry_On
 	  	   End,
       t.Result_On,
       t.entry_by
FROM Tests t 
join #Vars v on v.var_id = t.var_id 
join #Times R on (R.CTimeStamp = t.Result_On)
Where t.Result_On <= @MaxTime and
      t.Result_On >= @MinTime
drop Table #Vars
drop Table #Times
RETURN(100)
