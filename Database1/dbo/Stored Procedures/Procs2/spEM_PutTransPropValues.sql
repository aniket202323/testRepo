CREATE PROCEDURE dbo.spEM_PutTransPropValues
  @Trans_Id  int,
  @Spec_Id   int,
  @Char_Id   int,
  @L_Entry   nvarchar(25),
  @L_Reject  nvarchar(25),
  @L_Warning nvarchar(25),
  @L_User    nvarchar(25),
  @Target    nvarchar(25),
  @U_User    nvarchar(25),
  @U_Warning nvarchar(25),
  @U_Reject  nvarchar(25),
  @U_Entry   nvarchar(25),
  @L_Control nvarchar(25),
  @T_Control nvarchar(25),
  @U_Control nvarchar(25),
  @Test_Freq int,
  @Sig 	  	  int,
  @Comment_Id int,
  @RemoveOveride int,
  @User_Id int,
  @IsDelete 	  	 Int = 0
  AS
  --
  -- Declare local variables.
  --
  DECLARE @Id 	  	  	 int,
 	       @IsDefined 	  	 int
Select @IsDelete = Coalesce(@IsDelete,0)
-- Calculate Limit
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
 IF @Sig is Not null  
       Select @IsDefined = @IsDefined + 1024
 IF @L_Control is Not Null 
       Select @IsDefined = @IsDefined + 8192
 IF @T_Control is Not Null 
       Select @IsDefined = @IsDefined + 16384
 IF @U_Control is Not Null 
       Select @IsDefined = @IsDefined + 32768
If @IsDefined & @RemoveOveride > 0
 	 Select @IsDefined = @IsDefined - (@IsDefined & @RemoveOveride)
  --
  -- Try to find a matching transaction property.
  --
  SELECT @Id = Trans_Id FROM Trans_Properties
    WHERE (Trans_Id = @Trans_Id) AND (Spec_Id = @Spec_Id) AND (Char_Id = @Char_Id)
  --
  -- If a matching transaction property was found, update it. Otherwise,
  -- insert a new transaction property. In the special case where all the
  -- limits are null, delete any transaction property we find.
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
     (@L_Control IS NULL) AND
     (@T_Control IS NULL) AND
     (@U_Control IS NULL) AND
     (@Test_Freq IS NULL) AND
 	  (@Sig Is Null) And
     (@Comment_Id IS NULL) And
     (@RemoveOveride IS Null)And
 	  	  (@IsDelete = 0)
    BEGIN
      IF @Id IS NOT NULL
        DELETE FROM Trans_Properties
          WHERE (Trans_Id = @Trans_Id) AND (Spec_Id = @Spec_Id) AND (Char_Id = @Char_Id)
    END
  ELSE IF @Id IS NULL 
    INSERT INTO Trans_Properties(Trans_Id, Spec_Id, Char_Id, Target, L_Entry, L_Reject,
      L_Warning, L_User, U_User, U_Warning, U_Reject, U_Entry,L_Control,T_Control,U_Control, Test_Freq,Esignature_Level,Comment_Id,Is_Defined,Not_Defined,Force_Delete)
    VALUES(@Trans_Id, @Spec_Id, @Char_Id, @Target, @L_Entry, @L_Reject,
      @L_Warning, @L_User, @U_User, @U_Warning, @U_Reject, @U_Entry,@L_Control,@T_Control,@U_Control, @Test_Freq,@Sig,@Comment_Id,@IsDefined,@RemoveOveride,@IsDelete)
  ELSE
    UPDATE Trans_Properties
      SET L_Entry    = @L_Entry,
          L_Reject   = @L_Reject,
          L_Warning  = @L_Warning,
          L_User     = @L_User,
          Target     = @Target,
          U_User     = @U_User,
          U_Warning  = @U_Warning,
          U_Reject   = @U_Reject,
          U_Entry    = @U_Entry,
          L_Control  = @L_Control,
          T_Control  = @T_Control,
          U_Control  = @U_Control,
          Test_Freq  = @Test_Freq,
 	  	   Esignature_Level = @Sig,
          Comment_Id = @Comment_Id,
           Is_Defined = @IsDefined,
           Not_Defined = @RemoveOveride,
 	  	    Force_Delete = @IsDelete
      WHERE (Trans_Id = @Trans_Id) AND (Spec_Id = @Spec_Id) AND (Char_Id = @Char_Id)
  --
  -- Return success.
  --
  RETURN(0)
