Create Procedure dbo.spGBS_GetUnitSpecs 
@SheetName nvarchar(50), 
@Prod_Id int, 
@STime datetime, 
@DecimalSep nvarchar(2) = '.'
AS
SET NOCOUNT ON
Select @DecimalSep = COALESCE(@DecimalSep, '.')
Declare @SheetId int
create table #Vars (
  VarId int, Data_Type_id int
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
  Select 
      a.VS_Id
      ,a.Effective_Date
      ,a.Expiration_Date
      ,a.Deviation_From
      ,a.First_Exception
      ,a.Test_Freq
      ,a.AS_Id
      ,a.Comment_Id
      ,a.Var_Id
      ,a.Prod_Id
      ,a.Is_OverRiden
      ,a.Is_Deviation
      ,a.Is_OverRidable
      ,a.Is_Defined
      ,a.Is_L_Rejectable
      ,a.Is_U_Rejectable
      ,[L_User] = CASE WHEN @DecimalSep <> '.' and b.Data_Type_Id = 2 THEN REPLACE(a.L_User, '.', @DecimalSep) ELSE a.L_User END
      ,[L_Warning] = CASE WHEN @DecimalSep <> '.' and b.Data_Type_Id = 2 THEN REPLACE(a.L_Warning, '.', @DecimalSep) ELSE a.L_Warning END
      ,[L_Reject] = CASE WHEN @DecimalSep <> '.' and b.Data_Type_Id = 2 THEN REPLACE(a.L_Reject, '.', @DecimalSep) ELSE a.L_Reject END
      ,[L_Entry] = CASE WHEN @DecimalSep <> '.' and b.Data_Type_Id = 2 THEN REPLACE(a.L_Entry, '.', @DecimalSep) ELSE a.L_Entry END
      ,[Target] = CASE WHEN @DecimalSep <> '.' and b.Data_Type_Id = 2 THEN REPLACE(a.Target, '.', @DecimalSep) ELSE a.Target END
      ,[U_User] = CASE WHEN @DecimalSep <> '.' and b.Data_Type_Id = 2 THEN REPLACE(a.U_User, '.', @DecimalSep) ELSE a.U_User END
      ,[U_Warning] = CASE WHEN @DecimalSep <> '.' and b.Data_Type_Id = 2 THEN REPLACE(a.U_Warning, '.', @DecimalSep) ELSE a.U_Warning END
      ,[U_Reject] = CASE WHEN @DecimalSep <> '.' and b.Data_Type_Id = 2 THEN REPLACE(a.U_Reject, '.', @DecimalSep) ELSE a.U_Reject END
      ,[U_Entry] = CASE WHEN @DecimalSep <> '.' and b.Data_Type_Id = 2 THEN REPLACE(a.U_Entry, '.', @DecimalSep) ELSE a.U_Entry END
  from var_specs a 
  join #Vars b on (b.varid = a.var_id) 
  where (a.prod_id = @Prod_ID) and
        (a.effective_date <= @Stime) and  
        ((a.expiration_date > @Stime) or (a.expiration_date is NULL))
drop table #Vars
return(100)
