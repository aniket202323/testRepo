﻿CREATE PROCEDURE dbo.spEM_GetTransactionPP
  @Char_Id  int,
  @Trans_Id int,
  @DecimalSep     nVarChar(2) = '.'
  AS
  --
  --
  --
  DECLARE @Now Datetime,
          @Future Datetime,
          @Current Datetime,
          @Spec_Id int
  --
  -- Get transaction approval data.
  --
  SELECT  @Now = COALESCE(Effective_Date,dbo.fnServer_CmnGetDate(getUTCdate()))
    FROM Transactions
    WHERE Trans_Id = @Trans_Id
  IF Exists(SELECT 1 FROM Trans_Metric_Properties Where Trans_Id = @Trans_Id)
 	 SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate())
 Create Table #TempProp(Spec_Id  int,
 	  	 Char_Id 	  	 int,
 	  	 Data_Type_Id Int,
 	  	 L_Entry 	  	 nVarChar(100) NULL,
 	  	 L_Reject 	 nVarChar(100) NULL,
 	  	 L_Warning 	 nVarChar(100) NULL,
 	  	 L_User 	  	 nVarChar(100) NULL,
  	  	 Target 	  	 nVarChar(100) NULL,
 	  	 U_User 	  	 nVarChar(100) NULL,
 	  	 U_Warning 	 nVarChar(100) NULL,
 	  	 U_Reject 	 nVarChar(100) NULL,
 	  	 U_Entry 	  	 nVarChar(100) NULL,
 	  	 L_Control 	 nVarChar(100) NULL,
 	  	 T_Control 	 nVarChar(100) NULL,
 	  	 U_Control 	 nVarChar(100) NULL,
 	  	 Test_Freq 	 nVarChar(100) NULL,
 	  	 Esignature_Level 	 nVarChar(100) NULL,
 	  	 Comment_Id     	 int NULL)
Declare @TransProps Table( 	 Char_Id 	  	  	  	 Int,
 	  	  	  	  	  	  	 Spec_Id 	  	  	  	 Int,
 	  	  	  	  	  	  	 Effective_Date 	  	 Datetime,
 	  	  	  	  	  	  	 Esignature_Level 	 Int,
 	  	  	  	  	  	  	 L_Control 	  	  	 nvarchar(25),
 	  	  	  	  	  	  	 L_Entry 	  	  	  	 nvarchar(25),
 	  	  	  	  	  	  	 L_Reject 	  	  	 nvarchar(25),
 	  	  	  	  	  	  	 L_User 	  	  	  	 nvarchar(25),
 	  	  	  	  	  	  	 L_Warning 	  	  	 nvarchar(25),
 	  	  	  	  	  	  	 T_Control 	  	  	 nvarchar(25),
 	  	  	  	  	  	  	 Target 	  	  	  	 nvarchar(25),
 	  	  	  	  	  	  	 Trans_Id 	  	  	 Int,
 	  	  	  	  	  	  	 U_Control 	  	  	 nvarchar(25),
 	  	  	  	  	  	  	 U_Entry 	  	  	  	 nvarchar(25),
 	  	  	  	  	  	  	 U_Reject 	  	  	 nvarchar(25),
 	  	  	  	  	  	  	 U_User 	  	  	  	 nvarchar(25),
 	  	  	  	  	  	  	 U_Warning 	  	  	 nvarchar(25),
 	  	  	  	  	  	  	 Test_Freq 	  	  	 Int,
 	  	  	  	  	  	  	 Comment_Id 	  	  	 Int
)
Insert Into @TransProps(Char_Id,Spec_Id,Effective_Date,Esignature_Level,L_Control,L_Entry,L_Reject,L_User,L_Warning,T_Control,
 	  	  	  	  	  	 Target,Trans_Id,U_Control,U_Entry,U_Reject,U_User,U_Warning,Test_Freq,Comment_Id)
SELECT Distinct Char_id,Spec_Id,Null,Esignature_Level,L_Control,L_Entry,L_Reject,L_User,L_Warning,T_Control,
 	  	  	  	  	  	 Target,Trans_Id,U_Control,U_Entry,U_Reject,U_User,U_Warning,Test_Freq,Comment_Id
       FROM Trans_Properties 
       WHERE Trans_Id = @Trans_Id
Insert Into @TransProps(Char_Id,Spec_Id,Effective_Date,Esignature_Level,L_Control,L_Entry,L_Reject,L_User,L_Warning,T_Control,
 	  	  	  	  	  	 Target,Trans_Id,U_Control,U_Entry,U_Reject,U_User,U_Warning,Test_Freq,Comment_Id)
SELECT Distinct Char_id,Spec_Id,Effective_Date,Esignature_Level,L_Control,L_Entry,L_Reject,L_User,L_Warning,T_Control,
 	  	  	  	  	  	 Target,Trans_Id,U_Control,U_Entry,U_Reject,U_User,U_Warning,Null,Null
       FROM Trans_Metric_Properties
       WHERE Trans_Id = @Trans_Id
DECLARE TP_Cursor CURSOR
  FOR SELECT Distinct tp.Char_id,tp.Spec_Id
       FROM @TransProps tp
       WHERE Trans_Id = @Trans_Id and Char_Id = @Char_Id
  FOR READ ONLY
OPEN TP_Cursor
NextT:
  FETCH NEXT FROM TP_Cursor INTO @Char_Id,@Spec_Id
  IF  @@FETCH_STATUS = 0 
   BEGIN
     SELECT @Future =  Min(Effective_date)
       FROM Active_Specs
       WHERE  (Spec_Id = @Spec_Id) AND (Char_Id = @Char_Id) AND (Effective_Date > @Now)
     SELECT @Current =  Max(Effective_date)
       FROM Active_Specs
       WHERE  (Spec_Id = @Spec_Id) AND (Char_Id = @Char_Id) AND (Effective_Date < @Now)
     INSERT INTO #TempProp (Spec_Id,Char_Id,Data_Type_Id,L_Entry,L_Reject,L_Warning,L_User,Target,
                            U_User,U_Warning,U_Reject,U_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Comment_Id)
     SELECT Spec_Id = @Spec_Id,
            Char_Id = @Char_Id,
 	  	  	 s.Data_Type_Id, 
            L_Entry   =  CASE
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
            L_Warning  = CASE
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
            L_User   =  CASE
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
            Target  =   CASE
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
            U_User  =   CASE
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
            U_Warning = CASE
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
            U_Entry  =  CASE
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
            L_Control  =  CASE
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
            T_Control  =  CASE
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
            U_Control  =  CASE
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
      FROM @TransProps tp
 	   Join Specifications s on s.spec_Id = tp.Spec_Id
      LEFT JOIN Active_Specs c ON (c.Spec_Id = @Spec_Id) AND (c.Char_Id = @Char_Id) AND (c.Effective_Date = @Current)
      LEFT JOIN Active_Specs p ON (p.Spec_Id = @Spec_Id) AND (p.Char_Id = @Char_Id) AND (p.Effective_Date = @Future)
      WHERE tp.Trans_Id = @Trans_Id And tp.Spec_Id = @Spec_Id AND tp.Char_Id = @Char_Id
      GOTO NextT
   END
   If @DecimalSep != '.' 
     BEGIN
       Update #TempProp Set L_Entry = REPLACE(L_Entry, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempProp Set L_Reject = REPLACE(L_Reject, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempProp Set L_Warning = REPLACE(L_Warning, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempProp Set L_User = REPLACE(L_User, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempProp Set Target = REPLACE(Target, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempProp Set U_User = REPLACE(U_User, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempProp Set U_Warning = REPLACE(U_Warning, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempProp Set U_Reject = REPLACE(U_Reject, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempProp Set U_Entry = REPLACE(U_Entry, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempProp Set L_Control = REPLACE(L_Control, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempProp Set T_Control = REPLACE(T_Control, '.', @DecimalSep) Where Data_Type_Id = 2 
       Update #TempProp Set U_Control = REPLACE(U_Control, '.', @DecimalSep) Where Data_Type_Id = 2 
     END
 SELECT * From #TempProp
 Drop Table #TempProp
 DEALLOCATE TP_Cursor
