Create Procedure dbo.spAL_LookupLimitSet
  @Var_Id int,
  @Prod_Id int,
  @STime datetime,
  @DecimalSep char(1) = '.' 
AS
  --SM Added this for regional settings:
  --  Must replace the period in the result value with a comma if the 
  --  passed decimal separator is not a period.
Select @DecimalSep = COALESCE(@DecimalSep,'.')
--  SELECT *
  Select v.VS_Id, v.Effective_Date, v.Expiration_Date, v.Deviation_From, v.First_Exception, v.Test_Freq, v.AS_Id,
         v.Comment_Id, v.Var_Id, v.Prod_Id, v.Is_Overriden, v.Is_Deviation, v.Is_Overridable, v.Is_Defined,
         v.Is_L_Rejectable, v.Is_U_Rejectable, v.ESignature_Level,
         L_User = CASE 
              WHEN @DecimalSep <> '.' and vr.Data_Type_Id = 2 THEN REPLACE(v.L_User, '.', @DecimalSep)
 	  	  	   WHEN vr.Data_Type_Id > 50 and vr.String_Specification_Setting = 2 THEN 
 	  	  	  	  	 (SELECT Convert(nvarchar(25),Phrase_Order) FROM phrase WHERE Data_Type_Id = vr.Data_Type_Id and Phrase_Value = v.L_User)
              ELSE v.L_User
              END,
         L_Warning = CASE 
              WHEN @DecimalSep <> '.' and vr.Data_Type_Id = 2 THEN REPLACE(v.L_Warning, '.', @DecimalSep)
 	  	  	   WHEN vr.Data_Type_Id > 50 and vr.String_Specification_Setting = 2 THEN 
 	  	  	  	  	 (SELECT Convert(nvarchar(25),Phrase_Order) FROM phrase WHERE Data_Type_Id = vr.Data_Type_Id and Phrase_Value = v.L_Warning)
              ELSE v.L_Warning
              END,
         L_Reject = CASE 
              WHEN @DecimalSep <> '.' and vr.Data_Type_Id = 2 THEN REPLACE(v.L_Reject, '.', @DecimalSep)
 	  	  	   WHEN vr.Data_Type_Id > 50 and vr.String_Specification_Setting = 2 THEN 
 	  	  	  	  	 (SELECT Convert(nvarchar(25),Phrase_Order) FROM phrase WHERE Data_Type_Id = vr.Data_Type_Id and Phrase_Value = v.L_Reject)
              ELSE v.L_Reject
              END,
         L_Entry = CASE 
              WHEN @DecimalSep <> '.' and vr.Data_Type_Id = 2 THEN REPLACE(v.L_Entry, '.', @DecimalSep)
 	  	  	   WHEN vr.Data_Type_Id > 50 and vr.String_Specification_Setting = 2 THEN 
 	  	  	  	  	 (SELECT Convert(nvarchar(25),Phrase_Order) FROM phrase WHERE Data_Type_Id = vr.Data_Type_Id and Phrase_Value = v.L_Entry)
              ELSE v.L_Entry
              END,
         Target = CASE 
              WHEN @DecimalSep <> '.' and vr.Data_Type_Id = 2 THEN REPLACE(v.Target, '.', @DecimalSep)
 	  	  	   WHEN vr.Data_Type_Id > 50 and vr.String_Specification_Setting = 2 THEN 
 	  	  	  	  	 (SELECT Convert(nvarchar(25),Phrase_Order) FROM phrase WHERE Data_Type_Id = vr.Data_Type_Id and Phrase_Value = v.Target)
              ELSE v.Target
              END,
         U_User = CASE 
              WHEN @DecimalSep <> '.' and vr.Data_Type_Id = 2 THEN REPLACE(v.U_User, '.', @DecimalSep)
 	  	  	   WHEN vr.Data_Type_Id > 50 and vr.String_Specification_Setting = 2 THEN 
 	  	  	  	  	 (SELECT Convert(nvarchar(25),Phrase_Order) FROM phrase WHERE Data_Type_Id = vr.Data_Type_Id and Phrase_Value = v.U_User)
              ELSE v.U_User
              END,
         U_Warning = CASE 
              WHEN @DecimalSep <> '.' and vr.Data_Type_Id = 2 THEN REPLACE(v.U_Warning, '.', @DecimalSep)
 	  	  	   WHEN vr.Data_Type_Id > 50 and vr.String_Specification_Setting = 2 THEN 
 	  	  	  	  	 (SELECT Convert(nvarchar(25),Phrase_Order) FROM phrase WHERE Data_Type_Id = vr.Data_Type_Id and Phrase_Value = v.U_Warning)
              ELSE v.U_Warning
              END,
         U_Reject = CASE 
              WHEN @DecimalSep <> '.' and vr.Data_Type_Id = 2 THEN REPLACE(v.U_Reject, '.', @DecimalSep)
 	  	  	   WHEN vr.Data_Type_Id > 50 and vr.String_Specification_Setting = 2 THEN 
 	  	  	  	  	 (SELECT Convert(nvarchar(25),Phrase_Order) FROM phrase WHERE Data_Type_Id = vr.Data_Type_Id and Phrase_Value = v.U_Reject)
              ELSE v.U_Reject
              END,
         U_Entry = CASE 
              WHEN @DecimalSep <> '.' and vr.Data_Type_Id = 2 THEN REPLACE(v.U_Entry, '.', @DecimalSep)
 	  	  	   WHEN vr.Data_Type_Id > 50 and vr.String_Specification_Setting = 2 THEN 
 	  	  	  	  	 (SELECT Convert(nvarchar(25),Phrase_Order) FROM phrase WHERE Data_Type_Id = vr.Data_Type_Id and Phrase_Value = v.U_Entry)
              ELSE v.U_Entry
              END,
 	  	 Data_Type_Id = Case WHEN  vr.Data_Type_Id > 50 and vr.String_Specification_Setting = 2 THEN 1
 	  	  	  	  	  ELSE Data_Type_Id
 	  	  	  	  	  END
    FROM Var_Specs v
         Join Variables vr on vr.Var_Id = v.Var_Id
    WHERE (v.Var_Id = @Var_Id) AND
          (v.Prod_Id = @Prod_Id) AND
          (v.effective_date <= @Stime) AND
          ((v.expiration_date > @STime) OR 
           (v.expiration_date IS NULL))
