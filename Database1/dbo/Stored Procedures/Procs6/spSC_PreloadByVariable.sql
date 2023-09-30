Create Procedure dbo.spSC_PreloadByVariable 
@VariableId int,
@StartTime datetime,
@EndTime datetime,
@DecimalSep char(1) = '.'
AS
Declare @MasterUnit int
Declare @DataType int
Select @DecimalSep = Coalesce(@DecimalSep, '.')
Select @MasterUnit = PU_Id, @DataType = Data_Type_Id
  From Variables
  Where Var_Id = @VariableId
Select @MasterUnit = (case when master_unit is null then pu_id else master_unit end)
  From Prod_Units
  Where PU_Id = @MasterUnit
create table #products (
  ProductId int
)
DECLARE @UTCNow Datetime,@DbNow Datetime
SELECT @UTCNow = Getutcdate()
SELECT @DbNow = dbo.fnServer_CmnGetdate(@UTCNow)
If @EndTime Is Null Select @EndTime = dateadd(day,1,@DbNow)
Insert into #products
  Select distinct Prod_Id 
  From production_starts 
  Where PU_Id  = @MasterUnit and
        start_time <= @StartTime and
        ((end_time > @StartTime) or (end_time is null))    
  Union
  Select distinct Prod_Id 
  From production_starts 
  Where PU_Id = @MasterUnit and
        start_time > @StartTime and 
        start_time <= @EndTime
Select VariableId = @VariableId, Data_Type_Id = @DataType, p.ProductId,
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
  From #products p 
             join variables v on v.var_id = @VariableId
  left outer join var_specs s on s.var_id = @VariableId and 
                                 s.Prod_id = p.ProductId and
                                 s.effective_date <= @StartTime and
                                 ((s.expiration_date > @StartTime) or (s.expiration_date is null))   
union
Select VariableId = @VariableId, Data_Type_Id = @DataType, p.ProductId,
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
  From #products p 
  join variables v on v.var_id = @VariableId
  join var_specs s on s.var_id = @VariableId and 
                      s.Prod_id = p.ProductId and
                      s.effective_date > @StartTime and 
                      s.effective_date <= @EndTime
Order By VariableId, ProductId, Effective_Date   
drop table #products
