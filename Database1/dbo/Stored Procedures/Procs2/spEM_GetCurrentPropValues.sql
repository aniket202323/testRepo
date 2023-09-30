CREATE PROCEDURE dbo.spEM_GetCurrentPropValues
  @Spec_Id  int,
  @Char_Id  int,
  @DecimalSep     nVarChar(2) = '.'
  AS
  --
  DECLARE @Now DateTime
  SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate())
  --
If @DecimalSep != '.'
  SELECT U_Entry = Case When s.Data_Type_Id = 2 then REPLACE(U_Entry, '.', @DecimalSep)
 	  	  	  	  	     Else U_Entry
 	  	  	  	  	  	 End,
 	  	  U_Reject = Case When s.Data_Type_Id = 2 then REPLACE(U_Reject, '.', @DecimalSep)
 	  	  	  	  	     Else U_Reject
 	  	  	  	  	  	 End, 
 	  	  U_Warning = Case When s.Data_Type_Id = 2 then REPLACE(U_Warning, '.', @DecimalSep)
 	  	  	  	  	     Else U_Warning
 	  	  	  	  	  	 End, 
 	  	  U_User = Case When s.Data_Type_Id = 2 then REPLACE(U_User, '.', @DecimalSep)
 	  	  	  	  	     Else U_User
 	  	  	  	  	  	 End,
 	  	  Target = Case When s.Data_Type_Id = 2 then REPLACE(Target, '.', @DecimalSep)
 	  	  	  	  	     Else Target
 	  	  	  	  	  	 End,
         L_User = Case When s.Data_Type_Id = 2 then REPLACE(L_User, '.', @DecimalSep)
 	  	  	  	  	     Else L_User
 	  	  	  	  	  	 End,
 	  	  L_Warning = Case When s.Data_Type_Id = 2 then REPLACE(L_Warning, '.', @DecimalSep)
 	  	  	  	  	     Else L_Warning
 	  	  	  	  	  	 End,
 	  	  L_Reject = Case When s.Data_Type_Id = 2 then REPLACE(L_Reject, '.', @DecimalSep)
 	  	  	  	  	     Else L_Reject
 	  	  	  	  	  	 End,
 	  	  L_Entry = Case When s.Data_Type_Id = 2 then REPLACE(L_Entry, '.', @DecimalSep)
 	  	  	  	  	     Else L_Entry
 	  	  	  	  	  	 End,
 	  	  L_Control = Case When s.Data_Type_Id = 2 then REPLACE(L_Control, '.', @DecimalSep)
 	  	  	  	  	     Else L_Control
 	  	  	  	  	  	 End,
 	  	  T_Control = Case When s.Data_Type_Id = 2 then REPLACE(T_Control, '.', @DecimalSep)
 	  	  	  	  	     Else T_Control
 	  	  	  	  	  	 End,
 	  	  U_Control = Case When s.Data_Type_Id = 2 then REPLACE(U_Control, '.', @DecimalSep)
 	  	  	  	  	     Else U_Control
 	  	  	  	  	  	 End,
 	  	  Test_Freq = COALESCE(Test_Freq, 0),
 	  	  acs.Esignature_Level,
 	  	  acs.Comment_Id,
 	  	  Expiration_Date
    FROM Active_Specs acs
 	 Join Specifications s on s.Spec_Id = acs.Spec_Id
    WHERE (acs.Spec_Id = @Spec_Id) AND
          (Char_Id = @Char_Id) AND
          (Effective_Date <= @Now) AND
          ((Expiration_Date IS NULL) OR
           ((Expiration_Date IS NOT NULL) AND
            (Expiration_Date > @Now)))
Else
  SELECT U_Entry,
 	  	  U_Reject, 
 	  	  U_Warning, 
 	  	  U_User, 
 	  	  Target,
         L_User,
 	  	  L_Warning,
 	  	  L_Reject,
 	  	  L_Entry,
 	  	  L_Control,
 	  	  T_Control,
 	  	  U_Control,
 	  	  Test_Freq = COALESCE(Test_Freq, 0),
 	  	  Esignature_Level,
 	  	  Comment_Id,
 	  	  Expiration_Date
    FROM Active_Specs 
    WHERE (Spec_Id = @Spec_Id) AND
          (Char_Id = @Char_Id) AND
          (Effective_Date <= @Now) AND
          ((Expiration_Date IS NULL) OR
           ((Expiration_Date IS NOT NULL) AND
            (Expiration_Date > @Now)))
