Create Procedure dbo.spSC_PreloadByProduct 
@ProductId int,
@StartTime datetime,
@EndTime datetime,
@DecimalSep char(1) = '.'
AS
-- Must replace the period in the result value with a comma if the
-- passed decimal separator is not a period.
Select @DecimalSep = Coalesce(@DecimalSep, '.')
DECLARE @UTCNow Datetime,@DbNow Datetime
SELECT @UTCNow = Getutcdate()
SELECT @DbNow = dbo.fnServer_CmnGetdate(@UTCNow)
If @EndTime Is Null Select @EndTime = dateadd(day,1,@DbNow)
Select VariableId = s.Var_Id, Data_Type_Id = v.Data_Type_Id, ProductId = s.Prod_Id,
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
  From var_specs s
  Join Variables v on v.var_id = s.var_id 
  where s.Prod_id = @ProductId and
        s.effective_date <= @StartTime and
        ((s.expiration_date > @StartTime) or (s.expiration_date is null))   
union
Select VariableId = s.Var_Id, Data_Type_Id = v.Data_Type_Id, ProductId = s.Prod_Id,
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
  From var_specs s
  Join Variables v on v.var_id = s.var_id 
  where s.Prod_id = @ProductId and
        s.effective_date > @StartTime and 
        s.effective_date <= @EndTime
Order By VariableId, ProductId, Effective_Date   
