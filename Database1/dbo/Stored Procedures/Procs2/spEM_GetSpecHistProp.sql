CREATE PROCEDURE dbo.spEM_GetSpecHistProp
  @Char_Id int,
  @Spec_Id int,
  @DecimalSep     nVarChar(2) = '.'
  AS
  --
  -- Declare local variables.
  --
Create Table #TempSpecs(Effective_Date  	 DateTime,
 	  	  	  	  	  	 Expiration_Date DateTime,
 	  	  	  	  	  	 Data_Type_Id 	 Int,
 	  	  	  	  	  	 U_Entry  	  	 nvarchar(25),
 	  	  	  	  	  	 U_Reject  	  	 nvarchar(25),
 	  	  	  	  	  	 U_Warning  	  	 nvarchar(25),
 	  	  	  	  	  	 U_User  	  	  	 nvarchar(25),
 	  	  	  	  	  	 Target 	   	  	 nvarchar(25),
 	  	  	  	  	  	 L_User 	   	  	 nvarchar(25),
 	  	  	  	  	  	 L_Warning  	  	 nvarchar(25),
 	  	  	  	  	  	 L_Reject  	  	 nvarchar(25),
 	  	  	  	  	  	 L_Entry  	  	 nvarchar(25),
 	  	  	  	  	  	 L_Control  	  	 nvarchar(25),
 	  	  	  	  	  	 T_Control  	  	 nvarchar(25),
 	  	  	  	  	  	 U_Control  	  	 nvarchar(25),
 	  	  	  	  	  	 Test_Freq 	  	 Int,
 	  	  	  	  	  	 Esignature_Level Int,
 	  	  	  	  	  	 Comment_Id 	  	 Int)
Insert INto #TempSpecs(Effective_Date,Expiration_Date,Data_Type_Id,U_Entry,U_Reject,U_Warning,
 	  	  	  	  	    U_User,Target,L_User,L_Warning,L_Reject,L_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Comment_Id)
     SELECT Effective_Date,
         Expiration_Date,
 	  	  s.Data_Type_Id,
         U_Entry,
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
         Test_Freq,
 	  	  acs.Esignature_Level,
         acs.Comment_Id
      FROM Active_Specs acs
 	   Join Specifications s on s.spec_Id = acs.Spec_Id
      WHERE (Char_Id = @Char_Id) AND (acs.Spec_Id = @Spec_Id)
  If @DecimalSep != '.' 
   BEGIN
       Update #TempSpecs Set L_Entry = REPLACE(L_Entry, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempSpecs Set L_Reject = REPLACE(L_Reject, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempSpecs Set L_Warning = REPLACE(L_Warning, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempSpecs Set L_User = REPLACE(L_User, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempSpecs Set Target = REPLACE(Target, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempSpecs Set U_User = REPLACE(U_User, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempSpecs Set U_Warning = REPLACE(U_Warning, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempSpecs Set U_Reject = REPLACE(U_Reject, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempSpecs Set U_Entry = REPLACE(U_Entry, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempSpecs Set L_Control = REPLACE(L_Control, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempSpecs Set T_Control = REPLACE(T_Control, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempSpecs Set U_Control = REPLACE(U_Control, '.', @DecimalSep) Where Data_Type_Id = 2 
   END
SELECT Effective_Date,Expiration_Date,U_Entry,U_Reject,U_Warning,U_User,Target,L_User,
       L_Warning,L_Reject,L_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Comment_Id
      FROM #TempSpecs
    ORDER BY Effective_Date DESC
