Create Procedure dbo.spEM_CreateColorScheme
  @CS_Desc nvarchar(50),
  @User_Id int,
  @CS_Id   int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create color scheme.
  --   2 = Can't find default color scheme.
  --
  DECLARE @Return_Code int, @Default_CS_Id int
   DECLARE @Grid_Lines          int,
          @Gray_Area           int,
          @Inactive_Area_BG    int,
          @Row_Header_BG       int,
          @Column_Header_BG    int,
          @Read_Only_BG        int,
          @Unavailable_BG      int,
          @Available_BG        int,
          @Ready_BG            int,
          @Canceled_BG         int,
          @Header_FG           int,
          @No_Data_FG          int,
          @No_Specification_FG int,
          @Target_FG           int,
          @User_FG             int,
          @Warning_FG          int,
          @Reject_FG           int,
          @Entry_FG            int
 DECLARE @Insert_Id integer 
  Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateColorScheme',
                 @CS_Desc + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
 	 SELECT @Insert_Id = Scope_Identity()
 	 SELECT @Header_FG           = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 1
 	 SELECT @No_Data_FG          = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 2
 	 SELECT @No_Specification_FG = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 3
 	 SELECT @Target_FG           = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 4
 	 SELECT @User_FG             = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 5
 	 SELECT @Warning_FG          = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 6
 	 SELECT @Reject_FG           = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 7
 	 SELECT @Entry_FG            = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 8
 	 SELECT @Inactive_Area_BG    = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 9
 	 SELECT @Row_Header_BG       = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 10
 	 SELECT @Column_Header_BG    = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 11
 	 SELECT @Read_Only_BG        = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 12
 	 SELECT @Unavailable_BG      = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 13
 	 SELECT @Available_BG        = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 14
 	 SELECT @Ready_BG            = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 15
 	 SELECT @Canceled_BG         = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 16
 	 SELECT @Grid_Lines 	  	  	 = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 17
 	 SELECT @Gray_Area           = Default_Color_Scheme_Color FROM Color_Scheme_fields WHERE Color_Scheme_Field_id = 18
  INSERT INTO Color_Scheme(CS_Desc, Grid_Lines, Gray_Area, Inactive_Area_BG, Row_Header_BG,
                           Column_Header_BG, Read_Only_BG, Unavailable_BG, Available_BG, Ready_BG,
                           Canceled_BG, Header_FG, No_Data_FG, No_Specification_FG, Target_FG,
                           User_FG, Warning_FG, Reject_FG, Entry_FG)
    VALUES(@CS_Desc, @Grid_Lines, @Gray_Area, @Inactive_Area_BG, @Row_Header_BG,
           @Column_Header_BG, @Read_Only_BG, @Unavailable_BG, @Available_BG, @Ready_BG,
           @Canceled_BG, @Header_FG, @No_Data_FG, @No_Specification_FG, @Target_FG,
           @User_FG, @Warning_FG, @Reject_FG, @Entry_FG)
 SELECT @CS_Id = Scope_Identity()
 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = @Return_Code,Output_Parameters = convert(nVarChar(10),@CS_Id) where Audit_Trail_Id = @Insert_Id
 RETURN(@Return_Code)
