CREATE Procedure dbo.spRSQ_EvalSummaryRuns @Sql VarChar(7000),@MasterPU Int
As
Declare @SQLPart1 VarChar(2000)
Declare @SQLPart2 VarChar(2000)
Declare @End Int,@PU Int
Select @End = charindex('id =',@Sql)
Select @SQLPart1 = Left(@Sql,@End + 3) + ' '
Select @End = charindex('and',@Sql)
Select @SQLPart2 = ' ' + Substring(@Sql,@End,LEN(@Sql) - @End + 1)
Create Table #Starts(RSum_Id Int,Start_Time DateTime)
Select @Sql = @SQLPart1 + Convert(VarChar(10),@MasterPU) + @SQLPart2
Insert Into #Starts
  Execute (@Sql)
Declare PU_Cursor Cursor
 For Select PU_Id From Prod_Units where Master_Unit = @MasterPU
 For Read Only
Open PU_Cursor
FetchNext:
 Fetch Next from PU_Cursor INto @PU
 If @@Fetch_Status = 0
  Begin
   Select @Sql = @SQLPart1 + Convert(VarChar(10),@PU) + ' and Start_Time Not In (Select Start_Time From #Starts) ' + @SQLPart2
   INsert Into #Starts
   Execute (@Sql)
   Goto FetchNext
  End
Close PU_Cursor
deallocate PU_Cursor
select g.*
 from #Starts s
 Left Join gb_rsum g on g.RSum_Id = s.RSum_Id
drop table #Starts
