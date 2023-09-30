/* IMPORTANT : This proc is not used by the Proficy Operator, 
     it is left over from the GradeBook operator
     and required for backward compatibility */
Create Procedure dbo.spGBO_StartupData 
  @PU_Id int     AS
  declare @a datetime
  declare @b datetime
  declare @VarId int
  declare @MaxTime datetime
  declare @MaxResult nvarchar(25)
  select @a = dateadd(day,-2,dbo.fnServer_CmnGetDate(getutcdate()))
  select @b = dateadd(day,1,dbo.fnServer_CmnGetDate(getutcdate()))
  create table #Tests (Var_Id int, Result nvarchar(25) NULL, Result_On datetime)
  create table #Vars (Var_Id int)
  Insert into #Vars (Var_Id) 
  select var_id
    from variables 
    where pu_id = @PU_Id
  Declare Var_Cursor Insensitive Cursor
    For (Select * From #Vars)
    For READ ONLY
  Open Var_Cursor
FETCH_LOOP:
   Fetch Next From Var_Cursor 
   Into @VarId
   If (@@Fetch_Status = 0)
   Begin
      Select @MaxTime = NULL
      Select @MaxTime = Result_On, @MaxResult = Result 
        From Tests 
        Where Var_Id = @VarID and Result_On = 
              (Select max(result_on) From Tests  Where Var_Id = @VarID and Result_On between @a and @b)
      If @MaxTime Is Not Null
        insert into #Tests (Var_Id, Result, Result_On) Values (@VarID, @MaxResult, @MaxTime)
      GOTO FETCH_LOOP
   End
Close Var_Cursor
Deallocate Var_Cursor
Drop table #Vars
Select * From #Tests
Drop Table #Tests
