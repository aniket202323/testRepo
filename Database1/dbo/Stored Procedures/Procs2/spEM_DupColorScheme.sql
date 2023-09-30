CREATE PROCEDURE dbo.spEM_DupColorScheme
  @CS_Desc        nvarchar(50),
  @Original_CS_Id int,
  @User_Id   int,
  @CS_Id          int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create color scheme.
  --
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
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DupColorScheme',
                @CS_Desc + ','  + Convert(nVarChar(10), @Original_CS_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
 BEGIN TRANSACTION
  SELECT @Grid_Lines          = Grid_Lines,
         @Gray_Area           = Gray_Area,
         @Inactive_Area_BG    = Inactive_Area_BG,
         @Row_Header_BG       = Row_Header_BG,
         @Column_Header_BG    = Column_Header_BG,
         @Read_Only_BG        = Read_Only_BG,
         @Unavailable_BG      = Unavailable_BG,
         @Available_BG        = Available_BG,
         @Ready_BG            = Ready_BG,
         @Canceled_BG         = Canceled_BG,
         @Header_FG           = Header_FG,
         @No_Data_FG          = No_Data_FG,
         @No_Specification_FG = No_Specification_FG,
         @Target_FG           = Target_FG,
         @User_FG             = User_FG,
         @Warning_FG          = Warning_FG,
         @Reject_FG           = Reject_FG,
         @Entry_FG            = Entry_FG
    FROM Color_Scheme WHERE CS_Id = @Original_CS_Id
  INSERT INTO Color_Scheme(CS_Desc, Grid_Lines, Gray_Area, Inactive_Area_BG, Row_Header_BG,
                           Column_Header_BG, Read_Only_BG, Unavailable_BG, Available_BG, Ready_BG,
                           Canceled_BG, Header_FG, No_Data_FG, No_Specification_FG, Target_FG,
                           User_FG, Warning_FG, Reject_FG, Entry_FG)
    VALUES(@CS_Desc, @Grid_Lines, @Gray_Area, @Inactive_Area_BG, @Row_Header_BG,
           @Column_Header_BG, @Read_Only_BG, @Unavailable_BG, @Available_BG, @Ready_BG,
           @Canceled_BG, @Header_FG, @No_Data_FG, @No_Specification_FG, @Target_FG,
           @User_FG, @Warning_FG, @Reject_FG, @Entry_FG)
  SELECT @CS_Id = Scope_Identity()
  IF @CS_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1
 	  WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  Insert Into Color_Scheme_Data (CS_Id,Color_Scheme_Field_Id,Color_Scheme_Value)
 	 Select @CS_Id,Color_Scheme_Field_Id,Color_Scheme_Value
 	 From Color_Scheme_Data Where CS_Id = @Original_CS_Id
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0,Output_Parameters = convert(nVarChar(10),@CS_Id)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
