Create Procedure dbo.spSupport_ResearchEntries
@UnitName varchar(50), 
@STime datetime,
@ETime datetime
AS
set nocount on
--Declare Local Variables
Declare @MasterUnit int
Declare @TestId BigInt
Select @MasterUnit = NULL
Select @MasterUnit = PU_Id 
  From Prod_Units 
  Where PU_Desc = @UnitName
If @MasterUnit Is Null Return
--Declare Required Temporary Tables
Create Table #Report (
  VariableId       int,
  VariableName     varchar(50) NULL,
  TestId           BigInt,
  TestValue        varchar(25) NULL,
  TestTime         datetime,
  TestEntryId      int,
  TestEntryBy      varchar(25),
  TestEntryOn      datetime, 	 
  TestReelNumber   varchar(30) NULL,
  TestProductId    int NULL,
  TestProductCode  varchar(30) NULL,
  TestHasSpec      tinyint NULL,
  EventNumber      varchar(50) NULL,
  EventEntryOn     datetime NULL,
  Historical       varchar(3),
  MinEntryOn       datetime NULL  
)
Create Table #Variables (
  VariableId       int,
  VariableName     varchar(50) NULL,
)
--Get All Variable Information
Insert Into #Variables (VariableId, VariableName)
  Select v.var_id, v.var_desc
  From variables v
  Join prod_units pu on pu.pu_id = v.pu_id and ((pu.pu_id = @MasterUnit) or (pu.master_unit = @MasterUnit))  
--Get All Tests In Time Range
insert into #Report (TestId, VariableId, VariableName, TestValue , TestTime, TestEntryBy, TestEntryOn, TestEntryId, Historical)
Select T.Test_Id, t.Var_Id, v.VariableName, t.Result, t.Result_On, u.Username, t.entry_on, t.entry_by, 'No'
  From Tests t
  Join #Variables v on v.VariableId = t.var_id
  Join Users u on u.user_id = t.entry_by
  Where Result_On Between @STime and @ETime
Declare Test_Cursor Insensitive Cursor
  For (Select TestId From #Report)
  For READ ONLY
Open Test_Cursor
FETCH_LOOP:
   Fetch Next From Test_Cursor 
   Into @TestId
   If (@@Fetch_Status = 0)
   Begin
      insert into #Report (TestId, VariableId, VariableName, TestValue , TestTime, TestEntryBy, TestEntryOn, TestEntryId, Historical)
        Select T.Test_Id, t.Var_Id, v.VariableName, t.Result, t.Result_On, u.Username, th.entry_on, th.entry_by, 'Yes'
        From Test_History th 
        Join Tests t on t.test_id = @TestId
        Join #Variables v on v.VariableId = t.var_id
        Join Users u on u.user_id = th.entry_by
        Where th.test_id = @TestId
      GOTO FETCH_LOOP
   End
Close Test_Cursor
Deallocate Test_Cursor
--Get Event For Each Test
Update #Report
  Set EventNumber = e.Event_Num, EventEntryOn = e.Entry_On
    From Events e
    Where e.PU_Id = @MasterUnit and e.TimeStamp = #Report.TestTime 
--Get Rid Of Tests Not Event Based
Delete From #Report Where EventNumber is Null
--Get Products Of Each Test
Update #Report
  Set TestProductId = (Select ps.prod_id  
      From Production_Starts ps
      Where ps.PU_Id = @MasterUnit and
            ps.Start_Time <= #Report.TestTime and  
            ((ps.End_Time > #Report.TestTime) or (ps.End_Time Is Null))              
    )  
--Get Product Code Of Each Test
Update #Report
  Set TestProductCode = (
    Select Prod_Code 
      From Products p
      Where p.Prod_Id = #Report.TestProductId              
  )
--Get Minimum Entry On For Each Test
Update #Report 
  Set MinEntryOn = (Select min(r2.TestEntryOn) From #Report r2 
      Where r2.TestId = #Report.TestId              
  )
--Get Specs For Each Test
Update #Report
  Set TestHasSpec = vs.test_freq
    From var_specs vs
    Where vs.var_id = #Report.VariableId and vs.prod_id = #Report.TestProductId and
          vs.effective_date <= #Report.TestTime and ((vs.expiration_date > #Report.TestTime) or (vs.expiration_date is null)) 
Update #Report
  Set TestHasSpec = 0
  Where TestHasSpec Is null
print ''
print ''
print '*******************************************************************************'
print '         Values Entered Before Or Within 5 Seconds Of Column Entry Time'
print '*******************************************************************************'
print ''
print ''
print ''
Select EventNumber, TurnupTime = TestTime, VariableName, Historical, TestValue, EnteredBy = TestEntryBy, 
       EnteredOn = convert(varchar(20),TestEntryOn,109), ColumnEnteredOn = convert(varchar(20),EventEntryOn,109)    
  From #Report 
  Where datediff(second, EventEntryOn, TestEntryOn) < 5 and
        TestValue Is Not Null
  Order By EventNumber, VariableName, TestTime, TestEntryOn    
print ''
print ''
print ''
print ''
print ''
print ''
print '*******************************************************************************'
print '          Values Entered Where There Are No Specs Or Test Frequency = 0'
print '*******************************************************************************'
print ''
print ''
print ''
Select EventNumber, TurnupTime = TestTime, VariableName, Historical, TestValue, EnteredBy = TestEntryBy, 
       EnteredOn = convert(varchar(20),TestEntryOn,109)    
  From #Report 
  Where TesthasSpec = 0
  Order By EventNumber, VariableName, TestTime, TestEntryOn    
print ''
print ''
print ''
print ''
print ''
print ''
print '*******************************************************************************'
print '           Entries Made Within Five Seconds In Time'
print '*******************************************************************************'
print ''
print ''
print ''
Select r1.EventNumber,  r1.VariableName, Historical, EnteredOn = convert(varchar(20),r1.TestEntryOn,109), r1.TestValue, EnteredBy = r1.TestEntryBy, TurnupTime = r1.TestTime    
  From #Report r1
  Where (Select Count(testid) From #Report r2 Where abs(datediff(second, r1.TestEntryOn, r2.TestEntryOn)) < 5) > 1 and
         r1.TestValue Is Not Null
  Order By EventNumber,VariableName, TestTime, TestEntryOn    
print ''
print ''
print ''
print ''
print ''
print ''
print '*******************************************************************************'
print '       Entries Made Longer Than 3 Hours From Initial Entry For Same Test       '
print '*******************************************************************************'
print ''
print ''
print ''
Select EventNumber,  VariableName, Historical, OriginalEntryOn = convert(varchar(20),MinEntryOn,109), EnteredOn = convert(varchar(20),TestEntryOn,109), TestValue, EnteredBy = TestEntryBy, TurnupTime = TestTime    
  From #Report
  Where abs(datediff(minute,minentryon, testentryon )) > 180
  Order By EventNumber,VariableName, TestTime, TestEntryOn    
Drop Table #Report
Drop Table #Variables
