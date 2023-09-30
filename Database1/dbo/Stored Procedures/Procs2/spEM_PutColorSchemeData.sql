CREATE PROCEDURE dbo.spEM_PutColorSchemeData
  @CS_Id               int,
  @Color               int,
  @Field               int,
  @User_Id int
  AS
  DECLARE @Insert_Id integer,
 	   @Exists    Integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutColorSchemeData',
                Convert(nVarChar(10),@CS_Id) + ','  + 
                Convert(nVarChar(10),@Color) + ','  + 
                Convert(nVarChar(10),@Field) + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Update existing color scheme.
  --
Select @Exists = Null
Select @Exists = CS_Id
  From Color_Scheme_Data 
  Where CS_Id = @CS_Id and  Color_Scheme_Field_Id = @Field
If @Exists Is Null
  Insert Into Color_Scheme_Data(CS_Id,Color_Scheme_Field_Id,Color_Scheme_Value)
   Values(@CS_Id,@Field,@Color)
Else
  Update Color_Scheme_Data Set Color_Scheme_Value = @Color
   Where  CS_Id = @CS_Id and  Color_Scheme_Field_Id = @Field
If @Field < 19
    Begin
 	 If @Field = 1
 	   UPDATE Color_Scheme Set Header_FG           = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 2
 	   UPDATE Color_Scheme Set No_Data_FG          = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 3
 	   UPDATE Color_Scheme Set No_Specification_FG = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 4
 	   UPDATE Color_Scheme Set Target_FG           = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 5
 	   UPDATE Color_Scheme Set User_FG             = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 6
 	   UPDATE Color_Scheme Set Warning_FG          = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 7
 	   UPDATE Color_Scheme Set Reject_FG           = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 8
 	   UPDATE Color_Scheme Set Entry_FG            = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 9
 	   UPDATE Color_Scheme Set Inactive_Area_BG    = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 10
 	   UPDATE Color_Scheme Set Row_Header_BG       = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 11
 	   UPDATE Color_Scheme Set Column_Header_BG    = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 12
 	   UPDATE Color_Scheme Set Read_Only_BG        = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 13
 	   UPDATE Color_Scheme Set Unavailable_BG      = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 14
 	   UPDATE Color_Scheme Set Available_BG        = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 15
 	   UPDATE Color_Scheme Set Ready_BG            = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 16
 	   UPDATE Color_Scheme Set Canceled_BG         = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 17
 	   UPDATE Color_Scheme Set Grid_Lines  	       = @Color    WHERE CS_Id = @CS_Id
 	 Else If @Field = 18
 	   UPDATE Color_Scheme Set Gray_Area           = @Color    WHERE CS_Id = @CS_Id
  End
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
