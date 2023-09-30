CREATE PROCEDURE dbo.spEM_PutTransVarValues
  @Trans_Id  int,
  @Var_Id    int,
  @Prod_Id   int,
  @L_Entry   nvarchar(25),
  @L_Reject  nvarchar(25),
  @L_Warning nvarchar(25),
  @L_User    nvarchar(25),
  @Target    nvarchar(25),
  @U_User    nvarchar(25),
  @U_Warning nvarchar(25),
  @U_Reject  nvarchar(25),
  @U_Entry   nvarchar(25),
  @L_Control   nvarchar(25),
  @T_Control   nvarchar(25),
  @U_Control   nvarchar(25),
  @Test_Freq int,
  @Sig 	  	  Int,
  @Comm_Id   int,
  @RemoveOveride int,
  @User_Id int
  AS
  DECLARE @IsDefined Integer
  --
  -- Declare local variables.
  --
  DECLARE @Id int
  --
  -- Try to find a matching transaction variable.
  --
  SELECT @Id = Trans_Id FROM Trans_Variables
    WHERE (Trans_Id = @Trans_Id) AND (Var_Id = @Var_Id) AND (Prod_Id = @Prod_Id)
Select @IsDefined = null
IF (Select Spec_Id from Variables where var_Id = @Var_Id) is not Null 
   Begin
 	 Select @IsDefined = 0
 	  IF @L_Entry is Not Null   
 	     Select @IsDefined = @IsDefined + 1
 	  IF @L_Reject is Not Null 
 	      Select @IsDefined = @IsDefined + 2
 	  IF @L_Warning is Not Null 
 	      Select @IsDefined = @IsDefined + 4
 	  IF @L_User is Not Null 
 	      Select @IsDefined = @IsDefined + 8
 	  IF @Target is Not Null 
 	      Select @IsDefined = @IsDefined + 16
 	  IF @U_User is Not Null 
 	      Select @IsDefined = @IsDefined + 32
 	  IF @U_Warning is Not Null 
 	      Select @IsDefined = @IsDefined + 64
 	  IF @U_Reject is Not Null 
 	     Select @IsDefined = @IsDefined + 128
 	  IF @U_Entry is Not Null 
 	      Select @IsDefined = @IsDefined + 256
 	 IF @Test_Freq is Not Null 
 	      Select @IsDefined = @IsDefined + 512
 	 IF @Sig is Not Null 
 	      Select @IsDefined = @IsDefined + 1024
 	 If @L_Control is not Null 
 	  	 Select @IsDefined = @IsDefined + 8192
 	 If @T_Control is not Null 
 	  	 Select @IsDefined = @IsDefined + 16384
 	 If @U_Control is not Null 
 	  	 Select @IsDefined = @IsDefined + 32768
   End
  --
  -- If a matching transaction variable was found, update it. Otherwise,
  -- insert a new transaction variable. In the special case where all the
  -- limits are null, delete any transaction variable we find.
  --
  IF (@L_Entry IS NULL) AND
     (@L_Reject IS NULL) AND
     (@L_Warning IS NULL) AND
     (@L_User IS NULL) AND
     (@Target IS NULL) AND
     (@U_User IS NULL) AND
     (@U_Warning IS NULL) AND
     (@U_Reject IS NULL) AND
     (@U_Entry IS NULL) AND
     (@Test_Freq IS NULL) AND
     (@Sig IS NULL) AND
     (@Comm_Id IS NULL) And
    (@RemoveOveride Is Null) And
 	 (@L_Control Is Null) And
 	 (@T_Control Is Null) And
 	 (@U_Control Is Null)
    BEGIN
      IF @Id IS NOT NULL
        DELETE FROM Trans_Variables
          WHERE (Trans_Id = @Trans_Id) AND (Var_Id = @Var_Id) AND (Prod_Id = @Prod_Id)
    END
  ELSE IF @Id IS NULL 
    INSERT INTO Trans_Variables(Trans_Id, Var_Id, Prod_Id, Target, L_Entry, L_Reject,
      L_Warning, L_User, U_User, U_Warning, U_Reject, U_Entry,L_Control,T_Control,U_Control,Test_Freq,Esignature_Level,Comment_Id,Is_Defined,Not_Defined)
    VALUES(@Trans_Id, @Var_Id, @Prod_Id, @Target, @L_Entry, @L_Reject,
      @L_Warning, @L_User, @U_User, @U_Warning, @U_Reject, @U_Entry, @L_Control,@T_Control,@U_Control,@Test_Freq,@Sig, @Comm_Id,@IsDefined,@RemoveOveride)
  ELSE
    UPDATE Trans_Variables
      SET L_Entry    = @L_Entry,
          L_Reject   = @L_Reject,
          L_Warning  = @L_Warning,
          L_User     = @L_User,
          Target     = @Target,
          U_User     = @U_User,
          U_Warning  = @U_Warning,
          U_Reject   = @U_Reject,
          U_Entry    = @U_Entry,
          Test_Freq  = @Test_Freq,
 	  	   Esignature_Level = @Sig,
          Comment_Id = @Comm_Id,
          Is_Defined = @IsDefined,
          Not_Defined = @RemoveOveride,
 	  	   L_Control = @L_Control,
 	  	   T_Control = @T_Control,
 	  	   U_Control = @U_Control
      WHERE (Trans_Id = @Trans_Id) AND (Var_Id = @Var_Id) AND (Prod_Id = @Prod_Id)
