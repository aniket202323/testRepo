Create Procedure dbo.spEC_PreLoadByLine
 	 @LineId int
 AS
Declare @UnitId Int
Create Table   #LineEventData (UnitId Int,UnitName nvarchar(50),InputId Int,InputName  nvarchar(50),Event_Subtype  Int,EventId Int,PositionName  nvarchar(50) )
Declare Unit_Cursor Cursor 
 For Select PU_Id From Prod_Units Where PL_Id = @LineId and Master_Unit is null
 For Read Only
Open Unit_Cursor 
UnitLoop:
Fetch Next From Unit_Cursor InTo @UnitId
If @@Fetch_Status = 0
  Begin
     Insert Into #LineEventData Execute spEC_PreLoadByUnit @UnitId
     GoTo UnitLoop
  End
 	 
Close Unit_Cursor
Deallocate Unit_Cursor
Select * from #LineEventData Order By UnitId,InputId
Drop Table #LineEventData
