Create Procedure dbo.spSC_PreloadBySheet 
@SheetId int,
@StartTime datetime,
@EndTime datetime,
@DecimalSep char(1) = '.'
AS
Select @DecimalSep = Coalesce(@DecimalSep, '.')
create table #vars(
  VariableId int,
  MasterUnit int NULL,
  Data_Type_Id int NULL,
  ESignature_Level int NULL
)
create table #units (
  UnitId int
)
create table #products (
  ProductId int
)
DECLARE @UTCNow Datetime,@DbNow Datetime
SELECT @UTCNow = Getutcdate()
SELECT @DbNow = dbo.fnServer_CmnGetdate(@UTCNow)
If @EndTime Is Null Select @EndTime = dateadd(day,1,@DbNow)
Insert Into #vars
  Select VariableId = sv.Var_Id, MasterUnit = (case when pu.master_unit is null then pu.pu_id else pu.master_unit end), v.Data_Type_Id, v.ESignature_Level
    From sheet_variables sv
    Join variables v on v.var_id = sv.var_id
    Join prod_units pu on pu.pu_id = v.pu_id  
  Where sv.sheet_id = @SheetId
Insert Into #vars(VariableId,MasterUnit,Data_Type_Id,ESignature_Level)
 select Var_Id1, MasterUnit = (case when pu.master_unit is null then pu.pu_id else pu.master_unit end), v.Data_Type_Id, v.ESignature_Level
  From Sheet_Plots sv
    Join variables v on v.var_id = sv.Var_Id1
    Join prod_units pu on pu.pu_id = v.pu_id  
  Where sv.sheet_id = @SheetId
Insert Into #vars(VariableId,MasterUnit,Data_Type_Id,ESignature_Level)
 select Var_Id2, MasterUnit = (case when pu.master_unit is null then pu.pu_id else pu.master_unit end), v.Data_Type_Id, v.ESignature_Level
  From Sheet_Plots sv
    Join variables v on v.var_id = sv.Var_Id2
    Join prod_units pu on pu.pu_id = v.pu_id  
  Where sv.sheet_id = @SheetId
Insert Into #vars(VariableId,MasterUnit,Data_Type_Id,ESignature_Level)
 select Var_Id3, MasterUnit = (case when pu.master_unit is null then pu.pu_id else pu.master_unit end), v.Data_Type_Id, v.ESignature_Level
  From Sheet_Plots sv
    Join variables v on v.var_id = sv.Var_Id3
    Join prod_units pu on pu.pu_id = v.pu_id  
  Where sv.sheet_id = @SheetId
Insert Into #vars(VariableId,MasterUnit,Data_Type_Id,ESignature_Level)
 select Var_Id4, MasterUnit = (case when pu.master_unit is null then pu.pu_id else pu.master_unit end), v.Data_Type_Id, v.ESignature_Level
  From Sheet_Plots sv
    Join variables v on v.var_id = sv.Var_Id4
    Join prod_units pu on pu.pu_id = v.pu_id  
  Where sv.sheet_id = @SheetId
Insert Into #vars(VariableId,MasterUnit,Data_Type_Id,ESignature_Level)
 select Var_Id5, MasterUnit = (case when pu.master_unit is null then pu.pu_id else pu.master_unit end), v.Data_Type_Id, v.ESignature_Level
  From Sheet_Plots sv
    Join variables v on v.var_id = sv.Var_Id5
    Join prod_units pu on pu.pu_id = v.pu_id  
  Where sv.sheet_id = @SheetId
Insert into #units Select distinct MasterUnit From #vars
Insert into #products
  Select distinct Prod_Id 
  From production_starts 
  Where PU_Id in (Select UnitId From #Units) and
        start_time <= @StartTime and
        ((end_time > @StartTime) or (end_time is null))    
  Union
  Select distinct Prod_Id 
  From production_starts 
  Where PU_Id in (Select UnitId From #Units) and
        start_time > @StartTime and 
        start_time <= @EndTime
Select v.VariableId, v.Data_Type_Id, p.ProductId,
         s.VS_Id, s.Effective_Date, s.Expiration_Date, s.Deviation_From, s.First_Exception, s.Test_Freq, s.AS_Id,
         s.Comment_Id, s.Prod_Id, s.Is_Overriden, s.Is_Deviation, s.Is_Overridable, s.Is_Defined,
         s.Is_L_Rejectable, s.Is_U_Rejectable, ESignature_Level = Coalesce(s.ESignature_Level, v.ESignature_Level),
         L_Control = CASE
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.L_Control, '.', @DecimalSep)
              ELSE s.L_Control
              END,
         L_User = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.L_User, '.', @DecimalSep)
              ELSE s.L_User
              END,
         L_Warning = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.L_Warning, '.', @DecimalSep)
              ELSE s.L_Warning
              END,
         L_Reject = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.L_Reject, '.', @DecimalSep)
              ELSE s.L_Reject
              END,
         L_Entry = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.L_Entry, '.', @DecimalSep)
              ELSE s.L_Entry
              END,
         Target = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.Target, '.', @DecimalSep)
              ELSE s.Target
              END,
         U_User = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.U_User, '.', @DecimalSep)
              ELSE s.U_User
              END,
         U_Warning = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.U_Warning, '.', @DecimalSep)
              ELSE s.U_Warning
              END,
         U_Reject = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.U_Reject, '.', @DecimalSep)
              ELSE s.U_Reject
              END,
         U_Entry = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.U_Entry, '.', @DecimalSep)
              ELSE s.U_Entry
              END,
         U_Control = CASE
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.U_Control, '.', @DecimalSep)
              ELSE s.U_Control
              END,
         T_Control = CASE
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.T_Control, '.', @DecimalSep)
              ELSE s.T_Control
              END
  From #vars v 
  join #products p on (1 = 1) 
  left outer join var_specs s on s.var_id = v.variableId and 
                                 s.Prod_id = p.ProductId and
                                 s.effective_date <= @StartTime and
                                 ((s.expiration_date > @StartTime) or (s.expiration_date is null))   
union
Select v.VariableId, v.Data_Type_Id, p.ProductId,
         s.VS_Id, s.Effective_Date, s.Expiration_Date, s.Deviation_From, s.First_Exception, s.Test_Freq, s.AS_Id,
         s.Comment_Id, s.Prod_Id, s.Is_Overriden, s.Is_Deviation, s.Is_Overridable, s.Is_Defined,
         s.Is_L_Rejectable, s.Is_U_Rejectable, ESignature_Level = Coalesce(s.ESignature_Level, v.ESignature_Level),
         L_Control = CASE
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.L_Control, '.', @DecimalSep)
              ELSE s.L_Control
              END,
         L_User = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.L_User, '.', @DecimalSep)
              ELSE s.L_User
              END,
         L_Warning = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.L_Warning, '.', @DecimalSep)
              ELSE s.L_Warning
              END,
         L_Reject = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.L_Reject, '.', @DecimalSep)
              ELSE s.L_Reject
              END,
         L_Entry = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.L_Entry, '.', @DecimalSep)
              ELSE s.L_Entry
              END,
         Target = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.Target, '.', @DecimalSep)
              ELSE s.Target
              END,
         U_User = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.U_User, '.', @DecimalSep)
              ELSE s.U_User
              END,
         U_Warning = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.U_Warning, '.', @DecimalSep)
              ELSE s.U_Warning
              END,
         U_Reject = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.U_Reject, '.', @DecimalSep)
              ELSE s.U_Reject
              END,
         U_Entry = CASE 
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.U_Entry, '.', @DecimalSep)
              ELSE s.U_Entry
              END,
         U_Control = CASE
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.U_Control, '.', @DecimalSep)
              ELSE s.U_Control
              END,
         T_Control = CASE
              WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(s.T_Control, '.', @DecimalSep)
              ELSE s.T_Control
              END
  From #vars v
  Join #products p on (1 = 1) 
  join var_specs s on s.var_id = v.variableid and 
                      s.Prod_id = p.ProductId and
                      s.effective_date > @StartTime and 
                      s.effective_date <= @EndTime
Order By VariableId, ProductId, Effective_Date   
drop table #products
drop table #vars
drop table #units
