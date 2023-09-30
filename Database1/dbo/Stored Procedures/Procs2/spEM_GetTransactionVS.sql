CREATE PROCEDURE dbo.spEM_GetTransactionVS
  @Prod_Id  int,
  @Trans_Id int,
  @DecimalSep     nVarChar(2) = '.'
  AS
  --
  --
  --
  DECLARE @Now DateTime,
          @Future DateTime,
          @Current DateTime,
          @Var_Id Int,
          @Spec_Id int,
          @Char_Id int
  --
  -- Get transaction approval data.
  --
SELECT  @Now = COALESCE(Effective_Date,dbo.fnServer_CmnGetDate(getUTCdate()))
    FROM Transactions
    WHERE Trans_Id = @Trans_Id
DECLARE  @TempVar Table (Var_Desc      nvarchar(50),
 	          	  	  	 Data_Type_Id  int,
 	  	  	  	  	  	 Var_Precision int,
  	  	  	  	  	  	 PU_Id         int,
 	  	  	  	  	  	 PUG_Desc      nvarchar(50),
 	  	  	  	  	  	 Var_Id        int,
 	  	  	  	  	  	 Prod_Id       int, 
 	  	  	  	  	  	 L_Entry       nVarChar(100) NULL,
 	  	  	  	  	  	 L_Reject      nVarChar(100) NULL,
 	  	  	  	  	  	 L_Warning     nVarChar(100) NULL,
 	  	  	  	  	  	 L_User        nVarChar(100) NULL,
 	  	  	  	  	  	 Target        nVarChar(100) NULL,
 	  	  	  	  	  	 U_User        nVarChar(100) NULL,
 	  	  	  	  	  	 U_Warning     nVarChar(100) NULL,
 	  	  	  	  	  	 U_Reject      nVarChar(100) NULL,
 	  	  	  	  	  	 U_Entry       nVarChar(100) NULL,
 	  	  	  	  	  	 L_Control     nVarChar(100) NULL,
 	  	  	  	  	  	 T_Control     nVarChar(100) NULL,
 	  	  	  	  	  	 U_Control     nVarChar(100) NULL,
 	  	  	  	  	  	 Test_Freq     nVarChar(100) NULL,
 	  	  	  	  	  	 Esignature_Level     nVarChar(100) NULL,
 	  	  	  	  	  	 Comment_Id    int NULL)
--*******************************************************************************************************
--
-- Search Transaction Properties For Variables
--
--*******************************************************************************************************
Declare c Cursor for 
  Select Spec_Id,tp.Char_Id 
 	 From Trans_Properties tp
    JOIN Pu_Characteristics puc ON puc.Char_Id = tp.Char_Id
 	 Where tp.Trans_Id = @Trans_Id and puc.prod_Id = @Prod_Id
Open c
cLoop:
Fetch Next From c into @Spec_Id,@Char_Id
If @@Fetch_Status = 0
  Begin
   SELECT @Future =  Min(Effective_date)
     FROM Active_Specs
     WHERE  (Spec_Id = @Spec_Id) AND (Char_Id = @Char_Id) AND (Effective_Date > @Now)
   SELECT @Current =  Max(Effective_date)
     FROM Active_Specs
     WHERE  (Spec_Id = @Spec_Id) AND (Char_Id = @Char_Id) AND (Effective_Date < @Now)
    INSERT INTO @TempVar (Var_Desc,Data_Type_Id,Var_Precision,PU_Id,PUG_Desc,Var_Id,Prod_Id,
                      L_Entry,L_Reject,L_Warning,L_User,Target,U_User,U_Warning,U_Reject,U_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Comment_Id)
     SELECT v.Var_Desc,
 	       v.Data_Type_Id,
         v.Var_Precision,
         v.PU_Id,
         pg.PUG_Desc,
         v.Var_Id,
         @Prod_Id, 
         L_Entry   = CASE
                       WHEN (c.L_Entry IS NULL) THEN  '<none>'
                       WHEN (c.L_Entry  = '') THEN  '<Deleted>'
                       ELSE  c.L_Entry
                    END +
                    CASE 
                      WHEN (tp.L_Entry  IS NULL) THEN ''
                      WHEN (tp.L_Entry  = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tp.L_Entry
                    END +
                    CASE 
                      WHEN (p.L_Entry  IS NULL) THEN ''
                      WHEN (p.L_Entry  = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.L_Entry
                    END,
         L_Reject   = CASE
                       WHEN (c.L_Reject IS NULL) THEN  '<none>'
                       WHEN (c.L_Reject  = '') THEN  '<Deleted>'
                       ELSE  c.L_Reject
                    END +
                    CASE 
                      WHEN (tp.L_Reject  IS NULL) THEN ''
                      WHEN (tp.L_Reject  = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tp.L_Reject 
                    END +
                    CASE 
                      WHEN (p.L_Reject  IS NULL) THEN ''
                      WHEN (p.L_Reject  = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.L_Reject 
                    END,
         L_Warning   = CASE
                       WHEN (c.L_Warning  IS NULL) THEN  '<none>'
                       WHEN (c.L_Warning  = '') THEN  '<Deleted>'
                       ELSE  c.L_Warning
                    END +
                    CASE 
                      WHEN (tp.L_Warning IS NULL) THEN ''
                      WHEN (tp.L_Warning  = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tp.L_Warning 
                    END +
                    CASE 
                      WHEN (p.L_Warning IS NULL) THEN ''
                      WHEN (p.L_Warning  = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.L_Warning 
                    END,
          L_User   = CASE
                       WHEN (c.L_User IS NULL) THEN  '<none>'
                       WHEN (c.L_User  = '') THEN  '<Deleted>'
                       ELSE  c.L_User
                    END +
                    CASE 
                      WHEN (tp.L_User IS NULL) THEN ''
                      WHEN (tp.L_User  = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tp.L_User 
                    END +
                    CASE 
                      WHEN (p.L_User IS NULL) THEN ''
                      WHEN (p.L_User  = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.L_User 
                    END,
         Target  = CASE
                    WHEN (c.Target IS NULL) THEN  '<none>'
                    WHEN (c.Target = '') THEN  '<Deleted>' 
                    ELSE  c.Target  
                   END +
                   CASE 
                      WHEN (tp.Target IS NULL) THEN ''
                      WHEN (tp.Target = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tp.Target
                    END +
                   CASE 
                      WHEN (p.Target IS NULL) THEN ''
                      WHEN (p.Target = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.Target
                   END,
         U_User  = CASE
                    WHEN (c.U_User IS NULL) THEN  '<none>'
                    WHEN (c.U_User = '') THEN  '<Deleted>' 
                    ELSE  c.U_User  
                   END +
                   CASE 
                      WHEN (tp.U_User IS NULL) THEN ''
                      WHEN (tp.U_User = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tp.U_User
                    END +
                   CASE 
                      WHEN (p.U_User IS NULL) THEN ''
                      WHEN (p.U_User = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.U_User
                    END,
         U_Warning  = CASE
                    WHEN (c.U_Warning IS NULL) THEN  '<none>'
                    WHEN (c.U_Warning = '') THEN  '<Deleted>' 
                    ELSE  c.U_Warning  
                   END +
                   CASE 
                      WHEN (tp.U_Warning IS NULL) THEN ''
                      WHEN (tp.U_Warning = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tp.U_Warning
                   END +
                   CASE 
                      WHEN (p.U_Warning IS NULL) THEN ''
                      WHEN (p.U_Warning = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.U_Warning
                   END,
         U_Reject  = CASE
                    WHEN (c.U_Reject IS NULL) THEN  '<none>'
                    WHEN (c.U_Reject = '') THEN  '<Deleted>' 
                    ELSE  c.U_Reject  
                   END +
                   CASE 
                      WHEN (tp.U_Reject IS NULL) THEN ''
                      WHEN (tp.U_Reject = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tp.U_Reject
                    END +
                   CASE 
                      WHEN (p.U_Reject IS NULL) THEN ''
                      WHEN (p.U_Reject = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.U_Reject
                    END,
         U_Entry  = CASE
                    WHEN (c.U_Entry IS NULL) THEN  '<none>'
                    WHEN (c.U_Entry = '') THEN  '<Deleted>' 
                    ELSE  c.U_Entry  
                   END +
                   CASE 
                      WHEN (tp.U_Entry IS NULL) THEN ''
                      WHEN (tp.U_Entry = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tp.U_Entry
                    END +
                   CASE 
                      WHEN (p.U_Entry IS NULL) THEN ''
                      WHEN (p.U_Entry = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.U_Entry
                    END,
         L_Control  = CASE
                    WHEN (c.L_Control IS NULL) THEN  '<none>'
                    WHEN (c.L_Control = '') THEN  '<Deleted>' 
                    ELSE  c.L_Control  
                   END +
                   CASE 
                      WHEN (tp.L_Control IS NULL) THEN ''
                      WHEN (tp.L_Control = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tp.L_Control
                    END +
                   CASE 
                      WHEN (p.L_Control IS NULL) THEN ''
                      WHEN (p.L_Control = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.L_Control
                    END,
         T_Control  = CASE
                    WHEN (c.T_Control IS NULL) THEN  '<none>'
                    WHEN (c.T_Control = '') THEN  '<Deleted>' 
                    ELSE  c.T_Control  
                   END +
                   CASE 
                      WHEN (tp.T_Control IS NULL) THEN ''
                      WHEN (tp.T_Control = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tp.T_Control
                    END +
                   CASE 
                      WHEN (p.T_Control IS NULL) THEN ''
                      WHEN (p.T_Control = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.T_Control
                    END,
         U_Control  = CASE
                    WHEN (c.U_Control IS NULL) THEN  '<none>'
                    WHEN (c.U_Control = '') THEN  '<Deleted>' 
                    ELSE  c.U_Control  
                   END +
                   CASE 
                      WHEN (tp.U_Control IS NULL) THEN ''
                      WHEN (tp.U_Control = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tp.U_Control
                    END +
                   CASE 
                      WHEN (p.U_Control IS NULL) THEN ''
                      WHEN (p.U_Control = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.U_Control
                    END,
         Test_Freq  = CASE
                    WHEN (c.Test_Freq IS NULL) THEN  '<none>'
                    ELSE  Convert(nvarchar(25),c.Test_Freq)  
                   END +
                   CASE 
                      WHEN (tp.Test_Freq IS NULL) THEN ''
                      ELSE ' / ' + Convert(nvarchar(25),tp.Test_Freq)
                    END +
                   CASE 
                      WHEN (p.Test_Freq IS NULL) THEN ''
                      ELSE ' / ' + Convert(nvarchar(25),p.Test_Freq)
                    END,
          Esignature_Level  = CASE
                           WHEN (c.Esignature_Level IS NULL) THEN  '<none>'
 	  	  	  	  	  	    When (c.Esignature_Level = 1) then 'User Level'
 	  	  	  	  	  	    When (c.Esignature_Level = 2) then 'Approver Level'
                           ELSE  '<none>'
                           END +
                        CASE 
                           WHEN (tp.Esignature_Level IS NULL) THEN ''
 	  	  	  	  	  	    When (tp.Esignature_Level = 1) then ' / User Level'
 	  	  	  	  	  	    When (tp.Esignature_Level = 2) then ' / Approver Level'
                           ELSE ' / <none>'
                        END +
                        CASE 
                           WHEN (p.Esignature_Level IS NULL) THEN ''
 	  	  	  	  	  	    When (p.Esignature_Level = 1) then ' / User Level'
 	  	  	  	  	  	    When (p.Esignature_Level = 2) then ' / Approver Level'
                           ELSE ' / <none>'
                         END,
         tp.Comment_Id
        FROM Trans_Properties tp
        LEFT JOIN Active_Specs c   ON (c.Spec_Id = @Spec_Id) AND (c.Char_Id = @Char_Id) AND (c.Effective_Date = @Current)
        LEFT JOIN Active_Specs p  ON  (p.Spec_Id = @Spec_Id) AND (p.Char_Id = @Char_Id) AND (p.Effective_Date = @Future)
        JOIN Variables v ON v.Spec_Id = tp.Spec_Id 
 	  	 JOIN PU_Characteristics pu on v.pu_Id = pu.Pu_Id and pu.Prod_Id = @Prod_Id and  pu.Char_Id = @Char_Id
     	 JOIN PU_Groups pg ON v.PUG_Id = pg.PUG_Id
 	 WHERE Trans_Id = @Trans_Id
    goto cloop
  End
Close c
Deallocate c
--*******************************************************************************************************
--
-- Search Transaction Variable For Variables
--
--*******************************************************************************************************
--
Declare v Cursor for 
  Select Var_Id 
 	 From Trans_Variables tv
 	 Where tv.Trans_Id = @Trans_Id and tv.prod_Id = @Prod_Id
Open v
vLoop:
Fetch Next From v into @Var_Id
If @@Fetch_Status = 0
  Begin
   SELECT @Future =  Min(Effective_date)
     FROM Var_Specs
     WHERE  (Var_Id = @Var_Id) AND (Prod_Id = @Prod_Id) AND (Effective_Date > @Now)
   SELECT @Current =  Max(Effective_date)
     FROM Var_Specs
     WHERE  (Var_Id = @Var_Id) AND (Prod_Id = @Prod_Id) AND (Effective_Date < @Now)
    INSERT INTO @TempVar (Var_Desc,Data_Type_Id,Var_Precision,PU_Id,PUG_Desc,Var_Id,Prod_Id,
                      L_Entry,L_Reject,L_Warning,L_User,Target,U_User,U_Warning,U_Reject,U_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Comment_Id)
     SELECT v.Var_Desc,
 	  v.Data_Type_Id,
         v.Var_Precision,
         v.PU_Id,
         pug.PUG_Desc,
         v.Var_Id,
         @Prod_Id, 
         L_Entry   = CASE
                       WHEN (c.L_Entry IS NULL) THEN  '<none>'
                       WHEN (c.L_Entry  = '') THEN  '<Deleted>'
                       ELSE  c.L_Entry
                    END +
                    CASE 
                      WHEN (tv.L_Entry  IS NULL) THEN ''
                      WHEN (tv.L_Entry  = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tv.L_Entry
                    END +
                    CASE 
                      WHEN (p.L_Entry  IS NULL) THEN ''
                      WHEN (p.L_Entry  = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.L_Entry
                    END,
         L_Reject   = CASE
                       WHEN (c.L_Reject IS NULL) THEN  '<none>'
                       WHEN (c.L_Reject  = '') THEN  '<Deleted>'
                       ELSE  c.L_Reject
                    END +
                    CASE 
                      WHEN (tv.L_Reject  IS NULL) THEN ''
                      WHEN (tv.L_Reject  = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tv.L_Reject 
                    END +
                    CASE 
                      WHEN (p.L_Reject  IS NULL) THEN ''
                      WHEN (p.L_Reject  = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.L_Reject 
                    END,
         L_Warning   = CASE
                       WHEN (c.L_Warning  IS NULL) THEN  '<none>'
                       WHEN (c.L_Warning  = '') THEN  '<Deleted>'
                       ELSE  c.L_Warning
                    END +
                    CASE 
                      WHEN (tv.L_Warning IS NULL) THEN ''
                      WHEN (tv.L_Warning  = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tv.L_Warning 
                    END +
                    CASE 
                      WHEN (p.L_Warning IS NULL) THEN ''
                      WHEN (p.L_Warning  = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.L_Warning 
                    END,
          L_User   = CASE
                       WHEN (c.L_User IS NULL) THEN  '<none>'
                       WHEN (c.L_User  = '') THEN  '<Deleted>'
                       ELSE  c.L_User
                    END +
                    CASE 
                      WHEN (tv.L_User IS NULL) THEN ''
                      WHEN (tv.L_User  = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tv.L_User 
                    END +
                    CASE 
                      WHEN (p.L_User IS NULL) THEN ''
                      WHEN (p.L_User  = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.L_User 
                    END,
         Target  = CASE
                    WHEN (c.Target IS NULL) THEN  '<none>'
                    WHEN (c.Target = '') THEN  '<Deleted>' 
                    ELSE  c.Target  
                   END +
                   CASE 
                      WHEN (tv.Target IS NULL) THEN ''
                      WHEN (tv.Target = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tv.Target
                    END +
                   CASE 
                      WHEN (p.Target IS NULL) THEN ''
                      WHEN (p.Target = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.Target
                   END,
         U_User  = CASE
                    WHEN (c.U_User IS NULL) THEN  '<none>'
                    WHEN (c.U_User = '') THEN  '<Deleted>' 
                    ELSE  c.U_User  
                   END +
                   CASE 
                      WHEN (tv.U_User IS NULL) THEN ''
                      WHEN (tv.U_User = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tv.U_User
                    END +
                   CASE 
                      WHEN (p.U_User IS NULL) THEN ''
                      WHEN (p.U_User = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.U_User
                    END,
         U_Warning  = CASE
                    WHEN (c.U_Warning IS NULL) THEN  '<none>'
                    WHEN (c.U_Warning = '') THEN  '<Deleted>' 
                    ELSE  c.U_Warning  
                   END +
                   CASE 
                      WHEN (tv.U_Warning IS NULL) THEN ''
                      WHEN (tv.U_Warning = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tv.U_Warning
                   END +
                   CASE 
                      WHEN (p.U_Warning IS NULL) THEN ''
                      WHEN (p.U_Warning = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.U_Warning
                   END,
         U_Reject  = CASE
                    WHEN (c.U_Reject IS NULL) THEN  '<none>'
                    WHEN (c.U_Reject = '') THEN  '<Deleted>' 
                    ELSE  c.U_Reject  
                   END +
                   CASE 
                      WHEN (tv.U_Reject IS NULL) THEN ''
                      WHEN (tv.U_Reject = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tv.U_Reject
                    END +
                   CASE 
                      WHEN (p.U_Reject IS NULL) THEN ''
                      WHEN (p.U_Reject = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.U_Reject
                    END,
         U_Entry  = CASE
                    WHEN (c.U_Entry IS NULL) THEN  '<none>'
                    WHEN (c.U_Entry = '') THEN  '<Deleted>' 
                    ELSE  c.U_Entry  
                   END +
                   CASE 
                      WHEN (tv.U_Entry IS NULL) THEN ''
                      WHEN (tv.U_Entry = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tv.U_Entry
                    END +
                   CASE 
                      WHEN (p.U_Entry IS NULL) THEN ''
                      WHEN (p.U_Entry = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.U_Entry
                    END,
         L_Control  = CASE
                    WHEN (c.L_Control IS NULL) THEN  '<none>'
                    WHEN (c.L_Control = '') THEN  '<Deleted>' 
                    ELSE  c.L_Control  
                   END +
                   CASE 
                      WHEN (tv.L_Control IS NULL) THEN ''
                      WHEN (tv.L_Control = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tv.L_Control
                    END +
                   CASE 
                      WHEN (p.L_Control IS NULL) THEN ''
                      WHEN (p.L_Control = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.L_Control
                    END,
         T_Control  = CASE
                    WHEN (c.T_Control IS NULL) THEN  '<none>'
                    WHEN (c.T_Control = '') THEN  '<Deleted>' 
                    ELSE  c.T_Control  
                   END +
                   CASE 
                      WHEN (tv.T_Control IS NULL) THEN ''
                      WHEN (tv.T_Control = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tv.T_Control
                    END +
                   CASE 
                      WHEN (p.T_Control IS NULL) THEN ''
                      WHEN (p.T_Control = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.T_Control
                    END,
         U_Control  = CASE
                    WHEN (c.U_Control IS NULL) THEN  '<none>'
                    WHEN (c.U_Control = '') THEN  '<Deleted>' 
                    ELSE  c.U_Control  
                   END +
                   CASE 
                      WHEN (tv.U_Control IS NULL) THEN ''
                      WHEN (tv.U_Control = '') THEN ' / <Deleted>'
                      ELSE ' / ' + tv.U_Control
                    END +
                   CASE 
                      WHEN (p.U_Control IS NULL) THEN ''
                      WHEN (p.U_Control = '') THEN ' / <Deleted>'
                      ELSE ' / ' + p.U_Control
                    END,
         Test_Freq  = CASE
                    WHEN (c.Test_Freq IS NULL) THEN  '<none>'
                    ELSE  Convert(nvarchar(25),c.Test_Freq)  
                   END +
                   CASE 
                      WHEN (tv.Test_Freq IS NULL) THEN ''
                      ELSE ' / ' + Convert(nvarchar(25),tv.Test_Freq)
                    END +
                   CASE 
                      WHEN (p.Test_Freq IS NULL) THEN ''
                      ELSE ' / ' + Convert(nvarchar(25),p.Test_Freq)
                    END,
         Esignature_Level  = CASE
                           WHEN (c.Esignature_Level IS NULL) THEN  '<none>'
 	  	  	  	  	  	    When (c.Esignature_Level = 1) then 'User Level'
 	  	  	  	  	  	    When (c.Esignature_Level = 2) then 'Approver Level'
                           ELSE  '<none>'
                           END +
                        CASE 
                           WHEN (tv.Esignature_Level IS NULL) THEN ''
 	  	  	  	  	  	    When (tv.Esignature_Level = 1) then ' / User Level'
 	  	  	  	  	  	    When (tv.Esignature_Level = 2) then ' / Approver Level'
                           ELSE ' / <none>'
                        END +
                        CASE 
                           WHEN (p.Esignature_Level IS NULL) THEN ''
 	  	  	  	  	  	    When (p.Esignature_Level = 1) then ' / User Level'
 	  	  	  	  	  	    When (p.Esignature_Level = 2) then ' / Approver Level'
                           ELSE ' / <none>'
                         END,
        tv.Comment_Id
 	  From Trans_Variables tv
     Join Variables v on v.Var_Id = tv.Var_Id
 	  --JOIN PU_Characteristics pu on v.pu_Id = pu.Pu_Id and pu.Prod_Id = @Prod_Id and  pu.Char_Id = @Char_Id
     LEFT JOIN Var_Specs c ON (c.Prod_Id = @Prod_Id) AND (c.Effective_Date = @Current) and c.Var_Id = v.Var_Id
     LEFT JOIN Var_Specs p ON (p.Prod_Id = @Prod_Id) AND (p.Effective_Date = @Future)and p.Var_Id = v.Var_Id
     LEFT JOIN PU_Groups pug ON pug.PUG_Id = v.PUG_Id
     WHERE tv.Var_Id = @Var_Id and tv.Prod_Id = @Prod_Id and tv.Trans_Id = @Trans_Id
    goto vloop
  End
Close v
Deallocate v
   If @DecimalSep != '.' 
     BEGIN
       Update @TempVar Set L_Entry = REPLACE(L_Entry, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update @TempVar Set L_Reject = REPLACE(L_Reject, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update @TempVar Set L_Warning = REPLACE(L_Warning, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update @TempVar Set L_User = REPLACE(L_User, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update @TempVar Set Target = REPLACE(Target, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update @TempVar Set U_User = REPLACE(U_User, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update @TempVar Set U_Warning = REPLACE(U_Warning, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update @TempVar Set U_Reject = REPLACE(U_Reject, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update @TempVar Set U_Entry = REPLACE(U_Entry, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update @TempVar Set L_Control = REPLACE(L_Control, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update @TempVar Set T_Control = REPLACE(T_Control, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update @TempVar Set U_Control = REPLACE(U_Control, '.', @DecimalSep) Where Data_Type_Id = 2 
     END
 SELECT *
   FROM @TempVar
   ORDER BY Var_Desc,Prod_Id
