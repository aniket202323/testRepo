Create Procedure dbo.spGBS_StartupData 
@SheetName nvarchar(50),
@DecimalSep nvarchar(2) = '.'
AS
SET NOCOUNT ON
--Need this for old operator clients - ProfSVR will send a NULL
Select @DecimalSep = COALESCE(@DecimalSep, '.')
Declare @SheetId int
declare @a datetime
declare @b datetime
declare @c datetime
declare @VarId int, @Data_Type_Id int
declare @MaxTime datetime
declare @MaxResult nvarchar(25)
create table #Vars (
  VarId int, Data_Type_id int
)
create table #Tests (
  Var_Id int, 
  Result nvarchar(25) NULL, 
  Result_On datetime
)
Select @SheetId = Sheet_Id
  From Sheets
  Where Sheet_Desc = @SheetName
Insert Into #Vars
  Select sv.Var_id, v.Data_Type_Id
    From Sheet_Variables sv
    Join Variables v on v.Var_Id = sv.Var_Id
    Where Sheet_Id = @SheetId and
          sv.Var_Id Is Not Null
select @c = dbo.fnServer_CmnGetDate(getUTCdate())  
select @a = dateadd(day,-2,@c)
select @b = dateadd(day,1,@c)
Exec('Declare GBSVar_Cursor Cursor Global Static 
  For (Select VarId, Data_Type_Id From #Vars)
  For READ ONLY')
Open GBSVar_Cursor
FETCH_LOOP:
   Fetch Next From GBSVar_Cursor 
   Into @VarId, @Data_Type_Id
   If (@@Fetch_Status = 0)
   Begin
      Select @MaxTime = NULL
      Select @MaxTime = Result_On, @MaxResult = Result 
        From Tests 
        Where Var_Id = @VarID and Result_On = 
              (Select max(result_on) From Tests  Where Var_Id = @VarID and Result_On between @a and @b)
      If @MaxTime Is Not Null
        insert into #Tests (Var_Id, Result, Result_On) 
          Values (
            @VarID, 
            CASE WHEN @DecimalSep <> '.' and @Data_Type_Id = 2 THEN REPLACE(@MaxResult, '.', @DecimalSep) ELSE @MaxResult END,
            @MaxTime)
      GOTO FETCH_LOOP
   End
Close GBSVar_Cursor
Deallocate GBSVar_Cursor
Select 
  Var_Id, 
  Result, 
  Result_On From #Tests
Drop table #Vars
Drop Table #Tests
