/*
6-19-02 MSI/DS
This procedure searches for events where the variables
for the associated Production Units have data.  If no
specific variables are passed in then it will filter by 
all the event based variables associated with that unit.
In other words - Show the events where at least 1 of 
the variables has data.
*/
CREATE PROCEDURE [dbo].[spRS_SearchEventsWithVarData] 
@PU_id int,
@EventMask varchar(50), 
@VarString varchar(8000),
@InTimeZone varchar(200)= NULL
AS
--------------------
-- Local Variables
--------------------
Declare @MU int --Master Unit
Declare @INstr VarChar(7999)
Declare @I int
Declare @Id int
Declare @Count int
-------------------------------------
-- If a slave unit was sent in then
-- Get the Master Unit
-------------------------------------
Select @MU = Master_Unit from Prod_Units where PU_Id = @PU_Id
If @MU Is Not Null
  select @PU_Id = @MU
--------------------
-- Build Var Table
--------------------
Create Table #T (OrderID Int,Var_Id Int)
-------------------------------------
-- INITIALIZE LOCAL VARIABLES
-------------------------------------
Select @INstr = @VarString + ','
Select @I = 1
--------------------------------------
-- LOOP THROUGH THE DATA AND BUILD #T
--------------------------------------
While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
  Begin
 	 Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
 	 Insert into #T (OrderId,Var_Id) Values (@I,@Id)
 	 Select @I = @I + 1
 	 -----------------------
 	 -- SHORTEN THE STRING
 	 -----------------------
 	 Select @INstr = SubString(@INstr,CharIndex(',',@INstr),Datalength(@INstr))
 	 Select @INstr = Right(@INstr,Datalength(@INstr)-1)
  End
---------------------------------------------------------------------
-- If there is are no variables to filter by in the temp table then
-- add all Event-Based Variables for this unit to the temp table
---------------------------------------------------------------------
Select @Count = Count(*) From #t
If @Count = 0
  Insert into #t(var_id)  
    Select Var_Id From Variables 
    Where PU_ID = @PU_Id
    And Event_Type = 1
Select Distinct(e.Event_Id),
  convert(varchar(20), e.Event_Num) + ' - ' + Convert(varchar(20), p.Prod_Code) + ' - ' + Convert(varchar(25),   dbo.fnServer_CmnConvertFromDBTime(e.timeStamp,@InTimeZone) ) 'Description'
From Events E
inner Join Tests T on E.TimeStamp = T.Result_On 
  and E.PU_Id = @Pu_id 
  and T.result is not null
Join Variables V on V.Var_Id = T.Var_Id 
  and V.Var_Id in 
    (Select Var_Id From #t)
Join Production_Starts ps on ps.PU_Id = @PU_Id 
  and ps.Start_Time <= e.TimeStamp 
  and ((ps.End_Time > e.TimeStamp) or (ps.End_Time Is Null))
Join Products p on p.Prod_Id = ps.Prod_Id
Where upper(e.Event_Num) like '%' + Upper(@EventMask) + '%'
order by E.event_id
drop table #T
