CREATE PROCEDURE dbo.spEM_GetSpecHistVar
  @Prod_Id int,
  @Var_Id int,
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
  SELECT vs.Effective_Date,
         vs.Expiration_Date,
 	  	  v.Data_Type_Id,
         vs.U_Entry,
         vs.U_Reject,
         vs.U_Warning,
         vs.U_User,
         vs.Target,
         vs.L_User,
         vs.L_Warning,
         vs.L_Reject,
         vs.L_Entry,
 	  	  vs.L_Control,
 	  	  vs.T_Control,
 	  	  vs.U_Control,
         vs.Test_Freq,
 	  	  vs.Esignature_Level,
         vs.Comment_Id
    FROM Var_Specs vs
 	 Join Variables v on v.Var_Id = vs.Var_Id
    WHERE (vs.Prod_Id = @Prod_Id) AND (vs.Var_Id = @Var_Id)
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
