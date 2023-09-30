/* This sp is called by dbo.spBatch_ProcessProcedureReport parameters need to stay in sync*/
CREATE PROCEDURE dbo.spEM_ApproveTrans
  @Trans_Id       int,
  @User_Id        int,
  @Group_Id       int,
  @Deviation_Date datetime,
  @Approved_Date  datetime OUTPUT,
  @Effective_Date datetime OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success.
  --   1 = Error in fetch from main variable specification cursor (pass 2/2).
  --   2 = Error in fetch from main active specification cursor (pass 2/2).
  --   3 = Error in fetch from delete active specification cursor.
  --   4 = Error in insert to Active_Specs.
  --   5 = Error in fetch from old variable specification cursor.
  --   6 = Error in fetch from main active specification cursor (pass 1/2).
  --   7 = Error in fetch from main variable specification cursor (pass 1/2).
  --
  -- Declare local variables.
  --
  DECLARE @VS_Id 	 int,
          @Var_Id 	  	 int,
          @Prod_Id 	  	 int,
          @AS_Id 	  	 int,
          @Char_Id 	  	 int,
          @Spec_Id 	 int,
          @Approved_On  	 datetime,
          @Eff_Date 	 datetime,
          @Exp_Date 	 datetime,
          @Old_Eff_Date 	 datetime,
          @Old_Exp_Date  	 datetime,
          @Force_Delete 	 bit,
          @L_Entry  	 nvarchar(25),
          @L_Reject 	 nvarchar(25),
          @L_Warning 	 nvarchar(25),
          @L_User 	  	 nvarchar(25),
          @Target 	  	 nvarchar(25),
          @U_User 	  	 nvarchar(25),
          @U_Warning 	 nvarchar(25),
          @U_Reject 	 nvarchar(25),
          @U_Entry 	  	 nvarchar(25),
          @L_Control 	 nvarchar(25),
          @T_Control 	 nvarchar(25),
          @U_Control 	 nvarchar(25),
          @Test_Freq 	 int,
 	  	   @Esignature_Level 	 Int,
      @Comment_Id 	 int,
      @IsDefined 	 int,
      @IsOveridden 	 int,
      @PVar_Id 	  	 int,
      @ReturnCode 	 int,
      @InsertId 	  	 int ,
      @Trans_Type 	 Int,
      @Anti_Trans_Id 	 Int,
      @Is_OverRidable 	 Int,
   	   @BackDate_Eff 	  	 DateTime,
 	  	   @AttemptBackdate 	 Int,
 	  	   @Is_Defined 	  	 Int,
 	  	   @New_VsId 	  	  	 Int,
 	  	   @ExpDate 	  	  	 DateTime
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1, @User_Id,'spEM_ApproveTrans',  convert(nVarChar(10),@Trans_Id ) + ','  + convert(nVarChar(10),@User_Id ) + ','  + convert(nVarChar(10),@Group_Id ) + ','  +
 	 convert(nVarChar(25),@Effective_Date) ,dbo.fnServer_CmnGetDate(getUTCdate()))
select @InsertId = Scope_Identity()
 --
  -- Get the approval time to the current date/time.
  --
 SELECT @Approved_On = dbo.fnServer_CmnGetDate(getUTCdate())
 SELECT @Approved_On = DATEADD(Millisecond,-DatePart(Millisecond,@Approved_On),@Approved_On)
 SELECT @Approved_On = DATEADD(Second,-DatePart(Second,@Approved_On),@Approved_On)
  --
  -- Set the effective date/time greated than or equal to the approved on date/time.
  --
Create Table #Pv (Prod_Id Int,Var_Id Int) 
Select @BackDate_Eff = @Effective_Date
Select @AttemptBackdate = 0
If DateDiff(minute,@Effective_Date,@Approved_On) > 5
 	 Select @AttemptBackdate = 1
IF @Approved_On > @Effective_Date SELECT @Effective_Date = @Approved_On
Select @Trans_Type = Trans_Type_Id From Transactions Where Trans_Id = @Trans_Id
If @Trans_Type = 3  -- Deviation Create anti Dev
 	 Begin
 	    Insert into Transactions (Trans_Desc,Transaction_Grp_Id,Trans_Type_Id) Values ('<' + Convert(nVarChar(10),@Trans_Id) + '>' + 'Anti-Deviation',1,5)
 	    Select  @Anti_Trans_Id = Scope_Identity()
 	    Insert Into Trans_Variables (Trans_Id, Var_Id,Prod_Id,U_Entry,U_Reject,U_Warning,U_User,Target,L_User,L_Warning,L_Reject,L_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Comment_Id)
 	  	 Select  @Anti_Trans_Id,
 	  	              s.Var_Id,
 	  	  	 s.Prod_Id,
 	  	  	 U_Entry = Case   When t.U_Entry is null Then s.U_Entry
 	  	  	  	    	  When s.U_Entry is null Then ''
 	  	  	  	     	  Else   s.U_Entry
 	  	  	  	    End,
 	  	  	 U_Reject = Case   When t.U_Reject is null Then s.U_Reject
 	  	  	  	    	  When s.U_Reject is null Then ''
 	  	  	  	     	  Else   s.U_Reject
 	  	  	  	    End,
 	  	  	 U_Warning = Case   When t.U_Warning is null Then s.U_Warning
 	  	  	  	    	  When s.U_Warning is null Then ''
 	  	  	  	     	  Else   s.U_Warning
 	  	  	  	    End,
 	  	  	 U_User = Case   When t.U_User is null Then s.U_User
 	  	  	  	    	  When s.U_User is null Then ''
 	  	  	  	     	  Else   s.U_User
 	  	  	  	    End,
 	  	  	 Target = Case   When t.Target is null Then s.Target
 	  	  	  	    	  When s.Target is null Then ''
 	  	  	  	     	  Else   s.Target
 	  	  	  	    End,
 	  	  	 L_User = Case   When t.L_User is null Then s.L_User
 	  	  	  	    	  When s.L_User is null Then ''
 	  	  	  	     	  Else   s.L_User
 	  	  	  	    End,
 	  	  	 L_Warning = Case   When t.L_Warning is null Then s.L_Warning
 	  	  	  	    	  When s.L_Warning is null Then ''
 	  	  	  	     	  Else   s.L_Warning
 	  	  	  	    End,
 	  	  	 L_Reject = Case   When t.L_Reject is null Then s.L_Reject
 	  	  	  	    	  When s.L_Reject is null Then ''
 	  	  	  	     	  Else   s.L_Reject
 	  	  	  	    End,
 	  	  	 L_Entry = Case   When t.L_Entry is null Then s.L_Entry
 	  	  	  	    	  When s.L_Entry is null Then ''
 	  	  	  	     	  Else   s.L_Entry
 	  	  	  	    End,
 	  	  	 L_Control = Case   When t.L_Control is null Then s.L_Control
 	  	  	  	    	  When s.L_Control is null Then ''
 	  	  	  	     	  Else   s.L_Control
 	  	  	  	    End,
 	  	  	 T_Control = Case   When t.T_Control is null Then s.T_Control
 	  	  	  	    	  When s.T_Control is null Then ''
 	  	  	  	     	  Else   s.T_Control
 	  	  	  	    End,
 	  	  	 U_Control = Case   When t.U_Control is null Then s.U_Control
 	  	  	  	    	  When s.U_Control is null Then ''
 	  	  	  	     	  Else   s.U_Control
 	  	  	  	    End,
 	  	  	 Test_Freq = Case   When t.Test_Freq is null Then s.Test_Freq
 	  	  	  	    	  When s.Test_Freq is null Then -1
 	  	  	  	     	  Else   s.Test_Freq
 	  	  	  	    End,
 	  	  	 Esignature_Level = Case   When t.Esignature_Level is null Then s.Esignature_Level
 	  	  	  	    	  When s.Esignature_Level is null Then -1
 	  	  	  	     	  Else s.Esignature_Level
 	  	  	  	    End,
 	  	  	 Comment_Id = Case   When t.Comment_Id is null Then s.Comment_Id
 	  	  	  	     	  Else   s.Comment_Id
 	  	  	  	    End
 	  	   From Trans_Variables t
  	                INNER JOIN Var_Specs s ON (s.Prod_Id = t.Prod_Id) AND  (s.Var_Id = t.Var_Id) AND
             	  	  	  (s.Effective_Date <= @Effective_Date) AND  ((s.Expiration_Date IS NULL) OR ((s.Expiration_Date IS NOT NULL) AND  (s.Expiration_Date > @Effective_Date)))
 	  	   Where Trans_Id = @Trans_Id 
 	    Insert Into Trans_Properties(Trans_Id,Spec_Id,Char_Id,U_Entry,U_Reject,U_Warning,U_User,Target,L_User,L_Warning,L_Reject,L_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Comment_Id,is_defined)
 	  	 Select  	 @Anti_Trans_Id, 
 	  	  	 s.Spec_Id,
 	  	  	 s.Char_Id,
 	  	  	 U_Entry = Case   When t.U_Entry is null Then s.U_Entry
 	  	  	  	    	  When s.U_Entry is null Then ''
 	  	  	  	     	  Else   s.U_Entry
 	  	  	  	    End,
 	  	  	 U_Reject = Case   When t.U_Reject is null Then s.U_Reject
 	  	  	  	    	  When s.U_Reject is null Then ''
 	  	  	  	     	  Else   s.U_Reject
 	  	  	  	    End,
 	  	  	 U_Warning = Case   When t.U_Warning is null Then s.U_Warning
 	  	  	  	    	  When s.U_Warning is null Then ''
 	  	  	  	     	  Else   s.U_Warning
 	  	  	  	    End,
 	  	  	 U_User = Case   When t.U_User is null Then s.U_User
 	  	  	  	    	  When s.U_User is null Then ''
 	  	  	  	     	  Else   s.U_User
 	  	  	  	    End,
 	  	  	 Target = Case   When t.Target is null Then s.Target
 	  	  	  	    	  When s.Target is null Then ''
 	  	  	  	     	  Else   s.Target
 	  	  	  	    End,
 	  	  	 L_User = Case   When t.L_User is null Then s.L_User
 	  	  	  	    	  When s.L_User is null Then ''
 	  	  	  	     	  Else   s.L_User
 	  	  	  	    End,
 	  	  	 L_Warning = Case   When t.L_Warning is null Then s.L_Warning
 	  	  	  	    	  When s.L_Warning is null Then ''
 	  	  	  	     	  Else   s.L_Warning
 	  	  	  	    End,
 	  	  	 L_Reject = Case   When t.L_Reject is null Then s.L_Reject
 	  	  	  	    	  When s.L_Reject is null Then ''
 	  	  	  	     	  Else   s.L_Reject
 	  	  	  	    End,
 	  	  	 L_Entry = Case   When t.L_Entry is null Then s.L_Entry
 	  	  	  	    	  When s.L_Entry is null Then ''
 	  	  	  	     	  Else   s.L_Entry
 	  	  	  	    End,
 	  	  	 L_Control = Case   When t.L_Control is null Then s.L_Control
 	  	  	  	    	  When s.L_Control is null Then ''
 	  	  	  	     	  Else   s.L_Control
 	  	  	  	    End,
 	  	  	 T_Control = Case   When t.T_Control is null Then s.T_Control
 	  	  	  	    	  When s.T_Control is null Then ''
 	  	  	  	     	  Else   s.T_Control
 	  	  	  	    End,
 	  	  	 U_Control = Case   When t.U_Control is null Then s.U_Control
 	  	  	  	    	  When s.U_Control is null Then ''
 	  	  	  	     	  Else   s.U_Control
 	  	  	  	    End,
 	  	  	 Test_Freq = Case   When t.Test_Freq is null Then s.Test_Freq
 	  	  	  	    	  When s.Test_Freq is null Then -1
 	  	  	  	     	  Else   s.Test_Freq
 	  	  	  	    End,
 	  	  	 Esignature_Level = Case   When t.Esignature_Level is null Then s.Esignature_Level
 	  	  	  	    	  When s.Esignature_Level is null Then -1
 	  	  	  	     	  Else   s.Esignature_Level
 	  	  	  	    End,
 	  	  	 Comment_Id = Case   When t.Comment_Id is null Then s.Comment_Id
 	  	  	  	    	  When s.Comment_Id is null Then -1
 	  	  	  	     	  Else s.Comment_Id
 	  	  	  	    End,
 	  	  	  t.Is_Defined
 	  	   From Trans_Properties t 
 	  	   LEFT JOIN Active_Specs s ON (s.Spec_Id = t.Spec_Id) AND (s.Char_Id = t.Char_Id) AND
            	  	  	  (s.Effective_Date <= @Effective_Date) AND  ((s.Expiration_Date IS NULL) OR ((s.Expiration_Date IS NOT NULL) AND  (s.Expiration_Date > @Effective_Date)))
 	  	    WHERE t.Trans_Id = @Trans_Id
 	 End
If (((Select Count(*) From Characteristics 
      Where Derived_From_Parent IN (Select Distinct Char_Id from Trans_Properties Where Trans_Id = @Trans_Id)) <> 0) or
    ((Select Count(*) From Characteristics c 
 	 Join   Trans_Properties tp   on c.Char_Id = tp.char_Id
        Where Derived_From_Parent IS Not Null) <> 0) Or 
    ((Select Count(*) From Trans_Char_Links Where Trans_Id = @Trans_Id) <> 0))
 Begin
  Execute @ReturnCode =  spEM_AppTransExpandPP @Trans_Id,@User_Id
  If @ReturnCode <> 0 
   Begin
            Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 8 where Audit_Trail_Id = @InsertId
            Return (8)
   End
 End
Execute @ReturnCode =  spEM_AppTransProducts  @Trans_Id,@User_Id
If @ReturnCode <> 0 
   Begin
            Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 10 where Audit_Trail_Id = @InsertId
            Return (10)
   End
Execute @ReturnCode =  spEM_AppTransCharacteristics @Trans_Id,@User_Id
If @ReturnCode <> 0 
   Begin
            Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 9 where Audit_Trail_Id = @InsertId
            Return (9)
   End
Execute @ReturnCode =  spEM_AppTransCharLinks  @Trans_Id,@User_Id
If @ReturnCode <> 0 
   Begin
            Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 11 where Audit_Trail_Id = @InsertId
            Return (11)
   End
Execute @ReturnCode =  spEM_AppTransInValidation  @Trans_Id,@User_Id
If @ReturnCode <> 0 
   Begin
            Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 12 where Audit_Trail_Id = @InsertId
            Return (12)
   End
   --
  -- Create a temporary table for active specifications.
  --
  CREATE TABLE #New_Active_Specs (
    Spec_Id         int           NOT NULL,
    Char_Id         int           NOT NULL,
    Force_Delete    bit           NOT NULL,
    AS_Id           int           NULL,
    Effective_Date  datetime      NULL,
    Expiration_Date datetime      NULL,
    U_Entry         nVarChar(25)   NULL,
    U_Reject        nVarChar(25)   NULL,
    U_Warning       nVarChar(25)   NULL,
    U_User          nVarChar(25)   NULL,
    Target          nVarChar(25)   NULL,
    L_User          nVarChar(25)   NULL,
    L_Warning       nVarChar(25)   NULL,
    L_Reject        nVarChar(25)   NULL,
    L_Entry         nVarChar(25)   NULL,
    L_Control       nVarChar(25)   NULL,
    T_Control       nVarChar(25)   NULL,
    U_Control       nVarChar(25)   NULL,
    Test_Freq 	  	 int 	 Null,
 	 Esignature_Level Int Null,
    Comment_Id 	  	 int 	 Null,
    Is_Defined 	  	 int 	 Null,
    Not_Defined 	  	 int 	 Null
)
  --
  -- Load the temporary active specifications table with a record for every
  -- active specification record that will be added.
  --
  DECLARE Active_Spec_Cursor CURSOR
    FOR SELECT t.Spec_Id,
               t.Char_Id,
               t.Force_Delete,
               a.AS_Id,
               a.Effective_Date,
               a.Expiration_Date,
               U_Entry =
                 CASE
                   WHEN t.U_Entry IS NULL THEN a.U_Entry
                   WHEN t.U_Entry = '' THEN NULL
                   ELSE t.U_Entry
                 END,
               U_Reject =
                 CASE
                   WHEN t.U_Reject IS NULL THEN a.U_Reject
                   WHEN t.U_Reject = '' THEN NULL
                   ELSE t.U_Reject
                 END,
               U_Warning =
                 CASE
                   WHEN t.U_Warning IS NULL THEN a.U_Warning
                   WHEN t.U_Warning = '' THEN NULL
                   ELSE t.U_Warning
                 END,
               U_User =
                 CASE
                   WHEN t.U_User IS NULL THEN a.U_User
                   WHEN t.U_User = '' THEN NULL
                   ELSE t.U_User
                 END,
               Target =
                 CASE
                   WHEN t.Target IS NULL THEN a.Target
                   WHEN t.Target = '' THEN NULL
                   ELSE t.Target
                 END,
               L_User =
                 CASE
                   WHEN t.L_User IS NULL THEN a.L_User
                   WHEN t.L_User = '' THEN NULL
                   ELSE t.L_User
                 END,
               L_Warning =
                 CASE
                   WHEN t.L_Warning IS NULL THEN a.L_Warning
                   WHEN t.L_Warning = '' THEN NULL
                   ELSE t.L_Warning
                 END,
               L_Reject =
                 CASE
                   WHEN t.L_Reject IS NULL THEN a.L_Reject
                   WHEN t.L_Reject = '' THEN NULL
                   ELSE t.L_Reject
                 END,
               L_Entry =
                 CASE
                   WHEN t.L_Entry IS NULL THEN a.L_Entry
                   WHEN t.L_Entry = '' THEN NULL
                   ELSE t.L_Entry
                 END,
               L_Control =
                 CASE
                   WHEN t.L_Control IS NULL THEN a.L_Control
                   WHEN t.L_Control = '' THEN NULL
                   ELSE t.L_Control
                 END,
               T_Control =
                 CASE
                   WHEN t.T_Control IS NULL THEN a.T_Control
                   WHEN t.T_Control = '' THEN NULL
                   ELSE t.T_Control
                 END,
               U_Control =
                 CASE
                   WHEN t.U_Control IS NULL THEN a.U_Control
                   WHEN t.U_Control = '' THEN NULL
                   ELSE t.U_Control
                 END,
               Test_Freq =
                 CASE
                   WHEN t.Test_Freq IS NULL THEN a.Test_Freq
 	  	     	  	  	 WHEN t.Test_Freq = -1 THEN NULL
                   ELSE t.Test_Freq
                 END,
               Esignature_Level =
                 CASE
                   WHEN t.Esignature_Level IS NULL THEN a.Esignature_Level
 	  	     	  	  	  	  	  	  WHEN t.Esignature_Level = -1 THEN NULL
                   ELSE t.Esignature_Level
                 END,
              Comment_Id =
                 CASE
                   WHEN t.Comment_Id IS NULL THEN a.Comment_Id
  	  	     	  	    WHEN t.Comment_Id = -1 THEN NULL
                   ELSE t.Comment_Id
                 END,
 	 Is_Defined =
 	   CASE
 	       When t.Is_Defined Is Null and t.Not_Defined is null Then a.Is_Defined
 	       When a.Is_Defined Is Null Then t.Is_Defined
          When  t.Not_Defined is Not Null and  t.Is_Defined  is not null  Then ((a.Is_defined + t.Is_Defined) -  (a.Is_defined & t.Is_Defined)) - t.Not_Defined
 	       When  t.Not_Defined is Not Null then a.Is_Defined - t.Not_Defined
                   Else (a.Is_defined + t.Is_Defined) -  (a.Is_defined & t.Is_Defined)
 	   END
          FROM Trans_Properties t
          LEFT OUTER JOIN Active_Specs a ON
            (a.Spec_Id = t.Spec_Id) AND (a.Char_Id = t.Char_Id) AND
            (a.Effective_Date <= @Effective_Date) AND
            ((a.Expiration_Date IS NULL) OR
             ((a.Expiration_Date IS NOT NULL) AND
              (a.Expiration_Date > @Effective_Date)))
          WHERE t.Trans_Id = @Trans_Id
    FOR READ ONLY
  OPEN Active_Spec_Cursor
  Next_Active_Spec1:
  FETCH NEXT FROM Active_Spec_Cursor
    INTO @Spec_Id, @Char_Id, @Force_Delete, @AS_Id, @Eff_Date, @Exp_Date,
         @U_Entry, @U_Reject, @U_Warning, @U_User, @Target,
         @L_User, @L_Warning, @L_Reject, @L_Entry, @L_Control,@T_Control,@U_Control,@Test_Freq,@Esignature_Level,
 	  	   	  	  @Comment_Id,@IsDefined
  IF @@FETCH_STATUS = 0
    BEGIN
 	   IF @IsDefined = 0 SELECT @IsDefined = Null
      INSERT INTO #New_Active_Specs(AS_Id, Char_Id, Spec_Id, Effective_Date,
          Expiration_Date, Force_Delete, L_Entry, L_Reject, L_Warning, L_User,
          Target, U_User, U_Warning, U_Reject, U_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Comment_Id,Is_Defined)
        VALUES(@AS_Id, @Char_Id, @Spec_Id, @Eff_Date, @Exp_Date,
          @Force_Delete, @L_Entry, @L_Reject, @L_Warning, @L_User, @Target,
          @U_User, @U_Warning, @U_Reject, @U_Entry,@L_Control,@T_Control,@U_Control, @Test_Freq,@Esignature_Level, @Comment_Id,@IsDefined)
      GOTO Next_Active_Spec1
    END
  ELSE IF @@FETCH_STATUS <> -1
    BEGIN
      RAISERROR('Fetch error for Active_Spec_Cursor1 (@@FETCH_STATUS = %d).',
                11, -1, @@FETCH_STATUS)
      Close Active_Spec_Cursor
      DEALLOCATE Active_Spec_Cursor
      DROP TABLE #New_Active_Specs
     Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 6 where Audit_Trail_Id = @InsertId
      RETURN(6)
    END
Close Active_Spec_Cursor  
DEALLOCATE Active_Spec_Cursor
  --
  -- First delete  child variables  in case this was a previously failed transaction
  --
  Delete From Trans_Variables where
 	  Trans_Id  = @Trans_Id  and Var_Id In (Select Var_Id From Variables where PVar_Id is Not Null and SPC_Group_Variable_Type_Id is Null)
 --
  -- duplicate transaction for child variables
  --
  INSERT Trans_Variables (Trans_Id,
 	  	  	  	 Var_Id,
 	  	  	  	 Prod_Id,
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
 	  	  	  	 Esignature_Level,
 	  	  	  	 Force_Delete,
 	  	  	  	 Comment_Id,
 	  	  	  	 Is_Defined)
 	  	  	 SELECT  t.Trans_Id,
 	  	  	  	 v.Var_Id,
 	  	  	  	 t.Prod_Id,
 	  	  	  	 t.U_Entry,
 	  	  	  	 t.U_Reject,
 	  	  	  	 t.U_Warning,
 	  	  	  	 t.U_User,
 	  	  	  	 t.Target,
 	  	  	  	 t.L_User,
 	  	  	  	 t.L_Warning,
 	  	  	  	 t.L_Reject,
 	  	  	  	 t.L_Entry,
 	  	  	  	 t.L_Control,
 	  	  	  	 t.T_Control,
 	  	  	  	 t.U_Control,
 	  	  	  	 t.Test_Freq,
 	  	  	  	 t.Esignature_Level,
 	  	  	  	 t.Force_Delete,
 	  	  	  	 t.Comment_Id,
 	  	  	  	 t.Is_Defined
                         FROM Trans_Variables t
 	  	  	  JOIN Variables v ON v.PVar_Id = t.Var_Id
  	  	  	  WHERE Trans_Id = @Trans_Id AND PU_Id <> 0 AND SPC_Group_Variable_Type_Id is Null
  CREATE TABLE #New_Var_Specs (
    Var_Id 	  	 int 	  	 Not Null,
    Prod_Id 	  	 int  	  	 Not Null,
    Force_Delete 	  	 bit 	  	 Not Null,
    VS_Id 	  	 int 	  	 Null,
    Effective_Date  	 datetime 	 Null,
    Expiration_Date 	 datetime 	 Null,
    U_Entry 	  	 nVarChar(25) 	 Null,
    U_Reject 	 nVarChar(25) 	 Null,
    U_Warning 	 nVarChar(25) 	 Null,
    U_User 	  	 nVarChar(25) 	 Null,
    Target 	  	 nVarChar(25) 	 Null,
    L_User 	  	 nVarChar(25) 	 Null,
    L_Warning 	 nVarChar(25) 	 Null,
    L_Reject 	 nVarChar(25) 	 Null,
    L_Entry 	  	 nVarChar(25) 	 Null,
    L_Control 	 nVarChar(25) 	 Null,
    T_Control 	 nVarChar(25) 	 Null,
    U_Control 	 nVarChar(25) 	 Null,
    Test_Freq 	  	 int 	  	 Null,
 	  	 Esignature_Level Int Null,
    Comment_Id 	  	 int 	  	 Null,
    Is_Defined       	 int 	  	 Null,
    Is_OverRidable 	 int 	  	 Null,
    As_Id 	  	  	 int 	  	 Null)
  --
  -- Load the temporary variable specifications table with a record for every
  -- variable specification record that will be added.
  --  
Execute spEM_AppTransExpandVS @Trans_Id
Declare @T_LE nVarChar(25),@T_LW nVarChar(25),@T_LR nVarChar(25),@T_LU nVarChar(25),@T_T nVarChar(25),
 	 @T_UE nvarchar(25),@T_UW nvarchar(25),@T_UR nvarchar(25),@T_UU nvarchar(25),@T_TF nvarchar(25),@T_SIG nvarchar(25),
 	 @T_LC  nvarchar(25),@T_TC  nvarchar(25),@T_UC  nVarChar(25)
DECLARE Var_Spec_Cursor CURSOR
    FOR SELECT t.Var_Id,
               t.Prod_Id,
               t.Force_Delete,
               v.VS_Id,
               v.Effective_Date,
               v.Expiration_Date,
               U_Entry =
                 CASE
                   WHEN t.U_Entry IS NULL THEN v.U_Entry
                   WHEN (t.U_Entry = '') and (@Trans_Type = 2)  THEN v.U_Entry
                   WHEN t.U_Entry = '' THEN NULL
                   ELSE t.U_Entry
                 END,
               U_Reject =
                 CASE
                   WHEN t.U_Reject IS NULL THEN v.U_Reject
                   WHEN (t.U_Reject = '') and (@Trans_Type = 2) THEN v.U_Reject
                   WHEN t.U_Reject = '' THEN NULL
                   ELSE t.U_Reject
                 END,
               U_Warning =
                 CASE
                   WHEN t.U_Warning IS NULL THEN v.U_Warning
                   WHEN (t.U_Warning = '') and (@Trans_Type = 2) THEN v.U_Warning
                   WHEN t.U_Warning = '' THEN NULL
                   ELSE t.U_Warning
                 END,
               U_User =
              CASE
                   WHEN t.U_User IS NULL THEN v.U_User
                   WHEN (t.U_User = '') and (@Trans_Type = 2) THEN v.U_User
                   WHEN t.U_User = '' THEN NULL
                   ELSE t.U_User
                 END,
               Target =
                 CASE
                   WHEN t.Target IS NULL THEN v.Target
                   WHEN (t.Target = '') and (@Trans_Type = 2) THEN v.Target
                   WHEN t.Target = '' THEN NULL
                   ELSE t.Target
                 END,
               L_User =
                 CASE
                   WHEN t.L_User IS NULL THEN v.L_User
                   WHEN (t.L_User = '') and (@Trans_Type = 2) THEN v.L_User
                   WHEN t.L_User = '' THEN NULL
                   ELSE t.L_User
                 END,
               L_Warning =
                 CASE
                   WHEN t.L_Warning IS NULL THEN v.L_Warning
                   WHEN (t.L_Warning = '') and (@Trans_Type = 2) THEN v.L_Warning
                   WHEN t.L_Warning = '' THEN NULL
                   ELSE t.L_Warning
                 END,
              L_Reject =
                 CASE
                   WHEN t.L_Reject IS NULL THEN v.L_Reject
                   WHEN (t.L_Reject = '') and (@Trans_Type = 2) THEN v.L_Reject
                   WHEN t.L_Reject = '' THEN NULL
                   ELSE t.L_Reject
                 END,
               L_Entry =
                 CASE
                   WHEN t.L_Entry IS NULL THEN v.L_Entry
                   WHEN (t.L_Entry = '') and (@Trans_Type = 2) THEN v.L_Entry
                   WHEN t.L_Entry = '' THEN NULL
                   ELSE t.L_Entry
                 END,
               L_Control =
                 CASE
                   WHEN t.L_Control IS NULL THEN v.L_Control
                   WHEN (t.L_Control = '') and (@Trans_Type = 2) THEN v.L_Control
                   WHEN t.L_Control = '' THEN NULL
                   ELSE t.L_Control
                 END,
               T_Control =
                 CASE
                   WHEN t.T_Control IS NULL THEN v.T_Control
                   WHEN (t.T_Control = '') and (@Trans_Type = 2) THEN v.T_Control
                   WHEN t.T_Control = '' THEN NULL
                   ELSE t.T_Control
                 END,
               U_Control =
                 CASE
                   WHEN t.U_Control IS NULL THEN v.U_Control
                   WHEN (t.U_Control = '') and (@Trans_Type = 2) THEN v.U_Control
                   WHEN t.U_Control = '' THEN NULL
                   ELSE t.U_Control
                 END,
               Test_Freq =
                 CASE
                   WHEN t.Test_Freq IS NULL THEN v.Test_Freq
 	  	     	  	    WHEN (t.Test_Freq = -1) and (@Trans_Type = 2)  THEN v.Test_Freq
 	  	     	  	    WHEN t.Test_Freq = -1  THEN NULL
                   ELSE t.Test_Freq
                 END,
               Esignature_Level =
                 CASE
                   WHEN t.Esignature_Level IS NULL THEN v.Esignature_Level
 	  	     	  	    WHEN (t.Esignature_Level = -1) and (@Trans_Type = 2)  THEN v.Esignature_Level
 	  	     	  	    WHEN t.Esignature_Level = -1  THEN NULL
                   ELSE t.Esignature_Level
                 END,
               Comment_Id =
                 CASE
                   WHEN t.Comment_Id IS NULL THEN v.Comment_Id
 	  	     	  	    WHEN (t.Comment_Id = -1) and (@Trans_Type = 2)  THEN v.Comment_Id
 	  	     	  	    WHEN t.Comment_Id = -1  THEN NULL
                   ELSE t.Comment_Id
                 END,
 	 Is_Defined =  
 	   CASE
 	       When t.Is_Defined Is Null and t.Not_Defined is null Then v.Is_Defined
 	       When v.Is_Defined Is Null Then t.Is_Defined
          When  t.Not_Defined is Not Null and  t.Is_Defined  is not null  Then ((v.Is_defined + t.Is_Defined) -  (v.Is_defined & t.Is_Defined)) - t.Not_Defined
 	       When  t.Not_Defined is Not Null then v.Is_Defined - t.Not_Defined
                   Else (v.Is_defined + t.Is_Defined) -  (v.Is_defined & t.Is_Defined)
 	 End,
 	 v.Is_OverRidable,
 	 v.As_Id,
 	 t.U_Entry,t.U_Reject,t.U_Warning,t.U_User,t.Target,t.L_User,t.L_Warning,t.L_Reject,t.L_Entry,t.L_Control,t.T_Control,t.U_Control,
 	 T_F = Case When t.Test_Freq = -1  THEN NULL
 	  	    Else convert(nvarchar(25),t.Test_Freq)
 	  	   End,
 	 SIG = Case When t.Esignature_Level = -1  THEN NULL
 	  	    Else convert(nvarchar(25),t.Esignature_Level)
 	       End
          FROM Trans_Variables t
          LEFT OUTER JOIN Var_Specs v ON
            (v.Var_Id = t.Var_Id) AND
            (v.Prod_Id = t.Prod_Id) AND
            (v.Effective_Date <= @Effective_Date) AND
            ((v.Expiration_Date IS NULL) OR
             ((v.Expiration_Date IS NOT NULL) AND
              (v.Expiration_Date > @Effective_Date)))
          WHERE t.Trans_Id = @Trans_Id
    FOR READ ONLY
  OPEN Var_Spec_Cursor
  Next_Var_Spec1:
  FETCH NEXT FROM Var_Spec_Cursor
    INTO @Var_Id, @Prod_Id, @Force_Delete, @VS_Id, @Eff_Date, @Exp_Date,
         @U_Entry, @U_Reject, @U_Warning, @U_User, @Target,
         @L_User, @L_Warning, @L_Reject, @L_Entry,@L_Control,@T_Control,@U_Control,@Test_Freq,@Esignature_Level,@Comment_Id,@IsDefined,@Is_OverRidable ,@As_Id,
 	   	  @T_UE,@T_UR,@T_UW,@T_UU,@T_T,@T_LU,@T_LW,@T_LR,@T_LE,@T_LC,@T_TC,@T_UC,@T_TF,@T_SIG
  IF @@FETCH_STATUS = 0
    BEGIN
 	   IF @IsDefined = 0 SELECT @IsDefined = Null
      If @Trans_Type = 2
 	  	 Begin
 	  	   If @Is_OverRidable is null  	 Select @Is_OverRidable = 0
 	  	   Execute spEM_DoOverRideBitLogic 32768, @T_UC , @Is_OverRidable Output
 	  	   Execute spEM_DoOverRideBitLogic 16384, @T_TC , @Is_OverRidable Output
 	  	   Execute spEM_DoOverRideBitLogic 8192, @T_LC , @Is_OverRidable Output
 	  	   Execute spEM_DoOverRideBitLogic 1024, @T_SIG , @Is_OverRidable Output
 	  	   Execute spEM_DoOverRideBitLogic 512, @T_TF , @Is_OverRidable Output
 	  	   Execute spEM_DoOverRideBitLogic 256, @T_UE , @Is_OverRidable Output
 	  	   Execute spEM_DoOverRideBitLogic 128, @T_UR , @Is_OverRidable Output
 	  	   Execute spEM_DoOverRideBitLogic 64, @T_UW , @Is_OverRidable Output
 	  	   Execute spEM_DoOverRideBitLogic 32, @T_UU , @Is_OverRidable Output
 	  	   Execute spEM_DoOverRideBitLogic 16, @T_T , @Is_OverRidable Output
 	  	   Execute spEM_DoOverRideBitLogic 8, @T_LU , @Is_OverRidable Output
 	  	   Execute spEM_DoOverRideBitLogic 4, @T_LW , @Is_OverRidable Output
 	  	   Execute spEM_DoOverRideBitLogic 2, @T_LR , @Is_OverRidable Output
 	  	   Execute spEM_DoOverRideBitLogic 1, @T_LE , @Is_OverRidable Output
 	   	   If  @Is_OverRidable = 0 Select  @Is_OverRidable = Null
 	  	 End
      INSERT INTO #New_Var_Specs(VS_Id, Var_Id, Prod_Id, Effective_Date,
          Expiration_Date, Force_Delete, L_Entry, L_Reject, L_Warning, L_User,
          Target, U_User, U_Warning, U_Reject, U_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Comment_Id,Is_Defined,Is_OverRidable,As_Id)
        VALUES(@VS_Id, @Var_Id, @Prod_Id, @Eff_Date, @Exp_Date,
          @Force_Delete, @L_Entry, @L_Reject, @L_Warning, @L_User, @Target,
          @U_User, @U_Warning, @U_Reject,@U_Entry, @L_Control,@T_Control,@U_Control, @Test_Freq,@Esignature_Level, @Comment_Id,@IsDefined,@Is_OverRidable,@As_Id)
      GOTO Next_Var_Spec1
    END
  ELSE IF @@FETCH_STATUS <> -1
    BEGIN
      RAISERROR('Fetch error for Var_Spec_Cursor1 (@@FETCH_STATUS = %d).',
                11, -1, @@FETCH_STATUS)
      Close Var_Spec_Cursor
      DEALLOCATE Var_Spec_Cursor
      DROP TABLE #New_Var_Specs
      Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode =7 where Audit_Trail_Id = @InsertId
      RETURN(7)
    END
  Close Var_Spec_Cursor
  DEALLOCATE Var_Spec_Cursor
--
  -- Begin a transaction.
  --
  Create Table #Overides (VS_Id int,Is_Defined Int)
  BEGIN TRANSACTION
  --
  -- Update the transaction record.
  --
  UPDATE Transactions
    SET Approved_By = @User_Id,
        Approved_On = @Approved_On,
        Effective_Date = @Effective_Date,
        Transaction_Grp_Id = @Group_Id
    WHERE Trans_Id = @Trans_Id
   --
  -- Process new active specifications.
  --
  EXEC('DECLARE Active_Spec_Cursor CURSOR Global ' +
    'FOR SELECT AS_Id, Char_Id, Spec_Id, Effective_Date, Expiration_Date,' +
               'Force_Delete, L_Entry, L_Reject, L_Warning, L_User, Target,' +
               'U_User, U_Warning, U_Reject, U_Entry,L_Control,T_Control,U_Control, Test_Freq,Esignature_Level,Comment_Id,Is_Defined  ' +
          'FROM #New_Active_Specs '+
    'FOR UPDATE')
  OPEN Active_Spec_Cursor
  Next_Active_Spec2:
  FETCH NEXT FROM Active_Spec_Cursor
    INTO @AS_Id, @Char_Id, @Spec_Id, @Eff_Date, @Exp_Date,
         @Force_Delete, @L_Entry, @L_Reject, @L_Warning, @L_User, @Target,
         @U_User, @U_Warning, @U_Reject, @U_Entry,@L_Control,@T_Control,@U_Control,@Test_Freq,@Esignature_Level, @Comment_Id,@IsDefined
  IF @@FETCH_STATUS = 0
    BEGIN
      --
      -- If an existing specification has the same effective date as our       
      -- transaction, delete it.  Otherwise, expire is upon the transaction's
      -- effective date.
      --
      IF @AS_Id IS NOT NULL
        BEGIN
          IF @Eff_Date = @Effective_Date
            --
            -- The existing record's effective date is the same as the
            -- transaction's. Delete the existing record in the active specs table.
            --
            BEGIN
              DELETE FROM Var_Specs WHERE AS_Id = @AS_Id
              DELETE FROM Active_Specs WHERE AS_Id = @AS_Id
            END
          ELSE
            --
            -- The existing record's effective date is prior to the transaction's.
            -- Update the existing record and its associated variable specifications
            -- in the active specs table.
            --
            BEGIN
 	    	  	   Insert into #Overides(vs_Id,Is_Defined) 
 	  	  	  	 Select VS_Id,Is_Defined
 	  	  	  	 From Var_Specs WHERE AS_Id = @AS_Id  and (Expiration_Date is null or Expiration_Date > @Effective_Date) and Is_Defined > 0
              UPDATE Var_Specs SET Expiration_Date = @Effective_Date
                WHERE AS_Id = @AS_Id  and (Expiration_Date is null or Expiration_Date > @Effective_Date)
              UPDATE Active_Specs SET Expiration_Date = @Effective_Date
                WHERE AS_Id = @AS_Id
            END
        END
      -- Add the new active specification to the active specifications table.
      -- Determine the identity of the newly inserted active specification.
      --
      -- 09/18/98 set expiration date if needed
      -- 
      IF @Exp_Date IS NULL
        SELECT @Exp_Date  = (SELECT  min(effective_date) FROM active_specs
         WHERE spec_id = @Spec_Id and char_id = @Char_Id and effective_date > @Effective_Date)
      --
      -- Add the new active specification to the active specifications table.
      -- Determine the identity of the newly inserted active specification.
      --
If @Force_Delete = 0 /* If force_delete = 1 we only expire(above) and do not re-add */
  Begin
      EXECUTE spEM_ApproveTrans_Slave1 @Char_Id, @Spec_Id, @Effective_Date,
        @Exp_Date, @L_Entry, @L_Reject, @L_Warning, @L_User, @Target, @U_User,
        @U_Warning, @U_Reject, @U_Entry,@L_Control,@T_Control,@U_Control, @Test_Freq,@Esignature_Level, @Comment_Id,@IsDefined, @AS_Id OUTPUT
      IF @AS_Id IS NULL
        BEGIN
          RAISERROR('Failed to insert into table Active_Specs.', 11, -1)
          Close Active_Spec_Cursor
          DEALLOCATE Active_Spec_Cursor
          DROP TABLE #New_Active_Specs
          ROLLBACK TRANSACTION
  	 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 4 where Audit_Trail_Id = @InsertId
         RETURN(4)
        END
      --
      -- Declare and open a cursor for the old variable specification associated
      -- with newly inserted active specifications whose effective periods overlap.
      --
      -- EU: Needed Join On Prod_Units For Child Unit Variables
      --
 	 Delete From #PV
 	 Insert Into #Pv (Prod_Id,Var_Id)
 	 Select Prod_Id,Var_Id
 	   From PU_Characteristics puc
          JOIN Prod_Units pu on pu.Pu_Id = puc.Pu_Id or pu.Master_Unit = puc.PU_Id 
          JOIN Variables v ON (v.Spec_Id = @Spec_Id) AND (v.PU_Id = pu.PU_Id)
 	   Where puc.Char_Id = @Char_Id
      DECLARE Old_Spec_Cursor CURSOR
        FOR   SELECT vs.VS_Id, vs.Effective_Date, vs.Expiration_Date
              FROM Var_Specs vs 
 	       Join  #PV on  vs.Var_Id = #Pv.Var_Id and  vs.Prod_Id = #Pv.Prod_Id
 	       Where  NOT (((vs.Expiration_Date IS NOT NULL) AND(vs.Expiration_Date <= @Effective_Date)) OR
                                        ((@Exp_Date IS NOT NULL) AND (vs.Effective_Date > @Exp_Date)))
        FOR UPDATE
      OPEN Old_Spec_Cursor
      --
      -- Process old variable specifications.
      --
      Next_Old_Spec:
      FETCH NEXT FROM Old_Spec_Cursor INTO @VS_Id, @Old_Eff_Date, @Old_Exp_Date
      IF @@FETCH_STATUS = 0
        BEGIN
          --
          -- If the effective date of the old variable specification is before
          -- the effective date of the new active specification, expire the old
          -- variable specification as of the effective date of the new active
          -- specification. Otherwise, delete the old variable specification.
          --
          IF (@Old_Eff_Date >= @Effective_Date) AND
             (@Old_Exp_Date <= @Exp_Date)
            DELETE FROM Var_Specs WHERE CURRENT OF Old_Spec_Cursor
          ELSE IF (@Old_Eff_Date < @Effective_Date) AND
                  (@Old_Exp_Date > @Exp_Date)
            BEGIN
              UPDATE Var_Specs
                SET Expiration_Date = @Effective_Date
                WHERE CURRENT OF Old_Spec_Cursor
                INSERT INTO Var_Specs(Prod_Id, Var_Id, Effective_Date, Expiration_Date,
                                    L_Entry, L_Reject, L_Warning, L_User, Target,
                                    U_User, U_Warning, U_Reject, U_Entry, L_Control,T_Control,U_Control,Test_Freq,Esignature_Level, Comment_Id)
                SELECT Prod_Id, Var_Id, @Exp_Date, Expiration_Date,
                       L_Entry, L_Reject, L_Warning, L_User, Target,
                       U_User, U_Warning, U_Reject, U_Entry, L_Control,T_Control,U_Control,Test_Freq ,Esignature_Level, Comment_Id
                FROM Var_Specs WHERE VS_Id = @VS_Id
            END
          ELSE IF @Old_Eff_Date < @Effective_Date
            UPDATE Var_Specs
              SET Expiration_Date = @Effective_Date
              WHERE CURRENT OF Old_Spec_Cursor
          ELSE IF @Old_Exp_Date > @Exp_Date
            UPDATE Var_Specs
              SET Effective_Date = @Exp_Date
              WHERE CURRENT OF Old_Spec_Cursor
          --
          -- Process the next old variable specification.
          --
          GOTO Next_Old_Spec
        END
      ELSE IF @@FETCH_STATUS <> -1
        BEGIN
          RAISERROR('Fetch error for Old_Spec_Cursor (@@FETCH_STATUS = %d).',
                    11, -1, @@FETCH_STATUS)
          Close Old_Spec_Cursor
          DEALLOCATE Old_Spec_Cursor
          Close New_Spec_Cursor
          DEALLOCATE New_Spec_Cursor
          ROLLBACK TRANSACTION
         Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 5 where Audit_Trail_Id = @InsertId
         RETURN(5)
        END
      --
      -- Deallocate the old variable specification cursor.
      --
      Close Old_Spec_Cursor
      DEALLOCATE Old_Spec_Cursor
      --
      -- Insert variable specifications for associated with this active
      -- specification.
      --
      -- EU: Needed Join On Prod_Units For Child Unit Variables
      --
 	 If (@L_Entry is not null) or (@L_Reject is not null) or  (@L_Warning is not null) or  (@L_User is not null) or  (@Target is not null) or 
 	  	  (@U_User is not null) or (@U_Warning is not null) or (@U_Reject is not null) or (@U_Entry is not null) or (@L_Control is not null) or 
 	  	  (@T_Control is not null) or (@U_Control is not null) or (@Test_Freq is not null) or (@Comment_Id is not null) or (@Esignature_Level is not null)
      INSERT INTO Var_Specs(Prod_Id, Var_Id, Effective_Date, Expiration_Date, AS_Id,
                            L_Entry, L_Reject, L_Warning, L_User, Target, U_User,
                            U_Warning, U_Reject, U_Entry,L_Control,T_Control,U_Control, Test_Freq,Esignature_Level, Comment_Id)
        SELECT uc.Prod_Id, var.Var_Id, @Effective_Date, @Exp_Date, @AS_Id,
               @L_Entry, @L_Reject, @L_Warning, @L_User, @Target, @U_User,
               @U_Warning, @U_Reject, @U_Entry, @L_Control,@T_Control,@U_Control,@Test_Freq,@Esignature_Level, @Comment_Id
          FROM Variables var
          JOIN Prod_Units u ON (var.PU_Id = u.PU_Id)
          JOIN PU_Characteristics uc ON (uc.PU_Id = CASE WHEN u.Master_Unit IS NULL THEN u.PU_Id ELSE u.Master_Unit END) AND (uc.Char_Id = @Char_Id)
          WHERE var.Spec_Id = @Spec_Id
      --
      -- Process the next active specification.
      --
End 
     GOTO Next_Active_Spec2
    END
  ELSE IF @@FETCH_STATUS <> -1
    --
    -- We have encountered an fetch error on the variable specification cursor.
    --
    BEGIN
      RAISERROR('Fetch error for Active_Spec_Cursor2 (@@FETCH_STATUS = %d).',
                11, -1, @@FETCH_STATUS)
      Close Active_Spec_Cursor
      DEALLOCATE Active_Spec_Cursor
      DROP TABLE #New_Active_Specs
      ROLLBACK TRANSACTION
      Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @InsertId
      RETURN(2)
    END
 Close   Active_Spec_Cursor
 DEALLOCATE Active_Spec_Cursor
 If (Select Count(*) From #Overides) > 0 --replace overides
   Begin
 	 Declare Or_Cursor  Cursor For 
 	  Select Vs_Id,Is_Defined 
 	   From #Overides
 	 Open Or_Cursor
Or_Cursor_Loop:
 	 Fetch Next from Or_Cursor Into @VS_Id,@Is_Defined
 	 If @@Fetch_Status = 0
 	   Begin
 	     Select  @Var_Id = Var_Id,@Prod_Id = Prod_Id,@L_User  = L_User,@L_Entry = L_Entry, @L_Reject = L_Reject,@L_Warning = L_Warning, @Target = Target, @U_User  = U_User,
 	  	  	    @U_Warning = U_Warning,@U_Reject = U_Reject, @U_Entry = U_Entry, @L_Control = L_Control,@Esignature_Level = Esignature_Level,
 	  	   	    @T_Control = T_Control,@U_Control = U_Control,@Test_Freq = Test_Freq,@ExpDate = Expiration_Date
 	  	  	 From Var_Specs Where vs_Id = @VS_Id
 	  	 Select @New_VsId = Vs_Id From Var_Specs where Var_Id = @Var_Id and Prod_Id = @Prod_Id and Effective_Date = @ExpDate
 	  	 If  @Is_Defined & 1 = 1
 	  	  	 Update Var_Specs Set L_Entry = @L_Entry,Is_Defined = @Is_Defined  Where vs_Id = @New_VsId
 	  	 If  @Is_Defined & 2 = 2
 	  	  	 Update Var_Specs Set L_Reject = @L_Reject,Is_Defined = @Is_Defined   Where vs_Id = @New_VsId
 	  	 If  @Is_Defined & 4 = 4
 	  	  	 Update Var_Specs Set L_Warning = @L_Warning,Is_Defined = @Is_Defined   Where vs_Id = @New_VsId
 	  	 If  @Is_Defined & 8 = 8
 	  	  	 Update Var_Specs Set L_User = @L_User,Is_Defined = @Is_Defined   Where vs_Id = @New_VsId
 	  	 If  @Is_Defined & 16 = 16
 	  	  	 Update Var_Specs Set Target = @Target,Is_Defined = @Is_Defined   Where vs_Id = @New_VsId
 	  	 If  @Is_Defined & 32 = 32
 	  	  	 Update Var_Specs Set U_User = @U_User,Is_Defined = @Is_Defined   Where vs_Id = @New_VsId
 	  	 If  @Is_Defined & 64 = 64
 	  	  	 Update Var_Specs Set U_Warning = @U_Warning,Is_Defined = @Is_Defined   Where vs_Id = @New_VsId
 	  	 If  @Is_Defined & 128 = 128
 	  	  	 Update Var_Specs Set U_Reject = @U_Reject,Is_Defined = @Is_Defined   Where vs_Id = @New_VsId
 	  	 If  @Is_Defined & 256 = 256
 	  	  	 Update Var_Specs Set U_Entry = @U_Entry,Is_Defined = @Is_Defined   Where vs_Id = @New_VsId
 	  	 If  @Is_Defined & 512 = 512
 	  	  	 Update Var_Specs Set Test_Freq = @Test_Freq,Is_Defined = @Is_Defined   Where vs_Id = @New_VsId
 	  	 If  @Is_Defined & 1024 = 1024
 	  	  	 Update Var_Specs Set Esignature_Level = @Esignature_Level,Is_Defined = @Is_Defined   Where vs_Id = @New_VsId
 	  	 If  @Is_Defined & 8192 = 8192
 	  	  	 Update Var_Specs Set L_Control = @L_Control,Is_Defined = @Is_Defined   Where vs_Id = @New_VsId
 	  	 If  @Is_Defined & 16384 = 16384
 	  	  	 Update Var_Specs Set T_Control = @T_Control,Is_Defined = @Is_Defined   Where vs_Id = @New_VsId
 	  	 If  @Is_Defined & 32768 = 32768
 	  	  	 Update Var_Specs Set U_Control = @U_Control,Is_Defined = @Is_Defined   Where vs_Id = @New_VsId
  	  	 Goto Or_Cursor_Loop 
 	   End
 	 Close Or_Cursor
 	 Deallocate Or_Cursor
   End
 Drop Table #Overides
  --
  -- Drop the temporary active specifications table.
  --
  DROP TABLE #New_Active_Specs
  --
  -- Create a temporary table for variable specifications.
  --
  --
  -- Process new variable specifications.
  --
 	 
  EXEC ('DECLARE Var_Spec_Cursor CURSOR Global ' +
    'FOR SELECT VS_Id, Var_Id, Prod_Id, Effective_Date, Expiration_Date, Force_Delete ' +
          'FROM #New_Var_Specs ' +
    'FOR UPDATE')
  OPEN Var_Spec_Cursor
  Next_Var_Spec2:
  FETCH NEXT FROM Var_Spec_Cursor
    INTO @VS_Id, @Var_Id, @Prod_Id, @Eff_Date, @Exp_Date, @Force_Delete
  IF @@FETCH_STATUS = 0
    BEGIN
      --
      -- If an existing specification has the same effective date as our       
      -- transaction, delete it.  Otherwise, expire is upon the transaction's
      -- effective date.
      --
      IF @VS_Id IS NOT NULL
        BEGIN
          IF @Eff_Date = @Effective_Date
            DELETE FROM Var_Specs WHERE VS_Id = @VS_Id
          ELSE
            UPDATE Var_Specs
              SET Expiration_Date = @Effective_Date
              WHERE VS_Id = @VS_Id
        END
      --
      -- If forced deletion of future specifications is indicated, clear the
      -- expiration date of the new variable specification and delete any
      -- pending variable specifications. If forced deletion of future
      -- specifications is not indicated, update the expiration data of any
      -- new open ended specification for which there are pending specifications
      -- with a greater effective date.
      --
      IF (@Exp_Date IS NULL)
        BEGIN
 	   SELECT @Exp_Date = MIN(Effective_Date)
            FROM Var_Specs
            WHERE (Var_Id = @Var_Id) AND
                  (Prod_Id = @Prod_Id) AND
                  (Effective_Date > @Effective_Date)
          IF @Exp_Date IS NOT NULL
            UPDATE #New_Var_Specs
              SET Expiration_Date = @Exp_Date
              WHERE CURRENT OF Var_Spec_Cursor
        END
        --
      -- Process the next variable specification.
      --
      GOTO Next_Var_Spec2
    END
  ELSE IF @@FETCH_STATUS <> -1
    --
    -- We have encountered an fetch error on the variable specification cursor.
    --
    BEGIN
      RAISERROR('Fetch error for Var_Spec_Cursor2 (@@FETCH_STATUS = %d).',
                11, -1, @@FETCH_STATUS)
      Close Var_Spec_Cursor
      DEALLOCATE Var_Spec_Cursor
      DROP TABLE #New_Var_Specs
      ROLLBACK TRANSACTION
      Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @InsertId
      RETURN(1)
    END
  Close Var_Spec_Cursor
  DEALLOCATE Var_Spec_Cursor
  --
  -- Add new variable specifications to the variable specifications table.
  --
Delete From  #New_Var_Specs Where (L_Entry is null) and (L_Reject is null) and  (L_Warning is null) and  (L_User is null) and  (Target is null) and 
 	  	  (U_User is null) and (U_Warning is null) and (U_Reject is null) and (U_Entry is null) and (L_Control is null) and 
 	  	  (T_Control is null) and (U_Control is null) and (Test_Freq is null) and (Comment_Id is null) and (Esignature_Level is null) and (@IsDefined is Null or @IsDefined = 0)
  INSERT INTO Var_Specs(Var_Id,
                        Prod_Id,
                        Effective_Date,
                        Expiration_Date,
                        AS_Id,
                        L_Entry,
                        L_Reject,
                        L_Warning,
                        L_User,
                        Target,
                        U_User,
                        U_Warning,
                        U_Reject,
                        U_Entry,
 	  	  	  	  	  	 L_Control,
 	  	  	  	  	  	 T_Control,
 	  	  	  	  	  	 U_Control,
                        Test_Freq,
 	  	  	  	  	  	 Esignature_Level,
 	  	  	  	  	  	  Comment_Id,
 	            Is_Defined,
 	            Is_OverRidable)
    SELECT Var_Id,
           Prod_Id, 
           @Effective_Date,
           Expiration_Date, 
           As_Id,
           L_Entry,
           L_Reject,
           L_Warning,
           L_User,
           Target,
           U_User,
           U_Warning,
           U_Reject,
           U_Entry,
 	  	    L_Control,
 	  	    T_Control,
 	  	    U_Control,
           Test_Freq,
 	  	    Esignature_Level,
           Comment_Id,
           Is_Defined,
           Is_OverRidable
      FROM #New_Var_Specs
If @AttemptBackdate = 1
  Begin
 	 Update Var_specs  Set Effective_Date = @BackDate_Eff 
   	 Where Effective_Date = @Effective_Date and Expiration_Date is Null
    	 and ((Select Count(*) From Var_specs v Where v.Var_Id = Var_Specs.Var_Id and v.prod_Id = Var_Specs.Prod_Id) = 1)
 	 Update Active_Specs  Set Effective_Date = @BackDate_Eff 
 	    	 Where Effective_Date = @Effective_Date and Expiration_Date is Null
    	  	 and ((Select Count(*) From Active_Specs a Where a.Spec_Id = Active_Specs.Spec_Id and a.Char_Id = Active_Specs.Char_Id) = 1)
  End
   COMMIT TRANSACTION
 --
  -- Drop the temporary new variable specifications table.
  --
  DROP TABLE #New_Var_Specs
  --
  -- Commit our transaction and return success.
  --
  SELECT @Approved_Date = @Approved_On
 If @Anti_Trans_Id Is Not Null 
 	  Execute @ReturnCode = SpEM_ApproveTrans  @Anti_Trans_Id,1,1, null, @Approved_Date,@Deviation_Date
 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters =  convert(nvarchar(15),@Effective_Date) + ',' + convert(nvarchar(15),  @Approved_Date)
     where Audit_Trail_Id = @InsertId
 RETURN(0)
